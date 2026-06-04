# FlowTomato 技术设计文档

## 1. 文档信息

| 项目 | 内容 |
| --- | --- |
| 产品名称 | FlowTomato |
| 技术栈方向 | Flutter 优先 |
| 对应 PRD | `docs/prd.md` |
| 编写日期 | 2026-06-01 |
| 本地 Flutter 环境 | Flutter 3.41.9 stable，Dart 3.11.5 |

## 2. 技术目标

FlowTomato 使用 Flutter 构建单代码库应用，优先支持 macOS 桌面端，同时保留 Web/PWA 输出能力。第一阶段先完成高质量本地 UI 和核心交互；第二阶段接入NocoDB；第三阶段补齐番茄钟持久化、统计和同步队列；第四阶段强化 macOS 桌面体验。

核心技术目标：

1. 使用 Flutter 快速完成 macOS 风格的桌面应用界面。
2. 通过清晰的分层架构隔离 UI、业务逻辑、本地存储和NocoDB API。
3. 本地优先，离线可用，远端同步失败不影响用户继续操作。
4. 番茄钟状态可恢复，刷新或重启后尽量不丢失关键计时信息。
5. 为后续 Web/PWA 和 macOS 打包保留扩展空间。

## 3. 技术选型

### 3.1 主框架

| 方向 | 选择 | 原因 |
| --- | --- | --- |
| 应用框架 | Flutter | 本地已安装，适合桌面端高质量 UI，也可输出 Web |
| 语言 | Dart | Flutter 官方语言，类型系统稳定，适合状态建模 |
| 首选运行平台 | macOS Desktop | 与 PRD 中 macOS 原生感目标一致，系统通知和本地存储更可控 |
| 兼容平台 | Flutter Web | 保留 PWA 能力，但NocoDB同步需要额外处理密钥和 CORS |

### 3.2 推荐依赖

| 能力 | 推荐方案 | 说明 |
| --- | --- | --- |
| 状态管理 | `flutter_riverpod` | 明确、可测试，适合中小型应用 |
| 路由 | `go_router` | 当前页面少，但设置页、详情页后续会增长 |
| 本地数据库 | `drift` + SQLite | 适合结构化任务、番茄记录和同步队列 |
| HTTP 客户端 | `dio` | 拦截器、错误处理和重试能力更完整 |
| JSON 序列化 | `freezed` + `json_serializable` | 领域模型不可变，减少手写映射错误 |
| 本地设置 | `shared_preferences` | 存储主题、通知开关、番茄默认时长等轻量配置 |
| 安全存储 | `flutter_secure_storage` | 存储 NocoDB personal access token 等敏感信息 |
| 系统通知 | `flutter_local_notifications` | 支持桌面通知，作为番茄结束提醒 |
| 桌面窗口 | `window_manager` | macOS 窗口尺寸、标题栏和窗口行为控制 |
| 拖拽排序 | Flutter 内置 `ReorderableListView` | MVP 足够，避免过早引入复杂拖拽库 |

### 3.3 架构方案对比

| 方案 | 描述 | 优点 | 缺点 |
| --- | --- | --- | --- |
| 方案 A：纯 Flutter 本地应用 | Flutter macOS + 本地 SQLite + NocoDB直连 | 实现最快，桌面体验好，本地能力完整 | Web 端NocoDB密钥安全不理想 |
| 方案 B：Flutter + 后端同步服务 | Flutter 客户端 + 自建 API 转发NocoDB请求 | Web/PWA 更安全，可统一处理 Token | 需要额外部署后端 |
| 方案 C：Flutter Web 优先 | 先做 Flutter Web/PWA，再适配桌面 | 分发简单 | 桌面原生感和系统能力弱，NocoDB CORS/密钥问题更明显 |

推荐采用方案 A 作为第一到第三阶段主线，方案 B 作为 Web/PWA 正式发布前的安全增强。这样能最快做出可用的本地桌面工具，也不把后端复杂度提前引入 MVP。

## 4. 总体架构

采用分层架构：

```text
Flutter App
├── Presentation UI
│   ├── HomePage
│   ├── NowSection
│   ├── TodoSection
│   ├── DoneSection
│   ├── PomodoroDrawer
│   └── SettingsPage
├── Application State
│   ├── TaskController
│   ├── PomodoroController
│   ├── SummaryController
│   └── SettingsController
├── Domain
│   ├── Task
│   ├── PomodoroSession
│   ├── DailySummary
│   ├── AppSettings
│   └── SyncJob
├── Data
│   ├── TaskRepository
│   ├── PomodoroRepository
│   ├── SettingsRepository
│   └── SyncRepository
└── Infrastructure
    ├── LocalDatabase
    ├── NocoDBApiClient
    ├── NotificationService
    ├── TimerEngine
    └── SecureStorage
```

依赖方向只允许从上到下。UI 不直接访问数据库或NocoDB API，必须通过 Controller 和 Repository。NocoDB同步作为后台能力存在，不能阻塞用户的本地操作。

## 5. 目录结构设计

建议 Flutter 工程初始化后采用以下结构：

```text
lib/
├── main.dart
├── app/
│   ├── flow_tomato_app.dart
│   ├── router.dart
│   └── theme/
│       ├── app_theme.dart
│       ├── app_colors.dart
│       └── app_spacing.dart
├── features/
│   ├── home/
│   │   ├── presentation/
│   │   └── application/
│   ├── tasks/
│   │   ├── domain/
│   │   ├── application/
│   │   ├── data/
│   │   └── presentation/
│   ├── pomodoro/
│   │   ├── domain/
│   │   ├── application/
│   │   ├── data/
│   │   └── presentation/
│   ├── summary/
│   │   ├── domain/
│   │   ├── application/
│   │   └── presentation/
│   └── settings/
│       ├── domain/
│       ├── application/
│       ├── data/
│       └── presentation/
├── integrations/
│   └── nocodb/
│       ├── nocodb_base_api_client.dart
│       ├── nocodb_auth_service.dart
│       ├── nocodb_field_mapper.dart
│       └── nocodb_sync_service.dart
├── shared/
│   ├── database/
│   ├── notifications/
│   ├── timer/
│   ├── widgets/
│   ├── errors/
│   └── utils/
└── generated/
```

## 6. 核心模块设计

### 6.1 Home 模块

职责：

1. 组合 Now、Todo、Done 和 Pomodoro 抽屉。
2. 根据窗口宽度切换桌面布局和窄屏布局。
3. 展示全局加载、同步失败提示和今日摘要。

技术要点：

1. 桌面宽屏使用左右两栏布局，左侧任务区，右侧番茄钟抽屉。
2. 窄屏时 Pomodoro 抽屉切换为底部面板。
3. 首页本身不持有复杂业务状态，只消费各模块 Controller 的状态。

### 6.2 Task 模块

职责：

1. 管理任务创建、编辑、删除、排序、完成和恢复。
2. 保证同一时间最多只有一个 `now` 状态任务。
3. 在本地数据库写入后创建同步任务。

核心状态：

```dart
enum TaskStatus { todo, now, done }
enum TaskPriority { high, medium, low }
enum SyncStatus { localOnly, pending, synced, failed }
```

关键规则：

1. 设置某个任务为 Now 时，原 Now 任务自动回到 Todo。
2. 完成 Now 任务后，Now 区域置空，任务进入 Done。
3. 删除任务采用软删除或先提供撤销窗口，避免误删。
4. 排序只影响同一天的 Todo 列表。

### 6.3 Pomodoro 模块

职责：

1. 管理专注、短休息、长休息三种计时阶段。
2. 支持开始、暂停、继续、重置和自然结束。
3. 在专注自然结束后生成 Pomodoro 记录。
4. 更新关联任务的 `completedPomodoros`。

计时状态机：

```text
idle
 ├── startFocus/startBreak --> running
running
 ├── pause --> paused
 ├── reset --> idle
 └── complete --> completed
paused
 ├── resume --> running
 └── reset --> idle
completed
 ├── nextStage --> idle 或 running
 └── dismiss --> idle
```

计时恢复策略：

1. 开始时记录 `startedAt`、`durationSeconds`、`stage`、`taskId`。
2. 暂停时记录 `pausedAt` 和 `remainingSeconds`。
3. 应用重启后根据持久化状态恢复：
   - 若是 paused，按 `remainingSeconds` 恢复。
   - 若是 running，根据当前时间和 `startedAt` 计算剩余时间。
   - 若已超过结束时间，进入 completed 提示状态，并补写记录。

### 6.4 Summary 模块

职责：

1. 基于本地 Tasks 和 Pomodoro 表计算今日摘要。
2. 展示完成任务数、完成番茄数、专注分钟数。
3. 第三阶段同步 DailySummary 到NocoDB。

MVP 中 DailySummary 可以先不落库，使用查询聚合实时计算；接入NocoDB后再增加持久化表，降低同步复杂度。

### 6.5 Settings 模块

职责：

1. 管理番茄钟时长、自动开始、通知开关、主题偏好。
2. 管理NocoDB 连接配置。
3. 提供NocoDB连接测试和表结构校验。

敏感信息处理：

1. NocoDB personal access token 等敏感配置存入 `flutter_secure_storage`。
2. 设置页只展示脱敏内容。
3. 日志和错误上报中不得输出完整密钥。

## 7. 本地数据设计

### 7.1 数据库表

#### tasks

| 字段 | 类型 | 说明 |
| --- | --- | --- |
| id | text | 本地 UUID |
| remote_id | text nullable | NocoDB记录 ID |
| title | text | 任务标题 |
| note | text nullable | 备注 |
| status | text | todo、now、done |
| priority | text | high、medium、low |
| planned_pomodoros | integer | 预计番茄数 |
| completed_pomodoros | integer | 已完成番茄数 |
| sort_order | integer | 排序 |
| date | text | yyyy-MM-dd |
| created_at | integer | 毫秒时间戳 |
| updated_at | integer | 毫秒时间戳 |
| completed_at | integer nullable | 完成时间 |
| deleted_at | integer nullable | 软删除时间 |
| sync_status | text | localOnly、pending、synced、failed |

#### pomodoro_sessions

| 字段 | 类型 | 说明 |
| --- | --- | --- |
| id | text | 本地 UUID |
| remote_id | text nullable | NocoDB记录 ID |
| task_id | text nullable | 本地任务 ID |
| task_title | text nullable | 任务标题快照 |
| stage | text | focus、shortBreak、longBreak |
| duration_seconds | integer | 计划时长 |
| actual_seconds | integer | 实际时长 |
| status | text | completed、cancelled |
| started_at | integer | 开始时间 |
| ended_at | integer nullable | 结束时间 |
| date | text | yyyy-MM-dd |
| sync_status | text | localOnly、pending、synced、failed |

#### app_settings

| 字段 | 类型 | 说明 |
| --- | --- | --- |
| key | text | 设置项 key |
| value | text | JSON 或普通字符串 |
| updated_at | integer | 更新时间 |

#### sync_jobs

| 字段 | 类型 | 说明 |
| --- | --- | --- |
| id | text | 本地 UUID |
| entity_type | text | task、pomodoro、summary |
| entity_id | text | 本地实体 ID |
| action | text | create、update、delete |
| payload | text | JSON 快照 |
| status | text | pending、running、failed、done |
| retry_count | integer | 重试次数 |
| last_error | text nullable | 最近错误 |
| created_at | integer | 创建时间 |
| updated_at | integer | 更新时间 |

### 7.2 本地优先写入流程

```text
用户操作
  ↓
Controller 校验业务规则
  ↓
Repository 写入本地数据库
  ↓
UI 立即刷新
  ↓
创建 sync_jobs
  ↓
后台 SyncService 尝试同步NocoDB
  ↓
更新 sync_status 和 remote_id
```

## 8. NocoDB 集成设计

### 8.1 集成边界

NocoDB集成放在 `integrations/nocodb` 中，其他模块只依赖抽象 Repository，不感知NocoDB字段结构。

核心类：

| 类 | 职责 |
| --- | --- |
| `NocoDBApiClient` | 封装表格记录查询、创建、更新、删除 |
| `NocoDBFieldMapper` | 本地字段与NocoDB字段互转 |
| `NocoDBSyncService` | 消费同步队列，处理重试和状态回写 |

### 8.2 鉴权方案

macOS 桌面端 MVP 使用 NocoDB personal access token 直连记录 API。凭据保存在本地安全存储中，开发期可通过 `.env.local` 和 `--dart-define` 注入。

Web/PWA 端不建议直接内置或保存 personal access token，因为浏览器环境无法真正保护密钥，也可能遇到 NocoDB API CORS 限制。若后续正式发布 Web 版本，建议增加一个轻量同步代理服务：

```text
Flutter Web
  ↓
FlowTomato Sync Proxy
  ↓
NocoDB API
```

### 8.3 同步策略

1. 应用启动时拉取今日 Tasks。
2. 本地操作优先写入 SQLite，并创建同步任务。
3. 同步任务按创建时间串行执行，避免同一任务并发写入冲突。
4. 失败任务采用指数退避重试，最多自动重试 3 次。
5. 超过重试次数后标记为 failed，用户可手动重试。
6. MVP 冲突策略为本地优先，即本地最新 `updatedAt` 覆盖远端。

### 8.4 表结构校验

设置页连接测试需要校验：

1. NocoDB URL 和 personal access token 是否有效。
2. Tasks、Pomodoro、DailySummary 表是否存在。
3. 必要字段是否存在且类型可写。
4. 当前凭据是否具备读取和写入权限。

## 9. 通知与桌面能力

### 9.1 系统通知

番茄钟自然结束时触发通知：

1. 专注结束：提示进入短休息或长休息。
2. 休息结束：提示回到专注。
3. 通知权限不可用时，使用应用内 Banner 或 Dialog 提醒。

### 9.2 macOS 桌面体验

第四阶段增强：

1. 固定默认窗口尺寸和最小尺寸。
2. 支持应用图标和原生应用名称。
3. 可选支持菜单栏快速查看当前计时。
4. 可选支持窗口关闭后继续计时。

MVP 不要求后台常驻计时；但计时状态必须持久化，重新打开后能恢复或补齐完成状态。

## 10. UI 技术设计

### 10.1 主题系统

使用自定义 Theme Extension 管理颜色、圆角、阴影和间距：

1. `AppColors` 定义浅色和深色 token。
2. `AppSpacing` 定义 4、8、12、16、24、32 等间距。
3. 卡片圆角控制在 8 到 12，整体接近 macOS 工具风格。
4. 毛玻璃效果只用于抽屉或顶部栏，不滥用在列表项中。

### 10.2 组件拆分

| 组件 | 说明 |
| --- | --- |
| `FlowScaffold` | 应用基础布局 |
| `NowTaskCard` | 当前任务卡片 |
| `TaskListItem` | Todo 列表项 |
| `DoneTaskItem` | 完成任务项 |
| `PomodoroPanel` | 番茄钟主面板 |
| `TimerRing` | 计时进度显示 |
| `PriorityBadge` | 优先级标识 |
| `SyncStatusIndicator` | 同步状态标识 |
| `SettingsSection` | 设置分组 |

组件原则：

1. 单个组件只负责展示或局部交互。
2. 复杂业务操作放在 Controller。
3. 列表项固定高度或使用稳定约束，避免拖拽和状态变化造成布局跳动。

## 11. 错误处理

### 11.1 错误分类

| 类型 | 示例 | 用户提示 |
| --- | --- | --- |
| ValidationError | 任务标题为空 | 请填写任务标题 |
| LocalDatabaseError | SQLite 写入失败 | 本地保存失败，请重试 |
| NocoDBAuthError | Token 失效 | NocoDB token 已失效，请重新配置 |
| NocoDBSchemaError | 表字段缺失 | NocoDB表结构不完整，请检查配置 |
| NetworkError | 网络不可用 | 网络异常，已保留本地修改 |
| TimerStateError | 状态恢复异常 | 计时状态已重置 |

### 11.2 展示规则

1. 本地操作失败使用 Toast 或 Banner。
2. NocoDB同步失败不打断当前操作，只在任务项和设置页显示状态。
3. 连接测试失败展示具体原因和下一步建议。

## 12. 测试策略

### 12.1 单元测试

重点覆盖：

1. Task 状态流转：todo、now、done。
2. Now 唯一性规则。
3. 番茄钟状态机。
4. 今日统计计算。
5. NocoDB字段映射。

### 12.2 Widget 测试

重点覆盖：

1. 首页 Now、Todo、Done 渲染。
2. 空状态渲染。
3. 设置项保存后的 UI 状态。
4. 同步状态展示。

### 12.3 集成测试

重点覆盖：

1. 创建任务到完成任务的完整流程。
2. 开始并完成一次短时番茄钟的流程。
3. 模拟NocoDB同步成功和失败。
4. 重启后恢复计时状态。

## 13. 阶段实施方案

### 13.1 第一阶段：Flutter 工程 + 本地 UI

交付内容：

1. 初始化 Flutter 工程。
2. 建立主题、路由和目录结构。
3. 使用内存假数据实现首页。
4. 完成 Now、Todo、Done、Pomodoro 基础交互。

验收：

1. `flutter run -d macos` 可启动。
2. 首页视觉结构完整。
3. 任务可设为 Now、完成、恢复。

### 13.2 第二阶段：本地持久化

交付内容：

1. 接入 Drift/SQLite。
2. 实现 TaskRepository 和 PomodoroRepository。
3. 设置持久化。
4. 计时状态持久化恢复。

验收：

1. 应用重启后任务仍存在。
2. 番茄钟运行或暂停状态可恢复。
3. 今日统计来自真实本地数据。

### 13.3 第三阶段：NocoDB同步

交付内容：

1. 设置页增加NocoDB配置。
2. 实现 NocoDB API Client。
3. 实现同步队列和失败重试。
4. 支持 Tasks 和 Pomodoro 表同步。

验收：

1. 能读取NocoDB今日任务。
2. 本地创建、编辑、完成任务能同步到NocoDB。
3. 番茄钟完成后能写入 Pomodoro 表。
4. 同步失败可见且可重试。

### 13.4 第四阶段：macOS 打包和体验增强

交付内容：

1. 配置 macOS 应用名称、图标和窗口。
2. 完善系统通知。
3. 生成可安装产物。
4. 评估是否补充 Web/PWA 同步代理。

验收：

1. macOS 可独立启动 FlowTomato。
2. 通知、窗口和数据能力符合桌面应用预期。

## 14. 开发命令建议

初始化工程：

```bash
flutter create --platforms=macos,web .
```

运行 macOS：

```bash
flutter run -d macos
```

运行 Web：

```bash
flutter run -d chrome
```

代码生成：

```bash
dart run build_runner build --delete-conflicting-outputs
```

测试：

```bash
flutter test
```

静态检查：

```bash
flutter analyze
```

## 15. 主要风险

| 风险 | 影响 | 处理策略 |
| --- | --- | --- |
| Flutter Web 直连NocoDB存在密钥和 CORS 问题 | Web/PWA 同步无法安全上线 | MVP 先做 macOS 直连，Web 正式发布前增加同步代理 |
| 桌面后台计时行为复杂 | 关闭窗口后计时不准确 | MVP 用时间戳恢复，后续再做后台常驻 |
| NocoDB表字段被用户修改 | 同步失败 | 设置页做表结构校验，错误信息明确到字段 |
| 同步冲突 | 本地和远端状态不一致 | MVP 本地优先，记录远端更新时间，后续支持冲突提示 |
| UI 组件过早复杂化 | 影响开发速度 | 第一阶段使用内置组件和轻量自定义组件，稳定后再抽象 |

## 16. 待确认技术问题

1. NocoDB同步是否只要求 macOS 桌面端可用，还是 Web/PWA 也必须可用。
2. NocoDB 表是否由用户提前创建，还是由应用引导创建字段。
3. macOS 关闭窗口后是否需要继续后台计时。
4. 是否需要菜单栏倒计时入口。
5. 是否需要历史日期回看，如果需要，本地查询和 UI 需要提前预留日期筛选。
