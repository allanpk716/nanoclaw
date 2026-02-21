# NanoClaw 部署指南 - 使用 Telegram 和 cc-switch 代理

本文档记录了在 Windows 系统上部署 NanoClaw 的完整流程，包括使用 cc-switch 作为 LLM API 代理，以及使用 Telegram 作为交互渠道的配置方法。

## 目录

- [系统要求](#系统要求)
- [部署步骤](#部署步骤)
- [常见问题](#常见问题)
- [配置说明](#配置说明)

---

## 系统要求

- **操作系统**: Windows 10/11
- **Node.js**: v22.14.0 或更高版本
- **Docker Desktop**: 已安装并运行
- **Telegram 账号**: 用于创建和测试 bot
- **LLM API 代理**: cc-switch 或其他兼容 Anthropic API 的代理服务

---

## 部署步骤

### 1. 获取 NanoClaw 代码

```bash
git clone https://github.com/your-repo/nanoclaw.git
cd nanoclaw
```

### 2. 安装依赖

```bash
npm install
```

### 3. 配置环境变量

创建 `.env` 文件：

```env
# Claude API Configuration for cc-switch proxy
ANTHROPIC_API_KEY=sk-dummy
ANTHROPIC_BASE_URL=http://host.docker.internal:15721

# Assistant Configuration
ASSISTANT_NAME=<你的助手名称>
ASSISTANT_HAS_OWN_NUMBER=false

# Telegram Configuration
TELEGRAM_BOT_TOKEN=<你的-telegram-bot-token>
TELEGRAM_ONLY=true
```

**重要配置说明**：

- `ANTHROPIC_BASE_URL`: 使用 `host.docker.internal` 而不是 `127.0.0.1`，这样 Docker 容器可以访问宿主机的服务
- `TELEGRAM_ONLY=true`: 只使用 Telegram，不使用 WhatsApp
- `ANTHROPIC_API_KEY`: 可以是任意值（cc-switch 会处理实际的 API 密钥）

### 4. 配置 cc-switch 代理

确保 cc-switch 代理在宿主机上运行并监听 `15721` 端口：

```bash
# 验证代理是否运行
curl http://127.0.0.1:15721
```

### 5. 添加 Telegram 支持

运行 Telegram 集成 skill：

```bash
npx tsx scripts/apply-skill.ts --init
npx tsx scripts/apply-skill.ts .claude/skills/add-telegram
```

这会自动：
- 添加 Telegram 频道代码
- 安装 `grammy` npm 包
- 更新配置文件

### 6. 构建项目

```bash
npm run build
```

### 7. 创建 Telegram Bot

1. 在 Telegram 中搜索 `@BotFather`
2. 发送 `/newbot` 命令
3. 按提示设置 bot 名称和用户名
4. 保存返回的 bot token（格式：`123456:ABC-DEF...`）

### 8. 获取 Chat ID

1. 在 Telegram 中打开你的 bot
2. 发送 `/chatid` 命令
3. Bot 会返回你的 chat ID（格式：`tg:123456789`）

### 9. 注册 Chat 到数据库

```bash
node -e "
import Database from 'better-sqlite3';
const db = new Database('store/messages.db');

const stmt = db.prepare(\`
  INSERT OR REPLACE INTO registered_groups
  (jid, name, folder, trigger_pattern, added_at, requires_trigger)
  VALUES (?, ?, ?, ?, ?, ?)
\`);

stmt.run(
  'tg:<your-chat-id>',
  '<chat-name>',
  'main',
  '@<trigger-word>',
  new Date().toISOString(),
  0  // 0 = 主聊天，不需要触发词
);

db.close();
"
```

### 10. 创建必要的目录

```bash
mkdir -p groups/main
mkdir -p data/env
cp .env data/env/env
```

### 11. 配置 PM2 启动（推荐）

创建 `ecosystem.config.cjs` 文件：

```javascript
module.exports = {
  apps: [{
    name: 'nanoclaw',
    script: 'dist/index.js',
    cwd: 'C:\\WorkSpace\\agent\\nanoclaw',
    interpreter: 'node',
    instances: 1,
    autorestart: true,
    watch: false,
    max_memory_restart: '1G',
    env: {
      NODE_ENV: 'production',
      ANTHROPIC_API_KEY: 'sk-dummy',
      ANTHROPIC_BASE_URL: 'http://host.docker.internal:15721',
      ASSISTANT_NAME: '<你的助手名称>',
      ASSISTANT_HAS_OWN_NUMBER: 'false',
      TELEGRAM_BOT_TOKEN: '<你的-telegram-bot-token>',
      TELEGRAM_ONLY: 'true'
    },
    error_file: 'C:\\WorkSpace\\agent\\nanoclaw\\logs\\pm2-error.log',
    out_file: 'C:\\WorkSpace\\agent\\nanoclaw\\logs\\pm2-out.log',
    log_date_format: 'YYYY-MM-DD HH:mm:ss',
    merge_logs: true,
    max_restarts: 10,
    min_uptime: '10s',
    restart_delay: 5000
  }]
};
```

**重要**：必须使用 `.cjs` 扩展名，因为项目使用 ES modules。

启动服务：

```bash
pm2 start ecosystem.config.cjs
pm2 status
pm2 logs nanoclaw
```

### 12. 验证运行状态

```bash
pm2 status
```

应该看到：
- `status` 为 `online`
- `uptime` 持续增长（不是 0 或 1s）
- `↺`（重启次数）为 0

如果看到重启次数不断增加，说明进程在崩溃循环。检查日志：
```bash
pm2 logs nanoclaw --lines 100
```

---

## 常见问题

### 问题 1: 数据库 Schema 不匹配

**症状**: 错误信息 `table registered_groups has no column named added_at`

**原因**: 数据库使用的是旧 schema（列名是 `chat_jid` 和 `trigger`），但代码期望新 schema（列名是 `jid` 和 `trigger_pattern`）

**解决方案**:

1. 备份现有数据
2. 删除旧表并创建新表：

```sql
DROP TABLE IF EXISTS registered_groups;

CREATE TABLE registered_groups (
  jid TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  folder TEXT NOT NULL UNIQUE,
  trigger_pattern TEXT NOT NULL,
  added_at TEXT NOT NULL,
  container_config TEXT,
  requires_trigger INTEGER DEFAULT 1
);
```

3. 重新注册 chat（见步骤 9）

### 问题 2: Docker 容器无法访问 cc-switch 代理

**症状**: 容器启动后卡住，没有响应

**原因**: `.env` 中使用 `127.0.0.1`，容器内部无法访问

**解决方案**:

将 `.env` 中的：
```
ANTHROPIC_BASE_URL=http://127.0.0.1:15721
```

改为：
```
ANTHROPIC_BASE_URL=http://host.docker.internal:15721
```

### 问题 3: 环境变量未传递到容器

**症状**: 容器启动但没有 ANTHROPIC_API_KEY 等环境变量

**原因**: 环境变量需要通过 `data/env/env` 文件传递

**解决方案**:

```bash
mkdir -p data/env
cp .env data/env/env
```

### 问题 4: Telegram Bot 不响应消息

**症状**: Bot 启动成功，但发送消息没有响应

**可能原因**:
1. Chat 未正确注册
2. Bot 被用户 block
3. Grammy long polling 问题

**诊断步骤**:

1. 检查 bot token 有效性：
```bash
curl "https://api.telegram.org/bot<YOUR_TOKEN>/getMe"
```

2. 检查 webhook 状态：
```bash
curl "https://api.telegram.org/bot<YOUR_TOKEN>/getWebhookInfo"
```

3. 启用调试日志：
```bash
DEBUG=grammy* node dist/index.js
```

4. 手动测试发送消息：
```bash
curl "https://api.telegram.org/bot<YOUR_TOKEN>/sendMessage?chat_id=<CHAT_ID>&text=Test"
```

### 问题 5: Apple Container vs Docker

**症状**: 错误信息 `Apple Container system is required but failed to start`

**原因**: 代码使用 Apple Container 命令，但你使用的是 Docker

**解决方案**:

修改 `src/index.ts`：

```typescript
// 添加导入
import {
  ensureContainerRuntimeRunning,
  cleanupOrphans,
} from './container-runtime.js';

// 替换 ensureContainerSystemRunning() 调用
async function main(): Promise<void> {
  ensureContainerRuntimeRunning();  // 使用 Docker 版本
  cleanupOrphans();
  initDatabase();
  // ...
}
```

删除旧的 `ensureContainerSystemRunning()` 函数定义。

### 问题 6: PM2 进程不断重启（PID 每次查询都在变化）

**症状**: `pm2 status` 显示 `↺` 列的数字不断增加，uptime 总是很小（0-1秒）

**原因**: PM2 没有加载 `.env` 文件中的环境变量，导致进程因缺少必要的环境变量而崩溃

**解决方案**:

1. 创建 `ecosystem.config.cjs` 文件（不是 `.js`）：

```javascript
module.exports = {
  apps: [{
    name: 'nanoclaw',
    script: 'dist/index.js',
    cwd: 'C:\\WorkSpace\\agent\\nanoclaw',
    env: {
      ANTHROPIC_API_KEY: 'sk-dummy',
      ANTHROPIC_BASE_URL: 'http://host.docker.internal:15721',
      ASSISTANT_NAME: 'nex',
      ASSISTANT_HAS_OWN_NUMBER: 'false',
      TELEGRAM_BOT_TOKEN: '<your-token>',
      TELEGRAM_ONLY: 'true'
    },
    error_file: 'logs/pm2-error.log',
    out_file: 'logs/pm2-out.log',
    max_restarts: 10,
    min_uptime: '10s'
  }]
};
```

2. 删除旧进程并重新启动：

```bash
pm2 delete all
pm2 start ecosystem.config.cjs
pm2 logs  # 监控日志确认正常运行
```

**诊断命令**：
```bash
pm2 describe nanoclaw  # 查看重启次数
pm2 logs nanoclaw --lines 100  # 查看错误日志
pm2 env 0  # 查看环境变量是否正确设置
```

### 问题 7: Telegram Bot Privacy Mode

**症状**: Bot 在私聊中工作正常，但在群组中只响应 @mentions

**原因**: Telegram bot 默认启用 Group Privacy 模式

**解决方案**:

1. 打开 `@BotFather`
2. 发送 `/mybots`
3. 选择你的 bot
4. 进入 **Bot Settings** > **Group Privacy**
5. 选择 **Turn off**
6. 如果 bot 已在群组中，需要移除并重新添加

---

## 配置说明

### Telegram Channel 配置

**文件**: `src/channels/telegram.ts`

关键功能：
- 自动将 bot @mentions 转换为触发词格式
- 支持 `/chatid` 和 `/ping` 命令
- 处理文本、图片、文档、贴纸等消息类型

### 数据库配置

**文件**: `store/messages.db` (SQLite)

关键表：
- `registered_groups`: 注册的聊天列表
- `messages`: 消息历史
- `chats`: 聊天元数据

### 挂载配置

**文件**: `~/.config/nanoclaw/mount-allowlist.json`

示例配置：

```json
{
  "allowedRoots": [
    {
      "hostPath": "C:/WorkSpace/nex_things",
      "containerPath": "/workspace/extra/nex_things",
      "readonly": false
    }
  ],
  "blockedPatterns": [],
  "nonMainReadOnly": true
}
```

### 环境变量

| 变量名 | 说明 | 示例值 |
|--------|------|--------|
| `ANTHROPIC_API_KEY` | Claude API 密钥 | `sk-dummy` |
| `ANTHROPIC_BASE_URL` | API 代理地址 | `http://host.docker.internal:15721` |
| `ASSISTANT_NAME` | 助手名称 | `nex` |
| `ASSISTANT_HAS_OWN_NUMBER` | 是否有专用号码 | `false` |
| `TELEGRAM_BOT_TOKEN` | Telegram bot token | `123456:ABC-DEF...` |
| `TELEGRAM_ONLY` | 只使用 Telegram | `true` |

---

## 调试技巧

### 启用详细日志

```bash
DEBUG=grammy* node dist/index.js
```

### 查看容器日志

```bash
# 列出运行中的容器
docker ps --filter "name=nanoclaw-"

# 查看容器日志
docker logs <container-name>
```

### 检查数据库

```bash
node -e "
import Database from 'better-sqlite3';
const db = new Database('store/messages.db');

console.log('=== Registered Groups ===');
const groups = db.prepare('SELECT * FROM registered_groups').all();
console.log(groups);

console.log('\\n=== Recent Messages ===');
const messages = db.prepare('SELECT * FROM messages ORDER BY timestamp DESC LIMIT 10').all();
console.log(messages);

db.close();
"
```

### 测试 API 连接

```bash
# 测试 cc-switch 代理
curl http://127.0.0.1:15721

# 从容器内部测试
docker exec <container-name> curl http://host.docker.internal:15721
```

---

## 生产环境建议

### 使用 PM2 管理 Node 进程

```bash
npm install -g pm2
pm2 start dist/index.js --name nanoclaw
pm2 save
pm2 startup
```

### 日志轮转

配置日志轮转以防止日志文件过大：

```javascript
// 在 logger.ts 中添加
import { rotate } from 'rotating-file';

const transport = new rotator({
  path: 'logs/nanoclaw.log',
  size: '10m',
  count: 5
});
```

### 备份策略

定期备份以下目录：
- `store/` (数据库)
- `groups/` (会话记忆)
- `.env` (配置)

### 监控

设置健康检查：

```bash
# 检查进程
ps aux | grep "node.*dist/index.js"

# 检查端口（如果配置了）
netstat -an | grep <port>

# 检查 Docker
docker ps | grep nanoclaw
```

---

## PM2 管理命令

### 基本命令

```bash
# 启动
pm2 start ecosystem.config.cjs

# 查看状态
pm2 status

# 查看日志（实时）
pm2 logs nanoclaw

# 查看最近日志
pm2 logs nanoclaw --lines 100

# 重启
pm2 restart nanoclaw

# 停止
pm2 stop nanoclaw

# 删除进程
pm2 delete nanoclaw

# 查看详细信息
pm2 describe nanoclaw

# 监控（CPU、内存）
pm2 monit
```

### 日志位置

- **标准输出**: `C:\WorkSpace\agent\nanoclaw\logs\pm2-out.log`
- **错误输出**: `C:\WorkSpace\agent\nanoclaw\logs\pm2-error.log`

### 开机自启动

**方案 1: pm2-windows-startup**

```bash
npm install -g pm2-windows-startup
pm2-startup install
pm2 save
```

**方案 2: NSSM（更稳定）**

```bash
# 下载并解压 NSSM
# 添加到 PATH
nssm install NanoClaw
# 在 GUI 中配置
nssm start NanoClaw
```

---

## 故障排除清单

- [ ] Node.js 版本正确 (v22+)
- [ ] Docker 正在运行
- [ ] `.env` 文件配置正确
- [ ] `data/env/env` 文件存在并同步
- [ ] cc-switch 代理正在运行并可访问
- [ ] Telegram bot token 有效
- [ ] Chat ID 已注册到数据库
- [ ] `groups/main` 目录存在
- [ ] 项目已构建 (`npm run build`)
- [ ] 没有多个 NanoClaw 进程冲突

---

## 推荐的启动方式（Windows）

**不推荐使用 PM2** - 在 Windows 上有兼容性问题（进程重启循环、日志无法捕获）

### 方式 1: 使用批处理脚本（推荐）

```cmd
# 启动（后台运行）
start.bat

# 停止
stop.bat

# 查看实时日志
tail-log.bat

# 或使用完整菜单
nanoclaw.bat
```

### 方式 2: 直接命令行

```cmd
# 前台运行（可看到实时日志）
cd C:\WorkSpace\agent\nanoclaw
node dist/index.js

# 后台运行（重定向日志）
cd C:\WorkSpace\agent\nanoclaw
start /B node dist/index.js > logs\nanoclaw.log 2>&1
```

### 方式 3: 使用 NSSM（Windows 服务）

适合需要开机自启动的场景：

```bash
# 下载 NSSM: https://nssm.cc/download
# 添加到 PATH

nssm install NanoClaw "C:\Program Files\nodejs\node.exe" "C:\WorkSpace\agent\nanoclaw\dist\index.js"
nssm set NanoClaw AppDirectory "C:\WorkSpace\agent\nanoclaw"
nssm set NanoClaw DisplayName "NanoClaw Telegram Bot"
nssm start NanoClaw
```

管理命令：
```cmd
nssm status NanoClaw    # 查看状态
nssm restart NanoClaw   # 重启
nssm stop NanoClaw      # 停止
nssm remove NanoClaw    # 删除服务
```

---

## 升级和维护

### 更新代码

```bash
git pull
npm install
npm run build
# 重启服务
```

### 重建 Docker 镜像

```bash
./container/build.sh --no-cache
```

### 清理旧容器

```bash
docker ps -a --filter "name=nanoclaw-" -q | xargs docker rm -f
```

---

## 参考链接

- [NanoClaw GitHub](https://github.com/your-repo/nanoclaw)
- [cc-switch 项目](https://github.com/farion1231/cc-switch)
- [Telegram Bot API 文档](https://core.telegram.org/bots/api)
- [Grammy 文档](https://grammy.dev/)
- [Docker Desktop for Windows](https://www.docker.com/products/docker-desktop)

---

## 更新日志

- **2026-02-21**: 初始版本，基于 Windows 10 + Docker + Telegram + cc-switch 部署经验

---

## 贡献

如果你在部署过程中遇到其他问题并找到了解决方案，欢迎更新本文档！

