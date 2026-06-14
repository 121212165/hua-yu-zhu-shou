# 花语助手 - AI花束推荐

AI驱动的花束推荐应用。输入收花人信息和场景，获得个性化花束方案。

## 项目结构

```
├── app/          # HarmonyOS 前端 (ArkTS)
└── backend/      # Node.js 后端 (Express + TypeScript)
```

## 核心流程

1. 输入：收花人姓名 + 关系 + 送花场景 + 补充说明（可选）
2. AI生成：3套花束方案，含花材搭配、花语解读、贺卡文案
3. 浏览：花材库浏览（颜色/类别筛选）

## 技术栈

- **前端**: HarmonyOS / ArkTS
- **后端**: Node.js + Express + TypeScript + PostgreSQL
- **AI**: 通义千问 (qwen-plus)

## 启动

```bash
cd backend
cp .env.example .env
npm install
npm run dev
```
