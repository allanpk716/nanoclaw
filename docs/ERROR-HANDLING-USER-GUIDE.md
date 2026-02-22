# 增强错误处理 - 用户指南

## 概述

本次更新为 NanoClaw 添加了两大增强功能:

1. **自动修复损坏的会话** - 无需手动干预
2. **主动错误通知** - 容器失败时通过 Telegram 通知用户

## 使用方法

### 自动会话修复

**完全自动,无需操作**

系统现在会在每次使用会话前自动验证:
- 如果会话文件丢失,自动清除数据库记录
- 容器将启动新会话,而不是尝试恢复损坏的会话
- 避免因会话损坏导致的容器退出

**如何验证正在工作**:
- 查看日志中是否有 "Session file missing, clearing from database"
- 容器应该能够正常启动,即使之前有损坏的会话

### 错误通知

**自动接收错误通知**

当容器失败且重试5次后,您将收到包含以下信息的 Telegram 消息:

```
⚠️ *容器执行失败*

错误: `[错误摘要]`

日志摘要:
```
[最后500字符的日志]
```

💡 建议: 检查日志文件或重启服务
```

**通知包含**:
- 错误类型和摘要(最多200字符)
- 容器日志摘要(最后500字符)
- 建议操作

## 部署步骤

### 1. 清理现有损坏的会话(一次性操作)

```bash
node -e "const Database = require('better-sqlite3'); const db = new Database('store/messages.db'); db.prepare('DELETE FROM sessions WHERE group_folder = ?').run('main'); console.log('Cleaned corrupted session');"
```

### 2. 重新编译

```bash
npm run build
```

### 3. 重启服务

```bash
./stop.bat && ./start.bat
```

### 4. 测试

1. 通过 Telegram 发送消息: "测试消息"
2. 检查服务是否正常响应
3. 查看日志: `cat logs/nanoclaw.log | tail -50`

## 故障排除

### 如果容器仍然失败

1. **查看完整日志**
   ```bash
   cat data/groups/main/logs/container-*.log | tail -100
   ```

2. **检查数据库状态**
   ```bash
   node -e "const Database = require('better-sqlite3'); const db = new Database('store/messages.db'); console.log(db.prepare('SELECT * FROM sessions').all());"
   ```

3. **手动清理会话**
   ```bash
   node -e "const Database = require('better-sqlite3'); const db = new Database('store/messages.db'); db.prepare('DELETE FROM sessions').run(); console.log('All sessions cleared');"
   ```

### 如果没有收到错误通知

检查以下内容:

1. **Telegram 配置**
   - 确认 `TELEGRAM_BOT_TOKEN` 已配置
   - 确认 Telegram 频道已连接

2. **查看主程序日志**
   ```bash
   cat logs/nanoclaw.log | grep "error notification"
   ```

3. **检查事件监听器**
   - 日志中应该有 "Sent error notification to user" 消息

## 技术细节

### 会话验证逻辑

```typescript
// 每次运行容器前执行
validateSession(groupFolder, DATA_DIR);
const sessionId = sessions[groupFolder];
```

验证过程:
1. 检查数据库中是否有会话记录
2. 如果有,验证会话文件是否存在
3. 如果文件丢失,清除数据库记录
4. 容器将以新会话启动

### 重试机制

```
重试次数: 5
退避策略: 指数退避
基础延迟: 5秒

重试延迟:
- 第1次: 5秒
- 第2次: 10秒
- 第3次: 20秒
- 第4次: 40秒
- 第5次: 80秒
```

达到最大重试次数后:
- 发射 `max_retries_exceeded` 事件
- 读取最新容器日志
- 发送错误通知给用户

## 优势

### 对用户

- **透明度**: 知道何时发生错误
- **自动修复**: 无需手动清理损坏的会话
- **快速诊断**: 错误通知包含关键信息

### 对系统

- **稳定性**: 自动处理损坏状态
- **可观测性**: 错误不再静默失败
- **可维护性**: 减少手动干预需求

## 下一步

系统现在可以:
1. 自动检测和修复会话问题
2. 在失败时主动通知您
3. 提供诊断信息帮助排查问题

如果遇到任何问题,请查看日志文件或联系支持。
