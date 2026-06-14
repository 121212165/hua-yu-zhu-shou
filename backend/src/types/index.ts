import { Request } from 'express';

export interface JwtPayload {
  userId: string;
  phone: string;
}

export interface AuthRequest extends Request {
  user?: JwtPayload;
}

export interface ApiResponse<T = any> {
  code: number;
  message: string;
  data?: T;
  errors?: any[];
}
