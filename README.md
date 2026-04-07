# 🍅 FlowTomato

> 番茄工作法 PWA，支持飞书同步

## 技术栈

| 层级 | 技术 |
|------|------|
| 前端 | [React 18](https://react.dev/) + [TypeScript](https://www.typescriptlang.org/) |
| 构建工具 | [Vite 7](https://vitejs.dev/) |
| PWA | [vite-plugin-pwa](https://vite-pwa-org.netlify.app/) |
| 状态管理 | [Zustand](https://zustand-demo.pmnd.rs/) |

## 功能

- ⏱ **番茄计时器**：标准 25/5/15 分钟，可自定义时长
- 🔔 **系统通知**：每个阶段结束时弹出 Web 通知
- 📋 **历史记录**：今日专注统计，每条记录可见飞书同步状态
- 🔗 **飞书同步**：通过 Webhook 机器人自动推送专注完成消息
- ⚙️ **灵活配置**：时长、自动开始、通知开关，设置持久化存储
- 📱 **可安装 PWA**：支持添加到主屏幕，离线运行

## 快速开始

```bash
# 安装依赖
npm install

# 开发模式（热更新）
npm run dev

# 构建生产版本
npm run build

# 预览构建产物
npm run preview
```

## 飞书集成配置

在飞书群聊中添加「自定义机器人」：

1. 进入飞书群聊 → 设置 → 群机器人 → 添加机器人 → 自定义机器人
2. 复制生成的 **Webhook URL**
3. 打开 FlowTomato → 设置 → 飞书同步 → 填入 URL → 保存

## 项目结构

```
src/
├── api.ts           # 浏览器原生 API 层（设置存储、通知、飞书同步）
├── App.tsx          # 根组件
├── main.tsx         # 应用入口
├── env.d.ts         # 全局类型声明
├── components/      # Timer / Controls / Settings / History
├── hooks/           # usePomodoro（计时驱动）
├── store/           # Zustand 状态管理
└── styles/          # CSS
```

## 扩展开发

- **飞书更多能力**：在 `src/api.ts` 中扩展 `feishuSync` 函数
- **UI 组件**：在 `src/components/` 添加新组件并在 `App.tsx` 注册标签页
- **持久化**：设置通过 `localStorage` 持久化，可扩展为 IndexedDB 存储更多历史数据
