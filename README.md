# Turquoise

Turquoise 是一个通知聚合服务，支持从多个数据源订阅通知并通过多种方式推送到移动设备。目前支持 APNS (iOS) 和 NTFY 推送服务。

## 功能特性

- 支持多种推送方式
  - APNS (iOS 设备)
  - NTFY (官方服务器和自托管)
- 灵活的订阅管理
- 支持自定义通知格式
- 完整的错误处理和日志记录

## API 文档

### 获取订阅列表

```http
GET /subscriptions?method=APNS&token=device-token
```

查询参数：
| 参数 | 类型 | 必填 | 描述 |
|------|------|------|------|
| method | string | 是 | 推送服务类型（APNS 或 NTFY） |
| token | string | 是 | 设备令牌或 NTFY 配置 |

响应示例：
```json
{
    "success": true,
    "data": [
        "ruleset-12345678",
        "ruleset-87654321"
    ]
}
```

错误响应：
```json
{
    "success": false,
    "error": {
        "code": "INVALID_METHOD",
        "message": "不支持的推送方法"
    }
}
```

### 订阅通知

```http
POST /subscribe
Content-Type: application/json

{
    "topic": "ruleset-id",
    "method": "APNS|NTFY",
    "token": "device-token-or-ntfy-config"
}
```

#### APNS 订阅示例

```json
{
    "topic": "ruleset-id",
    "method": "APNS",
    "token": "device-token"
}
```

#### NTFY 订阅示例

1. 使用官方服务器：
```json
{
    "topic": "ruleset-id",
    "method": "NTFY",
    "token": "notification-topic"
}
```

2. 使用自托管服务器：
```json
{
    "topic": "ruleset-id",
    "method": "NTFY",
    "token": {
        "topic": "notification-topic",
        "server": "https://ntfy.example.com",
        "auth": "认证信息"  // 可选
    }
}
```

### 发送通知

```http
POST /notify
Content-Type: application/json

{
    "topic": "ruleset-id",
    "title": "通知标题",
    "message": "通知内容",
    "data": {
        "type": "notification-type",
        "priority": 3,
        "url": "https://example.com",
        "coordinates": {
            "lat": 123.456,
            "lng": 789.012
        },
        "custom": "metadata"
    }
}
```

### NTFY 认证配置

NTFY 支持两种认证方式：

1. Access Token:
```json
{
    "auth": "tk_myaccesstoken"
}
```

2. 用户名密码:
```json
{
    "auth": "username:password"
}
```

## 安全说明

- 所有认证信息都经过安全存储
- 支持 HTTPS 加密传输
- 完整的错误处理机制
- 详细的日志记录（不包含敏感信息）

## 部署要求

### 环境变量

```toml
# APNS 配置
APNS_TOPIC = "your.app.bundle.id"
APNS_PRODUCTION = "true|false"
APNS_KEY_ID = "your-key-id"
APNS_TEAM_ID = "your-team-id"
APNS_PRIVATE_KEY = "your-private-key"

# NTFY 配置（可选）
NTFY_DEFAULT_SERVER = "https://ntfy.sh"
```

### 数据库

使用 Cloudflare D1 数据库存储订阅信息：

```sql
CREATE TABLE subscribers (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    topic TEXT NOT NULL,
    method TEXT NOT NULL CHECK (method IN ('APNS', 'NTFY')),
    token TEXT NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(topic, method, token)
);
```

## 错误处理

所有 API 响应都遵循统一格式：

```json
// 成功响应
{
    "success": true,
    "data": {}
}

// 错误响应
{
    "success": false,
    "error": {
        "code": "ERROR_CODE",
        "message": "错误描述"
    }
}
```

## 开发说明

1. 克隆仓库
2. 安装依赖
3. 配置环境变量
4. 部署到 Cloudflare Workers

## 许可证

MIT License