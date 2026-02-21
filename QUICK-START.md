# NanoClaw 快速启动指南 (Windows)

## 🚀 快速启动

```cmd
cd C:\WorkSpace\agent\nanoclaw
start.bat
```

## 📋 管理命令

| 命令 | 说明 |
|------|------|
| `start.bat` | 启动 NanoClaw（后台运行） |
| `stop.bat` | 停止 NanoClaw |
| `tail-log.bat` | 实时查看日志 |
| `nanoclaw.bat` | 交互式管理菜单 |

## 📊 检查状态

```cmd
# 查看进程
tasklist | findstr node

# 查看最新日志
type logs\nanoclaw.log

# 实时日志
tail-log.bat
```

## 🔧 常见问题

### 1. Bot 没有响应

检查：
- Node 进程是否运行：`tasklist | findstr node`
- Bot token 是否正确：检查 `.env` 文件
- Chat 是否注册：`sqlite3 store/messages.db "SELECT * FROM registered_groups"`

### 2. Docker 容器无法访问代理

确保 `.env` 中使用：
```
ANTHROPIC_BASE_URL=http://host.docker.internal:15721
```
而不是 `127.0.0.1`

### 3. cc-switch 代理未运行

测试代理：
```bash
curl http://127.0.0.1:15721
```

### 4. 需要重启

```cmd
stop.bat
start.bat
```

## 📁 重要文件位置

```
C:\WorkSpace\agent\nanoclaw\
├── .env                    # 环境变量配置
├── start.bat              # 启动脚本
├── stop.bat               # 停止脚本
├── tail-log.bat           # 日志查看
├── logs\
│   └── nanoclaw.log       # 运行日志
├── store\
│   └── messages.db        # SQLite 数据库
└── groups\
    └── main\              # 主群组记忆文件
```

## 🔑 配置检查清单

- [x] Node.js v22+ 已安装
- [x] Docker Desktop 正在运行
- [x] cc-switch 代理在端口 15721 运行
- [x] `.env` 文件配置正确
- [x] Telegram bot token 有效
- [x] Chat ID 已注册到数据库

## 📝 日志说明

正常启动日志示例：
```
[19:10:21] INFO: Database initialized
[19:10:21] INFO: State loaded (groupCount: 1)
[19:10:22] INFO: Telegram bot connected
[19:10:22] INFO: NanoClaw running (trigger: @nex)
```

收到消息日志示例：
```
[19:12:51] INFO: Checking if chat is registered
[19:12:51] INFO: Telegram message stored
[19:12:51] INFO: Processing messages
[19:12:52] INFO: Spawning container agent
[19:13:08] INFO: Agent output: ...
[19:13:09] INFO: Telegram message sent
```

## 🆘 获取帮助

- 详细部署文档：`docs\DEPLOYMENT-TELEGRAM-WINDOWS.md`
- 项目说明：`README.md`
- 架构决策：`docs\REQUIREMENTS.md`

## 💡 提示

- **不要使用 PM2**：在 Windows 上有兼容性问题
- **日志轮转**：定期清理 `logs\nanoclaw.log`
- **备份**：定期备份 `store\` 目录和 `.env` 文件
