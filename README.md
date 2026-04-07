# 🍅 FlowTomato

> 番茄工作法桌面应用，支持飞书同步

## 技术栈

| 层级 | 技术 |
|------|------|
| 桌面框架 | [Electron 41](https://www.electronjs.org/) |
| 前端 | [React 18](https://react.dev/) + [TypeScript](https://www.typescriptlang.org/) |
| 构建工具 | [electron-vite](https://electron-vite.org/) + [Vite 7](https://vitejs.dev/) |
| 状态管理 | [Zustand](https://zustand-demo.pmnd.rs/) |
| 飞书 SDK | [@larksuiteoapi/node-sdk](https://github.com/larksuite/node-sdk) |
| 打包发布 | [electron-builder](https://www.electron.build/) |

## 功能

- ⏱ **番茄计时器**：标准 25/5/15 分钟，可自定义时长
- 🔔 **系统通知**：每个阶段结束时弹出系统通知
- 📋 **历史记录**：今日专注统计，每条记录可见飞书同步状态
- 🔗 **飞书同步**：支持两种方式
  - **Webhook（推荐）**：群聊自定义机器人，配置最简单
  - **Bot API**：飞书自建应用，可发送消息给指定用户
- ⚙️ **灵活配置**：时长、自动开始、置顶、通知开关
- 📦 **跨平台打包**：支持 macOS / Windows / Linux

## 快速开始

```bash
# 安装依赖
npm install

# 开发模式（热更新）
npm run dev

# 打包（当前平台）
npm run package

# 按平台打包
npm run package:mac
npm run package:win
npm run package:linux
```

## 飞书集成配置

### 方式一：Webhook（5 分钟配置）

1. 进入飞书群聊 → 设置 → 群机器人 → 添加机器人 → 自定义机器人
2. 复制生成的 **Webhook URL**
3. 打开 FlowTomato → 设置 → 飞书同步 → 填入 URL → 保存

### 方式二：Bot API（支持发消息给指定用户）

1. 前往 [飞书开放平台](https://open.feishu.cn/) 创建「自建应用」
2. 获取 **App ID** 和 **App Secret**
3. 在应用权限中开启 `im:message:send_as_bot`
4. 填入 FlowTomato 设置页面

## 项目结构

```
src/
├── main/                # Electron 主进程
│   ├── index.ts         # 窗口、IPC、系统托盘
│   └── feishu/          # 飞书 SDK 封装（可扩展更多 API）
│       ├── index.ts
│       └── types.ts
├── preload/
│   └── index.ts         # IPC 桥（安全暴露 API 给渲染进程）
└── renderer/
    └── src/
        ├── App.tsx
        ├── components/  # Timer / Controls / Settings / History
        ├── hooks/        # usePomodoro（计时驱动）
        ├── store/        # Zustand 状态管理
        └── styles/       # CSS
```

## 扩展开发

- **飞书更多能力**：在 `src/main/feishu/index.ts` 中调用 `@larksuiteoapi/node-sdk` 提供的任意 API（多维表格、日历、OKR 等）
- **新 IPC 接口**：在 `src/main/index.ts` 添加 `ipcMain.handle`，在 `src/preload/index.ts` 暴露，在 `src/renderer/src/env.d.ts` 声明类型
- **UI 组件**：在 `src/renderer/src/components/` 添加新组件并在 `App.tsx` 注册标签页
