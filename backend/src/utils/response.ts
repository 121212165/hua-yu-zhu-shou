import { Response } from 'express';
import { ApiResponse } from '../types';

/**
 * 成功响应
 */
export function success<T>(res: Response, data?: T, message: string = '操作成功', code: number = 200): Response {
  const response: ApiResponse<T> = {
    code,
    message,
    data,
  };
  return res.status(code).json(response);
}

/**
 * 创建成功响应 (201)
 */
export function created<T>(res: Response, data?: T, message: string = '创建成功'): Response {
  return success(res, data, message, 201);
}

/**
 * 错误响应
 */
export function error(res: Response, message: string = '操作失败', code: number = 400, errors?: any[]): Response {
  const response: ApiResponse = {
    code,
    message,
    ...(errors && { errors }),
  };
  return res.status(code).json(response);
}

/**
 * 未认证响应 (401)
 */
export function unauthorized(res: Response, message: string = '未认证，请先登录'): Response {
  return error(res, message, 401);
}

/**
 * 禁止访问响应 (403)
 */
export function forbidden(res: Response, message: string = '没有权限访问此资源'): Response {
  return error(res, message, 403);
}

/**
 * 资源未找到响应 (404)
 */
export function notFound(res: Response, message: string = '资源未找到'): Response {
  return error(res, message, 404);
}

/**
 * 服务器内部错误响应 (500)
 */
export function serverError(res: Response, message: string = '服务器内部错误'): Response {
  return error(res, message, 500);
}
