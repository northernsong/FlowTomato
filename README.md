# FlowTomato

> 番茄工作法 PWA，支持 NocoDB 同步

## 技术栈


## 功能

- ⏱ **番茄计时器**：标准 25/5/15 分钟，可自定义时长
- 🔔 **系统通知**：每个阶段结束时弹出 Web 通知
- 📋 **历史记录**：今日专注统计，每条记录可见 NocoDB 同步状态

- ⚙️ **灵活配置**：时长、自动开始、通知开关，设置持久化存储



## NocoDB 集成配置

本地调试使用 NocoDB personal access token。把开发变量放在 `.env.local`，运行 Flutter 时可按需转成 `--dart-define`：

```bash
NOCO_BASE_URL=http://127.0.0.1:8080
NOCO_TOKEN=your_pat_here
```

应用内设置入口会优先读取 `NOCO_BASE_URL` 和 `NOCO_TOKEN`，兼容旧的 `NOCODB_BASE_URL` 和 `NOCODB_API_TOKEN`。表格不需要手填：应用会查找 `FlowTomato` base 下的 `Tasks`、`Pomodoro`、`DailySummary` 表；找不到时会先询问是否初始化，然后自动创建并缓存 workspace 配置。

## 项目结构
