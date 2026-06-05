import { Request, Response, NextFunction } from 'express';
import jwt from 'jsonwebtoken';
import { AuthRequest, JwtPayload } from '../types';
import { unauthorized, error } from '../utils/response';

/**
 * JWT认证中间件
 * 验证Authorization Bearer token，解析用户ID注入req
 */
export function authMiddleware(req: Request, res: Response, next: NextFunction): void {
  const authReq = req as AuthRequest;

  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    unauthorized(res, '缺少认证令牌，请在Authorization头中提供Bearer token');
    return;
  }

  const token = authHeader.split(' ')[1];
  if (!token) {
    unauthorized(res, '认证令牌格式错误');
    return;
  }

  try {
    const secret = process.env.JWT_SECRET || 'default_secret';
    const decoded = jwt.verify(token, secret) as JwtPayload;
    authReq.user = {
      userId: decoded.userId,
      phone: decoded.phone,
    };
    next();
  } catch (err) {
    if (err instanceof jwt.TokenExpiredError) {
      unauthorized(res, '认证令牌已过期，请重新登录');
      return;
    }
    if (err instanceof jwt.JsonWebTokenError) {
      unauthorized(res, '认证令牌无效');
      return;
    }
    error(res, '认证失败', 401);
  }
}

/**
 * 可选认证中间件
 * 如果提供了token则解析，否则不拦截
 */
export function optionalAuth(req: Request, res: Response, next: NextFunction): void {
  const authReq = req as AuthRequest;

  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    next();
    return;
  }

  const token = authHeader.split(' ')[1];
  if (!token) {
    next();
    return;
  }

  try {
    const secret = process.env.JWT_SECRET || 'default_secret';
    const decoded = jwt.verify(token, secret) as JwtPayload;
    authReq.user = {
      userId: decoded.userId,
      phone: decoded.phone,
    };
  } catch {
    // 可选认证，忽略错误
  }

  next();
}
