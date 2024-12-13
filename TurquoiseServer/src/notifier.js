import { log } from './utils';
import jwt from 'jsonwebtoken';

export class Notifier {
    constructor(env) {
        this.env = env;
        this.apnsJWT = null;
        this.apnsJWTExpiry = null;
    }

    // 生成 APNS JWT token
    async getAPNSToken() {
        try {
            // 检查现有 token 是否有效
            if (this.apnsJWT && this.apnsJWTExpiry && Date.now() < this.apnsJWTExpiry) {
                return this.apnsJWT;
            }

            // 验证必要的环境变量
            if (!this.env.APNS_KEY_ID || !this.env.APNS_TEAM_ID || !this.env.APNS_PRIVATE_KEY) {
                throw new Error('Missing APNS configuration');
            }

            // 生成新的 JWT token
            const header = {
                alg: 'ES256',
                kid: this.env.APNS_KEY_ID
            };

            const claims = {
                iss: this.env.APNS_TEAM_ID,
                iat: Math.floor(Date.now() / 1000)
            };

            const token = jwt.sign(claims, this.env.APNS_PRIVATE_KEY, {
                algorithm: 'ES256',
                header: header
            });

            // 设置 token 和过期时间（50分钟后过期）
            this.apnsJWT = token;
            this.apnsJWTExpiry = Date.now() + 50 * 60 * 1000;

            return token;
        } catch (error) {
            log.error('APNS token generation error:', error);
            throw error;
        }
    }

    async sendAPNS(token, payload) {
        try {
            const apnsToken = await this.getAPNSToken();
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

            // 使用生产或开发环境的 APNS 服务器
            const host = this.env.APNS_PRODUCTION === 'true' 
                ? 'api.push.apple.com'
                : 'api.sandbox.push.apple.com';

            const url = `https://${host}/3/device/${token}`;

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