import rateLimit from 'express-rate-limit';

/**
 * 通用API限流 - 每分钟100次请求
 */
export const apiLimiter = rateLimit({
  windowMs: 60 * 1000,
  max: 100,
  message: {
    code: 429,
    message: '请求过于频繁，请稍后再试',
  },
  standardHeaders: true,
  legacyHeaders: false,
  keyGenerator: (req) => {
    return req.ip || 'unknown';
  },
});

/**
 * 认证相关限流 - 每分钟5次请求（防暴力破解）
 */
export const authLimiter = rateLimit({
  windowMs: 60 * 1000,
  max: 5,
  message: {
    code: 429,
    message: '登录尝试过于频繁，请1分钟后再试',
  },
  standardHeaders: true,
  legacyHeaders: false,
  keyGenerator: (req) => {
    return req.ip || 'unknown';
  },
});

/**
 * AI推荐限流 - 每分钟10次请求
 */
export const aiLimiter = rateLimit({
  windowMs: 60 * 1000,
  max: 10,
  message: {
    code: 429,
    message: 'AI推荐请求过于频繁，请稍后再试',
  },
  standardHeaders: true,
  legacyHeaders: false,
  keyGenerator: (req) => {
    return req.ip || 'unknown';
  },
});
