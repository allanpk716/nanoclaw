# Windows 用户部署指南

## 快速开始（5 分钟）

### 1. 安装前置要求

- [Node.js v22+](https://nodejs.org/) - 下载并安装 LTS 版本
- [Docker Desktop](https://www.docker.com/products/docker-desktop) - 下载并安装
- [Git for Windows](https://gitforwindows.org/) - 包含 Git Bash

### 2. 克隆并运行 Setup

```bash
# 克隆仓库
git clone https://github.com/your-repo/nanoclaw.git
cd nanoclaw

# 运行自动 setup
npx tsx scripts/apply-skill.ts .claude/skills/setup
```

### 3. 按提示配置

Setup 会自动：
- ✅ 检测 Windows 平台
- ✅ 安装依赖
- ✅ 创建 `.env` 文件
- ✅ 同步环境变量到容器
- ✅ 创建所有必需目录
- ✅ 生成服务管理脚本

你需要提供：
- Telegram Bot Token（从 @BotFather 获取）
- 助手名称（默认：nex）

### 4. 启动服务

```bash
# Windows 批处理脚本
start.bat          # 启动服务
stop.bat           # 停止服务
tail-log.bat       # 查看日志
```

### 5. 配置 Telegram

```bash
# 1. 在 Telegram 中发送 /chatid 给你的 bot
# 2. 记录返回的 chat ID（格式：tg:123456789）
# 3. 运行注册脚本
register-chat.bat

# 按提示输入：
# - Chat ID: tg:123456789
# - Chat 名称: MyChat
# - 触发词: @nex（私聊可留空）
```

### 6. 测试

在 Telegram 中发送：
```
@nex 你好
```

预期：收到 AI 回复 ✅

---

## 故障排除

### 问题：Invalid API key

**原因：** 环境变量未同步到容器

**解决：**
```bash
# 重新运行环境配置
.claude/skills/setup/scripts/04.5-setup-env.sh

# 验证同步
diff .env data/env/env
# 应该无输出（文件完全相同）
```

### 问题：Cannot connect to Docker daemon

**解决：**
```bash
# 1. 启动 Docker Desktop
# 2. 等待完全启动（系统托盘图标稳定）
# 3. 验证
docker info
```

### 问题：node.exe not found

**解决：**
```bash
# 1. 确保 Node.js 已安装
node --version

# 2. 如果命令未找到：
#    - 重启 Git Bash
#    - 或将 Node.js 添加到 PATH
#    - 或重新安装 Node.js（勾选 "Add to PATH"）
```

### 问题：服务启动失败

**解决：**
```bash
# 查看日志
tail-log.bat

# 或直接查看
type logs\nanoclaw.log

# 常见原因：
# 1. Docker 未运行
# 2. .env 文件缺失
# 3. 端口被占用
```

---

## 常见问题

**Q: 为什么要用 Git Bash？**
A: Setup 脚本使用 bash 编写。PowerShell 版本计划在未来发布。

**Q: `data/env/env` 是什么？**
A: Windows + Docker 的关键文件。容器从这里读取环境变量。Setup 会自动同步 `.env` → `data/env/env`。

**Q: 可以用 WSL 吗？**
A: 可以！WSL 也被检测为 Windows 平台，流程完全相同。

**Q: 如何开机自启动？**
A: Setup 提供 NSSM 服务选项，可以将 NanoClaw 安装为 Windows 服务。

**Q: 如何更新？**
A:
```bash
git pull
npm install
npm run build
# 重启服务
stop.bat
start.bat
```

---

## 进阶配置

### 使用 NSSM 服务（生产环境推荐）

```bash
# 1. 安装 NSSM
choco install nssm

# 2. 重新运行 setup，选择 NSSM 选项
npx tsx scripts/apply-skill.ts .claude/skills/setup

# 3. 管理服务
nssm start NanoClaw
nssm stop NanoClaw
nssm restart NanoClaw
nssm status NanoClaw
```

### 配置目录访问权限

如果需要让 agent 访问项目外的目录：

```bash
# 运行挂载配置
.claude/skills/setup/scripts/07-configure-mounts.sh

# 按提示添加目录
# 示例：
# - C:/Users/YourName/Documents (读写)
# - C:/Projects (只读)
```

### 自定义配置

编辑 `.env` 文件：

```env
# Claude API (cc-switch 代理)
ANTHROPIC_API_KEY=sk-dummy
ANTHROPIC_BASE_URL=http://host.docker.internal:15721

# 助手配置
ASSISTANT_NAME=nex
ASSISTANT_HAS_OWN_NUMBER=false

# Telegram 配置
TELEGRAM_BOT_TOKEN=your-token-here
TELEGRAM_ONLY=true
```

**重要：** 修改 `.env` 后必须同步：
```bash
cp .env data/env/env
```

---

## 验证安装

运行完整的验证脚本：

```bash
./scripts/final-verification.sh
```

预期输出：
```
✅ ALL TESTS PASSED

Total Tests: 40
Passed: 40
Failed: 0
```

---

## 获取帮助

- 📖 [完整文档](./WINDOWS-SETUP-IMPLEMENTATION.md)
- 🧪 [验证报告](./WINDOWS-VERIFICATION-REPORT.md)
- ⚡ [快速测试指南](./QUICK-TEST-GUIDE.md)
- 🐛 [提交问题](https://github.com/your-repo/nanoclaw/issues)

---

## 下一步

1. ✅ 完成基础 setup
2. 📱 测试 Telegram 消息收发
3. 🔧 根据需要自定义配置
4. 📚 阅读 [CLAUDE.md](../CLAUDE.md) 了解更多功能

---

**祝你使用愉快！** 🎉
