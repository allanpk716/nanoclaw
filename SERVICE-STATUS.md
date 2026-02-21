# NanoClaw 服务状态检查

## 检查时间
2026-02-21 21:30

## 服务状态

### ✅ Node.js 进程
- **状态**: 运行中
- **进程数**: 1
- **PID**: 139024
- **内存**: ~94 MB

### ✅ Telegram Bot
- **Bot名称**: @allan_simple_bot
- **Bot ID**: 8583297975
- **Token状态**: 有效
- **Webhook**: 未设置（使用long polling）
- **功能**:
  - ✅ 可以加入群组
  - ✅ 可以读取所有群组消息

### ✅ 环境变量
已从 `.env` 文件正确加载：
- TELEGRAM_BOT_TOKEN ✅
- ANTHROPIC_BASE_URL ✅
- TELEGRAM_ONLY=true ✅

### ✅ 启动方式
使用批处理脚本（推荐）：
```cmd
start.bat
```

## 测试步骤

1. **获取Chat ID**:
   - 打开Telegram
   - 找到 @allan_simple_bot
   - 发送 `/chatid`
   - 记录返回的chat ID

2. **注册Chat到数据库**:
   ```sql
   -- 使用SQLite工具或Node.js脚本
   INSERT OR REPLACE INTO registered_groups
   (jid, name, folder, trigger_pattern, added_at, requires_trigger)
   VALUES ('tg:<chat-id>', '<name>', 'main', '@nex', datetime('now'), 0);
   ```

3. **测试消息**:
   - 发送 `@nex 你好`
   - 应该收到AI回复

## 管理命令

```cmd
# 启动服务
start.bat

# 停止服务
stop.bat

# 查看日志
tail-log.bat

# 查看进程
tasklist | findstr node.exe

# 查看日志文件
type logs\nanoclaw.log
```

## 故障排查

### 服务未运行
```cmd
# 检查进程
tasklist | findstr node.exe

# 前台运行查看错误
node --import dotenv/config dist/index.js
```

### Telegram bot不响应
```cmd
# 检查bot token
curl "https://api.telegram.org/bot<TOKEN>/getMe"

# 检查webhook
curl "https://api.telegram.org/bot<TOKEN>/getWebhookInfo"

# 检查数据库
node -e "import Database from 'better-sqlite3'; const db = new Database('store/messages.db'); console.log(db.prepare('SELECT * FROM registered_groups').all());"
```

### API连接问题
```cmd
# 检查cc-switch代理
curl http://127.0.0.1:15721

# 检查Docker
docker ps | findstr nanoclaw
```

## 配置文件

### .env 文件位置
`C:\WorkSpace\agent\nanoclaw\.env`

### 日志文件位置
`C:\WorkSpace\agent\nanoclaw\logs\nanoclaw.log`

### 数据库位置
`C:\WorkSpace\agent\nanoclaw\store\messages.db`

### Groups目录
`C:\WorkSpace\agent\nanoclaw\groups\main\`
