# hua-yu-zhu-shou 可AI重构文档

> **元信息**
> - **一句话定位**：花语助手（花语心选）——HarmonyOS ArkTS 客户端 + Node/Express/TypeScript 后端的端云一体 AI 鲜花推荐应用：用户通过五步问卷描述送花对象与场景，后端调用通义千问生成 3 套花束方案，支持花材库浏览、收花人档案、购物车与订单全流程。
> - **生成日期**：2026-07-28
> - **复现深度**：精确级（功能等价且实现细节高度还原，白名单资产逐字收录）
> - **与已有文档的关系**：项目根目录 README.md 仅为简介性文档；本文档为唯一权威复现依据，内容以源码实测为准，与 README 冲突时以本文档为准。
> - **密钥零收录声明**：本文档不含任何真实密钥/token/密码。环境变量仅收录键名、用途与占位值（来源 backend/.env.example，该文件本身即为占位模板）。
> - **L 档覆盖策略声明**：后端全部 26 个业务文件逐一精讲；app 侧 35 个核心文件（13 页面 + 5 组件 + 2 服务 + 3 模型 + 1 存储 + 常量/主题/入口 + 8 配置）精讲，其余（测试模板、hvigor 脚手架等可由工具自动生成的文件）用模块级表格兜底。

---

## 1. 项目概述

### 1.1 定位

"花语助手"（内部又名"花语心选"，bundleName `com.flower.app`，后端服务名 `flower-backend`）是一个解决"送花不知道送什么"痛点的端云一体应用：

- **端（app/）**：HarmonyOS Stage 模型应用，ArkTS 编写，4 Tab 主框架（首页/推荐/花材库/我的），核心体验是"五步问卷 → AI 生成 3 套花束方案 → 加购/下单/模拟支付"。
- **云（backend/）**：Node.js + Express + TypeScript REST API，PostgreSQL 持久化，Redis 缓存 AI 推荐结果，通义千问（qwen-plus，OpenAI 兼容协议）生成推荐方案，JWT 鉴权，三级限流。

### 1.2 编号功能清单（第 9 章验收对照表）

**后端功能：**

| 编号 | 功能 | 实现位置 |
|---|---|---|
| F01 | 用户注册（手机号+密码，bcrypt 加密，返回 JWT） | backend/src/routes/auth.ts |
| F02 | 用户登录（统一错误提示防枚举，返回 JWT） | backend/src/routes/auth.ts |
| F03 | 获取/更新个人资料（昵称≤50、头像 URL≤500） | backend/src/routes/auth.ts |
| F04 | 花材分类列表（DISTINCT category） | backend/src/routes/flowers.ts |
| F05 | 花材列表：颜色/类别/季节筛选 + 关键词模糊搜索 + 分页 | backend/src/routes/flowers.ts |
| F06 | 花材详情（按 UUID 查询） | backend/src/routes/flowers.ts |
| F07 | 收花人档案 CRUD（属主校验、age 0-200 校验） | backend/src/routes/recipients.ts |
| F08 | AI 花束推荐生成（通义千问，3 方案，场景增强，价格修正） | backend/src/routes/recommendations.ts + services/qwen/* |
| F09 | 推荐历史列表/详情（JOIN 收花人姓名） | backend/src/routes/recommendations.ts |
| F10 | 推荐反馈评分（rating 1-5，防重复反馈） | backend/src/routes/recommendations.ts |
| F11 | 订单创建（关联推荐并记录选中方案索引） | backend/src/routes/orders.ts |
| F12 | 订单列表（状态筛选+分页）/详情 | backend/src/routes/orders.ts |
| F13 | 订单状态机流转（pending→paid→preparing→delivering→completed） | backend/src/routes/orders.ts |
| F14 | 订单取消（仅 pending/paid/preparing 可取消） | backend/src/routes/orders.ts |
| F15 | AI 推荐结果 Redis 缓存（TTL 4h，MD5 键，故障降级） | backend/src/services/qwen/cacheService.ts |
| F16 | 三级限流（通用 100/min、认证 5/min、AI 10/min） | backend/src/middleware/rateLimiter.ts |
| F17 | 统一响应格式 {code,message,data} 与全局错误处理 | backend/src/utils/response.ts + middleware/errorHandler.ts |
| F18 | 健康检查端点 GET /api/health | backend/src/routes/index.ts |
| F19 | 数据库一键初始化脚本（建表+种子数据 32 花材/8 模板） | backend/src/scripts/init-db.ts + database/*.sql |

**App 功能：**

| 编号 | 功能 | 实现位置 |
|---|---|---|
| F20 | 4 Tab 主框架（emoji 图标、购物车角标 99+ 封顶） | pages/Index.ets |
| F21 | 首页：搜索框跳转、Banner 3s 轮播、6 场景快捷入口、热门花材 Grid | pages/HomePage.ets |
| F22 | 五步问卷推荐流程（对象/场景/关系/画像/预算，Slider 50-2000） | pages/RecommendPage.ets |
| F23 | 推荐结果页：Swiper 3 方案卡片、换一批、贺卡文案复制到剪贴板 | pages/ResultPage.ets |
| F24 | 花材库：搜索 + 颜色/类别/季节三维筛选 + 分页加载 + 详情弹窗 | pages/FlowerLibrary.ets |
| F25 | 购物车：AppStorage + Preferences 双层持久化、数量 1-99、滑动删除 | pages/CartPage.ets + store/CartStore.ets |
| F26 | 订单确认：配送信息表单、贺卡定制开关、配送费 15 元、价格明细 | pages/OrderConfirmPage.ets |
| F27 | 模拟支付：3 种支付方式单选、2s 延时、成功动画、1.5s 后跳订单列表 | pages/PaymentPage.ets |
| F28 | 订单列表（6 Tab 状态筛选）/订单详情（5 步进度条、取消/去支付） | pages/OrderListPage.ets + OrderDetailPage.ets |
| F29 | 收花人档案页：列表/滑动删除/新建编辑表单（多选标签）/送花时间线 | pages/RecipientProfile.ets |
| F30 | 登录注册页：双 Tab、模拟验证码 60s 倒计时、token 持久化 | pages/LoginPage.ets |
| F31 | 我的页：登录态检测、统计数据、6 项菜单、手机号脱敏、退出登录 | pages/MinePage.ets |
| F32 | 接口失败 mock 数据降级（花材/订单/收花人/推荐方案均有内置 mock） | 各页面 getMockXxx() |

### 1.3 规模复核结论

排除 oh_modules / node_modules / build / .hvigor / .idea / dist 等生成物后的真实源码规模：

- **backend/**：26 个文件（src 下 24 个 .ts + database 下 2 个 .sql；另有 package.json、tsconfig.json、.env.example 3 个配置）。
- **app/**：22 个 .ets 源码文件（13 页面 + 5 组件 + 2 服务 + 3 模型 + 1 存储 + Constants + Theme + EntryAbility，共 22 个含工具类）+ 约 12 个配置/资源文件（json5 配置 8 个、资源 json 4 个）。
- 根目录：README.md、.github/workflows/ci.yml。

---

## 2. 技术栈与环境

### 2.1 精确版本表

**App 侧（HarmonyOS）：**

| 项 | 版本/取值 | 出处 |
|---|---|---|
| targetSdkVersion | "6.0.2(22)" | app/build-profile.json5 |
| compatibleSdkVersion | "6.0.2(22)" | app/build-profile.json5 |
| runtimeOS | HarmonyOS | app/build-profile.json5 |
| oh-package modelVersion | "6.0.2" | app/oh-package.json5 |
| @ohos/hypium（devDep） | 1.0.25 | app/oh-package.json5 |
| @ohos/hamock（devDep） | 1.0.0 | app/oh-package.json5 |
| DevEco Studio（前置条件） | 需支持 API 22 / HarmonyOS 6.0.2 的版本（DevEco Studio 6.x） | 推断自 SDK 版本 |
| hvigor | 随 DevEco 内置（hvigor/hvigor-config.json5 modelVersion 6.0.2） | app/hvigor/hvigor-config.json5 |
| 运行时依赖 | 无第三方运行时依赖（dependencies 为空对象） | app/oh-package.json5 |

**后端（Node/TS），来源 backend/package.json（name: flower-backend, version: 1.0.0, main: dist/index.js）：**

| dependencies | 版本 | 用途 |
|---|---|---|
| express | ^4.18.2 | Web 框架 |
| pg | ^8.11.3 | PostgreSQL 驱动（连接池） |
| jsonwebtoken | ^9.0.2 | JWT 签发/校验 |
| bcryptjs | ^2.4.3 | 密码哈希（salt rounds 10） |
| cors | ^2.8.5 | 跨域 |
| dotenv | ^16.3.1 | 环境变量加载 |
| ioredis | ^5.3.2 | Redis 客户端（推荐缓存） |
| express-rate-limit | ^7.1.4 | 限流 |

| devDependencies | 版本 |
|---|---|
| @types/express | ^4.17.21 |
| @types/node | ^20.10.0 |
| @types/pg | ^8.10.9 |
| @types/jsonwebtoken | ^9.0.5 |
| @types/bcryptjs | ^2.4.6 |
| @types/cors | ^2.8.17 |
| typescript | ^5.3.2 |
| ts-node | ^10.9.2 |

**基础设施：**

| 项 | 要求 | 说明 |
|---|---|---|
| Node.js | ≥ 18（@types/node ^20 对应） | 运行后端 |
| PostgreSQL | ≥ 13（依赖 `gen_random_uuid()` 内置函数） | 建议 14+ |
| Redis | ≥ 6 | 可选——连接失败自动降级为无缓存模式 |
| 通义千问 API Key | DashScope 控制台申请 | AI 推荐必需 |

### 2.2 tsconfig.json 关键配置（backend）

- target: ES2020，module: commonjs，strict: true
- outDir: ./dist，rootDir: ./src
- esModuleInterop: true，skipLibCheck: true，resolveJsonModule: true
- 路径别名：`baseUrl: "."`，`paths: { "@/*": ["src/*"] }`（注意：运行 `ts-node` 时别名不生效，实际源码统一使用相对路径导入，别名仅为保留配置）

### 2.3 安装 / 运行 / 构建命令

```bash
# ===== 后端 =====
cd backend
npm install
cp .env.example .env           # 按 2.4 表填写各键
npm run init-db                # 执行 database/init.sql + seed.sql（建表+种子数据）
npm run dev                    # ts-node src/index.ts，默认端口 3001
npm run build                  # tsc → dist/
npm start                      # node dist/index.js（生产）

# ===== App =====
# 1. DevEco Studio 打开 app/ 目录（工程级 build-profile.json5 所在层）
# 2. 首次同步自动执行 ohpm install（拉取 @ohos/hypium、@ohos/hamock）
# 3. 配置签名（signingConfigs 为空数组，需在 DevEco File>Project Structure>Signing Configs 勾选自动签名）
# 4. 选择模拟器/真机运行 entry 模块
# 命令行构建（DevEco 命令行工具）：
#   hvigorw assembleHap --mode module -p product=default
```

### 2.4 环境变量表（仅键名+用途+占位值；来源 backend/.env.example）

| 键名 | 用途 | 占位值（.env.example 原值） |
|---|---|---|
| DB_HOST | PostgreSQL 主机 | localhost |
| DB_PORT | PostgreSQL 端口 | 5432 |
| DB_NAME | 数据库名 | flower_db |
| DB_USER | 数据库用户 | postgres |
| DB_PASSWORD | 数据库密码 | your_password_here |
| JWT_SECRET | JWT 签名密钥 | your_jwt_secret_key_here_change_in_production |
| JWT_EXPIRES_IN | JWT 有效期 | 7d |
| QWEN_API_KEY | 通义千问 API Key | your_qwen_api_key_here |
| QWEN_API_URL | 通义千问 API 地址 | https://dashscope.aliyuncs.com/api/v1/services/aigc/text-generation/generation |
| REDIS_HOST | Redis 主机 | localhost |
| REDIS_PORT | Redis 端口 | 6379 |
| REDIS_PASSWORD | Redis 密码 | （空） |
| REDIS_DB | Redis 库号 | 0 |
| PORT | 后端服务端口 | 3001 |
| NODE_ENV | 运行环境 | development |

> ⚠️ 注意：`.env.example` 中 QWEN_API_URL 是 DashScope 原生 text-generation 端点，但代码 `qwenClient.ts` 的**默认值**是 OpenAI 兼容端点 `https://dashscope.aliyuncs.com/compatible-mode/v1/chat/completions`，且请求体按 OpenAI 格式（messages/model/temperature）构造。复现时 QWEN_API_URL 应填 compatible-mode 端点（或不填走默认值），.env.example 中该占位值属于历史遗留不一致（详见 10.2）。

### 2.5 app 工程级 build-profile.json5（白名单逐字收录）

```json5
{
  "app": {
    "products": [
      {
        "name": "default",
        "targetSdkVersion": "6.0.2(22)",
        "compatibleSdkVersion": "6.0.2(22)",
        "runtimeOS": "HarmonyOS",
        "signingConfig": "default",
        "buildOption": {
          "strictMode": {
            "caseSensitiveCheck": true,
            "useNormalizedOHMUrl": true
          }
        }
      }
    ],
    "buildModeSet": [
      {
        "name": "debug"
      },
      {
        "name": "release"
      }
    ],
    "signingConfigs": []
  },
  "modules": [
    {
      "name": "entry",
      "srcPath": "./entry",
      "targets": [
        {
          "name": "default",
          "applyToProducts": [
            "default"
          ]
        }
      ]
    }
  ]
}
```

### 2.6 app/oh-package.json5（白名单逐字收录）

```json5
{
  "modelVersion": "6.0.2",
  "description": "花语助手 - 智能花束推荐应用",
  "dependencies": {
  },
  "devDependencies": {
    "@ohos/hypium": "1.0.25",
    "@ohos/hamock": "1.0.0"
  }
}
```

entry 模块级 oh-package.json5：name "entry"，version "1.0.0"，description "花语助手入口模块"，dependencies 为空。
entry/build-profile.json5：buildOption 为空对象，targets 含 default（无特殊配置）。

### 2.7 backend/package.json scripts（逐字）

```json
"scripts": {
  "dev": "ts-node src/index.ts",
  "build": "tsc",
  "start": "node dist/index.js",
  "init-db": "ts-node src/scripts/init-db.ts"
}
```

### 2.8 CI（.github/workflows/ci.yml 摘要）

- 触发：push / pull_request 到 main。
- 后端 job：Node 20，`cd backend && npm ci && npm run build`（仅编译校验，无测试）。
- app 侧无 CI 构建（需 DevEco 工具链）。

---

## 3. 目录结构

以下目录树已排除 oh_modules/、node_modules/、build/、dist/、.hvigor/、.idea/、.preview/ 等生成物：

```
hua-yu-zhu-shou/
├── README.md                                # 项目简介（非权威，本文档为准）
├── .github/
│   └── workflows/
│       └── ci.yml                           # CI：后端 npm ci + tsc 编译校验
│
├── app/                                     # ===== HarmonyOS 客户端（Stage 模型）=====
│   ├── build-profile.json5                  # 工程级构建配置（SDK 6.0.2(22)，见 2.5）
│   ├── oh-package.json5                     # 工程级包管理（见 2.6）
│   ├── hvigorfile.ts                        # 工程级 hvigor 脚手架（appTasks 模板，无自定义逻辑）
│   ├── hvigor/
│   │   └── hvigor-config.json5              # hvigor modelVersion 6.0.2 及默认执行参数
│   ├── AppScope/
│   │   ├── app.json5                        # bundleName com.flower.app，versionCode 1000000，versionName 1.0.0
│   │   └── resources/base/
│   │       ├── element/string.json          # app_name = 花语助手
│   │       └── media/                       # 应用图标（占位文件 app_icon_placeholder.txt，见第10章）
│   └── entry/                               # 唯一 HAP 模块
│       ├── build-profile.json5              # 模块级构建配置（空 buildOption）
│       ├── oh-package.json5                 # 模块级依赖（空）
│       ├── hvigorfile.ts                    # 模块级 hvigor 脚手架（hapTasks 模板）
│       └── src/main/
│           ├── module.json5                 # 模块声明：EntryAbility、phone+tablet、INTERNET 权限
│           ├── ets/
│           │   ├── entryability/
│           │   │   └── EntryAbility.ets     # UIAbility 入口，windowStage 加载 pages/Index
│           │   ├── common/
│           │   │   └── Theme.ets            # AppTheme 静态常量类（色板/间距/字号/圆角/阴影）
│           │   ├── utils/
│           │   │   └── Constants.ets        # BASE_URL、TOKEN_KEY、场景/订单状态映射等全局常量
│           │   ├── models/
│           │   │   ├── UserModel.ets        # UserInfo/RecipientInfo/登录注册参数（camelCase）
│           │   │   ├── FlowerModel.ets      # FlowerInfo/FlowerCategory/FlowerColor 枚举
│           │   │   └── RecommendModel.ets   # SceneType/BouquetScheme/OrderInfo/推荐与订单参数
│           │   ├── services/
│           │   │   ├── HttpUtil.ets         # @ohos.net.http 封装：token 注入、超时、401 清 token
│           │   │   └── ApiService.ets       # 18 个静态 API 方法（含端云字段映射层）
│           │   ├── store/
│           │   │   └── CartStore.ets        # 购物车：AppStorage 内存态 + Preferences 磁盘持久化
│           │   ├── components/
│           │   │   ├── CommonButton.ets     # 通用按钮（4 类型 × 3 尺寸）
│           │   │   ├── FlowerCard.ets       # 花材卡片（图/名/花语/单价）
│           │   │   ├── BouquetCard.ets      # 花束方案卡片（图/名/描述/匹配度/价格）
│           │   │   ├── SceneSelector.ets    # 3×2 场景九宫格选择器
│           │   │   └── StepIndicator.ets    # 步骤指示器（圆点+连线+标题）
│           │   └── pages/                   # 13 个页面（与 main_pages.json 一一对应）
│           │       ├── Index.ets            # @Entry 主框架：4 Tab 容器 + 购物车角标
│           │       ├── HomePage.ets         # 首页：搜索/Banner/场景入口/热门花材
│           │       ├── RecommendPage.ets    # 五步问卷推荐（本项目最大页面，768 行）
│           │       ├── ResultPage.ets       # 推荐结果：Swiper 3 方案/换一批/贺卡复制
│           │       ├── FlowerLibrary.ets    # 花材库：三维筛选+分页+详情弹窗（含 FlowerDetailDialog）
│           │       ├── CartPage.ets         # 购物车：列表/数量调整/滑动删除/去结算
│           │       ├── OrderConfirmPage.ets # 订单确认：配送表单/贺卡定制/价格明细
│           │       ├── PaymentPage.ets      # 模拟支付：支付方式/延时/成功动画
│           │       ├── OrderListPage.ets    # 订单列表：6 Tab 状态筛选
│           │       ├── OrderDetailPage.ets  # 订单详情：进度条/取消/去支付
│           │       ├── RecipientProfile.ets # 收花人档案：列表/表单/时间线（855 行）
│           │       ├── LoginPage.ets        # 登录/注册双 Tab
│           │       └── MinePage.ets         # 我的：用户信息/统计/菜单
│           └── resources/base/
│               ├── element/
│               │   ├── color.json           # 8 个颜色资源（见 8.6）
│               │   └── string.json          # 16 个字符串资源（见 8.6）
│               ├── media/                   # 图标资源（icon_placeholder.txt 占位，见第10章）
│               └── profile/
│                   └── main_pages.json      # 13 个页面路由注册表（见 8.1）
│
└── backend/                                 # ===== Node/Express/TS 后端 =====
    ├── package.json                         # 依赖与脚本（见 2.1/2.7）
    ├── tsconfig.json                        # ES2020/commonjs/strict（见 2.2）
    ├── .env.example                         # 环境变量模板（见 2.4，15 个键）
    ├── database/
    │   ├── init.sql                         # 建表脚本：2 枚举 + 7 表 + 11 索引 + 触发器（152 行，见 4.1）
    │   └── seed.sql                         # 种子数据：32 种花材 + 8 个花束模板（110 行，见 4.2）
    └── src/
        ├── index.ts                         # Express 入口：CORS/限流/日志/路由挂载/错误兜底
        ├── config/
        │   └── database.ts                  # pg 连接池（Pool）配置与导出
        ├── middleware/
        │   ├── auth.ts                      # JWT Bearer 鉴权中间件
        │   ├── rateLimiter.ts               # 三级限流器（apiLimiter/authLimiter/aiLimiter）
        │   └── errorHandler.ts              # 全局错误处理 + 404 处理
        ├── models/                          # 仅行类型定义（无 ORM 逻辑）
        │   ├── User.ts                      # UserRow
        │   ├── Recipient.ts                 # RecipientRow
        │   ├── Flower.ts                    # FlowerRow
        │   ├── BouquetTemplate.ts           # BouquetTemplateRow
        │   ├── Recommendation.ts            # RecommendationRow
        │   └── Order.ts                     # OrderRow
        ├── routes/
        │   ├── index.ts                     # 路由聚合 + GET /health
        │   ├── auth.ts                      # 4 端点：注册/登录/资料读写
        │   ├── flowers.ts                   # 3 端点：分类/列表/详情（免鉴权）
        │   ├── recipients.ts                # 5 端点：收花人 CRUD
        │   ├── recommendations.ts           # 4 端点：生成/历史/详情/反馈
        │   └── orders.ts                    # 5 端点：创建/列表/详情/状态/取消
        ├── services/qwen/                   # AI 推荐服务模块
        │   ├── index.ts                     # 模块统一导出
        │   ├── types.ts                     # RecommendationInput/BouquetPlan 等 AI 域类型
        │   ├── prompts.ts                   # SYSTEM_PROMPT 原文 + UserPrompt 构建 + 场景增强
        │   ├── qwenClient.ts                # 原生 https 客户端：重试/超时/流式/错误码映射
        │   ├── recommendationService.ts     # 推荐主流程：缓存/调用/四级解析/校验/价格修正
        │   └── cacheService.ts              # Redis 缓存（TTL 4h，MD5 键，降级）
        ├── scripts/
        │   └── init-db.ts                   # 顺序执行 init.sql → seed.sql
        ├── types/
        │   └── index.ts                     # 全局业务类型（ApiResponse/JwtPayload/各实体）
        └── utils/
            └── response.ts                  # 统一响应工具（success/created/error/401/403/404/500）
```

<!-- SECTION 3 END -->

---

## 4. 数据模型

数据库为 PostgreSQL。全部 DDL 集中在 `backend/database/init.sql`（建表/枚举/索引/触发器），种子数据集中在 `backend/database/seed.sql`（32 种花材 + 8 个花束模板）。初始化脚本 `backend/src/scripts/init-db.ts` 顺序读取并执行这两个文件。

### 4.1 建表脚本 init.sql（白名单逐字全文，152 行）

```sql
-- =====================================================
-- 花语心选 - 数据库初始化脚本
-- =====================================================

-- 创建订单状态枚举类型
DO $$ BEGIN
  CREATE TYPE order_status AS ENUM ('pending', 'paid', 'preparing', 'delivering', 'completed', 'cancelled');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- 创建性别枚举类型
DO $$ BEGIN
  CREATE TYPE gender_type AS ENUM ('male', 'female', 'other');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- ==================== 用户表 ====================
CREATE TABLE IF NOT EXISTS users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  phone VARCHAR(20) NOT NULL UNIQUE,
  password_hash VARCHAR(255) NOT NULL,
  nickname VARCHAR(50),
  avatar VARCHAR(500),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_users_phone ON users(phone);

-- ==================== 收花人表 ====================
CREATE TABLE IF NOT EXISTS recipients (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  name VARCHAR(50) NOT NULL,
  gender gender_type,
  age INTEGER,
  relationship VARCHAR(50) NOT NULL,
  relationship_duration VARCHAR(50),
  interests TEXT,
  personality VARCHAR(100),
  career VARCHAR(100),
  color_preference VARCHAR(100),
  style_preference VARCHAR(100),
  allergies TEXT,
  cultural_notes TEXT,
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_recipients_user_id ON recipients(user_id);

-- ==================== 花材表 ====================
CREATE TABLE IF NOT EXISTS flowers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR(50) NOT NULL,
  name_en VARCHAR(80) NOT NULL,
  meaning TEXT NOT NULL,
  color VARCHAR(50) NOT NULL,
  category VARCHAR(50) NOT NULL,
  price_per_stem DECIMAL(10, 2) NOT NULL DEFAULT 0,
  season VARCHAR(50) NOT NULL,
  image_url VARCHAR(500),
  description TEXT,
  available BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE INDEX IF NOT EXISTS idx_flowers_category ON flowers(category);
CREATE INDEX IF NOT EXISTS idx_flowers_color ON flowers(color);
CREATE INDEX IF NOT EXISTS idx_flowers_season ON flowers(season);

-- ==================== 花束模板表 ====================
CREATE TABLE IF NOT EXISTS bouquet_templates (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR(100) NOT NULL,
  description TEXT,
  occasion VARCHAR(50) NOT NULL,
  style VARCHAR(50) NOT NULL,
  price_range_min DECIMAL(10, 2) NOT NULL,
  price_range_max DECIMAL(10, 2) NOT NULL,
  flower_composition JSONB NOT NULL DEFAULT '[]',
  image_url VARCHAR(500)
);

CREATE INDEX IF NOT EXISTS idx_bouquet_templates_occasion ON bouquet_templates(occasion);

-- ==================== AI推荐表 ====================
CREATE TABLE IF NOT EXISTS recommendations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  recipient_id UUID NOT NULL REFERENCES recipients(id) ON DELETE CASCADE,
  occasion VARCHAR(100) NOT NULL,
  input_context JSONB NOT NULL DEFAULT '{}',
  ai_response JSONB NOT NULL DEFAULT '{}',
  selected_plan_index INTEGER,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_recommendations_user_id ON recommendations(user_id);
CREATE INDEX IF NOT EXISTS idx_recommendations_recipient_id ON recommendations(recipient_id);

-- ==================== 订单表 ====================
CREATE TABLE IF NOT EXISTS orders (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  recommendation_id UUID REFERENCES recommendations(id) ON DELETE SET NULL,
  status order_status NOT NULL DEFAULT 'pending',
  total_price DECIMAL(10, 2) NOT NULL,
  delivery_address TEXT NOT NULL,
  delivery_time TIMESTAMP WITH TIME ZONE,
  greeting_card_message TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_orders_user_id ON orders(user_id);
CREATE INDEX IF NOT EXISTS idx_orders_status ON orders(status);

-- ==================== 用户反馈表 ====================
CREATE TABLE IF NOT EXISTS user_feedback (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  recommendation_id UUID NOT NULL REFERENCES recommendations(id) ON DELETE CASCADE,
  rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
  comment TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_user_feedback_user_id ON user_feedback(user_id);
CREATE INDEX IF NOT EXISTS idx_user_feedback_recommendation_id ON user_feedback(recommendation_id);

-- ==================== 自动更新 updated_at 触发器 ====================
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_users_updated_at
  BEFORE UPDATE ON users
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_recipients_updated_at
  BEFORE UPDATE ON recipients
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_orders_updated_at
  BEFORE UPDATE ON orders
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
```

### 4.2 表结构逐表说明

**枚举类型（2 个）：**

| 枚举名 | 取值 | 用途 |
|---|---|---|
| `order_status` | pending / paid / preparing / delivering / completed / cancelled | 订单状态机（注意：**不含** app 侧 Constants 里的 `confirmed`，见 10.2 端云不一致） |
| `gender_type` | male / female / other | 收花人性别 |

> 建枚举用 `DO $$ ... EXCEPTION WHEN duplicate_object THEN NULL; END $$;` 包裹，保证脚本可重复执行（幂等）。

**表 1：`users`（用户）**

| 字段 | 类型 | 约束 | 说明 |
|---|---|---|---|
| id | UUID | PK，默认 `gen_random_uuid()` | 主键 |
| phone | VARCHAR(20) | NOT NULL，UNIQUE | 手机号（登录账号） |
| password_hash | VARCHAR(255) | NOT NULL | bcrypt 哈希（salt rounds 10） |
| nickname | VARCHAR(50) | 可空 | 昵称（更新资料时校验 ≤50） |
| avatar | VARCHAR(500) | 可空 | 头像 URL（校验 ≤500） |
| created_at / updated_at | TIMESTAMPTZ | 默认 NOW() | updated_at 由触发器维护 |

索引：`idx_users_phone (phone)`。

**表 2：`recipients`（收花人档案）**

| 字段 | 类型 | 约束 | 说明 |
|---|---|---|---|
| id | UUID | PK | |
| user_id | UUID | NOT NULL，FK→users(id) ON DELETE CASCADE | 属主 |
| name | VARCHAR(50) | NOT NULL | 姓名 |
| gender | gender_type | 可空 | 性别枚举 |
| age | INTEGER | 可空 | 年龄（路由层校验 0–200） |
| relationship | VARCHAR(50) | NOT NULL | 关系（伴侣/朋友…） |
| relationship_duration | VARCHAR(50) | 可空 | 认识时长 |
| interests | TEXT | 可空 | 兴趣爱好（app 侧多选后逗号拼接） |
| personality | VARCHAR(100) | 可空 | 性格 |
| career | VARCHAR(100) | 可空 | 职业 |
| color_preference | VARCHAR(100) | 可空 | 颜色偏好 |
| style_preference | VARCHAR(100) | 可空 | 风格偏好 |
| allergies | TEXT | 可空 | 过敏花材 |
| cultural_notes | TEXT | 可空 | 文化/宗教禁忌 |
| notes | TEXT | 可空 | 备注 |
| created_at / updated_at | TIMESTAMPTZ | 默认 NOW() | updated_at 触发器维护 |

索引：`idx_recipients_user_id (user_id)`。

**表 3：`flowers`（花材库）**

| 字段 | 类型 | 约束 | 说明 |
|---|---|---|---|
| id | UUID | PK | |
| name | VARCHAR(50) | NOT NULL | 中文名（如"红玫瑰"） |
| name_en | VARCHAR(80) | NOT NULL | 英文名 |
| meaning | TEXT | NOT NULL | 花语 |
| color | VARCHAR(50) | NOT NULL | 颜色（红色/粉色/白色/黄色/紫色/蓝色/绿色/银色/多色） |
| category | VARCHAR(50) | NOT NULL | 类别（玫瑰/百合/康乃馨/配花/叶材…） |
| price_per_stem | DECIMAL(10,2) | NOT NULL 默认 0 | 单支价格 |
| season | VARCHAR(50) | NOT NULL | 花期（春夏/四季/冬春/夏秋） |
| image_url | VARCHAR(500) | 可空 | 图片 URL（种子数据未填，为 NULL，见第10章） |
| description | TEXT | 可空 | 描述 |
| available | BOOLEAN | NOT NULL 默认 TRUE | 是否上架 |

索引：`idx_flowers_category`、`idx_flowers_color`、`idx_flowers_season`（对应 F05 三维筛选）。注意本表**无** created_at/updated_at 列。

**表 4：`bouquet_templates`（花束模板）**

| 字段 | 类型 | 约束 | 说明 |
|---|---|---|---|
| id | UUID | PK | |
| name | VARCHAR(100) | NOT NULL | 模板名 |
| description | TEXT | 可空 | 描述 |
| occasion | VARCHAR(50) | NOT NULL | 场合（情人节/生日/母亲节…） |
| style | VARCHAR(50) | NOT NULL | 风格（浪漫/温馨/活力/优雅/纯洁/清新） |
| price_range_min / price_range_max | DECIMAL(10,2) | NOT NULL | 价格区间 |
| flower_composition | JSONB | NOT NULL 默认 '[]' | 花材组成数组 `[{flower_name, quantity}]` |
| image_url | VARCHAR(500) | 可空 | 图片 URL（种子未填） |

索引：`idx_bouquet_templates_occasion`。

> 说明：`bouquet_templates` 当前**没有任何后端路由读取**（无 /templates 端点），是预留的模板语料表，仅由 seed.sql 填充。

**表 5：`recommendations`（AI 推荐记录）**

| 字段 | 类型 | 约束 | 说明 |
|---|---|---|---|
| id | UUID | PK | |
| user_id | UUID | NOT NULL，FK→users ON DELETE CASCADE | 发起用户 |
| recipient_id | UUID | NOT NULL，FK→recipients ON DELETE CASCADE | 收花人（无档案时后端自动创建"匿名收花人"临时档案） |
| occasion | VARCHAR(100) | NOT NULL | 场景/场合 |
| input_context | JSONB | NOT NULL 默认 '{}' | 推荐输入快照（也是 Redis 缓存 key 的来源） |
| ai_response | JSONB | NOT NULL 默认 '{}' | AI 解析后的完整结果（plans + reason 等） |
| selected_plan_index | INTEGER | 可空 | 下单时选中的方案索引（创建订单时回写） |
| created_at | TIMESTAMPTZ | 默认 NOW() | 无 updated_at、无触发器 |

索引：`idx_recommendations_user_id`、`idx_recommendations_recipient_id`。

**表 6：`orders`（订单）**

| 字段 | 类型 | 约束 | 说明 |
|---|---|---|---|
| id | UUID | PK | |
| user_id | UUID | NOT NULL，FK→users ON DELETE CASCADE | 下单用户 |
| recommendation_id | UUID | FK→recommendations ON DELETE **SET NULL**，可空 | 关联推荐（推荐删除时置空，订单保留） |
| status | order_status | NOT NULL 默认 'pending' | 状态机（见 6.6） |
| total_price | DECIMAL(10,2) | NOT NULL | 订单总价（app 侧含配送费 15 元） |
| delivery_address | TEXT | NOT NULL | 配送地址 |
| delivery_time | TIMESTAMPTZ | 可空 | 期望配送时间 |
| greeting_card_message | TEXT | 可空 | 贺卡文案 |
| created_at / updated_at | TIMESTAMPTZ | 默认 NOW() | updated_at 触发器维护 |

索引：`idx_orders_user_id`、`idx_orders_status`（对应 F12 状态筛选）。

**表 7：`user_feedback`（推荐反馈）**

| 字段 | 类型 | 约束 | 说明 |
|---|---|---|---|
| id | UUID | PK | |
| user_id | UUID | NOT NULL，FK→users ON DELETE CASCADE | |
| recommendation_id | UUID | NOT NULL，FK→recommendations ON DELETE CASCADE | |
| rating | INTEGER | NOT NULL，`CHECK (rating >= 1 AND rating <= 5)` | 评分（数据库层与路由层双重校验） |
| comment | TEXT | 可空 | 评价文字 |
| created_at | TIMESTAMPTZ | 默认 NOW() | |

索引：`idx_user_feedback_user_id`、`idx_user_feedback_recommendation_id`。写入端点为 `POST /api/recommendations/:id/feedback`（见 5.5）；app 侧 `submitFeedback` 误调 `POST /feedbacks`（后端不存在，见 10.2）。

**外键与级联关系汇总：**

```
users (1) ──< recipients          ON DELETE CASCADE
users (1) ──< recommendations     ON DELETE CASCADE
users (1) ──< orders              ON DELETE CASCADE
users (1) ──< user_feedback       ON DELETE CASCADE
recipients (1) ──< recommendations      ON DELETE CASCADE
recommendations (1) ──< orders          ON DELETE SET NULL   ← 唯一非级联删除
recommendations (1) ──< user_feedback   ON DELETE CASCADE
```

统计：2 枚举、7 表、11 索引、1 触发器函数 + 3 触发器（users/recipients/orders 的 updated_at 自动更新）。

### 4.3 种子数据 seed.sql（白名单逐字全文，110 行）

```sql
-- =====================================================
-- 花语心选 - 花材种子数据（30+种）
-- =====================================================

INSERT INTO flowers (name, name_en, meaning, color, category, price_per_stem, season, description, available) VALUES

-- ========== 玫瑰系列 ==========
('红玫瑰', 'Red Rose', '热烈的爱情、我爱你、热恋', '红色', '玫瑰', 8.00, '春夏', '经典红玫瑰，象征热烈真挚的爱情，是情人节和纪念日的首选花材', TRUE),
('粉玫瑰', 'Pink Rose', '初恋、感动、爱的宣言、铭记于心', '粉色', '玫瑰', 8.00, '春夏', '粉色玫瑰温柔浪漫，代表初恋的悸动与甜蜜，适合送给心仪的人', TRUE),
('白玫瑰', 'White Rose', '纯洁、高贵、天真、尊敬', '白色', '玫瑰', 8.00, '春夏', '白色玫瑰纯洁无瑕，象征纯真的爱与尊敬，常用于婚礼花艺', TRUE),
('黄玫瑰', 'Yellow Rose', '友谊、祝福、道歉、消逝的爱', '黄色', '玫瑰', 8.00, '春夏', '黄色玫瑰明亮温暖，代表真挚的友谊，也可用于表达歉意', TRUE),
('紫玫瑰', 'Purple Rose', '浪漫真情、珍贵独特、梦幻', '紫色', '玫瑰', 10.00, '春夏', '紫色玫瑰神秘优雅，代表独一无二的爱，寓意珍贵而梦幻的感情', TRUE),

-- ========== 百合系列 ==========
('白百合', 'White Lily', '纯洁、庄严、百年好合、伟大的爱', '白色', '百合', 15.00, '春夏', '白百合端庄优雅，象征纯洁与百年好合，是婚礼和祝福场合的经典花材', TRUE),
('粉百合', 'Pink Lily', '清纯、高雅、祝福', '粉色', '百合', 15.00, '春夏', '粉百合柔美动人，代表清纯高雅的祝福，适合送予长辈或朋友', TRUE),

-- ========== 康乃馨系列 ==========
('红康乃馨', 'Red Carnation', '母爱、热情、热爱、祝母亲健康长寿', '红色', '康乃馨', 4.00, '四季', '红色康乃馨是母亲节的象征，代表对母亲深深的爱与祝福', TRUE),
('粉康乃馨', 'Pink Carnation', '感恩、美丽的母爱、祝母亲永远年轻', '粉色', '康乃馨', 4.00, '四季', '粉色康乃馨温馨柔和，表达对母亲的感恩与祝福', TRUE),
('白康乃馨', 'White Carnation', '纯真的爱、雅致、幸运', '白色', '康乃馨', 4.00, '四季', '白色康乃馨清雅脱俗，代表纯洁的爱与美好的祝福', TRUE),

-- ========== 向日葵 ==========
('向日葵', 'Sunflower', '信念、光辉、忠诚、爱慕', '黄色', '向日葵', 6.00, '夏秋', '向日葵阳光灿烂，象征对生活的热爱与积极向上的信念', TRUE),

-- ========== 满天星 ==========
('满天星', 'Baby''s Breath', '甘愿做配角的爱、真心喜欢、关心、纯洁', '白色', '配花', 3.00, '四季', '满天星花型细小，簇拥如星，代表默默守护的纯真爱意', TRUE),

-- ========== 桔梗 ==========
('桔梗', 'Lisianthus', '永恒不变的爱、真诚、柔顺', '紫色', '桔梗', 6.00, '春夏', '桔梗花优雅别致，象征永恒不变的爱与真诚的心意', TRUE),

-- ========== 郁金香系列 ==========
('红郁金香', 'Red Tulip', '爱的宣言、喜悦、热爱', '红色', '郁金香', 12.00, '冬春', '红色郁金香热情奔放，是表达爱意的经典之选', TRUE),
('粉郁金香', 'Pink Tulip', '美人、热爱、爱惜、幸福', '粉色', '郁金香', 12.00, '冬春', '粉色郁金香温柔可人，代表对幸福生活的憧憬', TRUE),
('紫郁金香', 'Purple Tulip', '高贵的爱、无尽的爱、最爱', '紫色', '郁金香', 12.00, '冬春', '紫色郁金香高贵神秘，象征最珍贵深沉的爱', TRUE),

-- ========== 芍药 ==========
('芍药', 'Peony', '情有所钟、依依不舍、美丽动人', '粉色', '芍药', 20.00, '春夏', '芍药花大色艳，自古就是爱情的象征，代表情有所钟', TRUE),

-- ========== 洋甘菊 ==========
('洋甘菊', 'Chamomile', '逆境中的坚强、苦难中的力量、和好', '白色', '配花', 5.00, '春夏', '洋甘菊小巧清新，象征在逆境中依然坚强乐观的精神', TRUE),

-- ========== 勿忘我 ==========
('勿忘我', 'Forget-me-not', '永恒的爱、浓情厚谊、永不变心', '蓝色', '配花', 3.00, '四季', '勿忘我花如其名，代表永恒不变的爱与深切的思念', TRUE),

-- ========== 绣球花 ==========
('蓝绣球', 'Blue Hydrangea', '浪漫、美满、团聚、希望', '蓝色', '绣球花', 18.00, '春夏', '蓝色绣球花团锦簇，象征浪漫与团聚的美满', TRUE),
('粉绣球', 'Pink Hydrangea', '浪漫与甜蜜、温馨美满', '粉色', '绣球花', 18.00, '春夏', '粉色绣球温馨浪漫，代表甜蜜美好的感情', TRUE),

-- ========== 雏菊 ==========
('雏菊', 'Daisy', '天真、和平、希望、纯洁的美', '白色', '雏菊', 4.00, '春夏', '雏菊清新可爱，象征天真无邪的纯洁之美', TRUE),

-- ========== 马蹄莲 ==========
('马蹄莲', 'Calla Lily', '博爱、圣洁虔诚、永恒、优雅', '白色', '马蹄莲', 12.00, '春夏', '马蹄莲花型独特优雅，象征纯洁与高雅的气质', TRUE),

-- ========== 非洲菊 ==========
('非洲菊', 'Gerbera Daisy', '互敬互爱、毅力、不畏艰难、神秘', '多色', '非洲菊', 5.00, '四季', '非洲菊色彩丰富，象征积极向上的生活态度与坚毅', TRUE),

-- ========== 洋牡丹 ==========
('洋牡丹', 'Ranunculus', '受欢迎、吉祥富贵、迷人的魅力', '多色', '洋牡丹', 10.00, '冬春', '洋牡丹花瓣层层叠叠，华丽富贵，象征吉祥与迷人魅力', TRUE),

-- ========== 紫罗兰 ==========
('紫罗兰', 'Violet', '永恒的美、质朴、美德、盛夏的清凉', '紫色', '紫罗兰', 8.00, '冬春', '紫罗兰优雅馥郁，代表永恒的美与质朴的美德', TRUE),

-- ========== 尤加利叶 ==========
('尤加利叶', 'Eucalyptus', '回忆、恩赐、新生', '绿色', '叶材', 5.00, '四季', '尤加利叶清新淡雅，是花束中的经典配叶，象征美好的回忆', TRUE),

-- ========== 银叶菊 ==========
('银叶菊', 'Dusty Miller', '坚韧、希望、永恒的爱', '银色', '叶材', 4.00, '四季', '银叶菊银白色叶片柔美，增添花束质感与层次', TRUE),

-- ========== 勿忘草 ==========
('黄金球', 'Craspedia', '圆满、财富、永恒的喜悦', '黄色', '配花', 5.00, '四季', '黄金球圆润可爱，金黄色泽寓意圆满与喜悦', TRUE),

-- ========== 蕾丝花 ==========
('蕾丝花', 'Queen Anne''s Lace', '惹人怜爱、忍耐、梦幻', '白色', '配花', 4.00, '春夏', '蕾丝花精致如蕾丝花边，增添花束浪漫梦幻的气质', TRUE),

-- ========== 花毛茛 ==========
('花毛茛', 'Ranunculus', '迷人的魅力、富贵吉祥、受欢迎', '多色', '花毛茛', 8.00, '冬春', '花毛茛花型饱满如牡丹，层次丰富，象征富贵吉祥', TRUE),

-- ========== 小苍兰 ==========
('小苍兰', 'Freesia', '纯洁、浓情、幸福、清香', '白色', '小苍兰', 6.00, '冬春', '小苍兰香气怡人，花姿优雅，象征纯洁的幸福', TRUE);

-- ==================== 花束模板种子数据 ====================

INSERT INTO bouquet_templates (name, description, occasion, style, price_range_min, price_range_max, flower_composition) VALUES

('经典红玫瑰花束', '11朵红玫瑰配满天星，经典不过时', '情人节', '浪漫', 99.00, 128.00,
  '[{"flower_name":"红玫瑰","quantity":11},{"flower_name":"满天星","quantity":5}]'::jsonb),

('粉色甜蜜花束', '粉玫瑰与粉百合的甜蜜组合，温柔浪漫', '生日', '温馨', 128.00, 168.00,
  '[{"flower_name":"粉玫瑰","quantity":9},{"flower_name":"粉百合","quantity":3},{"flower_name":"洋甘菊","quantity":3}]'::jsonb),

('母爱如花', '康乃馨与百合的组合，感恩母爱', '母亲节', '温馨', 88.00, 128.00,
  '[{"flower_name":"粉康乃馨","quantity":12},{"flower_name":"白百合","quantity":2},{"flower_name":"尤加利叶","quantity":3}]'::jsonb),

('阳光灿烂', '向日葵主花，充满正能量', '毕业', '活力', 68.00, 98.00,
  '[{"flower_name":"向日葵","quantity":5},{"flower_name":"雏菊","quantity":5},{"flower_name":"黄金球","quantity":3}]'::jsonb),

('优雅紫韵', '紫玫瑰与绣球的优雅搭配', '纪念日', '优雅', 158.00, 198.00,
  '[{"flower_name":"紫玫瑰","quantity":9},{"flower_name":"蓝绣球","quantity":2},{"flower_name":"蕾丝花","quantity":3}]'::jsonb),

('百年好合', '白百合与白玫瑰的婚礼花束', '婚礼', '纯洁', 198.00, 268.00,
  '[{"flower_name":"白百合","quantity":5},{"flower_name":"白玫瑰","quantity":11},{"flower_name":"蕾丝花","quantity":5},{"flower_name":"银叶菊","quantity":3}]'::jsonb),

('春日物语', '郁金香与洋牡丹的春日组合', '探病', '清新', 118.00, 158.00,
  '[{"flower_name":"粉郁金香","quantity":7},{"flower_name":"洋牡丹","quantity":5},{"flower_name":"洋甘菊","quantity":3}]'::jsonb),

('友谊之花', '黄玫瑰与非洲菊的明亮组合', '友谊', '活力', 68.00, 98.00,
  '[{"flower_name":"黄玫瑰","quantity":6},{"flower_name":"非洲菊","quantity":5},{"flower_name":"黄金球","quantity":3}]'::jsonb);
```

### 4.4 种子数据统计与要点

- **花材共 32 条 INSERT**，价格区间 3.00–20.00 元/支；类别分布：玫瑰 5、百合 2、康乃馨 3、郁金香 3、配花 6（满天星/洋甘菊/勿忘我/黄金球/蕾丝花）、叶材 2（尤加利叶/银叶菊）、其余单品各 1（向日葵/桔梗/芍药/蓝绣球/粉绣球/雏菊/马蹄莲/非洲菊/洋牡丹/紫罗兰/花毛茛/小苍兰）。
- **花束模板共 8 条**，场合覆盖：情人节/生日/母亲节/毕业/纪念日/婚礼/探病/友谊；风格取值：浪漫/温馨/活力/优雅/纯洁/清新。
- **单引号转义**：`'Baby''s Breath'`、`'Queen Anne''s Lace'` 使用 SQL 双写单引号转义，复现时必须保留，否则语法错误。
- **JSONB 强转**：模板 `flower_composition` 以 `'...'::jsonb` 写入。
- **image_url 全部为 NULL**（INSERT 列清单不含该列）——app 端因此以 emoji/占位图展示花材图（见第 10 章不可文本化资产）。
- **数据瑕疵（逐字保留）**：`洋牡丹` 与 `花毛茛` 的 name_en 均为 `Ranunculus`；注释写"勿忘草"的段落实际插入的是"黄金球"。

### 4.5 初始化流程（scripts/init-db.ts 行为规格）

`npm run init-db` → `ts-node src/scripts/init-db.ts`，执行逻辑：

1. `dotenv` 加载 .env；从 `config/database.ts` 导入 pg 连接池（读取 DB_HOST/DB_PORT/DB_NAME/DB_USER/DB_PASSWORD）。
2. 用 `fs.readFileSync` 读取 `database/init.sql` 全文（路径基于 `__dirname` 相对解析 `../../database/init.sql`），`pool.query(sql)` 一次性执行——建 2 枚举 + 7 表 + 11 索引 + 触发器。
3. 同法读取并执行 `seed.sql`——插入 32 花材 + 8 模板。
4. 各步打印中文成功日志；任一步出错 `console.error` 后 `process.exit(1)`；结束时关闭连接池。

> **幂等性边界**：init.sql 的表/索引/枚举可重复执行，但 `CREATE TRIGGER` 无 `IF NOT EXISTS`（PostgreSQL 语法不支持），第二次执行会在触发器语句处报 `trigger already exists` 导致 init-db 失败退出；且 **seed.sql 无去重保护**（flowers.name 无 UNIQUE 约束），重复执行会插入重复花材。复现时初始化只执行一次；需重置时先删库重建。

<!-- SECTION 4 END -->

## 5. API 契约

> 本章为后端全部 22 个 HTTP 端点的精确契约（与源码逐字段核对），含请求/响应 JSON shape、鉴权方式、错误码与错误消息原文，以及「端云对应表」（app 侧 ApiService 方法 → 后端端点映射，含 3 处调用不存在端点的已知缺陷）。

### 5.1 通用约定

#### 5.1.1 基础地址与挂载结构

- 后端监听端口：`3001`（`PORT` 环境变量可覆盖，src/index.ts 默认 3001）
- 所有路由挂载在 `/api` 前缀下（src/index.ts：`app.use('/api', routes)`）
- routes/index.ts 二级挂载（顺序即注册顺序）：

```ts
router.get('/health', ...);                    // GET /api/health
router.use('/auth', authRoutes);               // 4 端点
router.use('/recipients', recipientRoutes);    // 5 端点
router.use('/flowers', flowerRoutes);          // 3 端点
router.use('/recommendations', recommendationRoutes); // 4 端点
router.use('/orders', orderRoutes);            // 5 端点
```

- CORS 白名单：`http://localhost:3000`、`http://localhost:5173`；`express.json({ limit: '10mb' })`
- ⚠️ **端云不一致**：app 侧 `Constants.ets` 中 `BASE_URL = 'http://localhost:3000/api'`（端口 3000），而后端实际默认监听 3001。复现时需修正为 3001 或设置后端 `PORT=3000`。

#### 5.1.2 统一响应包络（utils/response.ts）

所有端点返回统一 JSON 包络：

```json
{ "code": 200, "message": "操作成功", "data": { }, "errors": [ ] }
```

| 辅助函数 | HTTP 状态码 | code 字段 | 说明 |
|---|---|---|---|
| `success(res, data, message)` | 200 | 200 | 常规成功 |
| `created(res, data, message)` | 201 | 201 | 资源创建成功 |
| `error(res, message, status)` | 自定义（默认400） | 同状态码 | 业务校验失败 |
| `notFound(res, message)` | 404 | 404 | 资源不存在 |
| `forbidden(res, message)` | 403 | 403 | 无权访问 |
| `serverError(res, message)` | 500 | 500 | 服务器内部错误 |

`data` 与 `errors` 均为可选字段；`data` 可为对象、数组或 `null`（如删除成功时 `success(res, null, '删除收花人成功')`）。

#### 5.1.3 鉴权方式

- 方案：JWT Bearer Token。请求头 `Authorization: Bearer <token>`。
- 签发：`jwt.sign({ userId, phone }, process.env.JWT_SECRET || 'default_secret', { expiresIn: '7d' })`（auth.ts 注册/登录两处相同）。
- 校验：`authMiddleware` 解析 header，失败返回 401（缺失 token / 格式错误 / 过期 / 签名无效）。
- 鉴权范围：`recipients`、`recommendations`、`orders` 三组路由整组 `router.use(authMiddleware)`；`auth` 组中 `GET/PUT /profile` 单独挂 `authMiddleware`；`flowers` 组与 `/health` 完全免鉴权。
- 属主校验模式（贯穿所有资源详情类端点）：先查记录 → 不存在返回 404 → `rows[0].user_id !== userId` 返回 403。

#### 5.1.4 限流（middleware/rateLimiter.ts）

| 限流器 | 窗口 | 上限 | 应用范围 |
|---|---|---|---|
| `apiLimiter` | 1 分钟 | 100 次 | 全局（src/index.ts 挂在 /api 上） |
| `authLimiter` | 1 分钟 | 5 次 | POST /auth/register、POST /auth/login |
| `aiLimiter` | 1 分钟 | 10 次 | POST /recommendations/generate |

超限返回 429，消息由 express-rate-limit 生成。

#### 5.1.5 分页约定

列表端点统一返回 `{ items: T[], pagination: { page, pageSize, total, totalPages } }`。参数解析逻辑逐字：

```ts
const page = Math.max(1, parseInt(pageStr, 10) || 1);
const pageSize = Math.min(50, Math.max(1, parseInt(pageSizeStr, 10) || DEFAULT));
```

⚠️ 默认 pageSize 各端点不同：`GET /flowers` 默认 **20**；`GET /orders`、`GET /recommendations` 默认 **10**。上限统一 50，下限 1。`totalPages = Math.ceil(total / pageSize)`。

### 5.2 端点总表（22 个）

| # | 方法 | 路径 | 鉴权 | 限流 | 成功码 | 用途 |
|---|---|---|---|---|---|---|
| 1 | GET | /api/health | 无 | 全局 | 200 | 健康检查 |
| 2 | POST | /api/auth/register | 无 | auth 5/min | 201 | 注册 |
| 3 | POST | /api/auth/login | 无 | auth 5/min | 200 | 登录 |
| 4 | GET | /api/auth/profile | Bearer | 全局 | 200 | 获取用户信息 |
| 5 | PUT | /api/auth/profile | Bearer | 全局 | 200 | 更新用户信息 |
| 6 | GET | /api/flowers/categories | 无 | 全局 | 200 | 花材分类列表 |
| 7 | GET | /api/flowers | 无 | 全局 | 200 | 花材列表（筛选+分页） |
| 8 | GET | /api/flowers/:id | 无 | 全局 | 200 | 花材详情 |
| 9 | GET | /api/recipients | Bearer | 全局 | 200 | 收花人列表 |
| 10 | GET | /api/recipients/:id | Bearer | 全局 | 200 | 收花人详情 |
| 11 | POST | /api/recipients | Bearer | 全局 | 201 | 创建收花人 |
| 12 | PUT | /api/recipients/:id | Bearer | 全局 | 200 | 更新收花人 |
| 13 | DELETE | /api/recipients/:id | Bearer | 全局 | 200 | 删除收花人 |
| 14 | POST | /api/recommendations/generate | Bearer | ai 10/min | 201 | 生成 AI 推荐 |
| 15 | GET | /api/recommendations | Bearer | 全局 | 200 | 推荐历史（分页） |
| 16 | GET | /api/recommendations/:id | Bearer | 全局 | 200 | 推荐详情 |
| 17 | POST | /api/recommendations/:id/feedback | Bearer | 全局 | 201 | 提交反馈评分 |
| 18 | POST | /api/orders | Bearer | 全局 | 201 | 创建订单 |
| 19 | GET | /api/orders | Bearer | 全局 | 200 | 订单列表（分页+状态筛选） |
| 20 | GET | /api/orders/:id | Bearer | 全局 | 200 | 订单详情 |
| 21 | PUT | /api/orders/:id/status | Bearer | 全局 | 200 | 更新订单状态 |
| 22 | PUT | /api/orders/:id/cancel | Bearer | 全局 | 200 | 取消订单 |

注意路由定义顺序约束：flowers.ts 中 `GET /categories` **必须定义在 `GET /:id` 之前**（源码注释明确说明），否则 "categories" 会被当作 id 匹配。

### 5.3 端点详细契约

#### 5.3.1 GET /api/health

- 鉴权：无。响应 200：

```json
{ "code": 200, "message": "服务运行正常",
  "data": { "status": "ok", "timestamp": "<ISO字符串>", "service": "flower-backend" } }
```

#### 5.3.2 POST /api/auth/register（authLimiter）

请求体：

```json
{ "phone": "13800138000", "password": "≥6位", "nickname": "可选" }
```

校验顺序与错误（消息为源码原文）：

| 条件 | 状态码 | message |
|---|---|---|
| phone 或 password 缺失 | 400 | 手机号和密码不能为空 |
| 不匹配 `/^1[3-9]\d{9}$/` | 400 | 手机号格式不正确 |
| password.length < 6 | 400 | 密码长度不能少于6位 |
| 手机号已存在 | 409 | 该手机号已注册 |
| 数据库异常 | 500 | 注册失败 |

处理：`bcrypt.genSalt(10)` → hash → `INSERT INTO users (phone, password_hash, nickname) ... RETURNING id, phone, nickname, avatar, created_at, updated_at`（nickname 缺省存 null）→ 签发 JWT。

响应 201：

```json
{ "code": 201, "message": "注册成功",
  "data": { "token": "<jwt>",
    "user": { "id": "uuid", "phone": "...", "nickname": null, "avatar": null,
              "created_at": "...", "updated_at": "..." } } }
```

#### 5.3.3 POST /api/auth/login（authLimiter）

请求体：`{ "phone": "...", "password": "..." }`。

| 条件 | 状态码 | message |
|---|---|---|
| 任一缺失 | 400 | 手机号和密码不能为空 |
| 用户不存在 **或** bcrypt.compare 失败 | 401 | 手机号或密码错误（统一消息，防手机号枚举） |
| 异常 | 500 | 登录失败 |

响应 200：`data` 同注册（`{ token, user }`，user 通过解构 `const { password_hash, ...userInfo } = user` 剔除密码哈希），message `登录成功`。

#### 5.3.4 GET /api/auth/profile（Bearer）

无参数。查询 `SELECT id, phone, nickname, avatar, created_at, updated_at FROM users WHERE id = $1`。用户不存在 → 404 `用户不存在`。响应 200 message `获取用户信息成功`，data 为 user 对象（6 字段）。

#### 5.3.5 PUT /api/auth/profile（Bearer）

请求体（均可选，动态 SET）：`{ "nickname": "≤50字符", "avatar": "URL ≤500字符" }`。

| 条件 | 状态码 | message |
|---|---|---|
| nickname 非 string 或 >50 | 400 | 昵称格式不正确（最长50字符） |
| avatar 非 string 或 >500 | 400 | 头像URL格式不正确 |
| 两字段均未提供 | 400 | 没有需要更新的字段 |
| UPDATE 后无行 | 404 | 用户不存在 |

响应 200 message `更新用户信息成功`，data 为更新后 user（RETURNING 同 6 字段）。

#### 5.3.6 GET /api/flowers/categories

SQL 逐字：`SELECT DISTINCT category FROM flowers WHERE available = true ORDER BY category`。

响应 200 message `获取花材分类成功`，data 为字符串数组（`rows.map(r => r.category)`），如 `["主花", "配花", "配叶"]`。

#### 5.3.7 GET /api/flowers

Query 参数：`color`、`category`、`season`、`keyword`、`page`（默认1）、`pageSize`（默认20，上限50）。

查询条件构建（恒含 `available = true`）：

- `color` → `color = $n` 精确匹配
- `category` → `category = $n` 精确匹配
- `season` → `season = $n` 精确匹配
- `keyword` → `(name LIKE $n OR name_en LIKE $n OR meaning LIKE $n)`，值为 `%${keyword}%`（LIKE 区分大小写，非 ILIKE）
- 排序：`ORDER BY name`（无方向即 ASC）

响应 200 message `获取花材列表成功`：

```json
{ "data": { "items": [ { "id": 1, "name": "红玫瑰", "name_en": "Red Rose", "category": "主花",
      "color": "红色", "season": "全年", "price_per_stem": "5.00", "meaning": "...",
      "description": "...", "image_url": null, "available": true, "created_at": "..." } ],
    "pagination": { "page": 1, "pageSize": 20, "total": 32, "totalPages": 2 } } }
```

注意：`price_per_stem` 为 PostgreSQL NUMERIC，pg 驱动返回 **字符串**（如 `"5.00"`），app 侧按 number 解析时需转换（ApiService.getFlowers 直接 `as number` 强转，存在隐患）。

#### 5.3.8 GET /api/flowers/:id

`SELECT * FROM flowers WHERE id = $1`。无记录 → 404 `花材不存在`。响应 200 message `获取花材详情成功`，data 为单个花材对象（字段同上）。

#### 5.3.9 GET /api/recipients（Bearer）

`SELECT * FROM recipients WHERE user_id = $1 ORDER BY created_at DESC`。响应 200 message `获取收花人列表成功`，data 为数组（**不分页**），元素为 recipients 全字段行（见 4.2 表结构，含 14 个业务字段 + id/user_id/created_at/updated_at）。

#### 5.3.10 GET /api/recipients/:id（Bearer）

| 条件 | 状态码 | message |
|---|---|---|
| 记录不存在 | 404 | 收花人不存在 |
| 非属主 | 403 | 无权访问此收花人档案 |

响应 200 message `获取收花人详情成功`。

#### 5.3.11 POST /api/recipients（Bearer）

请求体（14 个业务字段，仅 name/relationship 必填）：

```json
{ "name": "必填", "gender": "male|female|other 可选", "age": 25,
  "relationship": "必填，如：恋人", "relationship_duration": "可选",
  "interests": "可选", "personality": "可选", "career": "可选",
  "color_preference": "可选", "style_preference": "可选",
  "allergies": "可选", "cultural_notes": "可选", "notes": "可选" }
```

校验（消息原文）：

| 条件 | 状态码 | message |
|---|---|---|
| name 缺失/非string/trim后空 | 400 | 收花人姓名不能为空 |
| relationship 同上 | 400 | 与收花人的关系不能为空 |
| gender 提供但不在枚举内 | 400 | 性别字段无效，可选值：male, female, other |
| age 提供但非number或<0或>200 | 400 | 年龄格式不正确 |

INSERT 14 字段（name/relationship 存 trim 后值，其余 `|| null`）`RETURNING *`。响应 201 message `创建收花人成功`。

#### 5.3.12 PUT /api/recipients/:id（Bearer）

先属主校验：404 `收花人不存在` / 403 `无权修改此收花人档案`。gender/age 校验同 POST（区别：age 允许显式 `null`，即 `age !== undefined && age !== null` 才校验范围）。动态构建 SET（仅更新提供的字段，name/relationship 若为 string 则 trim）；无任何字段 → 400 `没有需要更新的字段`。响应 200 message `更新收花人成功`，data 为更新后全行。

#### 5.3.13 DELETE /api/recipients/:id（Bearer）

404 `收花人不存在` / 403 `无权删除此收花人档案`。成功：`success(res, null, '删除收花人成功')`（data 为 null）。注意外键级联：recommendations.recipient_id 为 `ON DELETE CASCADE`，删收花人会级联删推荐记录（见 4.2）。

#### 5.3.14 POST /api/recommendations/generate（Bearer + aiLimiter 10/min）

核心端点。请求体两种模式：

**模式 A（有档案）**：`recipientId` + `occasion`（必填）+ 可选覆盖字段：

```json
{ "recipientId": "uuid", "occasion": "生日",
  "relationshipContext": { "duration": "...", "previousFlowers": "...", "recentEvents": "..." },
  "culturalFactors": { "taboos": "...", "customs": "..." },
  "recipientProfile": { "interests": "...", "career": "...", "personality": "..." },
  "preferences": { "favoriteColors": "...", "style": "...", "allergies": "..." },
  "budget": { "min": 100, "max": 300 }, "additionalNotes": "..." }
```

**模式 B（无档案）**：不传 recipientId，但必须提供 `recipientProfile` 或 `recipientInfo` 之一。

处理流程（逐步）：

1. `occasion` 缺失 → 400 `送花场景不能为空`。
2. 模式 A：查档案 → 404 `收花人不存在` / 403 `无权访问此收花人档案`；用 DB 字段组装 `RecommendationInput`（duration←relationship_duration、customs←cultural_notes、favoriteColors←color_preference 等，空值转 undefined）；请求体中同名对象字段以浅层 spread **覆盖** DB 值。
3. 模式 B：两者均无 → 400 `请提供recipientId或recipientProfile/recipientInfo`；否则**创建临时收花人记录**（满足 recommendations.recipient_id NOT NULL 约束）：name 缺省 `'匿名收花人'`，relationship 缺省 `'朋友'`，cultural_notes 取 `taboos || customs`。
4. budget 归一化：`budget ? { min: budget.min || 50, max: budget.max || 500 } : undefined`。
5. 调用 `recommendationService.generateRecommendation(input)`（缓存/AI 逻辑见第 6 章）；抛 `RecommendationError` → 500 `AI推荐失败: ${aiErr.message}`。
6. 落库：`INSERT INTO recommendations (user_id, recipient_id, occasion, input_context, ai_response)`，input_context 为入参快照 JSON（含 occasion/relationshipContext/culturalFactors/recipientProfile/preferences/budget/additionalNotes），ai_response 为 `JSON.stringify(plans)`。

响应 201 message `AI推荐生成成功`：

```json
{ "data": {
    "recommendation": { "id": "uuid", "user_id": "...", "recipient_id": "...", "occasion": "...",
      "input_context": { }, "ai_response": [ ], "selected_plan_index": null, "created_at": "..." },
    "plans": [ { "name": "星河入梦", "theme": "浪漫告白",
        "flowers": [ { "name": "红玫瑰", "count": 9, "color": "红色", "meaning": "热烈的爱" } ],
        "wrapping": { "style": "韩式", "color": "香槟色", "material": "雾面纸" },
        "flowerLanguage": "...", "reason": "...", "estimatedPrice": 199,
        "cardSuggestion": "..." } ] } }
```

（BouquetPlan 字段结构以 services/qwen/types.ts 与 SYSTEM_PROMPT 输出规范为准，见 6.2；plans 最多 3 个。）

#### 5.3.15 GET /api/recommendations（Bearer）

分页（默认 pageSize 10）。SQL 含 LEFT JOIN：

```sql
SELECT r.*, rec.name as recipient_name
FROM recommendations r
LEFT JOIN recipients rec ON r.recipient_id = rec.id
WHERE r.user_id = $1 ORDER BY r.created_at DESC LIMIT $2 OFFSET $3
```

响应 200 message `获取推荐历史成功`，`{ items, pagination }`，items 元素额外含 `recipient_name`。

#### 5.3.16 GET /api/recommendations/:id（Bearer）

同样 LEFT JOIN 取 recipient_name。404 `推荐记录不存在` / 403 `无权访问此推荐记录`。响应 200 message `获取推荐详情成功`。

#### 5.3.17 POST /api/recommendations/:id/feedback（Bearer）

请求体：`{ "rating": 1-5整数, "comment": "可选" }`。

校验顺序（注意：先属主校验，后参数校验）：

| 条件 | 状态码 | message |
|---|---|---|
| 推荐记录不存在 | 404 | 推荐记录不存在 |
| 非属主 | 403 | 无权对此推荐记录提交反馈 |
| rating 缺失/非number/<1/>5 | 400 | 评分必须为1-5的整数 |
| `!Number.isInteger(rating)` | 400 | 评分必须为整数 |
| 同一 (recommendation_id, user_id) 已有反馈 | 409 | 已对此推荐提交过反馈 |

INSERT INTO user_feedback `RETURNING id, user_id, recommendation_id, rating, comment, created_at`。响应 201 message `提交反馈成功`。

#### 5.3.18 POST /api/orders（Bearer）

请求体：

```json
{ "recommendation_id": "uuid 可选", "selected_plan_index": 0,
  "total_price": 214, "delivery_address": "必填",
  "delivery_time": "可选 ISO 时间", "greeting_card_message": "可选" }
```

校验与处理：

| 条件 | 状态码 | message |
|---|---|---|
| delivery_address 缺失/非string/trim后空 | 400 | 配送地址不能为空 |
| total_price 缺失/非number/≤0 | 400 | 订单金额必须大于0 |
| 传了 recommendation_id 但记录不存在 | 404 | 推荐记录不存在 |
| 推荐记录非属主 | 403 | 无权使用此推荐记录 |

副作用：若同时传 `recommendation_id` 与 `selected_plan_index !== undefined`，会回写 `UPDATE recommendations SET selected_plan_index = $1 WHERE id = $2`。

INSERT 固定 `status='pending'`，可选字段 `|| null`，delivery_address 存 trim 后值，`RETURNING *`。响应 201 message `创建订单成功`，data 为 orders 全字段行。

#### 5.3.19 GET /api/orders（Bearer）

Query：`status`（需在 6 枚举值内才生效，非法值静默忽略）、`page`、`pageSize`（默认 **10**，上限 50）。`ORDER BY o.created_at DESC`。响应 200 message `获取订单列表成功`，`{ items, pagination }`。

#### 5.3.20 GET /api/orders/:id（Bearer）

404 `订单不存在` / 403 `无权访问此订单`。响应 200 message `获取订单详情成功`。

#### 5.3.21 PUT /api/orders/:id/status（Bearer）

请求体：`{ "status": "paid" }`。校验顺序：

1. 404 `订单不存在` / 403 `无权修改此订单`
2. status 不在 6 值内 → 400 `状态值无效，可选值：pending, paid, preparing, delivering, completed, cancelled`
3. 状态机校验（statusFlow 常量逐字）：

```ts
const statusFlow: Record<string, string[]> = {
  pending: ['paid', 'cancelled'],
  paid: ['preparing', 'cancelled'],
  preparing: ['delivering', 'cancelled'],
  delivering: ['completed'],
  completed: [],
  cancelled: [],
};
```

非法流转 → 400 `订单状态不能从"${currentStatus}"变更为"${status}"`。成功 UPDATE `RETURNING *`，200 message `更新订单状态成功`。

#### 5.3.22 PUT /api/orders/:id/cancel（Bearer）

无请求体。404 `订单不存在` / 403 `无权取消此订单`。可取消状态常量：`cancellableStatuses = ['pending', 'paid', 'preparing']`，否则 400 `订单状态为"${currentStatus}"，无法取消`。成功置 `cancelled`，200 message `取消订单成功`。

### 5.4 错误码总览

| 状态码 | 触发场景 |
|---|---|
| 400 | 参数校验失败（必填缺失/格式/范围/状态机非法流转/无更新字段） |
| 401 | 登录失败（统一消息）；token 缺失/无效/过期（authMiddleware） |
| 403 | 访问/修改/删除非本人资源（recipients/recommendations/orders 均有） |
| 404 | 资源不存在（用户/花材/收花人/推荐/订单）；未匹配路由（index.ts 兜底 `接口不存在`） |
| 409 | 手机号已注册；重复提交反馈 |
| 429 | 限流（全局 100/min、auth 5/min、AI 10/min） |
| 500 | 服务器异常；AI 推荐失败（`AI推荐失败: <原因>`，原因含余额不足/频繁/密钥无效/超时/服务不可用等，见第 6 章错误映射） |

### 5.5 端云对应表（ApiService → 后端端点）

app 侧唯一 API 层：`app/entry/src/main/ets/services/ApiService.ets`（19 个静态方法）+ `HttpUtil.ets`（底层封装，`BASE_URL + 相对路径`，第三参 `true` 表示携带 Bearer token）。

| ApiService 方法 | HTTP | 调用路径 | 后端端点 | 主要调用页面 | 状态 |
|---|---|---|---|---|---|
| login | POST | /auth/login | #3 | LoginPage | ✅（成功后 saveToken） |
| register | POST | /auth/register | #2 | RegisterPage | ✅（成功后 saveToken） |
| getProfile | GET | /auth/profile | #4 | ProfilePage | ✅ |
| updateProfile | PUT | /auth/profile | #5 | ProfilePage | ✅ |
| getFlowers | GET | /flowers | #7 | FlowerListPage | ✅（手工映射 items→flowers，price_per_stem→price，popularity 写死 80） |
| getFlowerDetail | GET | /flowers/:id | #8 | FlowerDetailPage | ✅ |
| getRecipients | GET | /recipients | #9 | RecipientProfilePage | ✅ |
| createRecipient | POST | /recipients | #11 | RecipientProfilePage | ✅ |
| updateRecipient | PUT | /recipients/:id | #12 | RecipientProfilePage | ✅ |
| deleteRecipient | DELETE | /recipients/:id | #13 | RecipientProfilePage | ✅ |
| generateRecommendation | POST | /recommendations/generate | #14 | RecommendPage→ResultPage | ✅ |
| getRecommendationHistory | GET | **/recommendations/history** | ❌ 无此端点 | HistoryPage | 🐞 404（应为 GET /recommendations） |
| createOrder | POST | /orders | #18 | OrderConfirmPage | ✅ |
| getOrders | GET | /orders | #19 | OrderListPage | ✅ |
| getOrderDetail | GET | /orders/:id | #20 | OrderDetailPage | ✅ |
| updateOrderStatus | PUT | /orders/:id/status | #21 | PaymentPage/OrderDetailPage | ✅ |
| cancelOrder | PUT | /orders/:id/cancel | #22 | OrderListPage/OrderDetailPage | ✅ |
| submitFeedback | POST | **/feedbacks** | ❌ 无此端点 | ResultPage | 🐞 404（应为 POST /recommendations/:id/feedback） |
| getFeedbackHistory | GET | **/feedbacks** | ❌ 无此端点 | （未被页面调用） | 🐞 404（后端无反馈列表端点） |

未被 app 调用的后端端点：#1 health、#6 /flowers/categories、#10 /recipients/:id、#15 /recommendations、#16 /recommendations/:id、#17 /recommendations/:id/feedback（应被 submitFeedback 调用但路径写错）。

**复现提示**：若目标是「实现细节高度还原」，应原样保留上述 3 处错配（app 相应功能实际走 mock 数据兜底，见第 7/8 章）；若目标是「功能可用」，再按上表「应为」列修正。

<!-- SECTION 5 END -->

## 6. 核心业务逻辑与算法

> 本章汇总全部关键流程、算法参数常量与边界条件。AI prompt 字符串属白名单资产，在 6.2 逐字收录。

### 6.1 AI 推荐全链路（recommendationService.ts）

主流程 `generateRecommendation(input)` 七步：

```
① validateInput → ② normalizeInput → ③ 查 Redis 缓存（命中则直接返回）
→ ④ buildMessages + 场景增强注入 → ⑤ 调用通义千问（temperature 0.8, max_tokens 4096）
→ ⑥ 四级容错解析（失败则追问重试 1 次，temperature 0.3）
→ ⑦ validateAndFixPlans（价格修正 + 截断到 3 个）→ 写缓存 → 返回
```

配置常量（逐字）：

```ts
const RECOMMENDATION_CONFIG = {
  maxPlans: 3,                    // 必须返回的方案数
  maxRetries: 1,                  // 解析失败最大重试次数
  defaultBudgetMin: 50,           // 默认最低预算
  defaultBudgetMax: 500,          // 默认最高预算
  priceTolerancePercent: 0.15,    // 价格超出预算的容忍度（15%）
};
```

#### 6.1.1 输入校验与归一化

`validateInput` 抛 `RecommendationError(msg, 'INVALID_INPUT', false)`：

- `recipientInfo.name` 缺失 → `收花人姓名不能为空`
- `recipientInfo.relationship` 缺失 → `与收花人的关系不能为空`
- `occasion` 缺失 → `送花场景不能为空`
- `budget.min < 0 || budget.max < 0` → `预算不能为负数`；`min > max` → `最低预算不能高于最高预算`

`normalizeInput`：occasion/name/relationship 各自 trim；budget 缺省填 `{min:50, max:500}`；additionalNotes trim 后空字符串转 undefined。

#### 6.1.2 错误包装链

- `QwenApiError` → 包装为 `RecommendationError('通义千问API调用失败: ' + msg, err.code, retryable)`，其中 retryable = `code !== 'INSUFFICIENT_BALANCE' && code !== 'INVALID_API_KEY'`。
- 其他异常 → `RecommendationError('AI服务异常: ' + msg, 'AI_SERVICE_ERROR', true)`。
- AI 返空 → `('AI返回了空内容', 'EMPTY_RESPONSE', true)`；重试后仍空 → `('重试后AI仍返回空内容', 'RETRY_EMPTY_RESPONSE', false)`。
- 路由层最终向客户端返回 500 `AI推荐失败: ${message}`。

#### 6.1.3 四级容错解析（parseAiResponse）

按顺序尝试，任一级成功即返回（同时支持 `{plans:[...]}` 对象与裸数组两种形态）：

1. **直接 JSON.parse** 整段内容。
2. **提取代码块**：正则逐字 `/```(?:json)?\s*\n?([\s\S]*?)\n?\s*```/`。
3. **提取最外层花括号**（extractOutermostBraces）：`indexOf('{')` 到 `lastIndexOf('}')` 切片；若无效则退而求 `[` 到 `]`。
4. **JSON 修复**（attemptJsonRepair，正则逐字）：
   - 去 markdown 标记：`/```(?:json)?\s*/g` 与 `/```\s*/g` 替空
   - 去 BOM：`/^\uFEFF/`
   - 去控制字符（保留 \n \t）：`/[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]/g`
   - 去尾部逗号：`/,\s*([}\]])/g` → `'$1'`
   - 键名补引号：`/([{,]\s*)(\w+)(\s*:)/g` → `'$1"$2"$3'`
   - 单引号转双引号：`/'/g` → `'"'`
   - 最后再走一次最外层括号提取

全部失败 → `RecommendationError('无法从AI响应中解析出有效的花束推荐方案', 'PARSE_ERROR', true)` → 触发**追问重试**：在原消息后追加 assistant 原文 + user 追问（原文逐字）：

> 你刚才的返回格式不正确，请严格按照JSON格式返回，不要添加markdown标记或其他多余文字。只返回包含plans数组的JSON对象。

重试参数 `temperature: 0.3, max_tokens: 4096`；仍失败 → `('AI响应格式异常，重试后仍无法解析: ...', 'PARSE_FAILED_AFTER_RETRY', false)`。

#### 6.1.4 单方案校验与默认值填充（validateSinglePlan）

逐字段检查，缺失时填默认值（不拒绝方案）：

| 字段 | 类型要求 | 默认值 |
|---|---|---|
| name | string | `花束方案${index+1}` |
| theme | string | `温馨花束` |
| flowers | 非空数组 | `[{ name: '玫瑰', count: 9, color: '红色', meaning: '爱情' }]` |
| flowers[i].name | - | `花材${fi+1}` |
| flowers[i].count | number>0 | `3` |
| flowers[i].color | - | `混合` |
| flowers[i].meaning | - | `美好祝福` |
| wrapping | object | `{ style: '简约', color: '素雅', material: '韩式包装纸' }`（逐字段兜底） |
| flowerLanguage | string | `美好的祝福与心意` |
| reason | string | `精心搭配的花束方案` |
| estimatedPrice | number>0 | `200` |
| cardSuggestion | string | `愿你每天如花般灿烂` |

注意：`validatePlansStructure` 对单个方案校验抛错时仅 console.warn 并原样保留该方案（`return plan as BouquetPlan`）；仅当 plans 整体为空数组才抛 `('AI返回的方案列表为空', 'EMPTY_PLANS', true)`。

#### 6.1.5 价格修正算法（validateAndFixPlans）

```
maxAllowed = budget.max × 1.15
minAllowed = budget.min × 0.85
estimatedPrice > maxAllowed            → 置 Math.round(budget.max)
estimatedPrice < minAllowed 且 min > 0 → 置 Math.round(budget.min)
```

即：允许±15% 超界；超出容忍带才硬修到预算边界（而非容忍边界）。方案数 >3 截断为前 3 个；<3 仅告警不补齐。

### 6.2 AI Prompt 全量原文（prompts.ts，白名单逐字收录）

#### 6.2.1 SYSTEM_PROMPT（常量原文，模板字符串全文）

```text
你是一位拥有20年经验的资深花艺师，精通全球花语文化、色彩心理学和情感表达艺术。你的使命是根据用户的送花需求，推荐最贴心、最恰当的花束方案。

## 你的核心能力
1. **花语文化精通**：熟知中西方花语体系，了解不同文化中花材的寓意差异与禁忌
2. **情感洞察敏锐**：能从细微的关系描述中捕捉情感需求，理解"刚交3天的对象"与"相恋3年的伴侣"之间截然不同的情感温度
3. **场景理解深刻**：深谙每种送花场合的社交礼仪和情感期望，知道道歉与感谢、表白与纪念日之间的微妙差别
4. **美学造诣深厚**：对花材搭配、色彩和谐、包装风格有专业审美，每个方案都兼具美感和寓意
5. **文化敏感度高**：尊重不同地域和文化背景的花材禁忌与习俗

## 推荐原则
- 同一花束中花材寓意要和谐统一，避免寓意冲突
- 花材颜色搭配要符合色彩美学，主花和配花层次分明
- 严格遵守文化禁忌，绝不推荐可能冒犯对方的花材
- 价格预估要合理，在用户预算范围内提供最优方案
- 3个方案之间要有明显的风格差异，覆盖不同的情感表达方式

## 输出格式要求
你必须严格返回JSON格式，不要添加任何markdown代码块标记或额外文字。返回一个对象，包含plans数组，数组中恰好3个方案。

每个方案的JSON结构如下：
{
  "plans": [
    {
      "name": "花束的诗意名称",
      "theme": "方案主题",
      "flowers": [
        {
          "name": "花材名称",
          "count": 数量(正整数),
          "color": "颜色",
          "meaning": "选择此花的寓意说明"
        }
      ],
      "wrapping": {
        "style": "包装风格",
        "color": "包装主色调",
        "material": "包装材质"
      },
      "flowerLanguage": "整束花的花语解读，融合各花材寓意的统一诠释",
      "reason": "详细解释为什么这个方案适合此场景，从情感、花语、美学等维度分析",
      "estimatedPrice": 预估价格(数字，单位元),
      "cardSuggestion": "贺卡文案建议，贴合场景的温暖文字"
    }
  ]
}

## 重要规则
- flowers数组至少包含3种花材
- estimatedPrice必须是数字，且在用户预算范围内
- name要有诗意和创意，如"星河入梦"、"春风知我意"
- cardSuggestion要贴合具体场景，避免空洞的套话
- reason要具体且有深度，体现对场景和关系的理解
- 绝对不要使用用户提及的禁忌花材
- 只返回JSON，不要有任何其他文字
```

#### 6.2.2 User Prompt 构建（buildUserPrompt）

按顺序拼接 sections（`join('\n')`），各段模板逐字：

1. `【收花人信息】`：4 行 `- 姓名：/性别：/年龄：/与我的关系：`；gender 经 `genderMap = { male: '男', female: '女', other: '其他' }` 映射，缺失显示 `未知`；age 拼 `${age}岁`，缺失 `未知`。
2. `\n【送花场景】${occasion}`。
3. 可选 `【关系进展】`：`交往时长：`/`之前送过：`/`最近发生的事：`（均有值才输出，段内 join('\n')）。
4. 可选 `【文化与地域因素】`：`花材禁忌：`/`地方习俗：`。
5. 可选 `【对方画像】`：`兴趣爱好：`/`职业：`/`性格特点：`。
6. 可选 `【个性化偏好】`：`喜欢的颜色：`/`风格偏好：`/`过敏信息：`。
7. `【预算范围】${min}元 - ${max}元`；无 budget 时：`【预算范围】不限（请推荐合理价位的方案）`。
8. 可选 `【补充说明】${additionalNotes}`。
9. 结尾指引（原文逐字）：

```text
请基于以上信息，为我推荐3个不同风格的花束方案。要求：
1. 三个方案风格各异，分别侧重不同的情感表达角度
2. 所有花材需符合文化禁忌要求
3. 预估价格需在预算范围内
4. 请直接返回JSON，不要添加任何多余文字
```

`buildMessages` 返回 `[{role:'system', content:SYSTEM_PROMPT}, {role:'user', content:buildUserPrompt(input)}]`。

#### 6.2.3 场景增强（getSceneEnhancement，8 条文案原文）

匹配规则：遍历 `sceneEnhancements`，`occasion.includes(key)` 首个命中即 break（只取一条）；命中后追加到 enhancement 并换行。

| key | 文案原文 |
|---|---|
| 表白 | 这是表白场景，花束需要传达含蓄而坚定的爱意，不宜过于张扬但必须让对方感受到真心。红色和粉色系为主，玫瑰是经典但可以考虑更有新意的主花。 |
| 道歉 | 道歉场景需要真诚和谦逊，花语要表达悔意和珍惜。避免过于热烈的颜色，选择温和的色调。白色和淡色系更合适，黄玫瑰在道歉中有特殊含义。 |
| 生日 | 生日花束要体现祝福和喜悦，可以根据对方性格选择活泼或优雅的风格。考虑年龄因素，年轻人可能更喜欢清新创意，长辈更注重传统花语的庄重。 |
| 纪念日 | 纪念日需要回顾和展望，花语要有时间感和延续感。可以融入“长久”、“永恒”的寓意，百合、桔梗都是好选择。 |
| 感谢 | 感谢花束要温暖而不越界，特别是异性之间要注意分寸。花语以感恩、敬意为主，避免容易产生误解的花材。 |
| 探望 | 探望病人或老人需要注意：避免浓烈香气、不用白色菊花（中国丧葬用花）、不选花粉多的花材。选择寓意健康、平安的花，颜色以温暖明亮为宜。 |
| 毕业 | 毕业是告别也是启程，花束要兼顾留念和期许。向日葵、雏菊象征光明未来，可以加入对方学校代表色的花材。 |
| 婚礼 | 婚礼用花讲究吉祥、圆满，红色和白色为主。注意不要使用在婚俗中有忌讳的花材。 |

特殊关系增强（对 additionalNotes 正则匹配，三条可叠加，正则逐字）：

| 正则 | 追加文案原文 |
|---|---|
| `/刚.{0,4}(交|在一起|确认|恋爱)/` | 注意：这是刚确认的关系，感情基础尚浅。推荐方案要把握“有心但不越界”的分寸感，花束不宜过于隆重或昂贵，避免给对方压力。清新、自然、有小心思的方案更合适。 |
| `/(暗恋|单恋|还没表白)/` | 注意：这是暗恋场景，花束的寓意要含蓄，不宜过于直白。可以选择花语有“默默守护”、“初见倾心”等含义的花材，为日后表白留有余地。 |
| `/(异地|远距离|分开)/` | 注意：异地关系需要特别的花语表达，花束要传达思念和坚守。可以考虑加入“跨越距离”寓意的花材，整体感觉要温暖而不伤感。 |

注入方式（injectEnhancement）：将增强文本以 `\n\n## 本次推荐的特殊注意\n` + enhancement 拼接到 system 消息末尾。

### 6.3 通义千问客户端（qwenClient.ts）

配置（构造函数内常量）：

| 配置 | 值 |
|---|---|
| apiKey | `process.env.QWEN_API_KEY \|\| ''`（未配时启动告警，调用时抛错） |
| apiUrl | `process.env.QWEN_API_URL \|\| 'https://dashscope.aliyuncs.com/compatible-mode/v1/chat/completions'` |
| model | `process.env.QWEN_MODEL \|\| 'qwen-plus'` |
| timeout | `30000` ms |
| maxRetries | `2` |

请求默认参数（chat/chatStream 共用）：`temperature ?? 0.7`、`top_p ?? 0.9`、`max_tokens ?? 4096`；推荐服务实际传 temperature 0.8（首次）/0.3（重试）。实现不用 SDK，直接用 Node 原生 `https/http.request`，header 含 `Authorization: Bearer <apiKey>`、`Content-Length: Buffer.byteLength(postData)`。

重试策略（requestWithRetry）：最多 `maxRetries+1 = 3` 次尝试；退避 `Math.min(1000 * 2^attempt, 5000)` ms（即 1s、2s）；`NO_API_KEY`/`INVALID_REQUEST`/statusCode 401 不重试直接抛；全部失败抛最后一个错或 `('请求失败，已达到最大重试次数', 'MAX_RETRIES', 500)`。

错误映射（sendRequest 内，消息原文）：

| 条件 | QwenApiError(message, code, statusCode) |
|---|---|
| 未配置 Key | `未配置QWEN_API_KEY，请设置环境变量后重试`, NO_API_KEY, 401 |
| error.code==='InsufficientBalance' 或消息含'余额' | `通义千问API余额不足，请充值后重试`, INSUFFICIENT_BALANCE, 402 |
| HTTP 429 | `API请求频率超限，请稍后重试`, RATE_LIMITED, 429 |
| HTTP 401 | `API Key无效或已过期`, INVALID_API_KEY, 401 |
| 其他 API error | 原 message, 原 code, 原 statusCode |
| 响应非 JSON | `API响应解析失败: ...`, PARSE_ERROR, 500 |
| 超时（req.setTimeout 30s） | `请求超时（30秒）`, TIMEOUT, 408 |
| 网络错误 | `网络请求失败: ...`, NETWORK_ERROR, 503 |

另有 `chatStream`（SSE 解析，`data: ` 前缀逐行、`[DONE]` 终止、末尾 buffer 补解析）——**当前业务未使用**，但实现完整，复现时应保留。

### 6.4 Redis 缓存策略（cacheService.ts）

| 参数 | 值 |
|---|---|
| 连接 | REDIS_HOST/REDIS_PORT/REDIS_PASSWORD/REDIS_DB（默认 localhost:6379 db0 无密码） |
| TTL | `4 * 60 * 60` 秒（4 小时，setex 写入） |
| keyPrefix | `'flower:rec:'` |
| key 生成 | `keyPrefix + md5(JSON.stringify(input, Object.keys(input).sort()))`（注意：仅顶层键排序，嵌套对象键顺序不归一） |
| 缓存值 | `CacheEntry = { plans, cachedAt: Date.now(), inputHash }` |
| 双重过期检查 | 读取时若 `Date.now() - cachedAt > ttl*1000` 则 del 并返回 null |
| 降级 | lazyConnect；retryStrategy 最多 5 次（间隔 `Math.min(times*1000, 5000)`）；`maxRetriesPerRequest: 2`；连不上则 get 返 null / set 静默跳过，**不影响主流程** |

### 6.5 订单状态机

```
pending ─paid─▶ paid ─preparing─▶ preparing ─delivering─▶ delivering ─completed─▶ completed（终态）
   │              │                  │
   └─cancelled───┴────────────────┴──▶ cancelled（终态；delivering 不可取消）
```

- 流转表 statusFlow 与可取消集合 `['pending','paid','preparing']` 已在 5.3.21/5.3.22 逐字收录。
- 创建订单恒为 `pending`；支付由 app 侧 PaymentPage 模拟（调 PUT /:id/status 置 paid）。
- 数据库层另有 CHECK 约束 + 枚举类型兼容（见第 4 章）；路由层校验先于 DB 约束生效。

### 6.6 鉴权与安全链

- 密码：bcryptjs，`genSalt(10)`；登录用 `bcrypt.compare`。
- JWT：payload `{userId, phone}`，`expiresIn: '7d'`，secret `JWT_SECRET || 'default_secret'`（❗生产必须设置环境变量，默认值仅开发兜底）。
- authMiddleware：解析 `Authorization: Bearer <token>`，`jwt.verify` 成功后挂 `req.user = { userId, phone }`；失败统一 401。
- 手机号正则（全局唯一校验点，逐字）：`/^1[3-9]\d{9}$/`。
- app 侧 token 存储：Preferences 键 `auth_token`（TOKEN_KEY）；HttpUtil 收到 401 时清除本地 token。

### 6.7 app 侧关键业务常量与逻辑（汇总，详见第 7/8 章）

| 位置 | 常量/逻辑 | 值 |
|---|---|---|
| Constants.ets | BASE_URL | `http://localhost:3000/api`（与后端 3001 不一致，见 5.1.1） |
| Constants.ets | HTTP_TIMEOUT | 15000 ms（connect/read 共用） |
| Constants.ets | TOKEN_KEY / USER_INFO_KEY | `auth_token` / `user_info` |
| CartStore | 商品数量边界 | 1–99（超界截断）；AppStorage + Preferences 双层持久化 |
| RecommendPage | budget 默认值 | 200 元（滑块） |
| ResultPage | mock 3 方案价格 | ¥108 / ¥133 / ¥127（AI 失败时兜底展示） |
| OrderConfirmPage | DELIVERY_FEE | 15 元；且 catch 分支也模拟下单成功 |
| PaymentPage | 模拟支付延时 | 支付 2000ms + 跳转 1500ms |
| OrderListPage | 状态 Tab | 6 个（全部/待付款/已付款/备货中/配送中/已完成）；接口失败时 mock 4 单兜底 |
| RecipientProfilePage | age 取值 | 选项为年龄段，提交时取范围下限 |

<!-- SECTION 6 END -->

## 7. 核心文件逐一说明【文档主体】

> 7.1 后端全部 26 个业务文件精讲；7.2 app 侧核心文件精讲；7.3 app 其余文件模块级表格。白名单内容（算法常数/正则/prompt/协议）已在前各章逐字收录，本章不重复全文，只标注引用。

### 7.1 后端文件精讲（backend/src，26 文件）

#### 7.1.1 src/index.ts（73 行）—— 应用入口

- **职责**：Express 应用组装与启动。
- **实现要点**（中间件顺序即注册顺序，不可颠倒）：`dotenv.config()` → cors → `express.json({limit:'10mb'})` → `express.urlencoded({extended:true})` → apiLimiter → 请求日志（`[请求] ${method} ${path} - ${ip}`）→ `app.use('/api', routes)` → notFoundHandler → errorHandler。
- **关键常量**：`PORT = parseInt(process.env.PORT || '3001', 10)`；CORS origin 生产环境 `['https://your-domain.com']`（占位），开发 `['http://localhost:3000', 'http://localhost:5173']`，`credentials: true`。
- **启动逻辑**：`startServer()` 先 `testConnection()`，失败仅告警 `[启动] 数据库连接失败，部分功能可能不可用` 而**不退出**；listen 后打印三行启动日志（含“花语心选后端服务”字样）。`export default app`。
- **边界**：urlencoded 未限 limit；日志中间件在限流之后（被限流的请求不记日志）。

#### 7.1.2 src/config/database.ts（53 行）—— PG 连接池

- **职责**：全局单例 Pool + query 封装。
- **连接池参数**（逐字）：`host: DB_HOST||'localhost'`、`port: DB_PORT||5432`、`database: DB_NAME||'flower_db'`、`user: DB_USER||'postgres'`、`password: DB_PASSWORD||''`、`max: 20`、`idleTimeoutMillis: 30000`、`connectionTimeoutMillis: 2000`。
- **query(text, params)**：计时并打印 `[数据库] 执行查询: ${text.slice(0,80)}... 耗时: ${duration}ms, 行数: ${rowCount}`。
- **其他导出**：`getPool()`、`testConnection()`（connect 后立即 release，返 boolean）、default pool；`pool.on('error')` 仅打日志。

#### 7.1.3 src/middleware/auth.ts（77 行）—— JWT 中间件

- **authMiddleware**：四段式校验，错误消息原文：
  1. 无 header 或不以 `Bearer ` 开头 → 401 `缺少认证令牌，请在Authorization头中提供Bearer token`
  2. `split(' ')[1]` 为空 → 401 `认证令牌格式错误`
  3. `jwt.verify(token, JWT_SECRET||'default_secret')` 抛 `TokenExpiredError` → 401 `认证令牌已过期，请重新登录`；`JsonWebTokenError` → 401 `认证令牌无效`；其他 → 401 `认证失败`
  4. 成功后 `authReq.user = { userId, phone }` 并 next()
- **optionalAuth**：同样解析但任何失败都静默 next()（**当前无路由使用**，复现时保留）。

#### 7.1.4 src/middleware/rateLimiter.ts（52 行）—— 三级限流

基于 express-rate-limit，三个实例均为 `windowMs: 60*1000`、`standardHeaders: true`、`legacyHeaders: false`、`keyGenerator: req => req.ip || 'unknown'`；差异仅 max 与 message：

| 实例 | max | message.message 原文 |
|---|---|---|
| apiLimiter | 100 | 请求过于频繁，请稍后再试 |
| authLimiter | 5 | 登录尝试过于频繁，请1分钟后再试 |
| aiLimiter | 10 | AI推荐请求过于频繁，请稍后再试 |

message 对象均含 `code: 429`。

#### 7.1.5 src/middleware/errorHandler.ts（50 行）—— 全局错误处理

- **errorHandler**（4 参签名）：`SyntaxError 且 'body' in err` → 400 `请求体JSON格式错误`（errors 含原始消息）；`ValidationError` → 422 `数据验证失败`；其他 → 500，生产环境消息固定 `服务器内部错误`，非生产透传 err.message 且 errors 附 `err.stack`。
- **notFoundHandler**：404，message 模板 `接口不存在: ${req.method} ${req.path}`。

#### 7.1.6 src/utils/response.ts（61 行）—— 统一响应

7 个函数及默认消息（逐字）：`success`（'操作成功', code 默认 200，且 `res.status(code)` 复用 code）、`created`（'创建成功', 201）、`error`（'操作失败', 400，errors 可选展开）、`unauthorized`（'未认证，请先登录', 401）、`forbidden`（'没有权限访问此资源', 403）、`notFound`（'资源未找到', 404）、`serverError`（'服务器内部错误', 500）。注意 HTTP 状态码与 body.code 始终相等。

#### 7.1.7 src/types/index.ts（223 行）—— 全局类型

- 通用：`ApiResponse<T> = { code, message, data?, errors? }`；`PaginatedResponse<T> = { items, total, page, pageSize }`（⚠️ 与路由实际返回的 `{items, pagination:{...}}` 不一致，路由未使用该类型）。
- 认证：`JwtPayload = { userId: string, phone: string }`；`AuthRequest extends Request { user?: JwtPayload }`。
- 实体：User（snake_case 字段同 DB）、Recipient（17 字段）、Flower、BouquetTemplate + FlowerComposition、Order + `OrderStatus = 'pending'|'paid'|'preparing'|'delivering'|'completed'|'cancelled'`、Recommendation、UserFeedback，及各 Create/Update Input。
- ⚠️ 此文件中 `AiRecommendationResponse/AiPlan/AiPlanFlower`（flower_name/quantity/reason 等）与 services/qwen/types.ts 的 BouquetPlan 结构**不同且未被路由使用**，属遗留设计；复现时照抄即可，实际生效的是 BouquetPlan。

#### 7.1.8 src/models/（6 文件，合计 146 行）—— 实体接口（未被引用的冗余层）

| 文件 | 内容 |
|---|---|
| User.ts（24行） | User 接口（id/phone/password_hash/nickname/avatar/created_at/updated_at） |
| Recipient.ts（38行） | Recipient 接口（同 types/index.ts 同名接口） |
| Flower.ts（22行） | Flower 接口 |
| Order.ts（27行） | Order + OrderStatus |
| Recommendation.ts（18行） | Recommendation 接口 |
| BouquetTemplate.ts（17行） | BouquetTemplate 接口 |

⚠️ 这些文件与 types/index.ts 内容重叠，路由实际 import 的是 `../types`；复现时可照建以保持目录结构一致，不影响运行。

#### 7.1.9 src/routes/index.ts（27 行）—— 路由总线

见 5.1.1 逐字挂载代码。/health 返回 `{ status:'ok', timestamp: new Date().toISOString(), service:'flower-backend' }`，message `服务运行正常`。

#### 7.1.10 src/routes/auth.ts（188 行）—— 认证路由

4 端点完整契约见 5.3.2–5.3.5。实现要点：注册/登录均挂 authLimiter；JWT 签发两处重复同样代码；登录时先查含 password_hash 的行再 `bcrypt.compare`，返回前解构剔除；PUT /profile 用 updates/values/paramIndex 三变量动态拼 SET（该模式在 recipients PUT 中重复）。边界：nickname 可设为空字符串（仅限长不限空）；注册时 nickname 未限长（DB 层 VARCHAR(50) 兼容）。

#### 7.1.11 src/routes/flowers.ts（114 行）—— 花材路由

3 端点见 5.3.6–5.3.8。实现要点：/categories 必须先于 /:id 定义；列表查询用 conditions 数组 + paramIndex 递增拼 WHERE；COUNT 与数据查询共用 values（数据查询追加 LIMIT/OFFSET 两参）。无鉴权、无限流（除全局）。

#### 7.1.12 src/routes/recipients.ts（221 行）—— 收花人路由

5 端点见 5.3.9–5.3.13。实现要点：整组 `router.use(authMiddleware)`；PUT 用 `fields: Record<string, any>` 对象 + `Object.entries` 过滤 undefined 构建动态更新（name/gender/age/relationship 四字段有显式三目处理，其余 9 字段直接透传）；DELETE 物理删除（非软删）。

#### 7.1.13 src/routes/recommendations.ts（353 行）—— 推荐路由

4 端点见 5.3.14–5.3.17。实现要点：/generate 的双模式入参组装（DB 档案 vs 临时档案）与请求体覆盖合并逻辑（四个 `if (xxx && recipientId)` spread 合并块）；ai_response/input_context 以 `JSON.stringify` 存 JSONB；RecommendationError 单独捕获转 500，其他异常重抛给外层 catch。边界：模式 B 每次调用都新建一条 recipients 记录（无去重，可能产生大量匿名档案）。

#### 7.1.14 src/routes/orders.ts（254 行）—— 订单路由

5 端点见 5.3.18–5.3.22。实现要点：statusFlow 定义在路由处理器内部（非模块级常量）；创建订单时 recommendation_id 校验与 selected_plan_index 回写是两步非事务操作；列表查询表别名 `o`。边界：total_price 与推荐方案价格无交叉校验（客户端传什么存什么）；delivery_time 未做格式校验（非法日期由 PG 报错落入 500）。

### 7.1.15 backend/src/services/qwen/index.ts（30 行）

- **职责**：qwen 服务模块统一导出入口（barrel file）。
- **实现要点**：
  - 类型导出（`export type`）：RecipientInfo、RelationshipContext、CulturalFactors、RecipientProfile、Preferences、BudgetRange、RecommendationInput、FlowerItem、WrappingInfo、BouquetPlan、ChatMessage、QwenChatRequest、QwenResponse、QwenStreamResponse、QwenErrorResponse、CacheEntry（全部来自 `./types`）。
  - 值导出：`QwenClient, QwenApiError, qwenClient`（qwenClient.ts）、`buildMessages, getSceneEnhancement, getSystemPrompt`（prompts.ts）、`CacheService, cacheService`（cacheService.ts）、`RecommendationService, RecommendationError, recommendationService`（recommendationService.ts）；另有 `export type { StreamCallback }`。
- **边界条件**：routes/recommendations.ts 实际直接从 `../services/qwen` 导入 `recommendationService` 与 `RecommendationError`。

### 7.1.16 backend/src/services/qwen/types.ts（166 行）

- **职责**：AI 推荐链路全部类型定义（输入结构、方案结构、千问协议、缓存条目）。
- **关键接口字段**（复现时字段名必须逐字一致，它们同时构成 API 请求体 shape 与 Prompt 模板取值路径）：

| 接口 | 字段 |
|---|---|
| `RecipientInfo` | `name: string`、`gender?: string`、`age?: number` |
| `RelationshipContext` | `relationship: string`、`duration?: string`、`stage?: string` |
| `CulturalFactors` | `background?: string`、`taboos?: string[]`、`religion?: string` |
| `RecipientProfile` | `interests?: string[]`、`personality?: string[]`、`career?: string` |
| `Preferences` | `favoriteColors?: string[]`、`favoriteFlowers?: string[]`、`dislikedFlowers?: string[]`、`allergies?: string[]`、`style?: string` |
| `BudgetRange` | `min: number`、`max: number` |
| `RecommendationInput` | `recipientInfo: RecipientInfo`、`occasion: string`、`relationshipContext: RelationshipContext`、`culturalFactors?: CulturalFactors`、`recipientProfile?: RecipientProfile`、`preferences?: Preferences`、`budget: BudgetRange`、`additionalNotes?: string` |
| `FlowerItem` | `name: string`、`count: number`、`color: string`、`meaning: string` |
| `WrappingInfo` | `style: string`、`color: string`、`material: string` |
| `BouquetPlan` | `name`、`theme`、`flowers: FlowerItem[]`、`wrapping: WrappingInfo`、`flowerLanguage`、`reason`、`estimatedPrice: number`、`cardSuggestion`（除标注外均 string） |
| `ChatMessage` | `role: 'system' \| 'user' \| 'assistant'`、`content: string` |
| `QwenChatRequest` | `model: string`、`messages: ChatMessage[]`、`temperature?`、`max_tokens?`、`top_p?`、`stream?` |
| `QwenResponse` | OpenAI 兼容：`id`、`object`、`created`、`model`、`choices[{index, message, finish_reason}]`、`usage{prompt_tokens, completion_tokens, total_tokens}` |
| `QwenStreamResponse` | `choices[{index, delta{role?, content?}, finish_reason}]`（SSE 分片） |
| `QwenErrorResponse` | `error{message, type, code?}` |
| `CacheEntry` | `plans: BouquetPlan[]`、`cachedAt: number`、`inputHash: string` |

- **边界条件**：`RecommendationInput.budget` 为必填（min/max 都必填），但路由层允许 app 只传 `budget` 数字——路由在调用前将其转为 `{min: budget*0.8, max: budget*1.2}`（见 5.3.14）；types.ts 与 types/index.ts 中遗留的 `AiRecommendationResponse` 系列（AiPlan/AiPlanFlower）互不相干，后者未被任何运行代码引用。

### 7.1.17 backend/src/services/qwen/prompts.ts（212 行）

- **职责**：Prompt 工程——系统提示词、用户提示词模板、场景增强文案。
- **实现要点**：导出 `getSystemPrompt()`（返回 SYSTEM_PROMPT 常量）、`buildUserPrompt(input)`（9 段模板拼接）、`buildMessages(input)`（返回 `[{role:'system',...},{role:'user',...}]` 二元数组）、`getSceneEnhancement(occasion, relationship?)`（场景/关系增强文案查表）。
- **关键代码片段**：SYSTEM_PROMPT 54 行原文、buildUserPrompt 模板结构、SCENE_ENHANCEMENTS 8 场景文案、3 条特殊关系正则及文案已全部逐字收录于 **6.2**，复现时直接照抄，此处不重复。
- **边界条件**：`getSceneEnhancement` 先匹配特殊关系正则（顺序：暗恋→道歉→长辈），命中即返回关系文案（优先于场景文案）；场景 key 匹配用 `occasion.includes(key)` 子串包含而非全等；均未命中返回空串。

### 7.1.18 backend/src/services/qwen/qwenClient.ts（334 行）

- **职责**：通义千问 OpenAI 兼容 API 的 HTTP 客户端（原生 https/http 模块实现，零 SDK 依赖）。
- **实现要点**：
  - `QwenClient` 类构造时读环境变量：`QWEN_API_KEY`（无则 console.warn 警告但不抛错）、`QWEN_API_URL`（默认 `https://dashscope.aliyuncs.com/compatible-mode/v1`）、`QWEN_MODEL`（默认 `qwen-plus`）。
  - `chat(messages, options?)`：构造 QwenChatRequest（temperature/max_tokens/top_p 取自 options 或 6.3 的默认值），调 `makeRequest('/chat/completions', body)`，返回 `response.choices[0].message.content`；choices 为空抛 QwenApiError。
  - `makeRequest`：用 `new URL()` 解析 baseUrl+path，按协议选 https/http 模块，`request()` 手工拼装（method POST、headers 含 `Authorization: Bearer ${apiKey}`、`Content-Type: application/json`），聚合 data 事件拼 body，超时 60000ms（`req.setTimeout`）触发 `req.destroy()` 并抛超时错。状态码非 2xx 时解析 QwenErrorResponse 抛 QwenApiError（含 statusCode 与 API 错误信息）。
  - 重试逻辑与 8 条错误分类映射表见 **6.3**（逐字收录），复现时照抄。
  - `chatStream(messages, callback, options?)`：SSE 流式实现——请求体 `stream: true`，按行解析 `data: ` 前缀分片，`[DONE]` 结束，每片取 `choices[0].delta.content` 回调 `StreamCallback(content, done)`。**业务代码未调用此方法**（推荐链路走非流式 chat），属预留能力，复现时可后置。
  - `QwenApiError extends Error`：字段 `statusCode?: number`、`errorType?: string`、`retryable: boolean`。
  - 文件尾导出单例 `export const qwenClient = new QwenClient()`。
- **边界条件**：API Key 缺失时构造不抛错，实际请求时才因 401 失败（映射为「AI 服务配置错误」）；响应 JSON 解析失败抛「响应解析失败」错误；超时归类为 retryable。

### 7.1.19 backend/src/services/qwen/recommendationService.ts（446 行）

- **职责**：AI 推荐核心编排——缓存查询→Prompt 构建→千问调用→四级降级解析→方案校验修正→缓存回写。
- **实现要点**：
  - `RecommendationService.generateRecommendations(input)` 七步链路、`RECOMMENDATION_CONFIG` 常量、四级解析（extractJson 正则）、`validateSinglePlan` 逐字段默认值表、价格修正算法全部逐字收录于 **6.1**，复现时照抄。
  - 私有方法 `injectEnhancement(messages, input)`：调 `getSceneEnhancement(input.occasion, input.relationshipContext.relationship)`，非空则把文案追加到 user 消息末尾（`\n\n` 分隔），返回新 messages 数组。
  - `RecommendationError extends Error`：字段 `code: string`（如 `'AI_SERVICE_ERROR'`、`'PARSE_ERROR'`）、`retryable: boolean`；路由层捕获后按 6.3 映射表转用户文案。
  - 文件尾导出单例 `export const recommendationService = new RecommendationService()`。
- **边界条件**：缓存命中直接返回（不再调 AI）；AI 返回方案数 >3 截断、<1 抛 PARSE_ERROR；缓存写失败仅 console.warn 不影响主流程；QwenApiError 会被包装为 RecommendationError 向上抛。

### 7.1.20 backend/src/services/qwen/cacheService.ts（237 行）

- **职责**：Redis 推荐结果缓存（可降级：Redis 不可用时全链路直连 AI）。
- **实现要点**：
  - 连接配置、键格式 `flower:rec:` + MD5、TTL 4h、顶层键排序哈希算法见 **6.4**（逐字收录）。
  - `get(input)`：hash→`redis.get`→JSON.parse 为 CacheEntry→返回 `entry.plans`；任何异常 console.warn 后返回 null。
  - `set(input, plans)`：组装 CacheEntry{plans, cachedAt: Date.now(), inputHash}，`setEx(key, TTL, JSON.stringify)`。
  - `delete(input)`：按 hash 删除单条。`clearAll()`：`redis.keys('flower:rec:*')` 扫描后批量 del（生产环境 keys 命令有阻塞风险，属已知妥协）。
  - `isAvailable()`：返回内部 connected 标志。`disconnect()`：优雅关闭连接。
  - 连接失败/错误事件均只置 connected=false + console.warn，**永不抛错**。
  - 文件尾导出单例 `export const cacheService = new CacheService()`。
- **边界条件**：JSON.parse 失败视为未命中；Redis 未连接时 get/set 直接短路返回（null/无操作）。

### 7.1.21 backend/src/scripts/init-db.ts（42 行）

- **职责**：数据库一键初始化脚本（`npm run init-db`）。
- **实现要点**：
  - 独立创建 `pg.Pool`（不复用 config/database.ts），`dotenv.config()` 后读 DB_HOST/DB_PORT/DB_NAME/DB_USER/DB_PASSWORD，默认值与 7.1.2 相同（localhost/5432/flower_assistant/postgres/空串）。
  - `runSQL(filePath)`：`fs.readFileSync(path, 'utf-8')` 整文件读入后 `pool.query(sql)` 单次执行（依赖 pg 对多语句 SQL 的支持）。
  - 执行顺序：`database/init.sql` → `database/seed.sql`（路径用 `path.join(__dirname, '../../database/…')` 解析）。
  - 失败 `console.error` + `process.exit(1)`；`finally` 中 `pool.end()`。
- **边界条件**：init.sql 含 `DROP TABLE IF EXISTS`，脚本可重复执行（幂等重建）；seed.sql 依赖 init.sql 先行，顺序不可颠倒。

### 7.1 小结

后端 26 个源码文件全部精讲完毕：入口 1（index.ts）+ 配置 1（database.ts）+ 中间件 3 + 工具 1（response.ts）+ 类型 1 + 模型 6 + 路由 6 + qwen 服务 6 + 脚本 1。其中 prompts/qwenClient/recommendationService/cacheService 的可逐字复现内容集中在第 6 章，第 7 章小节负责结构与边界补全，两章合用即可完整重写后端。

## 7.2 app 侧核心文件精讲（ArkTS，共 27 个 .ets 源文件全部精讲）

app 侧源码全部位于 `app/entry/src/main/ets/`，以下路径均省略此前缀。分层顺序：入口/主题/常量 → 模型 → 服务 → 状态 → 页面 → 组件。

### 7.2.1 entryability/EntryAbility.ets（45 行）

- **职责**：UIAbility 入口，Stage 模型标准模板。
- **实现要点**：`export class EntryAbility extends UIAbility`（具名导出，非 default）；`onWindowStageCreate` 中 `windowStage.loadContent('pages/Index', callback)`；其余 5 个生命周期回调（onCreate/onForeground/onBackground/onWindowStageDestroy/onDestroy）仅 `console.info('[EntryAbility] …')` 日志。
- **边界条件**：无权限申请、无窗口全屏/沉浸式设置；因为具名导出，module.json5 中 srcEntry 对应文件需与之匹配。

### 7.2.2 common/Theme.ets（63 行）

- **职责**：全局主题常量类 `AppTheme`（全 static readonly）。
- **关键常量（逐字，复现必须一致）**：

| 分类 | 常量 | 值 |
|---|---|---|
| 颜色 | PRIMARY_COLOR / PRIMARY_COLOR_ALPHA20 | `#FF69B4` / `#33FF69B4` |
| 颜色 | SECONDARY_COLOR / SECONDARY_COLOR_ALPHA20 | `#4CAF50` / `#334CAF50` |
| 颜色 | BACKGROUND_COLOR / CARD_BACKGROUND | `#FFF8F0` / `#FFFFFF` |
| 颜色 | TEXT_PRIMARY / TEXT_SECONDARY | `#333333` / `#666666` |
| 颜色 | ACCENT_COLOR / DIVIDER_COLOR / DISABLED_COLOR | `#FF4081` / `#EEEEEE` / `#CCCCCC` |
| 颜色 | ERROR_COLOR / SUCCESS_COLOR | `#FF5252` / `#4CAF50` |
| 圆角 | BORDER_RADIUS_SMALL/MEDIUM/LARGE/CIRCLE | 8 / 12 / 16 / 999 |
| 间距 | SPACING_SMALL/MEDIUM/LARGE/XLARGE | 8 / 16 / 24 / 32 |
| 字号 | FONT_SIZE_SMALL/NORMAL/MEDIUM/LARGE/XLARGE/TITLE | 12 / 14 / 16 / 20 / 24 / 28 |
| 阴影 | CARD_SHADOW_RADIUS / CARD_SHADOW_COLOR / CARD_SHADOW_OFFSETY | 8 / `#33000000` / 2 |

### 7.2.3 utils/Constants.ets（57 行）

- **职责**：全局业务常量（全部 `export const` 模块级常量，非类）。
- **逐字清单**：
  - `BASE_URL = 'http://localhost:3000/api'`（⚠ 后端实际监听 3001，端云错配见 5.5）
  - `DEFAULT_PAGE_SIZE = 20`、`DEFAULT_PAGE = 1`
  - `TOKEN_KEY = 'auth_token'`、`USER_INFO_KEY = 'user_info'`
  - `HTTP_TIMEOUT = 15000`、`BANNER_INTERVAL = 3000`
  - `SCENE_TYPES: string[] = ['birthday','confession','anniversary','apology','gratitude','visit']`
  - `SCENE_ICONS: Record<string,string>` → birthday:🎂 confession:💕 anniversary:🎁 apology:🙏 gratitude:🌻 visit:🏥
  - `SCENE_NAMES` → 生日/表白/纪念日/道歉/感谢/探望
  - `ORDER_STATUS_MAP` → pending:待确认、confirmed:已确认、delivering:配送中、completed:已完成、cancelled:已取消
- **边界条件**：`ORDER_STATUS_MAP` 含 `confirmed` 而后端状态机用 `paid/preparing`，且缺 `paid/preparing` 键——app 展示后端真实订单时这两态无中文映射（已知不一致，复现时保留或修正均可，默认保留）。

### 7.2.4 models/UserModel.ets（62 行）

- **职责**：用户/认证/收件人类型定义。
- **接口清单**：`UserInfo{id:number, username, nickname, avatarUrl, phone, email, createdAt, updatedAt}`、`LoginParams{phone, password}`、`RegisterParams{phone, password, nickname?}`、`LoginResponse{token, user:UserInfo}`、`RegisterResponse{token, user}`、`RecipientInfo{id:number, userId:number, name, gender:'male'|'female'|'other', ageRange:string, relationship, personality, preferences, createdAt, updatedAt}`、`CreateRecipientParams{name, gender, ageRange, relationship, personality?, preferences?}`。
- **边界条件**：⚠ 与后端实体字段不对齐——后端 User.id 为 UUID 字符串、无 username/email 字段（snake_case avatar）；后端 Recipient 用 `age:number` 而非 `ageRange:string`。app 实际运行时多用 mock 数据或宽松 JSON.parse，类型不匹配不报错（运行时无校验）。复现时照抄即可。

### 7.2.5 models/FlowerModel.ets（60 行）

- **职责**：花材类型定义。
- **枚举逐字**：`FlowerCategory`：rose/lily/tulip/carnation/sunflower/hydrangea/peony/chrysanthemum/orchid/other；`FlowerColor`：red/white/yellow/pink/purple/orange/blue/mixed。
- **接口**：`FlowerInfo{id:number, name, category, color, description, meaning, price:number, season, imageUrl, popularity:number(0-100), createdAt, updatedAt}`、`GetFlowersParams{category?, color?, keyword?, page?, pageSize?}`、`GetFlowersResponse{flowers:FlowerInfo[], total, page, pageSize}`。
- **边界条件**：后端字段为 `price_per_stem`(numeric 字符串)/`name_en`/`available`，无 popularity；ApiService.getFlowers 手工映射弥合差异（见 7.2.7）。

### 7.2.6 models/RecommendModel.ets（109 行）

- **职责**：推荐/订单/反馈类型定义（部分与后端对齐，部分本地自用）。
- **接口清单**：
  - `SceneType` 枚举：同 Constants.SCENE_TYPES 六值。
  - `GenerateRecommendationParams{recipientId?:number, scene:SceneType, budget?:number, stylePreference?:string, specialRequirements?:string}`（app 本地表单结构，非后端请求体）。
  - `BouquetScheme{id:number, name, description, flowers:FlowerItem[], totalPrice:number, style, meaning, imageUrl, matchScore:number(0-100)}`——ResultPage mock 方案与购物车项的核心结构。
  - `FlowerItem{flowerId:number, flowerName, quantity:number, unitPrice:number, color, meaning}`（⚠ 与后端 qwen FlowerItem{name,count,color,meaning} 同名不同型）。
  - `RecommendationResponse{schemes:BouquetScheme[], reason, sceneAnalysis}`（本地自用，后端实际返回 plans）。
  - **与后端对齐的部分（注释标注“与后端对齐”，snake_case）**：`OrderInfo{id:string, user_id, recommendation_id:string|null, status:6态联合, total_price:number, delivery_address, delivery_time:string|null, greeting_card_message:string|null, created_at, updated_at}`、`OrderListResponse{items:OrderInfo[], pagination{page,pageSize,total,totalPages}}`、`CreateOrderParams{recommendation_id?, selected_plan_index?, total_price, delivery_address, delivery_time?, greeting_card_message?}`、`UpdateOrderStatusParams{status}`。
  - `FeedbackInfo{id:number, userId, orderId, rating(1-5), content, images?:string[], createdAt}`、`SubmitFeedbackParams{orderId:number, rating, content, images?}`（⚠ 对应的 POST /feedbacks 后端不存在，见 5.5）。

### 7.2.7 services/HttpUtil.ets（172 行）

- **职责**：基于 `@ohos.net.http` 的 HTTP 封装 + Token 本地存储。
- **实现要点**：
  - 导出 `ApiResponse<T>{code, message, data}`、`HttpMethod` 枚举（GET/POST/PUT/DELETE）；私有 `RequestOptions{url, method, data?, headers?, needAuth?}`。
  - Token 存储：Preferences 实例名 `'flower_app_prefs'`，键 `TOKEN_KEY`；getToken 失败返空串；saveToken/clearToken 后都 `flush()`。⚠ 三处均写成 `preferences.getContext(context, 'flower_app_prefs')`——该 API 不存在（应为 `preferences.getPreferences`），为源码原样缺陷，运行时 Token 持久化失效但被 catch 吞掉不崩溃。**复现决策：细节还原则照抄；功能可用则改 getPreferences（参照 CartStore 正确写法）**。
  - `request<T>`：`http.createHttp()`；headers 基底 `Content-Type: application/json`；needAuth 且有 token 时加 `Authorization: Bearer ${token}`；`fullUrl = options.url.startsWith('http') ? options.url : BASE_URL + options.url`；`connectTimeout/readTimeout = HTTP_TIMEOUT`；body 为 `JSON.stringify(options.data)`。
  - 响应处理：responseCode 200/201 → JSON.parse 后再判业务码 `result.code === 0 || 200 || 201` 才返回，否则抛 `业务错误: ${message}`；401 → `clearToken()` 后抛 `'登录已过期，请重新登录'`；其他 → 抛 `HTTP错误: ${responseCode}`；`finally { httpRequest.destroy() }`。
  - `get<T>(url, params?, needAuth=false)`：手工拼 query（undefined/null 跳过，`encodeURIComponent(String(v))`）；`post(needAuth=false)`、`put(needAuth=true)`、`delete(needAuth=true)`。
- **边界条件**：非 200/201 的成功码（如 204）会被当错误；后端错误响应（4xx）的 message 不会被解析展示（直接抛 HTTP错误），401 除外。

### 7.2.8 services/ApiService.ets（173 行）

- **职责**：全部后端接口的静态方法封装（19 个方法，与 5.5 端云对应表一一对应）。
- **实现要点**：
  - 认证（4）：`login(params)` POST /auth/login、`register(params)` POST /auth/register——两者成功后若 `response.data.token` 存在则 `await HttpUtil.saveToken(token)`（Token 落库在 ApiService 层而非页面层）；`getProfile()` GET /auth/profile(needAuth)；`updateProfile({nickname?, avatar?})` PUT /auth/profile(needAuth)。
  - 花材（2）：`getFlowers(params?)` GET /flowers（不鉴权）——先手工组装 queryParams（category/color/keyword/page/pageSize，truthy 才加入）；**手工映射层**：后端返回 `{items, pagination}`，逐条转 FlowerInfo：`price: (item['price_per_stem'] as number) || 0`（as 强转，numeric 字符串实际仍是 string，靠运行时宽松性工作）、`category || 'other'`、`color || 'mixed'`、`season || '全年'`、`imageUrl: item['image_url'] || ''`、`popularity: 80`（写死）、createdAt/updatedAt 空串；返回 `{flowers, total: pagination.total||0, page: pagination.page||1, pageSize: pagination.pageSize||20}`（字面量 20 兜底，非常量引用）；`getFlowerDetail(id:number)` GET /flowers/:id。
  - 收件人（4）：`getRecipients()`、`createRecipient(params)`、`updateRecipient(id:number, params)`、`deleteRecipient(id:number)`（均 needAuth，对应 /recipients CRUD）。
  - 推荐（2）：`generateRecommendation(params:GenerateRecommendationParams)` POST /recommendations/generate(needAuth)；`getRecommendationHistory(page=1, pageSize=10)` GET /recommendations/history ⚠端点不存在（后端是 GET /recommendations 列表，见 5.5）。
  - 订单（5）：`createOrder(params)` POST /orders；`getOrders(page=1, pageSize=10, status?)` GET /orders（status 有值才入参）；`getOrderDetail(id:string)` GET /orders/:id；`updateOrderStatus(id, status:string)` PUT /orders/:id/status（body `{status}`）；`cancelOrder(id)` PUT /orders/:id/cancel（body undefined）（全 needAuth）。
  - 反馈（2）：`submitFeedback(params)` POST /feedbacks、`getFeedbackHistory(page=1, pageSize=10)` GET /feedbacks ⚠两端点后端均不存在（后端是 POST /recommendations/:id/feedback）。
- **边界条件**：无 healthCheck 封装（GET /health 未被 app 调用）；除 getFlowers 外其余方法直接透传 `response.data`，无字段映射；泛型参数多为 app 侧模型，与后端实际 shape 的偏差（如 RecommendationResponse.schemes vs 后端 plans）靠运行时宽松性掩盖。

### 7.2.9 store/CartStore.ets（162 行）

- **职责**：购物车双层状态（AppStorage 内存态 + Preferences 持久态），全静态方法类。
- **实现要点**：
  - `CartItem{scheme: BouquetScheme, quantity: number}`；常量 `CART_STORAGE_KEY='cart_items'`、`PREFERENCES_NAME='cart_prefs'`。
  - AppStorage 三键：`cartItems: CartItem[]`、`cartTotalPrice: number`、`cartItemCount: number`；`initAppStorage()` 用 `AppStorage.has` 判重后 `setOrCreate` 默认值（[]/0/0）。
  - `setCartItems(items)` 为唯一写入口：同步 `updateSummary`（遍历累加 `scheme.totalPrice * quantity` 与 quantity）+ 异步 `persistToDisk`。
  - 业务方法：`addItem(scheme, quantity=1)` 按 `scheme.id` 查重，存在则累加数量（展开运算符不可变更新）；`updateQuantity(index, q)` 要求 `q>=1` 且 index 合法；`increaseQuantity` 上限 `<99`；`decreaseQuantity` 下限 `>1`；`removeItem` 用 filter；`clearCart()` 置空数组；`getItemCount/getTotalPrice/isEmpty` 读 AppStorage。
  - 持久化：`loadFromDisk()` 用 `preferences.getPreferences(context,'cart_prefs')`（正确 API，对比 HttpUtil 的错误写法）读 JSON 后**直接写 AppStorage 不再回写磁盘**（避免循环）；`persistToDisk` put + flush；两者异常均仅 console.error。
- **边界条件**：数量区间 [1,99]；JSON.parse 失败时购物车保持初始空态；`getContext(this)` 在 static 方法中调用（ArkTS 允许，取当前 UIAbility 上下文）。

### 7.2.10 pages/Index.ets（108 行）

- **职责**：`@Entry` 主入口，底部 4-Tab 容器。
- **实现要点**：
  - `@StorageLink('currentTab') currentIndex = 0`（其它页面可写 AppStorage 实现跨页切 Tab）、`@StorageLink('cartItemCount') cartCount = 0`。
  - `aboutToAppear`：`CartStore.initAppStorage()` + `CartStore.loadFromDisk()`。
  - `Tabs({barPosition: BarPosition.End, index: this.currentIndex})` 包 4 个 TabContent：HomePage/RecommendPage/FlowerLibrary/MinePage；`.scrollable(true)`、`.barHeight(56)`、onChange 回写 currentIndex。
  - `TabBuilder(index, title, iconResource)`：Stack 内文字 emoji 图标（`['🏠','💡','🌺','👤']`，非图片资源）+ 购物车角标（cartCount>0 显示，`>=100` 显 '99+'，红底白字 borderRadius 10，position {x:'60%', y:-6}）；选中态 PRIMARY_COLOR + Bold。
  - tabBar 第三参引用 `$r('app.string.tab_home')` 等 4 个字符串资源（仅传入未实际渲染，标题用硬编码中文）。
- **边界条件**：角标挂在每个 Tab 图标上（四个 Tab 都显示同一角标，非仅购物车 Tab——实际没有独立购物车 Tab，CartPage 由 router 进入）。

### 7.2.11 pages/HomePage.ets（261 行）

- **职责**：首页 Tab —— 搜索栏 + Banner 轮播 + 场景入口 + 热门花材网格。
- **状态**：`searchKeyword`、`bannerIndex`（声明未用）、`hotFlowers: FlowerInfo[]`、`isLoading`。
- **实现要点**：
  - `@Entry @Component export struct HomePage`（既是入口又被 Index 嵌入，导出 struct）。
  - Banner：`bannerData` 4 条硬编码文案（`'🌸 春日樱花季 - 浪漫之选'`、`'🌹 经典红玫瑰 - 永恒的爱'`、`'🌻 向日葵季 - 阳光祝福'`、`'🌷 郁金香季 - 优雅之选'`）；Swiper 高 160、autoPlay、interval=BANNER_INTERVAL(3000)、indicator、loop，粉色底白字。
  - 搜索：🔍 点击后若 keyword 非空 → `AppStorage.setOrCreate('searchKeyword', kw)` + `setOrCreate('currentTab', 2)`（跳花材库 Tab 带关键词）。
  - 场景入口：SceneSelector 组件回调 → `AppStorage.setOrCreate('selectedScene', scene)` + `currentTab=1`（跳推荐 Tab 预选场景）。
  - 数据：`loadHotFlowers()` 调 `ApiService.getFlowers({page:1, pageSize:10})`，**catch 后用 `getMockFlowers()` 兜底**——6 条 mock：红玫瑰¥8/粉色康乃馨¥5/白百合¥12/向日葵¥6/紫色绣球¥15/粉色郁金香¥10（popularity 95/88/82/78/75/70，id 1-6）。
  - 热门列表：Grid 双列 `'1fr 1fr'`，FlowerCard 点击回调 `onFlowerClick`：把单支花材包装成单品 BouquetScheme（id=flower.id、flowers=[{flowerId,flowerName,quantity:1,unitPrice:price,color,meaning}]、totalPrice=price、style='简约'、matchScore=popularity）后 `CartStore.addItem`，Toast `「${name} 已加入购物车」` 1500ms。
- **边界条件**：搜索仅写 AppStorage，花材库 Tab 需自行监听 'searchKeyword'；网络失败静默降级 mock 无提示。

### 7.2.12 pages/LoginPage.ets（405 行）

- **职责**：登录/注册双 Tab 表单页（router 进入）。
- **状态**：`currentTab`(0登录/1注册)、`isLoading`、登录表单 `loginPhone/loginPassword`、注册表单 `registerPhone/registerCode/registerPassword/registerConfirmPassword`、`codeCountDown`；私有 `timerId=-1`。
- **实现要点**：
  - `doLogin()`：两字段非空才执行；`ApiService.login` 成功后额外 `AppStorage.setOrCreate('auth_token', token)`（与 HttpUtil.saveToken 双写），`router.back()`；失败仅 console.error 无 UI 提示。
  - `doRegister()`：四字段非空 + 两次密码一致才执行；nickname 写死 `'花语用户'`；成功后同登录。
  - `sendVerifyCode()`：**纯模拟**（console.info），`codeCountDown=60` 后 setInterval 每秒递减，到 0 清除；`aboutToDisappear` 清理定时器；验证码未参与后端校验（后端 register 无 code 参数）。
  - UI：顶部 '←' 返回；Logo 区 🌸 + 「花语」+ Slogan「让每一束花都有故事」；Tab 切换样式（选中 PRIMARY_COLOR_ALPHA20 底 + 上圆角）；表单用 @Builder LoginFormBuilder/RegisterFormBuilder；提交按钮用 CommonButton（disabled 联动字段空值与 isLoading，文案切「登录中...」）；底部《用户协议》《隐私政策》仅 console.info。
  - 输入框 type：PhoneNumber/Password/Number（验证码）；验证码按钮 `enabled(codeCountDown<=0 && registerPhone.length>0)`，倒计时态灰底显 `${n}s`。
- **边界条件**：手机号/密码格式前端零校验（后端正则兜底）；登录失败用户无感知（无 Toast）。

### 7.2.13 pages/MinePage.ets（410 行）

- **职责**：「我的」Tab —— 登录态/未登录态双分支 + 统计 + 菜单 + 登出。
- **状态**：`userInfo: UserInfo|null`、`isLoggedIn`、统计三数 `flowerCount/recipientCount/favoriteCount`。
- **实现要点**：
  - 菜单表（逐字）：📦我的订单→pages/OrderListPage、⭐收藏的方案→pages/ResultPage、📅送花日历提醒→pages/RecommendPage、👥收花人档案→pages/RecipientProfile、🔔消息通知→pages/OrderListPage、⚙️设置→pages/MinePage（后三项为占位路由）。
  - `checkLoginStatus()`：`HttpUtil.getToken()` 长度>0 即登录态，再 `loadUserInfo()`。
  - `loadUserInfo()`：`ApiService.getProfile() as Record<string,Object>` 后**手工 snake_case→camelCase 映射**：username 取 phone、nickname 兜底 `'花语爱好者'`、avatar→avatarUrl、email 空串、created_at/updated_at；统计：recipientCount=getRecipients().length、flowerCount=getOrders(1,100).total、favoriteCount=0（写死），子请求各自 catch 置 0；外层 catch 则登出态 + clearToken。
  - `maskPhone(phone)`：`length>=7` 时 `substring(0,3)+'****'+substring(7)`。
  - `editProfile()`：promptAction.showDialog（标题「修改昵称」，按钮取消#999999/确认PRIMARY），确认后用**当前昵称原值**调 `updateProfile({nickname})`（无输入框，实际不改值——已知简化），Toast 修改成功/失败。
  - `logout()`：clearToken + 全部状态复位（无二次确认弹窗）。
  - 登录态 UI：头像（有 avatarUrl 用 Image 圆形，否则 Circle 内昵称首字）+ 昵称 + maskPhone + 「编辑资料」描边胶囊钮；统计行三格（送花次数/收花人数/收藏方案，竖 Divider 分隔）；菜单列表（行高 56，尾部 '›'，非末项 Divider 左缩 52）；「退出登录」红色描边透明钮。
  - 未登录态 UI：👤 占位头像 + 「未登录」+「登录后享受更多服务」+「登录 / 注册」实心钮（跳 pages/LoginPage）+ 灰色不可点菜单。
- **边界条件**：aboutToAppear 只执行一次，从 LoginPage 返回后不自动刷新登录态（需切 Tab 重建触发，已知体验缺陷）。

### 7.2.14 pages/CartPage.ets（270 行）

- **职责**：购物车页（router 进入）——列表/空态/数量调整/左滑删除/去结算。
- **实现要点**：
  - `@StorageLink('cartItems') cartItems: CartItem[]`——与 CartStore 同源双向同步；aboutToAppear 重复 `initAppStorage+loadFromDisk`（防直进本页）。
  - 增减删全部委托 CartStore 对应方法（见 7.2.9 边界 [1,99]）。
  - `goToCheckout()`：`router.pushUrl({url:'pages/OrderConfirmPage', params:{cartData: JSON.stringify(this.cartItems)}})`——**购物车快照以 JSON 字符串随路由参数传递**。
  - UI：标题栏 '<' 返回 + 「购物车」+ 条目数；空态 🛒 + 「购物车空空如也」+「去选花」钮（router.back）；列表 List 项 `swipeAction({end: DeleteButton})` 实现左滑删除（宽 80 红底）；卡片：💐 图标 70×70 + 方案名 + 花材名顿号拼接（`flowers.map(f=>f.flowerName).join('、')`）+ 价格 + ±数量控件（减号在 quantity<=1 时灰色）；底部结算栏：合计 `¥${CartStore.getTotalPrice()}` + 「去结算(n)」钮，上阴影 `#1A000000` offsetY -2。
- **边界条件**：ListItem key 用 `scheme.id`，同方案不同数量合并为一项；删除无二次确认。

### 7.2.15 pages/FlowerLibrary.ets — 花材图鉴页（535 行）
- **路径**：`app/entry/src/main/ets/pages/FlowerLibrary.ets`
- **职责**：花材图鉴：搜索 + 三维筛选（颜色/类别/季节）+ 双列 Grid 瀑布展示 + 详情底部弹窗；接口失败时回落 12 条内置 mock。
- **文件级筛选常量（逐字收录）**：
  - `COLOR_FILTERS`（7 项）：`全部:''`、`红色:FlowerColor.RED`、`粉色:PINK`、`白色:WHITE`、`黄色:YELLOW`、`紫色:PURPLE`、`蓝色:BLUE`
  - `CATEGORY_FILTERS`（6 项）：`全部:''`、`玫瑰:ROSE`、`百合:LILY`、`康乃馨:CARNATION`、`向日葵:SUNFLOWER`、`其他:OTHER`
  - `SEASON_FILTERS`（6 项）：`全部:''`、`春季:'春季'`、`夏季:'夏季'`、`秋季:'秋季'`、`冬季:'冬季'`、`四季:'全年'`（注意 label 为「四季」但 value 为 `'全年'`）
- **@CustomDialog FlowerDetailDialog**（同文件内定义）：
  - `englishNameMap`（15 条，逐字）：红玫瑰:Red Rose、粉玫瑰:Pink Rose、白玫瑰:White Rose、黄玫瑰:Yellow Rose、白百合:White Lily、粉色康乃馨:Pink Carnation、向日葵:Sunflower、紫色绣球:Purple Hydrangea、粉色郁金香:Pink Tulip、牡丹:Peony、兰花:Orchid、菊花:Chrysanthemum、红康乃馨:Red Carnation、蓝色绣球:Blue Hydrangea、白郁金香:White Tulip；未命中回落中文名。
  - `careAdviceMap`（按 FlowerCategory 键，7 条逐字）：
    - ROSE：`斜切花枝，每日换水，避免阳光直射，可加入保鲜剂延长花期`
    - LILY：`去除下部叶片，深水养护，避免与水果同放，花粉勿沾染衣物`
    - CARNATION：`浅水养护，避免向花头喷水，远离暖气和空调出风口`
    - SUNFLOWER：`深水养护，每天换水剪根，适合通风阴凉处摆放`
    - HYDRANGEA：`深水浸泡，整枝倒置入水恢复活力，避免强光照射`
    - TULIP：`少量清水，包住花头整形，避免与水仙同瓶`
    - OTHER：`清水养护，定期换水剪根，摆放于阴凉通风处`
  - `sceneMap`（7 条逐字）：ROSE:['表白','纪念日','求婚','婚礼']、LILY:['婚礼','探望','慰问','乔迁']、CARNATION:['母亲节','感恩','探望','教师节']、SUNFLOWER:['生日','祝贺','毕业','开业']、HYDRANGEA:['婚礼','表白','纪念日','装饰']、TULIP:['表白','春季祝福','乔迁','装饰']、OTHER:['日常','祝福','装饰','慰问']；未命中类别一律回落 OTHER。
  - 弹窗 UI：Scroll 容器高 `'85%'`、底部对齐、顶部左右圆角 `BORDER_RADIUS_LARGE`；内容自上而下：✕ 关闭（右对齐）→ 大图（高 220、Cover、灰底）→ 中文名+英文名 → Divider → `🌸 花语详解`(meaning) → `🎯 适合场景`(scenes 用「、」join) → `💰 当前价格`（`¥${price}/支`，ACCENT 色加粗）→ `📅 可用季节`（season || '全年'）→ `🌿 养护建议` → 收藏按钮（文案 `已收藏 ♥`/`加入收藏`，选中态 SECONDARY 色，仅切换本地 `isFavorited`，**不调任何接口、不持久化**）。
- **主 struct 状态**：`flowerList/searchKeyword/selectedColor/selectedCategory/selectedSeason/isLoading/currentPage(1)/hasMore(true)/currentFlower/filterType`（filterType：0=颜色 1=类别 2=季节，三组筛选条通过 Tab 式切换互斥展示）。
- **loadFlowers(reset: boolean) 关键逻辑**：
  1. 组参：`{ keyword, color: selectedColor, category: selectedCategory, page: currentPage, pageSize: 12 }`（**pageSize 固定 12**）；
  2. 调 `ApiService.getFlowers`；reset 时替换列表并 `currentPage=1`，否则追加；
  3. `hasMore = 返回条数 >= 12`；
  4. **catch 兜底**：reset 时用 12 条 mock 全量替换；追加时取 mock 前 4 条、改写 id 避免 key 冲突后追加，并置 `hasMore=false`。
- **12 条 mock 花材（name/价格/popularity/season）**：红玫瑰 ¥8/95/全年、粉玫瑰 ¥8/90/全年、白玫瑰 ¥10/85/全年、粉色康乃馨 ¥5/88/全年、白百合 ¥12/82/全年、向日葵 ¥6/78/夏季、紫色绣球 ¥15/75/夏季、粉色郁金香 ¥10/70/春季、黄玫瑰 ¥8/65/全年、蓝色绣球 ¥18/72/夏季、红康乃馨 ¥5/68/全年、白郁金香 ¥12/60/春季；花语示例：红玫瑰=`热烈的爱、我爱你`、粉玫瑰=`初恋、感动`、白百合=`纯洁、高贵、百年好合`、向日葵=`阳光、希望、崇拜`。
- **交互**：搜索框 onSubmit 与 🔍 点击均 `loadFlowers(true)`；筛选标签点击后立即 reset 加载；Grid 双列，`onReachEnd` 且 `hasMore && !isLoading` 时 `currentPage++` 追加加载；点卡片**重建** `CustomDialogController({ builder: FlowerDetailDialog({ flower }), autoCancel: true, alignment: DialogAlignment.Bottom, customStyle: true })` 后 `open()`；空态显示 🔍 + `未找到匹配的花材`；列表底部 `上拉加载更多...` / `— 已经到底了 —`。
- **边界条件/已知缺陷**：① `selectedSeason` 选中后仅存状态，`loadFlowers` **未将 season 传入请求参数**（季节筛选实际无效，仅 UI 高亮）；② 未消费 HomePage 写入 AppStorage 的 `'searchKeyword'`（首页搜索跳转后关键词不带入）；③ 收藏为纯本地假状态。复现时按原样保留这三处行为。

### 7.2.16 pages/RecommendPage.ets — AI 推荐五步表单页（767 行）
- **路径**：`app/entry/src/main/ets/pages/RecommendPage.ets`
- **职责**：五步向导收集送花信息 → 组装 `GenerateRecommendationParams` → 调 `generateRecommendation` → 携结果跳 ResultPage。
- **选项常量（全部逐字收录，复现必须一致）**：
  - `RELATIONSHIP_OPTIONS`：['伴侣','暗恋对象','朋友','长辈','同事','其他']
  - `DURATION_OPTIONS`：['刚认识','1周内','1-3个月','3-6个月','半年-1年','1-3年','3年以上']
  - `FLOWER_EXP_OPTIONS`：['没送过','送过1-2次','经常送']
  - `INTERACTION_OPTIONS`：['甜蜜','平淡','刚和好','热恋期','老夫老妻']
  - `HOBBY_OPTIONS`：['文艺','运动','美食','旅行','游戏','音乐','阅读','追剧']
  - `PERSONALITY_OPTIONS`：['温柔','活泼','内向','理性','感性','独立','浪漫']
  - `PROFESSION_OPTIONS`：['学生','IT','金融','教育','医疗','艺术','自由职业','其他']
  - `STYLE_OPTIONS`：['简约','华丽','可爱','优雅','自然']
  - `QUICK_TAGS`：['第一次送花','想要惊喜','需要浪漫','预算有限','想要大气','低调内涵']（点击追加进场景描述 TextArea）
  - `COLOR_OPTIONS`（name/value）：红 #E74C3C、粉 #FF69B4、白 #FFFFFF、紫 #9B59B6、黄 #F1C40F、蓝 #3498DB、混搭 #E0E0E0
  - `stepTitles`：['送花对象','场景选择','关系背景','对方画像','预算配送']
- **状态分组**：步骤控制 `currentStep(0)/isLoading`；Step1 `recipientList/selectedRecipientId(-1)/showNewRecipient/newRecipientName/newRecipientGender('female')/newRecipientAge/newRecipientRelationship('伴侣')`；Step2 `selectedScene(SceneType.BIRTHDAY)/sceneDescription`；Step3 `relationshipDuration/sentFlowersBefore/recentEvents/interactionModes[]`；Step4 `hobbies[]/personality[]/profession/cultureNote`；Step5 `budget(200)/preferredColors[]/stylePreference/needDelivery(false)/deliveryAddress/deliveryDate`。
- **aboutToAppear**：`loadRecipients()`（失败置空数组）；读 AppStorage `'selectedScene'`，非空则设为当前场景、清空该键（`setOrCreate('selectedScene','')`）并直接 `currentStep=1`（跳过 Step1 进入场景步）。
- **五步表单结构**：
  - Step1：已有收件人档案 List 单选 + 「新建对象」表单（姓名 TextInput / 性别 Radio male|female / 年龄 TextInput / 关系 Select 用 RELATIONSHIP_OPTIONS）；
  - Step2：`SceneSelector` 组件选场景 + 场景描述 TextArea + QUICK_TAGS 快捷追加；
  - Step3：认识时长 Select(DURATION) + 送花经验单选(FLOWER_EXP) + 最近发生的事 TextArea + 相处模式多选(INTERACTION)；
  - Step4：兴趣多选(HOBBY) + 性格多选(PERSONALITY) + 职业 Select(PROFESSION) + 文化禁忌备注 TextArea；
  - Step5：预算 `Slider(min:50, max:2000, step:50, value:200)` + 颜色圆点多选(COLOR_OPTIONS) + 风格单选(STYLE) + 配送 Toggle，开启后条件显示地址 TextInput 与 DatePicker（范围 2024-01-01 ~ 2027-12-31，选中格式化为 `${year}-${month+1}-${day}`，月份+1）。
- **buildRecommendParams()**：先组 `extraInfo: Record<string,string>`，13 个键全部**有值才写入**：`sceneDescription / relationshipDuration / sentFlowersBefore / recentEvents / interactionModes(逗号 join) / hobbies(join) / personality(join) / profession / cultureNote / preferredColors(join) / needDelivery:'true'(仅开启时) / deliveryAddress / deliveryDate`；返回 `{ recipientId: selectedRecipientId>0 ? id : undefined, scene, budget, stylePreference || undefined, specialRequirements: JSON.stringify(extraInfo) }`——**extraInfo 整体序列化塞进 specialRequirements 字符串**，与后端 prompt 组装约定对应（见 6.2）。
- **submitRecommendation() 流程**：① 若 `showNewRecipient && selectedRecipientId<=0 && newRecipientName` 非空 → 先 `createRecipient({name, gender, ageRange: newRecipientAge, relationship, personality: personality.join(','), preferences: hobbies.join(',')})` 并回填 id；② `generateRecommendation(params)`；③ 成功 `router.pushUrl('pages/ResultPage')`，params 为 `{ schemesData: JSON.stringify(response.schemes), reason, sceneAnalysis, requestParams: JSON.stringify(params) }`；④ **catch 仅 console.error，无用户可见错误提示**。
- **辅助**：`toggleInArray` 手工 for 循环复制数组再增删（规避 ArkTS 展开限制）；`TagGroup` @Builder 通用多选标签组（选中态白字 PRIMARY 底、圆角 CIRCLE、内边距 14/6）；底部按钮：`上一步`(OUTLINE, 45%，step>0 显示) + `下一步`/最后一步文案 `生成专属花束方案`(PRIMARY)。
- **边界条件**：未做任何必填校验，全部可空提交；`recipientId` 仅在选中已有档案（>0）时传；新建收件人失败会直接走 catch 中断整个提交。

### 7.2.17 pages/ResultPage.ets — 推荐结果页（460 行）
- **路径**：`app/entry/src/main/ets/pages/ResultPage.ets`
- **职责**：Swiper 横滑展示推荐方案卡片；支持换一批（用原参数重新推荐）、加入购物车、直接下单、复制贺卡文案。
- **入参解析（aboutToAppear）**：`router.getParams()` 取 `schemesData`（JSON.parse 为 `BouquetScheme[]`，解析失败或缺参→mock）、`reason`、`sceneAnalysis`、`requestParams`（存 `requestParamsJson` 供换一批）。无参数时直接用 mock。
- **3 条 mock 方案（逐字要点）**：
  1. `初恋悸动`：粉玫瑰×9(¥8)+白百合×3(¥12)+满天星×5(¥3)=**¥108**，风格`简约`，matchScore 95，花语解读：`初恋的悸动，如同这束粉白交织的花朵，纯真而心动。九朵粉玫瑰代表长久的期待，白百合守护着这份纯洁的心意。`
  2. `浪漫满屋`：红玫瑰×11(¥8)+粉色绣球×2(¥15)+尤加利叶×3(¥5)=**¥133**，风格`华丽`，matchScore 88；
  3. `温柔告白`：紫玫瑰×9(¥10)+白色桔梗×5(¥6)+银叶菊×3(¥4)=**¥127**，风格`优雅`，matchScore 82。
- **贺卡文案映射 getGreetingText（逐字）**：`初恋悸动`→`遇见你的那一刻，世界突然有了颜色。愿这束花替我说出那句——我喜欢你。`；`浪漫满屋`→`每一朵玫瑰都是我对你的思念，愿我们的故事如这束花，越来越美。`；`温柔告白`→`用最温柔的方式告诉你，你是我心中最珍贵的存在。`；未命中回落模板 `送你一束${scheme.name}，愿每一朵花都带给你幸福与喜悦。`
- **风格标签色 getStyleColor（逐字）**：简约 #4CAF50、华丽 #FF69B4、可爱 #FFB6C1、优雅 #9B59B6、自然 #8BC34A，未命中用 PRIMARY_COLOR。
- **核心方法**：
  - `refreshSchemes()`：requestParamsJson 为空直接 return；否则 JSON.parse 后重调 `generateRecommendation`，成功替换 schemes/reason/sceneAnalysis 并重置 `currentSchemeIndex=0`，失败仅 console.error；
  - `selectScheme(scheme)`：`CartStore.addItem(scheme, 1)` → Toast `已添加到购物车`(1500ms) → pushUrl CartPage；
  - `selectSchemeDirect(scheme)`：不进购物车，直接 pushUrl OrderConfirmPage，params `{ cartData: JSON.stringify([{scheme, quantity:1}]) }`（与购物车结算同一入参协议）；
  - `copyGreetingText(text)`：`pasteboard.createData(MIMETYPE_TEXT_PLAIN, text)` → `getSystemPasteboard().setData()` → Toast `已复制到剪贴板` + 页内 copyTip 提示 2s 后清空。
- **SchemeCard @Builder 布局**：方案名 → 标签行（风格标签白字彩底 + `匹配度 ${matchScore}%` SECONDARY 20% 底 + 右侧 `¥${totalPrice}`）→ 描述 → `花材搭配` 列表（每行：`${flowerName} ×${quantity}` | 颜色 | 寓意 | `¥${unitPrice*quantity}`，#FAFAFA 底）→ `花语解读`（装饰引号 + 斜体，PRIMARY 20% 底）→ 条件显示 `推荐理由` → `贺卡文案建议` + `复制` 按钮 → copyTip。
- **主布局**：标题栏（`<` 返回 + `为TA定制的花束方案`）→ Swiper（`indicator(true)`、`loop(false)`、onChange 更新 currentSchemeIndex）→ 底部按钮组：`换一批方案`(OUTLINE 45%，isLoading 时禁用) + `加入购物车`(PRIMARY 45%) + `直接下单`(OUTLINE 100%)。
- **边界条件**：所有操作作用于 `schemes[currentSchemeIndex]`（Swiper 当前页）；schemes 为空时按钮点击直接 no-op；换一批失败无用户提示。

### 7.2.18 pages/RecipientProfile.ets — 收花人档案页（854 行）
- **路径**：`app/entry/src/main/ets/pages/RecipientProfile.ets`
- **职责**：收花人档案 CRUD（列表/新建/编辑/左滑删除）+ 关系进展时间线（mock）；页内三视图切换（列表/表单/时间线），非路由跳转。
- **选项常量（逐字，注意与 RecommendPage 同名常量取值不同）**：
  - `RELATIONSHIP_OPTIONS`（7）：['伴侣','朋友','父母','子女','同事','领导','其他']
  - `COLOR_OPTIONS`（8）：['红色','粉色','白色','黄色','紫色','蓝色','橙色','绿色']
  - `STYLE_OPTIONS`（7）：['浪漫','简约','华丽','自然','可爱','优雅','清新']
  - `HOBBY_OPTIONS`（10）：['阅读','旅行','音乐','运动','美食','摄影','绘画','园艺','手工','电影']
  - `PERSONALITY_OPTIONS`（10）：['温柔','开朗','内向','活泼','安静','独立','浪漫','理性','感性','幽默']
  - `ALLERGY_OPTIONS`（5）：['百合','菊花','郁金香','绣球','康乃馨']
- **状态**：`recipientList/showForm/isEditing/editingId(-1)/showTimeline/timelineRecipient/isLoading`；表单 11 字段 `formName/formGender('female')/formAge/formRelationship/formLikedColors[]/formStyle/formAllergies[]/formHobbies[]/formPersonality[]/formOccupation/formNotes`；`flowerRecords`(mock)、`pendingDeleteId(-1)`。
- **loadRecipients() 字段映射（关键：snake_case→camelCase 手工映射）**：`user_id→userId`、`age→String(age)→ageRange`、`interests || color_preference → preferences`、`created_at/updated_at→createdAt/updatedAt`；catch 回落 4 条 mock：李小红(伴侣/20-30/温柔、浪漫/喜欢粉色玫瑰、百合)、张妈妈(父母/50-60/开朗、温和/喜欢康乃馨)、王大伟(朋友/male/30-40/活泼、幽默/向日葵)、陈同事(同事/25-35/独立、理性/简约风格)。
- **saveRecipient() 提交参数（snake_case，与后端契约对齐）**：必填 `formName && formRelationship`；`age = parseInt(formAge.split('-')[0]) || 0`（**年龄区间取下限**，0 时传 undefined）；其余键：`personality/interests/color_preference/allergies` 均用「、」join（空数组传 undefined）、`career=formOccupation`、`style_preference=formStyle`、`notes=formNotes`；`as CreateRecipientParams` 强转绕过类型。编辑走 `updateRecipient(editingId,…)` Toast `修改成功`，新建走 `createRecipient` Toast `创建成功`；成功后关表单并 reload；**catch 也关表单**（Toast `保存失败`）。
- **openEditForm 回填**：仅回填 name/gender/ageRange/relationship，`personality.split('、')`，`preferences→formNotes`；颜色/风格/过敏/爱好/职业**不回填**（信息丢失，已知缺陷）。
- **删除**：ListItem `swipeAction({end})` 红底`删除`钮（宽 70）→ `deleteRecipient()`：调接口后本地 filter 移除，Toast `删除成功`/`删除失败`，无二次确认。
- **时间线（纯 mock）**：`getMockRecords()` 3 条逐字：2025-01-14/生日/粉色浪漫花束/`非常喜欢，感动落泪`；2025-02-14/情人节/红玫瑰99朵/`惊喜满分，拍了好多照片`；2025-03-20/纪念日/白百合+粉玫瑰混搭/`优雅漂亮，很满意`。UI：左侧圆点(12) + 竖线(2×60，非末项) + 右侧卡片（日期/`场景:`/`花束:`/`反馈:`）；`+ 添加送花记录` 钮仅 Toast `送花记录将在下单后自动生成`(2000ms)。
- **表单 UI 细节**：三分区（基本信息/偏好设置/画像信息+备注）；性别三态胶囊单选（女/男/其他）；关系与风格用横向 Scroll 胶囊单选；过敏花材选中态用 **ERROR_COLOR** 底（区别于其他多选的 PRIMARY/SECONDARY）；保存钮文案 `保存修改`/`创建档案`，`disabled: !formName || !formRelationship`。
- **边界条件**：`toggleItem` 用 filter/spread（与 RecommendPage 手工循环写法不同，保留差异）；头像为姓名首字 Circle 占位；列表项显示 `上次送花: ${updatedAt || '暂无'}`。

### 7.2.19 pages/OrderConfirmPage.ets — 订单确认页（492 行）
- **路径**：`app/entry/src/main/ets/pages/OrderConfirmPage.ets`
- **职责**：确认订单：展示花束卡片 + 配送信息表单 + 贺卡定制 + 价格明细，逐方案调 `createOrder` 后跳支付页。
- **常量**：`DELIVERY_FEE = 15`（配送费固定 15 元）。
- **入参**：优先 `router.getParams().cartData`（JSON 串，直接购买流程）；解析失败或为空则回落 `CartStore.getCartItems()`（购物车结算流程）；随后 `generateGreetingText()`。
- **推荐贺卡文案**：取 `cartItems[0].scheme.name` 查与 ResultPage **完全相同的 3 条文案映射**（初恋悸动/浪漫满屋/温柔告白，回落模板也相同，见 7.2.17，复现时两处重复定义）；`使用推荐文案` 钮将其填入 greetingMessage。
- **价格**：`getBouquetTotal() = Σ totalPrice×quantity`；`getTotalPrice() = 花束总价 + 15`。
- **校验 validateForm()**：`recipientName/phone/deliveryAddress` 三者 trim 后非空；不校验手机号格式。提交钮文案随校验切换：`确认支付`/`请填写完整信息`，未通过时 disabled。
- **confirmOrder() 关键流程**：
  1. **逐个 cartItem 循环调 `createOrder`**（一个方案一单），入参 snake_case：`{ total_price: totalPrice×quantity + 15, delivery_address: trim后, delivery_time || undefined, greeting_card_message: hasGreetingCard ? greetingMessage : undefined }`（注意：**每单都加了 15 配送费**；未传 flowers 明细/recipient_name/phone/remark，后端订单只存总价与地址，已知信息丢失）；
  2. 成功：`CartStore.clearCart()` → pushUrl PaymentPage，params `{ totalPrice: getTotalPrice(), recipientName, deliveryAddress }`；
  3. **catch 分支也模拟成功**：同样 clearCart + 跳 PaymentPage（调试用兜底，复现时保留）。
- **UI 结构**：标题栏`确认订单` → Scroll（方案卡片 SchemeCard：💐 60×60 + 名称 + `花材名×数量`顿号拼接 + `¥总价`+`×数量`；配送信息 4 行输入：收货人/联系电话(InputType.PhoneNumber)/配送地址/送达时间（placeholder `请选择期望送达日期（如：2025-06-15）`，实为普通 TextInput 非 DatePicker）；贺卡定制：Toggle 默认开 + TextArea + `使用推荐文案`(TEXT 钮)；备注输入；底部留白 Blank(100)）→ 底部固定区（花束费/配送费/合计 + 提交钮，上阴影 `#1A000000` offsetY -2）。
- **边界条件**：`remark` 仅存状态**未随订单提交**；多方案时循环下单但 PaymentPage 只收到合计总价；下单成功/失败均清空购物车。

### 7.2.20 pages/OrderListPage.ets — 订单列表页（370 行）
- **路径**：`app/entry/src/main/ets/pages/OrderListPage.ets`
- **职责**：订单列表：横向 Tab 状态筛选 + 订单卡片 + 点击跳详情；失败回落 4 条 mock。
- **Tab 常量（逐字，6 项）**：`全部:''`、`待支付:pending`、`已支付:paid`、`制作中:preparing`、`配送中:delivering`、`已完成:completed`（无 cancelled Tab，已取消订单只能在「全部」看到）。
- **loadOrders()**：`getOrders(currentPage, 10, status || undefined)`（pageSize 固定 10）；成功取 `response.items` 与 `response.pagination.totalPages`；catch 回落 mock。切 Tab：`currentPage=1` 后重新加载。**注意：totalPages 存了但页面无翻页 UI，永远只展示第 1 页 10 条**（已知缺陷）。
- **4 条 mock 订单（snake_case 字段，与后端返回同构）**：id'1' pending ¥123 北京市朝阳区xxx路1号 2025-06-15 `生日快乐！`；id'2' paid ¥88 上海市浦东新区xxx路2号 2025-06-10 无贺卡；id'3' delivering ¥256 广州市天河区xxx路3号 `永远爱你`；id'4' completed ¥168 深圳市南山区xxx路4号；created_at 均为 ISO 串（如 `2025-06-01T10:00:00Z`）。
- **状态映射（页内私有，与 Constants.ORDER_STATUS_MAP 独立重复定义）**：getStatusLabel：pending待支付/paid已支付/preparing制作中/delivering配送中/completed已完成/cancelled已取消；getStatusColor：pending #FF9800、paid #2196F3、preparing #9C27B0、delivering #4CAF50、completed TEXT_SECONDARY、cancelled ERROR_COLOR。
- **工具**：`formatTime`：`yyyy-MM-dd HH:mm`（padStart(2,'0')）；`getShortOrderId`：超 8 位截前 8 位（UUID 缩短显示）。
- **UI**：标题栏`我的订单` → 横向 Scroll Tab 胶囊（选中 PRIMARY 字 + ALPHA20 底）→ isLoading 时 LoadingProgress；空态 📋 + `暂无订单` + `快去挑选心仪的花束吧`；列表 `List({space: SPACING_MEDIUM})`。OrderCard：`订单号：短 id` + 状态彩色字 → Divider → 💐 50×50 + 固定文案`花束方案` + 下单时间 + `¥总价` → 地址（超 20 字截断加 `...`）+ `查看详情 ›`；整卡 onClick → pushUrl OrderDetailPage，params `{orderId: order.id}`。
- **边界条件**：订单无花材明细（后端未存），卡片只能显示固定文案「花束方案」。

### 7.2.21 pages/OrderDetailPage.ets — 订单详情页（414 行）
- **路径**：`app/entry/src/main/ets/pages/OrderDetailPage.ets`
- **职责**：订单详情：状态头部 + 五步进度条 + 花束/配送/贺卡信息 + 待支付时取消/去支付操作。
- **入参**：`router.getParams().orderId`；`loadOrderDetail()` 调 `getOrderDetail(orderId)`（`as unknown as OrderInfo` 双重强转），catch 回落 mock（pending/¥123/北京市朝阳区xxx路1号/2025-06-15/`生日快乐！愿这束花带给你一整天的好心情。`）。
- **状态展示三套映射（逐字）**：
  - label：复用 `Constants.ORDER_STATUS_MAP`（注意含 confirmed 键，见 7.2.3）；
  - color：pending #FF9800、confirmed #2196F3、paid #2196F3、preparing #9C27B0、delivering #4CAF50、completed TEXT_SECONDARY、cancelled ERROR_COLOR；
  - icon：pending ⏳、confirmed ✅、paid 💳、preparing 💐、delivering 🚚、completed 🎉、cancelled ❌，默认 📋。
- **五步进度条**：`getStatusSteps() = ['待确认','已确认','制作中','配送中','已完成']`；`getCurrentStepIndex` stepMap（逐字）：`pending:0、confirmed:1、paid:1、preparing:2、delivering:3、completed:4、cancelled:-1`（?? -1 兜底）；`status!=='cancelled'` 才渲染进度条；圆点 24，`index <= 当前步` 点亮 PRIMARY，步骤名字号 10。
- **cancelOrder()**：调 `ApiService.cancelOrder(id)` → actionTip `订单已取消` 并 reload；失败 actionTip `取消订单失败，请稍后重试`；2s 后清空提示；无二次确认弹窗。
- **UI 结构**：状态头部（大 icon 48 + 状态彩色字 + `订单号：全 id`）→ 进度条卡片 → 花束信息（💐 + `下单时间：`formatTime + `¥总价`）→ 配送信息（InfoRow：配送地址||'暂无'、期望送达||'尽快送达'、更新时间）→ 贺卡文案（有则渲染，PRIMARY 20% 底）→ actionTip → Blank(80)；底部仅 `status==='pending'` 时显示：`取消订单`(OUTLINE 45%) + `去支付`(PRIMARY 45%，pushUrl PaymentPage，params `{totalPrice: total_price, orderId: id}`)。
- **边界条件**：`formatTime(null)` 返回 `暂无`；取消成功后重新拉取详情使头部/按钮区随状态刷新。

### 7.2.22 pages/PaymentPage.ets — 模拟支付页（276 行）
- **路径**：`app/entry/src/main/ets/pages/PaymentPage.ets`
- **职责**：收银台：支付方式单选 + 模拟延时支付 + 成功态展示 + 自动跳转订单列表。**无真实支付 SDK**。
- **支付方式常量（逐字）**：`支付宝/🔵/alipay`、`微信支付/🟢/wechat`、`银行卡/🏦/bankcard`；默认选中 `alipay`。
- **入参**：`totalPrice/recipientName/deliveryAddress/orderId` 四键均可选（OrderConfirmPage 传前三个；OrderDetailPage `去支付` 传 totalPrice+orderId）。
- **confirmPayment() 关键时序（算法常量）**：① 若有 orderId 先 `updateOrderStatus(orderId,'paid')`（失败仅 console.error 不阻断）；② `setTimeout(2000)` 后 isPaying=false、isPaymentSuccess=true；③ 再 `setTimeout(1500)` 后 `router.replaceUrl('pages/OrderListPage')`（replaceUrl，支付页不可返回）。**延时 2000ms + 1500ms 为固定常量**。
- **三态 UI**：① 正常态：金额展示（`支付金额` + `¥总价` 字号 40 ACCENT + 条件显示 `收货人：`）+ 支付方式列表（Radio group 'payment'，选中行 ALPHA20 底）+ `🔒 支付环境安全，请放心支付` + 底部 `确认支付 ¥总价` 钮；② 支付中：LoadingProgress 60 + `支付处理中...` + `请勿关闭页面`；③ 成功态：✓ 白字 SUCCESS 圆底 80×80 + `支付成功` + `¥总价` + `正在为您跳转到订单列表...`；标题随态切换 `收银台`/`支付结果`，成功态隐藏返回钮。
- **边界条件**：`selectedPayment` 仅 UI 状态，不随任何请求提交；无 orderId 时（购物车流程多单）**不会更新任何订单状态**，支付纯演示（已知缺陷）。

### 7.2.23 components/CommonButton.ets — 通用按钮（120 行）
- **导出**：`enum CustomButtonType { PRIMARY, SECONDARY, OUTLINE, TEXT }`（命名避免与系统 ButtonType 冲突）、`enum ButtonSize { LARGE, MEDIUM, SMALL }`、`struct CommonButton`。
- **Props**：`text/type(PRIMARY)/size(MEDIUM)/disabled(false)` + 回调 `onClick?`。
- **样式规则（常量）**：背景—disabled→DISABLED_COLOR，PRIMARY→PRIMARY_COLOR，SECONDARY→SECONDARY_COLOR，OUTLINE/TEXT→透明；字色—disabled/PRIMARY/SECONDARY→白，OUTLINE/TEXT→PRIMARY_COLOR；高度—LARGE 48 / MEDIUM 40 / SMALL 32；字号—LARGE=FONT_SIZE_MEDIUM / MEDIUM=NORMAL / SMALL=SMALL；仅 LARGE 时 width '100%'；OUTLINE 且非 disabled 时加 1px PRIMARY 实线边框；`ButtonType.Capsule`；`enabled(!disabled)` 且 onClick 内再判 disabled。

### 7.2.24 components/FlowerCard.ets — 花材卡片（71 行）
- **Props**：`@Prop flower: FlowerInfo` + `onCardClick?(flower)`。
- **布局**：图（高 120、Cover、顶部圆角、灰底占位）→ 名称（maxLines 1）→ 花语 meaning（maxLines 1）→ `¥${price}` ACCENT 加粗 + `/支`；卡片白底圆角阴影（Theme 三常量）；整卡 onClick 回调。

### 7.2.25 components/BouquetCard.ets — 花束方案卡片（78 行）
- **Props**：`@Prop scheme: BouquetScheme` + `onCardClick?(scheme)`。
- **布局**：效果图（高 140）→ 名称（maxLines 1）→ 描述（maxLines 2）→ 底行：`匹配度 ${matchScore}%`（SECONDARY 字 + SECONDARY_COLOR_ALPHA20 底）与 `¥${totalPrice}` SpaceBetween；其余同 FlowerCard。当前仅 HomePage 热门推荐使用。

### 7.2.26 components/SceneSelector.ets — 场景选择器（73 行）
- **数据**：内置 6 场景（BIRTHDAY/CONFESSION/ANNIVERSARY/APOLOGY/GRATITUDE/VISIT），名称与图标取自 `Constants.SCENE_NAMES / SCENE_ICONS`（见 7.2.3，单一数据源）。
- **UI**：Grid `'1fr 1fr 1fr'` 三列、总高 160、行列间距 SPACING_SMALL；单元格：icon 字号 28 + 名称；选中态：PRIMARY 字加粗 + ALPHA20 底 + 2px PRIMARY 边框。
- **状态**：`@State selectedScene = BIRTHDAY`（**内部状态非 @Prop**，父预选场景不会同步高亮，已知缺陷）；点击更新自身并回调 `onSceneSelect(type)`。

### 7.2.27 components/StepIndicator.ets — 步骤指示器（60 行）
- **Props**：`steps: {title,isCompleted,isCurrent}[]`、`currentStep`（传入但渲染实际只用 steps 内标志位）。
- **渲染规则**：圆点—当前 24、否则 20；填充色—current→PRIMARY、completed→SECONDARY、其他→DISABLED；连接线用 Row 代 Line（30×2，completed→SECONDARY 否则 DISABLED）；标题字色同圆点逻辑，current 加粗；ForEach key 用 index。

### 7.2 小结

app 侧 27 个 .ets 文件已全部精讲（7.2.1–7.2.27）：入口 1（EntryAbility）+ 主题/常量 2 + 模型 3 + 服务 2 + 全局存储 1 + 页面 13 + 组件 5。复现时优先顺序：Theme/Constants/模型 → HttpUtil/ApiService/CartStore → 组件 → Index 壳 → 各页面。

## 7.3 app 其余非代码文件（模块级表格兜底）

| 路径 | 职责 | 要点 |
|------|------|------|
| `app/entry/src/main/module.json5` | 模块声明 | module.name=entry、type=entry、srcEntry=./ets/entryability/EntryAbility.ets、mainElement=EntryAbility、pages=$profile:main_pages；权限 `ohos.permission.INTERNET`；EntryAbility skills 含 action.system.home + entity.system.home（桌面启动） |
| `app/entry/src/main/resources/base/profile/main_pages.json` | 路由表 | 13 个页面路径（见 8.1 路由表，首项 pages/Index 为启动页） |
| `app/entry/src/main/resources/base/element/color.json` | 颜色资源 | 项目主色定义（start_window_background 等）；业务色实际全部硬编码在 Theme.ets，此文件仅系统窗口用 |
| `app/entry/src/main/resources/base/element/string.json` | 字符串资源 | module_desc/ability 标签等模板默认项；业务文案全部硬编码在 ets 内 |
| `app/entry/src/main/resources/base/media/*` | 图标资源 | layered_image.json/startIcon 等模板默认图标；需另行提供（见第 10 章） |
| `app/entry/src/main/resources/en_US|zh_CN/*` | 多语言副本 | 与 base 同构的 element 副本，未做真实国际化 |
| `app/entry/src/ohosTest/**`、`app/entry/src/test/**` | 测试模板 | DevEco 脚手架默认测试（Ability.test.ets/List.test.ets/LocalUnit.test.ets），未写业务用例，可照搬模板 |
| `app/entry/obfuscation-rules.txt` | 混淆规则 | 模板默认（release 未启用自定义规则） |
| `app/entry/oh-package.json5`、`app/oh-package.json5` | 包声明 | 依赖表见第 2 章（无三方运行时依赖，仅 hypium/hamock devDependencies） |
| `app/build-profile.json5`、`app/entry/build-profile.json5` | 构建配置 | 关键字段已逐字收录于第 2 章（SDK/signingConfigs 占位） |
| `app/hvigorfile.ts`、`app/entry/hvigorfile.ts`、`app/hvigor/hvigor-config.json5` | 构建脚本 | 模板默认（appTasks/hapTasks），无自定义逻辑 |
| `app/AppScope/app.json5`、`app/AppScope/resources/**` | 应用级声明 | bundleName、versionCode/versionName、应用图标/名称（见第 2 章） |

<!-- SECTION 7 END -->

---

# 8. UI 与交互

本章从"整体导航结构"视角汇总 app 的路由表、Tab 框架、页面跳转协议、页面状态机与状态管理。单页面内部实现细节以第 7 章 7.2.x 各小节为准，本章聚焦页面之间的关系与全局状态。

## 8.1 路由表（main_pages.json 逐字顺序）

`app/entry/src/main/resources/base/profile/main_pages.json` 中 `src` 数组共 13 项，顺序如下（首项为启动页）。复现时必须保证 13 个路径全部注册，否则 `router.pushUrl` 抛 `Uri error`：

| # | 路由路径 | 源文件（ets/pages/） | 页面名 | 进入方式 | 入参（router params） |
|---|---------|---------------------|--------|----------|----------------------|
| 1 | `pages/Index` | Index.ets | Tab 主框架（启动页） | 应用启动 / EntryAbility loadContent | 无 |
| 2 | `pages/HomePage` | HomePage.ets | 首页 | 常规为 Index Tab0 内嵌组件（注册路由但业务上不直接 push） | 无 |
| 3 | `pages/RecommendPage` | RecommendPage.ets | 五步问卷推荐 | Index Tab1 内嵌；MinePage「送花日历提醒」菜单 pushUrl | 无（预选场景走 AppStorage） |
| 4 | `pages/FlowerLibrary` | FlowerLibrary.ets | 花材图鉴库 | Index Tab2 内嵌 | 无（搜索词走 AppStorage） |
| 5 | `pages/MinePage` | MinePage.ets | 我的 | Index Tab3 内嵌；MinePage「设置」菜单 pushUrl 自身 | 无 |
| 6 | `pages/ResultPage` | ResultPage.ets | 推荐结果（3 方案） | RecommendPage 生成成功后 pushUrl；MinePage「收藏的方案」菜单 pushUrl | `schemesData`、`reason`、`sceneAnalysis`、`requestParams`（菜单进入时无参，走 mock 兜底） |
| 7 | `pages/RecipientProfile` | RecipientProfile.ets | 收花人档案 | MinePage「收花人档案」菜单 pushUrl | 无 |
| 8 | `pages/LoginPage` | LoginPage.ets | 登录/注册 | MinePage 未登录时点击头像区/登录按钮 pushUrl | 无 |
| 9 | `pages/CartPage` | CartPage.ets | 购物车 | ResultPage「加入购物车」后 pushUrl | 无(数据走 CartStore/AppStorage) |
| 10 | `pages/OrderConfirmPage` | OrderConfirmPage.ets | 订单确认 | CartPage「去结算」pushUrl；ResultPage「立即购买」pushUrl | `cartData: CartItem[]` |
| 11 | `pages/PaymentPage` | PaymentPage.ets | 模拟支付 | OrderConfirmPage 下单后 pushUrl；OrderDetailPage「去支付」pushUrl | `totalPrice`；来自订单确认时另有 `recipientName`、`deliveryAddress`；来自订单详情时另有 `orderId` |
| 12 | `pages/OrderListPage` | OrderListPage.ets | 订单列表 | MinePage「我的订单」「消息通知」菜单 pushUrl；PaymentPage 支付成功 1.5s 后 **replaceUrl** | 无 |
| 13 | `pages/OrderDetailPage` | OrderDetailPage.ets | 订单详情 | OrderListPage 点击订单卡片 pushUrl | `orderId: string` |

要点：
- HomePage/RecommendPage/FlowerLibrary/MinePage 四页**双重身份**：既是 Tabs 的内嵌子组件，又注册了路由供 MinePage 菜单直接 push（此时以独立页面打开，顶部无 Tab 栏）。原码四个文件均用 `@Entry @Component` 声明，作为子组件引用亦可编译通过，复现时保持一致。
- 只有 PaymentPage → OrderListPage 用 `router.replaceUrl`（防止返回键回到支付页），其余全部 `router.pushUrl`；所有二级页面左上角返回按钮统一调 `router.back()`。

## 8.2 Tab 主框架（Index.ets）

结构（与 7.2.10 一致，此处给导航视角规格）：

```
Index (@Entry)
└─ Column
   └─ Tabs(barPosition: BarPosition.End, index: $currentIndex)
      ├─ TabContent → HomePage()      tabBar: TabBuilder(0,'首页')   图标 🏠
      ├─ TabContent → RecommendPage() tabBar: TabBuilder(1,'推荐')   图标 💡
      ├─ TabContent → FlowerLibrary() tabBar: TabBuilder(2,'花材库') 图标 🌺
      └─ TabContent → MinePage()      tabBar: TabBuilder(3,'我的')   图标 👤
```

- Tab 项标题数组：`['首页', '推荐', '花材库', '我的']`；图标为 emoji 文字占位：`['🏠', '💡', '🌺', '👤']`（fontSize 20，选中色 PRIMARY_COLOR，未选中 TEXT_SECONDARY；标题 fontSize 12，选中加粗）。
- Tabs 属性：`scrollable(true)`（支持左右滑动切页）、`barHeight(56)`、`barBackgroundColor(CARD_BACKGROUND)`、`onChange` 回写 `currentIndex`。
- 跨页切 Tab 协议：`@StorageLink('currentTab') currentIndex`，任何页面 `AppStorage.setOrCreate('currentTab', n)` 即可切换（HomePage 用此跳搜索/场景）。
- 购物车角标：`@StorageLink('cartItemCount') cartCount`，>0 时在 Tab 图标右上角（`position({x:'60%', y:-6})`）显示红底白字数量，`>=100` 显示 `99+`，`constraintSize({minWidth:16})`。注意：角标由 TabBuilder 统一渲染，因此 4 个 Tab 图标都会出现角标（原实现如此，复现时保持一致）。
- `aboutToAppear`：依次调 `CartStore.initAppStorage()`（注册 cartItems/cartItemCount 键）与 `CartStore.loadFromDisk()`（Preferences 恢复购物车）。

## 8.3 页面跳转关系与参数协议

### 8.3.1 跳转关系图

```
                ┌───────────────────── Index（4 Tab 壳）─────────────────────┐
                │ Tab0 HomePage  Tab1 RecommendPage  Tab2 FlowerLibrary  Tab3 MinePage │
                └──────┬──────────────┬────────────────────────────────┬──────────────┘
 搜索:searchKeyword+切Tab2 │        生成成功                    菜单(6项) │ 未登录点头像
 场景:selectedScene+切Tab1 │           │                               │
                          ▼           ▼                               ▼
                    (Tab内切换)   ResultPage ──加购──► CartPage   ┌─ OrderListPage ─► OrderDetailPage
                                      │                 │        ├─ ResultPage(无参mock)     │去支付
                                      │立即购买          │去结算   ├─ RecommendPage            ▼
                                      ▼                 ▼        ├─ RecipientProfile    PaymentPage
                                 OrderConfirmPage ◄─────┘        ├─ OrderListPage(消息)
                                      │下单(成败均跳)              ├─ MinePage(设置自跳)
                                      ▼                          └─ LoginPage ─成功─ router.back()
                                 PaymentPage ──支付成功1.5s──replaceUrl──► OrderListPage
```

### 8.3.2 跳转参数协议表（逐条）

| 起点 → 终点 | 触发 | 方式 | 传参 | 接收方读取 |
|------------|------|------|------|-----------|
| HomePage → FlowerLibrary | 搜索框提交（非空 trim） | `AppStorage.setOrCreate('searchKeyword', kw)` + `setOrCreate('currentTab', 2)` | searchKeyword | ⚠️ FlowerLibrary 未消费该键（已知缺陷，见 10.2-②） |
| HomePage → RecommendPage | 点击 6 场景快捷入口 | `AppStorage.setOrCreate('selectedScene', scene)` + `setOrCreate('currentTab', 1)` | selectedScene | RecommendPage aboutToAppear 读取，非空则 `this.selectedScene = preScene`、清空该键、`currentStep = 1`（直接跳到第 2 步） |
| RecommendPage → ResultPage | AI 推荐生成成功 | pushUrl | `{ schemesData: BouquetScheme[], reason: string, sceneAnalysis: string, requestParams: RecommendRequest }` | ResultPage `router.getParams()`，无参/解析失败走 `getMockSchemes()` |
| ResultPage → CartPage | 方案卡「加入购物车」 | 先 `CartStore.addItem(scheme, 1)` + Toast「已添加到购物车」(1500ms)，再 pushUrl | 无 | CartPage 从 AppStorage 'cartItems' 渲染 |
| ResultPage → OrderConfirmPage | 「立即购买」 | pushUrl | `{ cartData: [{ scheme, quantity: 1 }] }` | OrderConfirmPage getParams |
| CartPage → OrderConfirmPage | 「去结算」（购物车非空） | pushUrl | `{ cartData: CartItem[] }`（全量购物车项） | 同上 |
| OrderConfirmPage → PaymentPage | 「提交订单」（表单校验过） | createOrder 成功后 pushUrl；**catch 中也模拟成功 pushUrl**（缺陷 10.2-⑨） | `{ totalPrice, recipientName, deliveryAddress }`，跳转前 `CartStore.clearCart()` | PaymentPage getParams 显示金额 |
| OrderDetailPage → PaymentPage | 状态 pending 时「去支付」 | pushUrl | `{ totalPrice, orderId }` | PaymentPage 持有 orderId（⚠️ 但支付成功后未调 updateOrderStatus，缺陷 10.2-⑪） |
| PaymentPage → OrderListPage | 支付动画完成 1.5s 后 | **replaceUrl**（源码注释误写"跳转到订单详情页"，实际目标为 OrderListPage） | 无 | OrderListPage 重新拉取列表 |
| OrderListPage → OrderDetailPage | 点击订单卡片 | pushUrl | `{ orderId: order.id }` | OrderDetailPage getParams 后 getOrderDetail(orderId) |
| MinePage → 各页 | 6 项菜单 | `router.pushUrl({ url: item.route })` | 无 | 菜单 route 映射：我的订单📦→OrderListPage、收藏的方案⭐→ResultPage、送花日历提醒📅→RecommendPage、收花人档案👥→RecipientProfile、消息通知🔔→OrderListPage、设置⚙️→MinePage（自跳） |
| MinePage → LoginPage | 未登录点头像区/登录按钮 | pushUrl | 无 | 登录/注册成功后 `router.back()` 返回（⚠️ MinePage 返回不自动刷新登录态，缺陷 10.2-④） |
| 各二级页 → 上一页 | 左上返回按钮 | `router.back()` | 无 | — |

## 8.4 页面状态机

各页面均遵循统一的四态模型（详细字段见对应 7.2.x 小节），此处给出状态迁移规格。

**通用加载态模型：**
```
[初始] --aboutToAppear/onPageShow--> [loading: isLoading=true]
  --API 成功--> [data: 渲染列表/详情]
  --API 失败--> [mock 降级: getMockXxx() 填充]  （F32：失败不展示错误页，而是 mock 数据兜底）
  --数据为空--> [empty: 空态占位（文案+emoji）]
```

各页面关键状态与迁移：

| 页面 | 关键状态变量 | 状态迁移要点 |
|------|-------------|-------------|
| HomePage | searchKeyword、bannerIndex、hotFlowers[] | Banner Swiper `interval 3000` 自动轮播；热门花材加载失败→mock；搜索/场景触发 Tab 切换（见 8.3.2） |
| RecommendPage | currentStep(0-4)、selectedTarget/Scene/Relation、画像字段、budget、isGenerating | 五步向导：currentStep 驱动 StepIndicator 与分步表单；「上一步/下一步」±1；最后一步「生成推荐」→isGenerating=true→成功 pushUrl ResultPage / 失败静默（缺陷⑦）；外部预选场景则初始 currentStep=1 |
| ResultPage | schemes[3]、currentSchemeIndex、reason、sceneAnalysis | Swiper 切换方案卡；「换一批」重调 generateRecommendation（同参）；贺卡文案点击→剪贴板+Toast；无入参→mock 3 方案 |
| FlowerLibrary | flowers[]、selectedColor/Category/Season、searchText、page、hasMore、isLoading | 三维筛选任一变更→重置 page=1 重查；触底且 hasMore→page+1 追加；`hasMore = 返回条数 >= 12`；点击卡片→@CustomDialog 详情弹窗 |
| CartPage | @StorageLink cartItems（直连全局） | 数量 1-99 边界；swipeAction 左滑删除；清空→确认弹窗；空车显示空态+「去逛逛」router.back() |
| OrderConfirmPage | cartData[]、recipientName/Phone/Address、needCard、cardMessage、remark | 表单必填校验（姓名/电话/地址）不过→Toast；needCard 开关控制贺卡输入区展开；提交→创建订单→PaymentPage |
| PaymentPage | selectedPayment、isPaying、isPaymentSuccess | 「确认支付」→isPaying=true→2000ms 定时→isPaymentSuccess=true（成功动画）→1500ms→replaceUrl OrderListPage |
| OrderListPage | orders[]、currentStatusTab(6 Tab)、page、totalPages、isLoading | Tab 切换→重置 page=1 重查（status 参数映射见 7.2.20）；失败→mock 订单 |
| OrderDetailPage | order、isLoading | stepMap 驱动 5 步进度条（pending:0/confirmed:1/paid:1/preparing:2/delivering:3/completed:4/cancelled:-1）；按钮组按状态渲染（pending：取消+去支付） |
| RecipientProfile | recipients[]、弹窗开关、编辑表单十余字段 | 列表↔新建/编辑弹窗↔时间线弹窗三视图；swipeAction 删除→确认；编辑保存→PUT，新建→POST；编辑不回填部分字段（缺陷⑧） |
| LoginPage | activeTab(login/register)、phone、password、code、countdown | 双 Tab 切换；「获取验证码」→countdown=60 每秒-1（纯前端模拟，缺陷⑤）；登录/注册成功→存 token→router.back() |
| MinePage | userInfo、isLoggedIn、stats | aboutToAppear 读 token→getProfile→登录态渲染；退出→清 token+回未登录态；返回页面不重查（缺陷④） |
| Index | currentIndex、cartCount（均 @StorageLink） | Tab 切换 + 角标联动，无其他状态 |

## 8.5 状态管理总览

三层状态体系：

**① AppStorage（跨页面内存态）——全部键位清单：**

| 键 | 类型 | 写入方 | 读取方 | 用途 |
|----|------|--------|--------|------|
| `currentTab` | number | HomePage（搜索/场景跳转）、Index onChange | Index @StorageLink | 跨页切 Tab |
| `cartItemCount` | number | CartStore（增删改时同步） | Index 角标 @StorageLink | 购物车总件数 |
| `cartItems` | string(JSON) | CartStore | CartPage @StorageLink / CartStore | 购物车项数组序列化 |
| `searchKeyword` | string | HomePage 搜索提交 | （无消费方——缺陷②） | 预期传递搜索词给花材库 |
| `selectedScene` | string | HomePage 场景入口 | RecommendPage aboutToAppear（读后清空） | 场景预选 |

**② Preferences（磁盘持久化）：**

| preferences 实例/键 | 写入时机 | 内容 |
|--------------------|---------|------|
| CartStore：`flower_cart` 表、键 `cart_items` | 购物车任意变更（addItem/updateQuantity/removeItem/clearCart） | 购物车 JSON；App 启动 loadFromDisk 恢复 |
| HttpUtil/ApiService：`user_data` 表、键 `token` | 登录/注册成功；退出登录时删除 | JWT 字符串；HttpUtil 每次请求读取并拼 `Bearer ${token}` |

**③ CartStore 单例（内存业务态）**：静态类封装购物车全部读写（详见 7.2.9），任何页面不得直接改 `cartItems` 键，必须走 CartStore 方法以保证 AppStorage 与 Preferences 双写一致。

## 8.6 通用交互规范

- **Toast**：统一 `promptAction.showToast({ message, duration: 1500/2000 })`；成功类 1500ms、错误提示 2000ms。
- **确认弹窗**：删除/清空类操作统一二次确认弹窗，确认按钮红色（ERROR_COLOR）。
- **左滑删除**：List 项 `swipeAction({ end: DeleteBuilder })`，删除按钮红底白字（CartPage、RecipientProfile 一致）。
- **详情弹窗**：FlowerLibrary 花材详情用 `@CustomDialog` + `CustomDialogController`，每次打开前重建 controller（ArkTS 弹窗数据刷新的规避写法，见 7.2.15）。
- **触底加载**：列表页统一触底加载下一页，无下拉刷新容器。
- **返回**：二级页统一自绘顶栏（‹ 返回箭头 + 标题），`router.back()`；无系统 NavBar。
- **按钮**：统一走 CommonButton（4 类型×3 尺寸，见 7.2.23），主操作 PRIMARY 大按钮置底。
- **金额展示**：一律 `¥${price}` 前缀、ACCENT_COLOR 橙色加粗。

## 8.7 资源文件清单

| 资源 | 路径 | 现状与规格 | 复现要求 |
|------|------|-----------|---------|
| 应用图标 | `app/entry/src/main/resources/base/media/icon.png` | 1.0KB 占位 PNG | **需另行提供**：256×256px PNG（见同目录 icon_placeholder.txt 说明） |
| 图标占位说明 | `.../media/icon_placeholder.txt` | 3 行中文说明（目录用途/放置方式/建议 256×256 PNG） | 可选保留 |
| 启动窗背景 | `.../base/element/color.json` | start_window_background 白色 | 照写 |
| Tab/菜单图标 | 无图片文件 | 全部 emoji 文字占位（🏠💡🌺👤📦⭐📅👥🔔⚙️ 等） | 无需图片资源 |
| 花材/方案图片 | 无本地文件 | 全部网络 URL（种子数据 image_url 字段），加载失败显示 DIVIDER_COLOR 灰底 | 无需本地图片 |
| 字符串资源 | `.../base/element/string.json` 及 en_US/zh_CN 副本 | 模板项 + tab_home/tab_recommend/tab_library/tab_mine 四个 Tab 标签 | 照写；业务文案全部硬编码 ets |
| AppScope 图标/名称 | `app/AppScope/resources/**` | 模板默认 app_icon/app_name（花语助手） | app_name 写"花语助手" |

<!-- SECTION 8 END -->

---

# 9. 从零复现步骤

本章给出严格的编号步骤。每步完成后有明确的验证点；全部完成后按 9.8 验收表逐项对照第 1 章功能清单 F01–F32。

## 9.1 前置条件

| 依赖 | 版本要求 | 说明 |
|------|---------|------|
| Node.js | ≥ 18（CI 用 20） | 后端运行时 |
| PostgreSQL | ≥ 14 | 本地实例即可 |
| Redis | ≥ 6 | 可选（缺失时缓存自动降级，F15） |
| DevEco Studio | 5.x（配 HarmonyOS 5.0.0+ SDK，compatibleSdkVersion 见第 2 章 build-profile 收录） | app 编译/模拟器 |
| 通义千问 API Key | dashscope 有效 key | 无 key 时 F08 不可用，app 侧靠 mock 兜底 |

## 9.2 阶段 A：创建后端工程

1. 新建 `backend/` 目录，按第 3 章目录树创建 `src/{config,middleware,models,routes,services/qwen,scripts,utils}` 与 `database/` 骨架。
2. 创建 `package.json`：依赖与脚本逐字照第 2 章依赖表（express/pg/redis/axios/bcryptjs/jsonwebtoken/express-rate-limit/cors/dotenv 及对应 @types + typescript/ts-node/nodemon）。
3. 创建 `tsconfig.json`（第 2 章收录的编译选项：target ES2020、outDir dist、strict）。
4. 创建 `.env.example`：键位逐字照 2.4 环境变量表（13 键）；复制为 `.env` 并填入真实值（勿提交）。
5. `npm install`，验证点：无报错、lock 文件生成。

## 9.3 阶段 B：建库

6. 本地启动 PostgreSQL，创建数据库（库名与 .env 的 DB_NAME 一致，占位值 `flower_assistant`）。
7. 将第 4 章 4.2/4.3 内嵌的 `init.sql`、`seed.sql` 逐字写入 `backend/database/`。
8. 按 4.5 规格实现 `src/scripts/init-db.ts`，执行 `npm run init-db`。验证点：`SELECT count(*) FROM flowers` = 32，`bouquet_templates` = 8，且**只执行一次**（重复执行触发器报错 + 种子重复，见 4.5 幂等性边界）。

## 9.4 阶段 C：后端代码

9. 按第 7 章 7.1.1–7.1.21 逆依赖顺序实现：先 utils（response/jwt）与 config（database/redis/qwen 配置），再 middleware（auth/errorHandler/rateLimiter），再 models，再 services/qwen（promptBuilder → qwenClient → responseParser → cacheService → recommendService），最后 routes（auth/flowers/recipients/recommendations/orders/index）与 `src/index.ts` 装配。
10. 关键不可推导项直接取自本文档：SYSTEM_PROMPT 原文（第 6 章）、价格修正/场景增强算法与常量、限流三级参数（100/min、5/min、10/min）、缓存 TTL 4h/MD5 键、统一响应 `{code,message,data}`、JWT 过期 7d。
11. `npm run build` 通过；`npm run dev` 启动。验证点：`GET http://localhost:3001/api/health` 返回 `{code:200,...}`。

## 9.5 阶段 D：后端接口验证

12. 用第 5 章 API 契约表逐端点自测（共 22 端点）：注册→登录拿 token→带 `Authorization: Bearer` 访问受保护端点；重点验证 F08 推荐（有 key 时返回 3 方案 JSON）与 F13 订单状态机非法迁移被拒。

## 9.6 阶段 E：创建 app 工程

13. DevEco Studio 新建 Empty Ability 工程（Stage 模型，bundleName 照第 2 章 AppScope 收录），目录对齐第 3 章 app 树。
14. 替换 `main_pages.json` 为 8.1 的 13 项路由表；`module.json5` 加 `ohos.permission.INTERNET`。
15. 按 7.2 小结的优先顺序实现 27 个 .ets：Theme/Constants/模型 → HttpUtil/ApiService/CartStore → 5 组件 → Index 壳 → 13 页面。BASE_URL 按原码写 `http://localhost:3000/api`（注意：与后端 3001 不一致为**原项目已知错配**，精确复现应保留；若要联调成功需改为真实后端地址，见 10.2-⑮）。
16. 提供 `icon.png`（256×256，不可文本化资产）。编译 HAP，验证点：模拟器启动见 4 Tab 框架。

## 9.7 阶段 F：端云联调

17. 模拟器访问宿主机后端：将 BASE_URL 改为宿主机局域网 IP + 真实端口（如 `http://192.168.x.x:3001/api`）。
18. 联调主链路：注册登录 → 花材库加载真实 32 花材 → 五步问卷生成 AI 推荐 → 加购 → 下单 → 模拟支付 → 订单列表。同时知晓 4 处端云已知错配（见 10.2-⑭/⑮）属原项目行为，不影响验收（app 有 mock 兜底）。

## 9.8 验收标准（对照第 1 章 F01–F32）

| 编号 | 验收操作 | 预期结果 |
|------|---------|---------|
| F01 | POST /api/auth/register（新手机号+密码） | 200，返回 user+token；库中 password_hash 为 bcrypt 密文 |
| F02 | 错误密码登录 | 401，提示与"手机号不存在"同文案（防枚举） |
| F03 | GET/PUT /api/auth/profile 带 token | 返回/更新成功；昵称 51 字被拒 |
| F04 | GET /api/flowers/categories | 去重后的类别数组 |
| F05 | GET /api/flowers?color=红色&keyword=玫瑰&page=1 | 命中筛选与分页，返回 total/totalPages |
| F06 | GET /api/flowers/:uuid | 单花材详情；不存在返 404 |
| F07 | 收花人 CRUD；用他人 token 改非属主档案 | 自有档案成功；非属主 404；age 201 被拒 |
| F08 | POST /api/recommendations/generate（全参） | 返回 3 方案+reason+sceneAnalysis；方案价格落在预算修正区间 |
| F09 | GET /api/recommendations + /:id | 列表含收花人姓名 JOIN 字段 |
| F10 | POST 反馈 rating=5；重复提交 | 首次成功；重复被拒；rating=6 被拒 |
| F11 | POST /api/orders 关联 recommendation_id+selected_scheme_index | 创建成功返订单号 |
| F12 | GET /api/orders?status=pending&page=1；/:id | 筛选分页正确；详情完整 |
| F13 | PUT /api/orders/:id/status 按 pending→paid→preparing 逐步迁移；尝试 pending→completed | 合法迁移成功；非法迁移 400 |
| F14 | 取消 pending 订单；取消 completed 订单 | 前者成功；后者被拒 |
| F15 | 同参数连续两次 generate；关掉 Redis 再请求 | 第二次命中缓存（日志/耗时可辨）；无 Redis 仍正常返回 |
| F16 | 1 分钟内第 6 次登录请求 | 429；AI 端点第 11 次 429 |
| F17 | 任意错误请求 | 响应体始终 `{code,message,data}` 结构 |
| F18 | GET /api/health | 200，含服务状态 |
| F19 | 见 9.3 步骤 8 | 花材 32 / 模板 8 |
| F20 | 启动 app | 4 Tab（首页/推荐/花材库/我的）emoji 图标；加购 100 件后角标显 99+ |
| F21 | 首页操作 | Banner 3s 自动轮播；点场景切到推荐 Tab 且直达第 2 步；搜索切到花材库 Tab |
| F22 | 推荐 Tab 走完五步 | 每步表单正确；Slider 范围 50-2000 步长 50 默认 200 |
| F23 | 结果页 | Swiper 3 方案卡；换一批重新生成；点贺卡文案 Toast"已复制" |
| F24 | 花材库 | 颜色/类别/季节筛选生效（季节筛选为已知缺陷①不生效属正常复现）；触底加载第 2 页；点卡片弹详情 |
| F25 | 加购后杀进程重开 | 购物车数据从 Preferences 恢复；数量边界 1-99；左滑删除 |
| F26 | 订单确认页 | 必填校验 Toast；贺卡开关展开输入；价格明细含配送费 15 元 |
| F27 | 支付页 | 3 支付方式单选；确认后 2s 转圈→成功动画→1.5s 跳订单列表（返回键不能回支付页） |
| F28 | 订单列表/详情 | 6 状态 Tab 筛选；详情 5 步进度条与状态对应；pending 可取消/去支付 |
| F29 | 档案页 | 列表/新建/编辑/左滑删除/时间线弹窗均可用 |
| F30 | 登录页 | 双 Tab；验证码按钮 60s 倒计时；登录后 token 持久化（重开仍登录态） |
| F31 | 我的页 | 登录态显脱敏手机号；6 菜单可跳；退出后回未登录态 |
| F32 | 关闭后端再操作各页 | 花材/订单/档案/推荐均显示内置 mock 数据，无崩溃无空白错误页 |

<!-- SECTION 9 END -->

---

# 10. 不可文本化资产与已知问题

## 10.1 不可文本化资产（需人工补录）

| 资产 | 位置 | 说明 | 获取/替代方案 |
|------|------|------|--------------|
| 应用图标 icon.png | `app/entry/src/main/resources/base/media/` | 当前仅 1KB 占位图 | 自行设计 256×256 PNG；不影响功能验收 |
| AppScope 应用图标 | `app/AppScope/resources/base/media/` | DevEco 模板默认图 | 同上 |
| HarmonyOS 签名材料 | build-profile.json5 signingConfigs | 未收录（含密钥性质） | DevEco 自动签名或自建 p7b/cer/p12 |
| 通义千问 API Key | backend/.env 的 QWEN_API_KEY | 密钥零收录红线 | 自行到 dashscope 控制台申请 |
| JWT_SECRET / DB 密码 | backend/.env | 同上 | 自行生成随机强密钥 |
| 花材图片 | seed.sql 的 image_url 外链 | URL 已逐字收录在第 4 章，但外链可能失效 | 失效时 UI 显灰底，不影响功能；可自行替换图床 |
| HarmonyOS SDK / DevEco | 本地开发环境 | 二进制工具链 | 华为官网下载 |
| 模拟器/真机 | 运行环境 | — | DevEco Device Manager |

## 10.2 已知缺陷清单（原项目行为，精确复现应保留；优化重构可修）

| 编号 | 缺陷 | 位置 | 影响 |
|------|------|------|------|
| ① | 季节筛选 selectedSeason 未传入查询参数 | FlowerLibrary.ets | 季节 Tab 切换无实际筛选效果 |
| ② | AppStorage 'searchKeyword' 无消费方 | HomePage 写入、FlowerLibrary 未读 | 首页搜索仅切 Tab，关键词丢失 |
| ③ | 花材收藏纯本地 @State，无持久化无后端 | FlowerLibrary 详情弹窗 | 退出页面即丢 |
| ④ | MinePage 从 LoginPage 返回不刷新登录态 | MinePage（无 onPageShow 重查） | 登录后需切 Tab 才见登录态 |
| ⑤ | 验证码纯前端模拟，无短信通道，后端也无校验端点 | LoginPage | 验证码无实际作用 |
| ⑥ | 「编辑资料」菜单无输入弹窗实现 | MinePage editProfile | 点击仅 Toast |
| ⑦ | 推荐生成无必填校验；catch 无用户提示 | RecommendPage | 参数不全也可提交；失败静默 |
| ⑧ | 编辑档案不回填颜色/风格/过敏/爱好/职业 | RecipientProfile | 保存会覆盖为空 |
| ⑨ | remark 未提交；每单重复加 15 配送费；catch 也模拟成功；未传花材明细 | OrderConfirmPage | 订单数据不完整；失败无感知 |
| ⑩ | totalPages 已算但无翻页 UI | OrderListPage | 仅能看第一页（触底加载为花材库独有） |
| ⑪ | selectedPayment 未提交；持有 orderId 也不调 updateOrderStatus | PaymentPage | 支付后订单仍 pending |
| ⑫ | SceneSelector 用 @State 非 @Prop，父预选不同步 | SceneSelector.ets | 场景预选只能靠 RecommendPage 自身逻辑兼容 |
| ⑬ | HttpUtil 引用了不存在的 preferences.getContext 写法（实际以原码实现为准，见 7.2.7） | HttpUtil.ets | 复现时按 7.2.7 的实际代码写，勿自行"修正" |
| ⑭ | 端云路径错配 3 处：app 调 GET /recommendations/history、POST/GET /feedbacks，后端无此路由（实为 /recommendations 与 /recommendations/:id/feedback） | ApiService vs 后端 routes | 对应功能永远走 mock 兜底 |
| ⑮ | BASE_URL 端口 3000 vs 后端默认 3001 | Constants.ets | 默认配置下全部请求失败→mock；联调需手改 |
| ⑯ | app ORDER_STATUS_MAP 含 confirmed，后端状态机无 confirmed | Constants.ets vs orders.ts | 详情页 confirmed 映射为防御性冗余 |
| ⑰ | 贺卡 3 条文案在 ResultPage 与 OrderConfirmPage 重复定义 | 两页面 | 改文案需改两处 |

## 10.3 坑与注意事项（复现时易踩）

1. **init-db 非幂等**：见 4.5，只能执行一次；重置需删库重建。
2. **ArkTS 严格模式**：不可用 any/对象字面量类型推断，router 传参需显式 interface（各页 Params 类型见 7.2.x）；否则编译报 arkts-no-any 系列错误。
3. **CustomDialogController 刷数据**：必须重建 controller 再 open（FlowerLibrary 详情弹窗写法），直接改数据不触发弹窗重渲染。
4. **模拟器访问宿主机**：localhost 指向模拟器自身，联调必须用局域网 IP（见 9.7）。
5. **限流自测干扰**：连续自测登录易触发 5/min 限流 429，自测时注意间隔或临时调参。
6. **qwen 返回非标准 JSON**：responseParser 已处理 markdown 围栏等容错（见 7.1 对应小节），复现时勿省略容错分支，否则线上解析失败率高。
7. **CI 仅编译后端**：.github/workflows/ci.yml 不构建 app（需 DevEco 工具链），app 编译验证只能本地。

## 10.4 TODO（从源码注释与实现现状归纳）

- 接入真实短信验证码服务（⑤）；收藏同步后端（③）；支付成功回写订单状态（⑪）；订单列表分页 UI（⑩）；统一贺卡文案常量（⑰）；修复端云路径错配（⑭/⑮）。

## 10.5 复现缺口总结

单凭本文档可 100% 复现：全部后端代码行为、全部 app 交互逻辑、数据库结构与种子数据、API 契约、prompt 与算法常量。需人工补录后才能运行：10.1 表中的密钥三项（QWEN_API_KEY/JWT_SECRET/DB 密码）与签名材料；可选补录：应用图标。除此之外无复现缺口。

<!-- SECTION 10 END -->

（全文完）
