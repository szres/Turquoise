import { log } from './utils';

export class Notifier {
    constructor(env) {
        this.env = env;
    }

    async generateToken() {
        try {
            // 验证必要的环境变量
            if (!this.env.APNS_KEY_ID || !this.env.APNS_TEAM_ID || !this.env.APNS_PRIVATE_KEY) {
                throw new Error('Missing APNS configuration');
            }

            // 准备 JWT header 和 payload
            const header = {
                alg: 'ES256',
                kid: this.env.APNS_KEY_ID
            };

            const payload = {
                iss: this.env.APNS_TEAM_ID,
                iat: Math.floor(Date.now() / 1000)
            };

            // Base64Url 编码
            const encodedHeader = btoa(JSON.stringify(header)).replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '');
            const encodedPayload = btoa(JSON.stringify(payload)).replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '');

            // 创建签名内容
            const signatureInput = `${encodedHeader}.${encodedPayload}`;

            // 导入私钥
            const keyData = this.env.APNS_PRIVATE_KEY
                .replace(/-----BEGIN PRIVATE KEY-----/, '')
                .replace(/-----END PRIVATE KEY-----/, '')
                .replace(/\s/g, '');

            const binaryKey = Uint8Array.from(atob(keyData), c => c.charCodeAt(0));
            const privateKey = await crypto.subtle.importKey(
                'pkcs8',
                binaryKey,
                {
                    name: 'ECDSA',
                    namedCurve: 'P-256'
                },
                false,
                ['sign']
            );

            // 签名
            const encoder = new TextEncoder();
            const signatureBytes = await crypto.subtle.sign(
                { name: 'ECDSA', hash: 'SHA-256' },
                privateKey,
                encoder.encode(signatureInput)
            );

            // 编码签名
            const signature = btoa(String.fromCharCode(...new Uint8Array(signatureBytes)))
                .replace(/\+/g, '-')
                .replace(/\//g, '_')
                .replace(/=+$/, '');

            // 组合 JWT
            return `${signatureInput}.${signature}`;
        } catch (error) {
            log.error('Token generation error:', error);
            throw error;
        }
    }

    async sendAPNS(token, payload) {
        try {
            const apnsToken = await this.generateToken();
            const host = this.env.APNS_PRODUCTION === 'true' 
                ? 'api.push.apple.com'
                : 'api.sandbox.push.apple.com';

            const url = `https://${host}/3/device/${token}`;
            
            const apnsPayload = {
                aps: {
                    alert: {
                        title: payload.title,
                        body: payload.message
                    },
                    sound: "default",
                    badge: 1,
                    'mutable-content': 1
                },
                ...payload.data
            };

            const response = await fetch(url, {
                method: 'POST',
                headers: {
                    'apns-topic': this.env.APNS_TOPIC,
                    'apns-push-type': 'alert',
                    'apns-priority': '10',
                    'apns-expiration': '0',
                    'authorization': `bearer ${apnsToken}`,
                    'content-type': 'application/json'
                },
                body: JSON.stringify(apnsPayload)
            });

            if (!response.ok) {
                const errorData = await response.json();
                log.error('APNS send failed:', {
                    status: response.status,
                    error: errorData
                });
                throw new Error(`APNS send failed: ${errorData.reason || response.statusText}`);
            }

            log.info('APNS notification sent successfully', {
                token: token.substring(0, 6) + '...',
                title: payload.title
            });
        } catch (error) {
            log.error('APNS send error:', error);
            throw error;
        }
    }

    async sendNTFY(subscriber, payload) {
        try {
            // 解析 token 中的 NTFY 配置
            let ntfyConfig;
            try {
                ntfyConfig = JSON.parse(subscriber.token);
            } catch (error) {
                // 如果不是 JSON，则视为纯 topic
                ntfyConfig = {
                    topic: subscriber.token,
                    server: 'https://ntfy.sh',
                    auth: null  // 默认无认证
                };
            }

            const { topic, server = 'https://ntfy.sh', auth } = ntfyConfig;
            
            // 构建完整的 URL
            const url = `${server}/${topic}`;

            // 准备通知数据
            const ntfyPayload = {
                topic: topic,
                title: payload.title,
                message: payload.message,
                priority: this._getPriority(payload),
                tags: this._getTags(payload),
                click: payload.data?.url,
                actions: this._getActions(payload)
            };

            // 准备请求头
            const headers = {
                'Content-Type': 'application/json'
            };

            // 添加认证头
            if (auth) {
                if (auth.startsWith('tk_')) {
                    // 如果是 token
                    headers['Authorization'] = `Bearer ${auth}`;
                } else if (auth.includes(':')) {
                    // 如果是用户名密码
                    const authString = Buffer.from(auth).toString('base64');
                    headers['Authorization'] = `Basic ${authString}`;
                }
            }

            // 发送通知
            const response = await fetch(url, {
                method: 'POST',
                headers: headers,
                body: JSON.stringify(ntfyPayload)
            });

            if (!response.ok) {
                const error = await response.text();
                throw new Error(`NTFY send failed: ${error}`);
            }

            log.info('NTFY notification sent successfully', {
                server,
                topic,
                title: payload.title
            });
        } catch (error) {
            log.error('NTFY send error:', error);
            throw error;
        }
    }
} 