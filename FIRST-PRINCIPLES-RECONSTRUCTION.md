# Reconstruction Plan

## Core Problem
People who know nothing about flowers need help choosing the right bouquet fast.

## What Was Cut

| # | Over-Engineering | Action |
|---|---|---|
| 1 | 5-step wizard (30 fields) | → 3-field form (name, relationship, notes) |
| 2 | Redis caching (237 lines) | → Deleted entirely |
| 3 | Multi-strategy JSON parser | → Simple parse with one fallback |
| 4 | Dual-state cart (162 lines) | → Deleted cart entirely |
| 5 | 6-state order machine | → Simplified to 4 states |
| 6 | 13-field recipient profile | → 3 fields (name, relationship, notes) |
| 7 | 3-tier rate limiting | → Single global limiter |
| 8 | Mock data fallbacks | → Removed, errors surface properly |
| 9 | Bouquet templates table | → Deleted |
| 10 | Feedback table | → Deleted |

## Files Deleted (13)
- `backend/src/services/qwen/cacheService.ts`
- `backend/src/models/BouquetTemplate.ts`
- `backend/src/types/index.ts`
- `backend/src/scripts/init-db.ts`
- `app/.../store/CartStore.ets`
- `app/.../pages/CartPage.ets`
- `app/.../pages/OrderConfirmPage.ets`
- `app/.../pages/OrderListPage.ets`
- `app/.../pages/OrderDetailPage.ets`
- `app/.../pages/PaymentPage.ets`
- `app/.../pages/RecipientProfile.ets`
- `app/.../components/BouquetCard.ets`
- `app/.../components/StepIndicator.ets`

## Files Modified (17)
- `backend/package.json` — removed ioredis dependency
- `backend/.env.example` — removed Redis config
- `backend/database/init.sql` — removed feedback, bouquet_templates, simplified schema
- `backend/src/index.ts` — simplified startup
- `backend/src/middleware/rateLimiter.ts` — single limiter
- `backend/src/models/Recipient.ts` — 3 fields
- `backend/src/models/Order.ts` — 4 states
- `backend/src/routes/index.ts` — simplified
- `backend/src/routes/recommendations.ts` — simplified input
- `backend/src/routes/recipients.ts` — 3 fields
- `backend/src/routes/orders.ts` — simplified
- `backend/src/services/qwen/*` — all 5 files simplified
- `app/.../models/UserModel.ets` — simplified
- `app/.../models/RecommendModel.ets` — simplified
- `app/.../utils/Constants.ets` — removed order constants
- `app/.../pages/*` — all pages simplified

## Philosophy
Ship the 500 lines of actual value. Get users. Then earn the right to add complexity.
