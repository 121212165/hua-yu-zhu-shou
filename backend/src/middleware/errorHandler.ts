import { Request, Response, NextFunction } from 'express';
import { ApiResponse } from '../types';

/**
 * 统一错误处理中间件
 */
export function errorHandler(err: Error, req: Request, res: Response, next: NextFunction): void {
  console.error(`[错误] ${req.method} ${req.path}:`, err.message);

  // 处理JSON解析错误
  if (err.name === 'SyntaxError' && 'body' in err) {
    const response: ApiResponse = {
      code: 400,
      message: '请求体JSON格式错误',
      errors: [err.message],
    };
    res.status(400).json(response);
    return;
  }

  // 处理验证错误
  if (err.name === 'ValidationError') {
    const response: ApiResponse = {
      code: 422,
      message: '数据验证失败',
      errors: [err.message],
    };
    res.status(422).json(response);
    return;
  }

  // 默认服务器错误
  const response: ApiResponse = {
    code: 500,
    message: process.env.NODE_ENV === 'production' ? '服务器内部错误' : err.message,
    ...(process.env.NODE_ENV !== 'production' && { errors: [err.stack] }),
  };
  res.status(500).json(response);
}

/**
 * 404处理中间件
 */
export function notFoundHandler(req: Request, res: Response): void {
  const response: ApiResponse = {
    code: 404,
    message: `接口不存在: ${req.method} ${req.path}`,
  };
  res.status(404).json(response);
}
