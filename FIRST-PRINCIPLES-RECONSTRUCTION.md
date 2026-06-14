# First-Principles Reconstruction: hua-yu-zhu-shou

> Applied Elon Musk's first-principles thinking.

## Core Problem

People who know nothing about flowers need help choosing the right bouquet fast.

## 10 Over-Engineering Points

1. 5-step wizard with ~30 fields (3 fields suffice)
2. Redis caching (237 lines) for $0.001 API calls
3. Multi-strategy JSON parser (120+ lines) — fix the prompt
4. Dual-state cart (162 lines) — users buy one bouquet
5. 6-state order machine (254 lines) — managing fake orders
6. 13-field recipient profile — AI needs name + relationship + notes
7. 3-tier rate limiting for zero users
8. Frontend mock data fallbacks masking real failures
9. Bouquet templates table — unused by AI flow
10. Feedback table — collected, never acted on

## Musk's Razor

6,000+ lines → ~500 lines of actual value. Backend ~400 lines, Frontend ~800 lines. Ship the 500 lines, get users, then earn the right to add complexity.
