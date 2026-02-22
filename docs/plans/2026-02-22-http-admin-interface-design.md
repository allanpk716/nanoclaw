# HTTP 管理接口设计方案

## 问题背景

当前的 `start.bat` / `stop.bat` 方案存在以下问题：
1. 通过 `wmic` 查找 `node.exe` 进程获取 PID，多进程时可能抓错
2. `stop.bat` 直接 taskkill 指定 PID，PID 文件错误时可能误杀其他程序
3. 不支持优雅关闭，可能导致数据丢失
4. 无法支持服务内自更新

## 设计目标

1. 精准控制：不会误杀其他进程
2. 优雅关闭：保存状态、断开连接后再退出
3. 自更新：通过 Telegram 发 `/update` 触发自动更新重启
4. 简化脚本：start/stop.bat 不再需要复杂的 PID 管理

## 架构

```
┌─────────────────────────────────────────────┐
│                 NanoClaw                     │
│  ┌─────────────┐    ┌──────────────────┐    │
│  │ 主服务      │    │ 管理接口 (9999)   │    │
│  │ - WhatsApp  │    │ - GET /health    │    │
│  │ - Telegram  │    │ - POST /shutdown │    │
│  │ - Agent     │    │ - POST /restart  │    │
│  └─────────────┘    │ - POST /update   │    │
│                     └──────────────────┘    │
└─────────────────────────────────────────────┘
```

## 核心组件

### 1. 管理接口 (admin-server.ts)

- **端口**：localhost:9999（可配置）
- **认证**：请求头 `X-Admin-Token: {token}`
- **Token 来源**：
  - 优先从 `.env` 读取 `ADMIN_TOKEN`
  - 不存在则启动时自动生成，写入 `.env`

### 2. API 端点

| 端点 | 方法 | 功能 | 响应 |
|------|------|------|------|
| `/health` | GET | 健康检查 | `{status: "ok", uptime: 123}` |
| `/shutdown` | POST | 优雅关闭 | `{status: "shutting down"}` |
| `/restart` | POST | spawn 新进程后退出 | `{status: "restarting"}` |
| `/update` | POST | git pull → npm build → restart | `{status: "updating"}` |

### 3. 自举重启流程

```
/restart 或 /update 触发
    ↓
spawn 新 node 进程 (继承 stdout/stderr)
    ↓
原进程优雅关闭:
  - 停止接受新消息
  - 等待进行中的任务完成 (超时 10s)
  - 断开 WhatsApp/Telegram 连接
  - 关闭数据库连接
    ↓
原进程退出
    ↓
新进程接管
```

### 4. 启动/停止脚本

**start.bat** (简化):
```batch
@echo off
cd /d "%~dp0"
if not exist logs mkdir logs
start /B node dist/index.js > logs\nanoclaw.log 2>&1
echo NanoClaw started. Log: logs\nanoclaw.log
```

**stop.bat** (通过 HTTP):
```batch
@echo off
cd /d "%~dp0"
for /f "tokens=2 delims==" %%a in ('findstr "^ADMIN_TOKEN=" .env 2^>nul') do set TOKEN=%%a
curl -s -X POST -H "X-Admin-Token: %TOKEN%" http://localhost:9999/shutdown
echo NanoClaw stopped.
```

## 配置项

| 配置 | 默认值 | 说明 |
|------|--------|------|
| `ADMIN_PORT` | 9999 | 管理接口端口 |
| `ADMIN_TOKEN` | (自动生成) | 认证 token |

## 文件变更清单

| 文件 | 操作 | 说明 |
|------|------|------|
| `src/admin-server.ts` | 新增 | HTTP 管理接口服务 |
| `src/index.ts` | 修改 | 启动管理接口，处理关闭信号 |
| `src/config.ts` | 修改 | 添加 ADMIN_TOKEN, ADMIN_PORT 配置 |
| `start.bat` | 重写 | 简化，移除 PID 逻辑 |
| `stop.bat` | 重写 | 通过 HTTP 接口关闭 |
| `.env.example` | 修改 | 添加 ADMIN_TOKEN, ADMIN_PORT |

## 安全考虑

1. 仅监听 localhost，外部无法访问
2. 所有写操作需要 token 认证
3. `/health` 端点无需认证（方便监控）

## 降级方案

如果管理接口启动失败（端口被占用等），主服务仍正常运行，只是无法通过 HTTP 管理。此时可通过 `Ctrl+C` 或关闭终端窗口停止。
