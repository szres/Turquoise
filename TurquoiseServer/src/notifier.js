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

    async sendNTFY(token, payload) {
        try {
            const response = await fetch(`https://ntfy.sh/${token}`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify({
                    topic: token,
                    title: payload.title,
                    message: payload.message,
                    priority: payload.priority || 3,
                    tags: payload.tags || []
                })
            });

            if (!response.ok) {
                throw new Error(`NTFY send failed: ${response.statusText}`);
            }

            log.info('NTFY notification sent successfully');
        } catch (error) {
            log.error('NTFY send error:', error);
            throw error;
        }
    }
} 