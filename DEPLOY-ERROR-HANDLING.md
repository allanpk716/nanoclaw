# 部署说明 - 错误处理增强

## 快速部署

### 1. 重新编译
```bash
npm run build
```

### 2. 重启服务
```bash
./stop.bat && ./start.bat
```

### 3. 测试
- 通过 Telegram 发送: "测试消息"
- 验证服务正常响应

## 即时修复(已完成)

当前损坏的会话已被清理:
```bash
✓ 已执行: DELETE FROM sessions WHERE group_folder = 'main'
```

## 新功能

### 自动会话修复
- 无需操作
- 系统自动检测并修复损坏的会话

### 错误通知
- 容器失败5次后,自动发送 Telegram 通知
- 包含错误详情和日志摘要

## 验证

查看日志:
```bash
cat logs/nanoclaw.log | tail -50
```

查找以下消息:
- "Session file missing, clearing from database" - 会话自动修复
- "Sent error notification to user" - 错误通知发送

## 详细文档

- **技术实现**: docs/ERROR-HANDLING-IMPLEMENTATION.md
- **用户指南**: docs/ERROR-HANDLING-USER-GUIDE.md
- **完成总结**: docs/ERROR-HANDLING-COMPLETION.md

## 故障排除

如果服务无法启动:
1. 检查日志: `cat logs/nanoclaw.log`
2. 清理所有会话: `node -e "const Database = require('better-sqlite3'); const db = new Database('store/messages.db'); db.prepare('DELETE FROM sessions').run();"`
3. 重启服务: `./stop.bat && ./start.bat`
