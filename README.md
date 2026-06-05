# 花语助手 - 智能花束推荐应用

AI 驱动的花束定制推荐应用，基于收花人画像、场景和关系背景提供个性化花束方案。

## 项目结构

```
├── app/          # HarmonyOS 前端应用 (ArkTS)
└── backend/      # Node.js 后端服务 (Express + TypeScript)
```

## 技术栈

### 前端 (app/)
- HarmonyOS / ArkTS
- @ohos.net.http 网络请求
- @ohos.data.preferences 本地持久化
- Tab 导航 + 自定义组件体系

### 后端 (backend/)
- Node.js + Express + TypeScript
- PostgreSQL 数据库
- Redis 缓存
- 通义千问 AI 推荐引擎
- JWT 认证

## 功能模块

- 智能花束推荐（5 步引导式问卷 + AI 生成 3 套方案）
- 花材库浏览（颜色/类别/季节筛选）
- 收花人画像管理
- 购物车 + 订单管理
- 用户注册登录

## 启动

### 后端
```bash
cd backend
cp .env.example .env  # 配置数据库和 API 密钥
npm install
npm run dev
```

### 前端
使用 DevEco Studio 打开 `app/` 目录，连接设备或模拟器运行。
