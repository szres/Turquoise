# Turquoise

Turquoise 是一个通知聚合服务，支持从多个数据源订阅通知并通过 APNS 推送到 iOS 设备。它允许用户管理多个数据源端点，并为每个端点的规则集单独设置订阅。

## 数据源集成

### 端点要求

要集成新的数据源，需要实现以下 API 端点：

#### 获取规则集列表
```http
GET /rulesets
```

Response:
```json
{
    "success": true,
    "data": [
        {
            "uuid": "unique-rule-set-id",
            "name": "Rule Set Name",
            "description": "Rule Set Description",
            "rules": [
                {
                    "type": "string",
                    "value": "string",
                    "center": {
                        "lat": 0.0,
                        "lng": 0.0
                    },
                    "radius": 0.0,
                    "points": [
                        {
                            "lat": 0.0,
                            "lng": 0.0
                        }
                    ]
                }
            ],
            "record_count": 0,
            "last_record_at": "yyyy-MM-dd HH:mm:ss",
            "created_at": "yyyy-MM-dd HH:mm:ss",
            "updated_at": "yyyy-MM-dd HH:mm:ss"
        }
    ]
}
```

### Turquoise Server API

Turquoise 服务器处理所有通知的订阅和推送。

#### 订阅通知
```http
POST /subscribe
Content-Type: application/json

{
    "topic": "rule-set-uuid",
    "method": "APNS",
    "token": "device-token"
}
```

#### 取消订阅
```http
POST /unsubscribe
Content-Type: application/json

{
    "topic": "rule-set-uuid",
    "method": "APNS",
    "token": "device-token"
}
```

#### 发送通知
```http
POST /notify
Content-Type: application/json

{
    "topic": "rule-set-uuid",
    "title": "通知标题",
    "message": "通知内容",
    "data": {
        "custom": "metadata"
    }
}
```

## iOS 客户端功能

- 管理多个数据源端点
- 自动获取并显示每个端点的规则集
- 支持订阅/取消订阅规则集
- 自动处理 APNS 注册和权限管理
- 使用 SwiftData 进行本地数据持久化

### 系统要求

- iOS 17.0+
- Xcode 15.0+
- Swift 5.9+

### 安装

1. 克隆仓库
```bash
git clone https://github.com/yourusername/Turquoise.git
```

2. 打开 Xcode 项目
```bash
cd Turquoise
open Turquoise.xcodeproj
```

3. 配置开发者账号和推送证书

4. 运行应用

### 使用方法

1. 首次启动时允许通知权限
2. 添加数据源端点
3. 查看可用的规则集
4. 订阅感兴趣的规则集
5. 等待通知推送

## 技术栈

- SwiftUI
- SwiftData
- UserNotifications
- Async/Await
- CloudFlare Workers (服务端)

## 架构

- Models: 使用 SwiftData 管理数据模型
- Views: SwiftUI 视图层
- Services: 网络服务和通知管理
- App: 应用程序生命周期和环境配置

## 开发

### 添加新的数据源

1. 实现 `/rulesets` 端点，返回符合规范的 JSON 格式
2. 确保规则集包含所有必要字段
3. 实现通知触发逻辑，调用 Turquoise Server 的 `/notify` 端点

## 许可证

[Your License] 
