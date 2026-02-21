# Windows 部署快速指南

## 🚀 快速部署（5分钟）

### 前提条件
- ✅ Node.js v22+
- ✅ Docker Desktop 运行中
- ✅ cc-switch 代理运行在 15721 端口

### 部署步骤

```cmd
# 1. 克隆并安装
git clone https://github.com/allanpk716/nanoclaw.git
cd nanoclaw
npm install

# 2. 配置环境变量
copy .env.example .env
notepad .env
```

在 `.env` 中填入：
```env
ANTHROPIC_API_KEY=sk-dummy
ANTHROPIC_BASE_URL=http://host.docker.internal:15721
TELEGRAM_BOT_TOKEN=<从@BotFather获取>
TELEGRAM_ONLY=true
ASSISTANT_NAME=nex
ASSISTANT_HAS_OWN_NUMBER=false
```

```cmd
# 3. 构建项目
npm run build

# 4. ⚠️ 关键步骤：同步环境变量
copy .env data\env\env

# 5. 创建目录
mkdir groups\main
mkdir data\sessions\main\.claude
mkdir data\ipc\main

# 6. 启动服务
start.bat

# 7. 在Telegram中获取Chat ID
# 发送: /chatid
# 记录返回的 ID（如: tg:123456789）

# 8. 注册Chat到数据库
register-chat.bat
# 输入Chat ID和名称

# 9. 测试
# 在Telegram中发送: @nex 你好
```

## ⚠️ 最常见问题

### Invalid API key 错误

**原因**: 环境变量未同步到容器

**解决**:
```cmd
copy .env data\env\env
stop.bat
start.bat
```

**验证**: 在Telegram中发送 `@nex 你好`，应该收到AI回复。

## 📋 管理命令

```cmd
start.bat          # 启动服务
stop.bat           # 停止服务
tail-log.bat       # 查看日志
nanoclaw.bat       # 交互式菜单
```

## 🔍 故障排查

```cmd
# 检查进程
tasklist | findstr node.exe

# 检查环境变量同步
fc .env data\env\env

# 检查API代理
curl http://127.0.0.1:15721/health

# 查看容器日志
docker logs $(docker ps -lq --filter "name=nanoclaw-")
```

## 📚 完整文档

详细部署说明请查看: [DEPLOYMENT-TELEGRAM-WINDOWS.md](docs/DEPLOYMENT-TELEGRAM-WINDOWS.md)

## ✅ 成功标志

- `tasklist` 显示1个node进程
- Telegram bot响应消息
- 收到AI回复（不是"Invalid API key"）

---

**部署成功后，你可以**:
- 在Telegram中与AI对话
- 发送 `@nex <消息>` 获得AI帮助
- Bot会记住对话历史（存储在 `groups/main/CLAUDE.md`）
