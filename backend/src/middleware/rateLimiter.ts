import rateLimit from 'express-rate-limit';

export const apiLimiter = rateLimit({
  windowMs: 60 * 1000,
  max: 100,
  message: { code: 429, message: 'Too many requests' },
  standardHeaders: true,
  legacyHeaders: false,
});
