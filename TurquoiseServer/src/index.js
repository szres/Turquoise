import { NotificationDatabase } from './db';
import { Notifier } from './notifier';
import { log } from './utils';

export default {
    async fetch(request, env, ctx) {
        try {
            const url = new URL(request.url);
            const db = new NotificationDatabase(env.NOTIFICATION_DB);
            await db.initializeTables();

            if (request.method === 'POST' && url.pathname === '/notify') {
                // 处理通知请求
                const { topic, title, message, data } = await request.json();
                
                if (!topic || !title || !message) {
                    return new Response('Missing required fields', { status: 400 });
                }

                const subscribers = await db.getSubscribers(topic);
                const notifier = new Notifier(env);
                const results = [];

                for (const subscriber of subscribers) {
                    try {
                        const payload = { title, message, data };
                        
                        if (subscriber.method === 'APNS') {
                            await notifier.sendAPNS(subscriber.token, payload);
                        } else if (subscriber.method === 'NTFY') {
                            await notifier.sendNTFY(subscriber.token, payload);
                        }
                        
                        results.push({
                            success: true,
                            subscriber: subscriber.id
                        });
                    } catch (error) {
                        results.push({
                            success: false,
                            subscriber: subscriber.id,
                            error: error.message
                        });
                    }
                }

                return Response.json({
                    success: true,
                    results
                });
            }

            if (request.method === 'POST' && url.pathname === '/subscribe') {
                // 处理订阅请求
                const { topic, method, token } = await request.json();
                
                if (!topic || !method || !token) {
                    return new Response('Missing required fields', { status: 400 });
                }

                if (!['APNS', 'NTFY'].includes(method)) {
                    return new Response('Invalid method', { status: 400 });
                }

                await db.addSubscriber(topic, method, token);
                return Response.json({ success: true });
            }

            if (request.method === 'POST' && url.pathname === '/unsubscribe') {
                // 处理取消订阅请求
                const { topic, method, token } = await request.json();
                
                if (!topic || !method || !token) {
                    return new Response('Missing required fields', { status: 400 });
                }

                await db.removeSubscriber(topic, method, token);
                return Response.json({ success: true });
            }

            if (url.pathname === '/subscriptions' && request.method === 'GET') {
                const params = new URLSearchParams(url.search);
                const method = params.get('method');
                const token = params.get('token');
                
                if (!method || !token) {
                    return Response.json({
                        success: false,
                        error: {
                            code: 'INVALID_PARAMS',
                            message: 'Method and token are required'
                        }
                    }, { status: 400 });
                }
                
                if (!['APNS', 'NTFY'].includes(method)) {
                    return Response.json({
                        success: false,
                        error: {
                            code: 'INVALID_METHOD',
                            message: 'Unsupported push notification method'
                        }
                    }, { status: 400 });
                }
                
                try {
                    const subscriptions = await db.getSubscriptionsByToken(method, token);
                    return Response.json({
                        success: true,
                        data: subscriptions
                    });
                } catch (error) {
                    return Response.json({
                        success: false,
                        error: {
                            code: 'SERVER_ERROR',
                            message: error.message
                        }
                    }, { status: 500 });
                }
            }
            
            if (url.pathname === '/subscribe' && request.method === 'POST') {
                const { topic, method, token } = await request.json();
                
                const key = `${method}:${token}:subscriptions`;
                let subscriptions = await env.TURQUOISE_KV.get(key, { type: 'json' }) || [];
                
                if (!subscriptions.includes(topic)) {
                    subscriptions.push(topic);
                    await env.TURQUOISE_KV.put(key, JSON.stringify(subscriptions));
                }
                
                return Response.json({ success: true });
            }
            
            if (url.pathname === '/unsubscribe' && request.method === 'POST') {
                const { topic, method, token } = await request.json();
                
                const key = `${method}:${token}:subscriptions`;
                let subscriptions = await env.TURQUOISE_KV.get(key, { type: 'json' }) || [];
                
                subscriptions = subscriptions.filter(t => t !== topic);
                await env.TURQUOISE_KV.put(key, JSON.stringify(subscriptions));
                
                return Response.json({ success: true });
            }

            return new Response('Not found', { status: 404 });
        } catch (error) {
            log.error('Request handling error:', error);
            return new Response(error.message, { status: 500 });
        }
    }
}; 