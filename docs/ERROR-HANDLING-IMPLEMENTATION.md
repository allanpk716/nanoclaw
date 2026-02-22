# 增强错误处理和自动修复机制 - 实现报告

## 实现日期
2026-02-22

## 问题背景

用户部署的 NanoClaw 昨天工作正常,今天发送消息后容器立即退出且没有任何反馈。

**问题现象**:
- 数据库中记录的会话ID `0638c65f-b628-4f9b-a91a-9813314ab23c` 在文件系统中不存在
- 容器尝试恢复损坏会话导致退出码 1
- 主程序重试5次后静默失败,用户未收到任何错误通知

## 实现方案

### Part A: 自动修复损坏的会话

**原理**: 在使用会话ID前验证文件是否存在,如果不存在则清除数据库记录

#### 修改内容

1. **src/db.ts** (第497-531行)
   - 新增 `validateSession(groupFolder, sessionsDir)` 函数
   - 检查会话文件是否存在
   - 如果会话文件丢失,自动清除数据库记录
   - 返回验证结果(true/false)

2. **src/index.ts** (第229-232行)
   - 在 `runAgent` 函数中,获取 `sessionId` 之前调用 `validateSession`
   - 确保不会尝试恢复损坏的会话

**好处**:
- 自动处理会话文件丢失的情况
- 避免尝试恢复损坏的会话
- 用户无需手动干预

### Part B: 容器失败时发送错误通知

**原理**: 当容器重试耗尽时,通过可用频道发送错误详情给用户

#### 修改内容

1. **src/group-queue.ts**
   - 导入 `EventEmitter` (第2行)
   - `GroupQueue` 继承 `EventEmitter` (第29行)
   - `GroupState` 接口添加 `lastError` 属性 (第24行)
   - `scheduleRetry` 函数在达到最大重试次数时发射 `max_retries_exceeded` 事件 (第223-233行)
   - `runForGroup` 函数记录错误信息 (第177-189行)

2. **src/index.ts**
   - 新增 `notifyContainerError` 函数 (第56-91行)
   - 格式化错误消息
   - 读取容器日志摘要
   - 通过可用频道发送通知
   - 在 `main` 函数中添加事件监听器 (第507-524行)

**通知内容**:
- 错误类型和摘要
- 容器日志最后500字符
- 建议操作

## 测试验证

### 编译检查
```bash
npm run build
# ✓ 成功,无 TypeScript 错误
```

### 即时修复当前问题
```bash
node -e "const Database = require('better-sqlite3'); const db = new Database('store/messages.db'); db.prepare('DELETE FROM sessions WHERE group_folder = ?').run('main'); console.log('Cleaned corrupted session');"
# ✓ 已清理损坏的会话
```

## 关键文件变更

| 文件 | 修改内容 | 行数 |
|------|---------|------|
| `src/db.ts` | 添加 `validateSession` 函数 | +35 |
| `src/index.ts` | 添加 `notifyContainerError` 函数和事件监听 | +71 |
| `src/group-queue.ts` | 添加 `EventEmitter`、`lastError` 和事件发射 | +15 |

## 部署步骤

1. **重新编译**
   ```bash
   npm run build
   ```

2. **重启服务**
   ```bash
   ./stop.bat && ./start.bat
   ```

3. **发送测试消息**
   - 通过 Telegram 发送: "测试消息"

4. **检查日志**
   ```bash
   cat logs/nanoclaw.log | tail -50
   ```

## 预防措施

- 每次使用会话前自动验证
- 损坏的会话会被自动清理
- 用户会收到明确的错误通知
- 不再静默失败

## 测试场景

### 场景 1: 会话自动修复
1. 手动删除会话文件但保留数据库记录
2. 发送消息触发容器
3. 验证日志中出现 "Session file missing, clearing from database"
4. 验证容器成功启动并处理消息

### 场景 2: 错误通知
1. 触发一个会导致容器失败的错误(如损坏的会话)
2. 等待5次重试耗尽
3. 验证通过可用频道收到错误通知
4. 验证通知包含错误信息和日志摘要

## 后续改进建议

1. **增强错误分类**
   - 区分临时错误和永久错误
   - 对不同类型错误采用不同重试策略

2. **通知频率控制**
   - 添加通知冷却时间,避免频繁通知
   - 支持用户配置通知偏好

3. **自动恢复**
   - 对于某些可恢复错误,尝试自动修复
   - 记录恢复操作供用户审查

4. **监控指标**
   - 统计错误发生频率
   - 跟踪自动修复成功率
   - 生成健康报告
