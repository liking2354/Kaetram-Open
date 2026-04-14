# Kaetram

**Kaetram** 是一个开源的 2D 多人在线角色扮演游戏（MMORPG）引擎，以 Little Workshop 的经典演示游戏 [BrowserQuest](http://browserquest.mozilla.org/) 为灵感，代码从零完全重写。游戏可直接在浏览器中运行，同时支持 PWA 安装及 Android/桌面原生应用打包。

- **版本**：`0.5.5-beta`
- **官网**：[https://kaetram.com](https://kaetram.com)
- **许可证**：[MPL-2.0](./LICENSE) + [OPL](./LICENSE_OPL)
- **作者**：OmniaDev

---

## 目录

- [项目简介](#项目简介)
- [技术栈](#技术栈)
- [项目结构](#项目结构)
- [游戏特性](#游戏特性)
- [环境要求](#环境要求)
- [快速开始](#快速开始)
- [配置说明](#配置说明)
- [启动方式](#启动方式)
- [多服务器（Hub）模式](#多服务器hub模式)
- [地图工具](#地图工具)
- [测试](#测试)
- [CI/CD](#cicd)
- [第三方集成](#第三方集成)
- [贡献指南](#贡献指南)

---

## 项目简介

Kaetram 是一个功能完整的 MMORPG 游戏引擎，专为希望进入游戏开发领域的开发者设计。引擎提供了一个可直接在浏览器中游玩的 2D 游戏，支持实时多人交互，包含：

- 完整的 **MMORPG 核心系统**：战斗、技能、装备、任务、成就、公会、交易
- **4MB 世界地图**，基于 Tiled 格式构建
- 双渲染引擎（**Canvas 2D** + **WebGL**），支持动态光照
- 全平台支持：**网页**、**PWA**、**Android App**（通过 Tauri）

---

## 技术栈

### 后端（Server / Hub）

| 技术 | 版本 | 用途 |
|------|------|------|
| **Node.js** | ^18.14.1 \| ^20.0.0 | 运行时环境 |
| **TypeScript** | ^5.2.2 | 全栈类型系统 |
| **uWebSockets.js** | latest | 高性能 C++ WebSocket 服务器 |
| **Express** | ^4.18.2 | REST HTTP API |
| **MongoDB** | ^6.0.0 | 数据库驱动（官方原生驱动，非 Mongoose）|
| **tsx** | ^3.12.10 | TypeScript 直接执行（开发模式）|
| **esbuild** | ^0.19.2 | 生产构建打包 |
| **discord.js** | ^14.13.0 | Discord 机器人集成 |
| **nodemailer** | ^6.9.5 | SMTP 邮件发送（Hub）|
| **stripe** | ^13.5.0 | 支付处理（Hub）|

### 前端（Client）

| 技术 | 版本 | 用途 |
|------|------|------|
| **Astro** | ^3.2.0 | SSG 静态站点框架 |
| **Vite** | 内置 | 前端构建工具 |
| **TypeScript** | ^5.2.2 | 类型系统 |
| **socket.io-client** | ^4.7.2 | WebSocket 客户端 |
| **Canvas 2D API** | 原生 | HTML5 Canvas 2D 渲染 |
| **WebGL** | 原生 | GPU 加速地图渲染 |
| **GLSL 着色器** | - | 地图层渲染着色器（layer.vert / layer.frag）|
| **illuminated** | ^1.3.7 | 2D 动态光照引擎 |
| **gl-tiled** | ^1.0.0 | Tiled 格式地图解析 |
| **pako** | ^2.1.0 | Zlib 压缩/解压 |
| **SCSS** | ^1.66.1 | 样式预处理 |
| **vite-plugin-pwa** | ^0.16.4 | PWA 支持（离线访问、桌面安装）|
| **astro-i18n-aut** | ^0.4.23 | 国际化路由 |
| **i18next** | ^23.5.1 | 国际化框架（8 种语言）|

### 开发工具

| 工具 | 用途 |
|------|------|
| **Yarn 4 Berry** | Monorepo 包管理（Workspaces）|
| **ESLint** | TypeScript / Astro 代码规范 |
| **Prettier** | 代码格式化 |
| **Stylelint** | CSS / SCSS 样式规范 |
| **Husky + lint-staged** | Git Hooks 提交前检查 |
| **Commitlint** | Commit 消息规范（Conventional Commits）|
| **Cypress 13** | E2E 端到端测试 |
| **Cucumber（BDD）** | 行为驱动测试描述 |
| **GitHub Actions** | CI/CD 自动化流水线 |
| **Tauri** | Android / 桌面原生应用打包 |
| **Sentry** | 前后端错误监控 |

---

## 项目结构

项目采用 **Yarn Workspaces Monorepo** 架构，所有子包位于 `packages/` 目录下：

```
Kaetram-Open/
├── .env.defaults              # 所有环境变量默认值（必读）
├── .env.e2e                   # E2E 测试专用环境变量
├── package.json               # 根 Monorepo 配置
├── tsconfig.json              # 根 TypeScript 配置
└── packages/
    ├── server/                # 游戏服务端（端口 9001/9002）
    ├── client/                # 游戏客户端 Web（端口 9000）
    ├── hub/                   # 多服务器中心节点（端口 9526/9527/9528）
    ├── common/                # 公共共享代码（协议/配置/数据库）
    ├── admin/                 # 管理后台（端口 9528）
    ├── tools/                 # 地图解析/导出工具
    └── e2e/                   # 端到端测试（Cypress + Cucumber）
```

### `packages/server` — 游戏服务端

```
src/
├── main.ts                    # 入口：初始化数据库、WebSocket、世界
├── args.ts                    # 命令行参数解析
├── console.ts                 # 服务端控制台命令
├── game/
│   ├── world.ts               # 游戏世界核心（实体/地图/网络管理）
│   ├── entity/
│   │   ├── character/
│   │   │   ├── player/        # 玩家逻辑（88KB，含所有玩家系统）
│   │   │   │   ├── player.ts
│   │   │   │   ├── skills.ts、achievements.ts、quests.ts
│   │   │   │   ├── equipments.ts、friends.ts、trade.ts
│   │   │   │   └── containers/（bank、inventory）
│   │   │   ├── mob/           # 怪物 AI
│   │   │   └── character.ts   # 角色基类（战斗/移动）
│   │   └── objects/（item、chest、lootbag、projectile、resource）
│   ├── map/
│   │   ├── map.ts、region.ts、regions.ts
│   │   └── areas/（camera、chest、dynamic、minigame、music、overlay、pvp）
│   └── minigames/（teamwar、coursing）
├── controllers/
│   ├── commands.ts            # 玩家/版主/管理员命令（43KB）
│   ├── entities.ts            # 实体管理（24KB）
│   ├── crafting.ts、enchanter.ts、guilds.ts、stores.ts、warps.ts
├── network/
│   ├── sockethandler.ts、websocket.ts
│   ├── network.ts、connection.ts、api.ts
└── info/
    ├── formulas.ts            # 伤害/经验计算公式
    └── loader.ts              # 游戏数据加载器

data/
├── items.json（222KB）、mobs.json（126KB）、map/world.json（4MB）
├── achievements.json、npcs.json、spawns.json、stores.json
├── quests/（35个完整任务文件）
├── quest_bases/（22个任务模板）
└── crafting/（alchemy、cooking、crafting、fletching、smelting、smithing）
```

### `packages/client` — 游戏客户端

```
src/
├── app.ts（28KB）             # 应用初始化
├── game.ts（16KB）            # 游戏主循环
├── renderer/
│   ├── renderer.ts（62KB）    # 核心渲染器（Canvas/WebGL）
│   ├── canvas.ts（19KB）      # Canvas 2D 绘制
│   ├── camera.ts              # 摄像机
│   ├── webgl/（webgl.ts、shader.ts、layer.ts）
│   └── shaders/（layer.vert、layer.frag）
├── controllers/
│   ├── input.ts（26KB）       # 键盘/鼠标/触控输入
│   ├── audio.ts               # 音效/音乐控制
│   └── joystick.ts            # 移动端虚拟摇杆
├── menu/（24个UI界面组件）
│   └── guilds.ts、inventory.ts、trade.ts、equipments.ts 等
├── network/
│   ├── connection.ts（56KB）  # 所有网络消息处理
│   └── socket.ts              # Socket.io 封装
└── utils/
    ├── pathfinder.ts          # A* 寻路算法
    ├── storage.ts             # localStorage 持久化
    └── detect.ts              # 设备/平台检测

pages/（Astro 页面）
├── index.astro                # 游戏主页
├── privacy.astro              # 隐私政策
├── reset.astro                # 密码重置
└── unavailable.astro          # 服务不可用页

components/
├── game.astro（36KB）         # 游戏 HTML/CSS 结构
└── intro.astro（13KB）        # 登录/注册界面

scss/（52个 SCSS 文件）
```

### `packages/common` — 公共共享库

```
├── config.ts                  # 统一配置加载（dotenv）
├── network/
│   ├── opcodes.ts             # 所有网络操作码枚举
│   ├── modules.ts             # 游戏常量枚举（Skills/Equipment/Effects/Ranks 等）
│   ├── packet.ts              # 数据包基类
│   └── impl/（54个具体数据包实现）
├── database/
│   └── mongodb/（mongodb.ts、creator.ts、loader.ts）
├── i18n/（de/en/es/fr/pt/ro/ru/tl 8种语言）
└── types/（18个 TypeScript 类型定义）
```

### `packages/hub` — 多服务器中心

```
src/
├── main.ts                    # 入口：Discord/WebSocket/API 初始化
├── controllers/
│   ├── api.ts（12KB）         # REST API + Stripe 支付 + 排行榜
│   ├── cache.ts               # 服务器列表缓存
│   ├── mailer.ts              # SMTP 邮件发送
│   └── models.ts              # 游戏服务器模型管理
└── model/（server、admin）
```

---

## 游戏特性

### 核心玩法系统

| 系统 | 详情 |
|------|------|
| **技能系统** | 17种技能：`Health`、`Accuracy`、`Strength`、`Defense`、`Archery`、`Magic`、`Lumberjacking`、`Mining`、`Fishing`、`Cooking`、`Smithing`、`Crafting`、`Fletching`、`Foraging`、`Eating`、`Loitering`、`Alchemy` |
| **装备系统** | 12个装备槽：头盔、项链、箭矢、胸甲、武器、盾牌、戒指、护甲皮肤、武器皮肤、护腿、披风、靴子 |
| **战斗系统** | 近战（Stab/Slash/Crush/Hack/Chop/Defensive/Shared）、弓箭（Accurate/Fast/LongRange）、魔法（Focused）多种攻击风格 |
| **任务系统** | 35个完整任务 + 22个任务模板，支持多阶段流程 |
| **成就系统** | 多成就追踪，完成弹窗提示 |
| **状态效果** | 30+种效果：中毒/冰冻/燃烧/击晕/恐惧/无敌/各属性 Buff 等 |
| **附魔系统** | Bloodsucking/Critical/Evasion/Thorns/Explosive/Stun/Splash/DoubleEdged 等 |
| **公会系统** | 创建/加入/离开/踢人/晋升/降级/公会聊天/旗帜 |
| **好友系统** | 添加/删除/在线状态实时同步 |
| **交易系统** | 玩家间实时交易（完整前后端实现）|
| **背包/银行** | 独立背包 + 银行存储系统 |
| **制作系统** | 炼金、烹饪、制作、箭矢、冶炼、锻造 6类配方 |
| **掠夺袋** | 怪物掉落战利品袋（LootBag），可被其他玩家拾取 |
| **宠物系统** | 宠物跟随与自动拾取 |
| **小游戏** | `TeamWar`（团队对战）、`Coursing`（追逐赛）|
| **商店系统** | NPC 商店买卖，含库存管理 |
| **传送点** | Mudwich / Aynor / Lakesworld / Patsow / Crullfield / Undersea |
| **PVP 系统** | 专属 PVP 区域与独立战斗逻辑 |
| **教程系统** | 完整新手教程（可配置开关）|

### 玩家等级/头衔

`None` → `Moderator` → `Admin` → `Veteran` → `Patron` → `Artist` → `TierOne ~ TierSeven`（赞助等级）→ `Booster`

### 技术特性

| 特性 | 说明 |
|------|------|
| **双渲染引擎** | Canvas 2D（默认）+ WebGL（GPU 加速地图层）|
| **动态光照** | `illuminated` 库 + 自定义 GLSL 着色器（layer.vert/frag）|
| **A* 寻路** | 客户端 `pathfinder.ts` + `astar.ts` 路径计算 |
| **区域系统** | 服务端基于 Region 的可见性管理，支持区域缓存 |
| **4MB 世界地图** | Tiled 格式，支持动态区域/动态图块 |
| **多语言支持** | i18next，支持 `de/en/es/fr/pt/ro/ru/tl` 8种语言 |
| **PWA** | 离线访问、桌面安装、横屏锁定 |
| **移动端** | 虚拟摇杆（joystick.ts）、设备检测（detect.ts）|
| **多服务器** | Hub 模式支持多游戏服务器实例负载分布 |
| **排行榜** | MongoDB 聚合查询，支持技能经验/PVP/总经验/怪物击杀 |
| **Tauri** | 支持打包为 Android APK / 桌面原生应用 |

---

## 环境要求

- **Node.js**：`^18.14.1` 或 `^20.0.0`
- **Yarn**：4.0.0（通过 Corepack 启用）
- **MongoDB**：本地或远程 MongoDB 实例（可选，开发模式可跳过）

---

## 快速开始

### 1. 克隆仓库

```bash
git clone https://github.com/Kaetram/Kaetram-Open.git
cd Kaetram-Open
```

### 2. 启用 Corepack（Yarn 4）

```bash
corepack enable
```

### 3. 安装依赖

```bash
yarn install
```

### 4. 配置环境变量

复制并修改环境变量：

```bash
cp .env.defaults .env
```

**最重要的配置**：必须在 `.env` 中将 `ACCEPT_LICENSE` 设为 `true`，否则服务器将拒绝启动：

```env
ACCEPT_LICENSE=true
```

如果没有本地 MongoDB，开发模式可跳过数据库检查：

```env
SKIP_DATABASE=true
```

### 5. 启动开发服务器

```bash
yarn dev
```

这会同时启动所有子包（`server`、`client`、`hub`、`admin`、`tools`）的开发模式。

游戏地址：**http://localhost:9000**

---

## 配置说明

所有配置通过根目录的 `.env` 文件（覆盖 `.env.defaults` 默认值）进行管理。

### 核心配置

| 变量 | 默认值 | 说明 |
|------|--------|------|
| `NAME` | `Kaetram` | 服务器名称 |
| `HOST` | `localhost` | 服务端主机 |
| `PORT` | `9001` | WebSocket 端口 |
| `SSL` | `false` | 是否启用 HTTPS/WSS |
| `ACCEPT_LICENSE` | `false` | **必须设为 true** 才能启动 |

### 数据库配置

| 变量 | 默认值 | 说明 |
|------|--------|------|
| `SKIP_DATABASE` | `true` | 跳过数据库检查（开发用）|
| `DATABASE` | `mongodb` | 数据库类型 |
| `MONGODB_HOST` | `127.0.0.1` | MongoDB 主机 |
| `MONGODB_PORT` | `27017` | MongoDB 端口 |
| `MONGODB_USER` | `` | 用户名 |
| `MONGODB_PASSWORD` | `` | 密码 |
| `MONGODB_DATABASE` | `kaetram_devlopment` | 数据库名 |
| `MONGODB_TLS` | `false` | 是否启用 TLS |
| `MONGODB_SRV` | `false` | 使用 `mongodb+srv://` 格式 |

### 游戏世界配置

| 变量 | 默认值 | 说明 |
|------|--------|------|
| `MAX_PLAYERS` | `200` | 最大玩家数 |
| `UPDATE_TIME` | `300` | 数据包处理间隔（ms）|
| `TUTORIAL_ENABLED` | `true` | 是否开启新手教程 |
| `OVERWRITE_AUTH` | `false` | 允许任意凭据登录（测试用）|
| `DISABLE_REGISTER` | `false` | 禁止新用户注册 |
| `SAVE_INTERVAL` | `60000` | 世界自动保存间隔（ms）|
| `REGION_CACHE` | `true` | 是否缓存区域数据 |
| `GVER` | `0.5.5-beta` | 游戏版本号 |

### Hub 配置（多服务器模式）

| 变量 | 默认值 | 说明 |
|------|--------|------|
| `HUB_ENABLED` | `false` | 是否启用 Hub 模式 |
| `HUB_PORT` | `9526` | Hub HTTP API 端口 |
| `HUB_WS_PORT` | `9527` | Hub WebSocket 端口 |
| `ADMIN_PORT` | `9528` | 管理后台端口 |
| `HUB_ACCESS_TOKEN` | `` | Hub 访问令牌 |

### SMTP 邮件配置（密码重置功能）

| 变量 | 默认值 | 说明 |
|------|--------|------|
| `SMTP_HOST` | `smtp.gmail.com` | SMTP 服务器 |
| `SMTP_PORT` | `465` | SMTP 端口 |
| `SMTP_USER` | `` | 发件邮箱 |
| `SMTP_PASSWORD` | `` | 邮箱应用密码 |

### 调试配置

| 变量 | 默认值 | 说明 |
|------|--------|------|
| `DEBUGGING` | `false` | 是否输出详细调试日志 |
| `DEBUG_LEVEL` | `all` | 调试级别 |
| `FS_DEBUGGING` | `false` | 是否写入文件流而非 stdout |

---

## 启动方式

### 开发模式（热重载）

```bash
# 启动全部子包（推荐）
yarn dev

# 单独启动服务端
yarn workspace @kaetram/server dev

# 单独启动客户端
yarn workspace @kaetram/client dev

# 单独启动 Hub
yarn workspace @kaetram/hub hub
```

| 服务 | 地址 | 说明 |
|------|------|------|
| 客户端 | http://localhost:9000 | Astro 开发服务器（热重载）|
| 服务端 WS | ws://localhost:9001 | 游戏 WebSocket |
| 服务端 API | http://localhost:9002 | REST API |
| Hub API | http://localhost:9526 | Hub HTTP API |
| Hub WS | ws://localhost:9527 | Hub WebSocket |
| 管理后台 | http://localhost:9528 | Admin 界面 |

### 生产模式

```bash
# 构建所有子包
yarn build

# 启动所有子包（生产模式）
yarn start

# 单独启动
yarn workspace @kaetram/server start
yarn workspace @kaetram/client start
yarn workspace @kaetram/hub start
```

### Hub 模式（多服务器）

```bash
# 启动所有服务（含 Hub）
yarn hub
```

### 服务端脚本参数

服务端支持命令行参数覆盖配置：

```bash
# 示例：跳过数据库、启用调试
node ./dist/main.js --skip-database --debug
```

---

## 多服务器（Hub）模式

Hub 是一个中心管理节点，用于协调多个游戏服务器实例：

```
┌─────────┐    ┌─────────┐    ┌─────────┐
│ Server 1│    │ Server 2│    │ Server N│
│  :9001  │    │  :9001  │    │  :9001  │
└────┬────┘    └────┬────┘    └────┬────┘
     │              │              │
     └──────────────┼──────────────┘
                    ▼
           ┌────────────────┐
           │   Hub (:9527)  │  ← WebSocket
           │   API (:9526)  │  ← HTTP REST
           │  Admin (:9528) │  ← 管理界面
           └────────────────┘
                    │
              ┌─────┴─────┐
              │  Discord  │
              │  Stripe   │
              │  MongoDB  │
              └───────────┘
```

启用 Hub 模式需在 `.env` 中配置：

```env
HUB_ENABLED=true
HUB_PORT=9526
HUB_WS_PORT=9527
HUB_ACCESS_TOKEN=your_secret_token
```

---

## 地图工具

`packages/tools` 提供地图数据处理工具：

```bash
# 将 Tiled 编辑器导出的地图转换为游戏格式
yarn map

# 地图数据替换工具
yarn replacer
```

地图工作流：
1. 使用 [Tiled Map Editor](https://www.mapeditor.org/) 编辑地图
2. 导出为 `packages/tools/map/data/map.json`
3. 运行 `yarn map` 生成 `packages/server/data/map/world.json`

---

## 测试

### E2E 端到端测试

基于 Cypress 13 + Cucumber（BDD）：

```bash
# 运行测试（无头模式）
yarn test:run

# 打开 Cypress 交互界面
yarn test:open
```

测试覆盖：
- `login.feature` — 登录功能（正确/错误凭据、空表单）
- `inventory.feature` — 背包功能

> **注意**：E2E 测试需要 MongoDB，会使用独立的 `kaetram_e2e` 数据库。

### 代码质量检查

```bash
# TypeScript + Astro 代码规范检查
yarn lint:script

# CSS / SCSS 样式规范检查
yarn lint:style

# 运行全部 lint 检查
yarn lint

# 自动修复 lint 问题
yarn lint:fix
```

---

## CI/CD

项目通过 GitHub Actions 实现自动化流水线：

| 工作流 | 触发条件 | 内容 |
|--------|----------|------|
| `build.yml` | push / PR | 多平台（Ubuntu/Windows/macOS）× 多 Node 版本（18/20）构建 |
| `e2e.yml` | push / PR | 启动 MongoDB 服务 + 运行 Cypress 测试 |
| `app.yml` | 手动触发 | 构建 Android APK（Tauri + Rust + Gradle）|
| `server.yml` | 专项触发 | 服务端专项工作流 |

---

## 第三方集成

### Sentry 错误监控

配置 `.env`：

```env
SENTRY_ORG=your-org
SENTRY_PROJECT=your-project
SENTRY_AUTH_TOKEN=your-token
SENTRY_DSN=https://...
```

### Discord 机器人

游戏内聊天与 Discord 频道双向同步：

```env
DISCORD_ENABLED=true
DISCORD_CHANNEL_ID=your-channel-id
DISCORD_BOT_TOKEN=your-bot-token
```

### Stripe 支付（赞助系统）

```env
STRIPE_ENDPOINT=your-endpoint
STRIPE_KEY_LOCAL=your-local-key
STRIPE_SECRET_KEY=your-secret-key
```

### Google SMTP（密码重置）

```env
SMTP_HOST=smtp.gmail.com
SMTP_PORT=465
SMTP_USE_SECURE=true
SMTP_USER=your-email@gmail.com
SMTP_PASSWORD=your-app-password
```

> Gmail 需要在 Google 账户设置中生成**应用专用密码**。

---

## 国际化

支持 8 种语言，语言文件位于 `packages/common/i18n/`：

| 代码 | 语言 |
|------|------|
| `en` | English（默认）|
| `de` | Deutsch |
| `es` | Español |
| `fr` | Français |
| `pt` | Português |
| `ro` | Română |
| `ru` | Русский |
| `tl` | Filipino |

---

## 数据库设计

### 连接格式

```
# 标准格式
mongodb://[user:password@]host:port/database

# SRV 格式（Atlas 等云服务）
mongodb+srv://user:password@cluster/database
```

### 玩家数据结构

MongoDB 中每个玩家文档包含：
- 基础信息：用户名、密码、邮箱、注册 IP
- 角色数据：位置、方向、外观
- 装备数据：12个装备槽
- 背包/银行数据
- 技能经验：17种技能
- 任务进度：35个任务
- 成就进度
- 统计信息：PVP 记录、怪物击杀等

---

## 贡献指南

1. Fork 本仓库
2. 创建功能分支：`git checkout -b feature/your-feature`
3. 提交遵循 [Conventional Commits](https://www.conventionalcommits.org/) 规范：
   ```
   feat: add new skill system
   fix: resolve combat damage calculation bug
   docs: update README
   ```
4. 提交前会自动运行 lint 检查（Husky）
5. 发起 Pull Request

### 报告问题

请在 [GitHub Issues](https://github.com/Kaetram/Kaetram-Open/issues) 提交 bug 报告或功能请求。

---

## 许可证

本项目采用双重许可证：

- **[MPL-2.0](./LICENSE)**：代码许可证（Mozilla Public License 2.0）
- **[OPL](./LICENSE_OPL)**：开放游戏许可证（Open Game License）

使用本项目前，请务必阅读并同意两份许可协议的条款，并在 `.env` 中设置：

```env
ACCEPT_LICENSE=true
```
