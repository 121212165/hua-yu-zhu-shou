import { Router, Request, Response } from 'express';
import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import { authLimiter } from '../middleware/rateLimiter';
import { authMiddleware } from '../middleware/auth';
import { query } from '../config/database';
import { success, error, created, serverError } from '../utils/response';
import { AuthRequest } from '../types';

const router = Router();

/**
 * POST /api/auth/register
 * 用户注册（手机号+密码+昵称）
 */
router.post('/register', authLimiter, async (req: Request, res: Response) => {
  try {
    const { phone, password, nickname } = req.body;

    // 输入验证
    if (!phone || !password) {
      return error(res, '手机号和密码不能为空', 400);
    }
    if (!/^1[3-9]\d{9}$/.test(phone)) {
      return error(res, '手机号格式不正确', 400);
    }
    if (password.length < 6) {
      return error(res, '密码长度不能少于6位', 400);
    }

    // 检查手机号是否已注册
    const existing = await query('SELECT id FROM users WHERE phone = $1', [phone]);
    if (existing.rows.length > 0) {
      return error(res, '该手机号已注册', 409);
    }

    // bcryptjs加密密码
    const salt = await bcrypt.genSalt(10);
    const password_hash = await bcrypt.hash(password, salt);

    // 插入用户
    const result = await query(
      'INSERT INTO users (phone, password_hash, nickname) VALUES ($1, $2, $3) RETURNING id, phone, nickname, avatar, created_at, updated_at',
      [phone, password_hash, nickname || null]
    );

    const user = result.rows[0];

    // 生成JWT token
    const token = jwt.sign(
      { userId: user.id, phone: user.phone },
      process.env.JWT_SECRET || 'default_secret',
      { expiresIn: '7d' }
    );

    return created(res, { token, user }, '注册成功');
  } catch (err) {
    console.error('[注册] 错误:', err);
    return serverError(res, '注册失败');
  }
});

/**
 * POST /api/auth/login
 * 用户登录（手机号+密码）
 */
router.post('/login', authLimiter, async (req: Request, res: Response) => {
  try {
    const { phone, password } = req.body;

    // 输入验证
    if (!phone || !password) {
      return error(res, '手机号和密码不能为空', 400);
    }

    // 查找用户
    const result = await query(
      'SELECT id, phone, password_hash, nickname, avatar, created_at, updated_at FROM users WHERE phone = $1',
      [phone]
    );

    if (result.rows.length === 0) {
      return error(res, '手机号或密码错误', 401);
    }

    const user = result.rows[0];

    // 验证密码
    const isPasswordValid = await bcrypt.compare(password, user.password_hash);
    if (!isPasswordValid) {
      return error(res, '手机号或密码错误', 401);
    }

    // 生成JWT token
    const token = jwt.sign(
      { userId: user.id, phone: user.phone },
      process.env.JWT_SECRET || 'default_secret',
      { expiresIn: '7d' }
    );

    // 返回token和用户信息（排除password_hash）
    const { password_hash, ...userInfo } = user;
    return success(res, { token, user: userInfo }, '登录成功');
  } catch (err) {
    console.error('[登录] 错误:', err);
    return serverError(res, '登录失败');
  }
});

/**
 * GET /api/auth/profile
 * 获取当前用户信息（需认证）
 */
router.get('/profile', authMiddleware, async (req: Request, res: Response) => {
  try {
    const authReq = req as AuthRequest;
    const userId = authReq.user!.userId;

    const result = await query(
      'SELECT id, phone, nickname, avatar, created_at, updated_at FROM users WHERE id = $1',
      [userId]
    );

    if (result.rows.length === 0) {
      return error(res, '用户不存在', 404);
    }

    return success(res, result.rows[0], '获取用户信息成功');
  } catch (err) {
    console.error('[获取用户信息] 错误:', err);
    return serverError(res, '获取用户信息失败');
  }
});

/**
 * PUT /api/auth/profile
 * 更新用户信息（需认证）
 */
router.put('/profile', authMiddleware, async (req: Request, res: Response) => {
  try {
    const authReq = req as AuthRequest;
    const userId = authReq.user!.userId;
    const { nickname, avatar } = req.body;

    // 构建更新字段
    const updates: string[] = [];
    const values: any[] = [];
    let paramIndex = 1;

    if (nickname !== undefined) {
      if (typeof nickname !== 'string' || nickname.length > 50) {
        return error(res, '昵称格式不正确（最长50字符）', 400);
      }
      updates.push(`nickname = $${paramIndex++}`);
      values.push(nickname);
    }

    if (avatar !== undefined) {
      if (typeof avatar !== 'string' || avatar.length > 500) {
        return error(res, '头像URL格式不正确', 400);
      }
      updates.push(`avatar = $${paramIndex++}`);
      values.push(avatar);
    }

    if (updates.length === 0) {
      return error(res, '没有需要更新的字段', 400);
    }

    values.push(userId);

    const result = await query(
      `UPDATE users SET ${updates.join(', ')} WHERE id = $${paramIndex} RETURNING id, phone, nickname, avatar, created_at, updated_at`,
      values
    );

    if (result.rows.length === 0) {
      return error(res, '用户不存在', 404);
    }

    return success(res, result.rows[0], '更新用户信息成功');
  } catch (err) {
    console.error('[更新用户信息] 错误:', err);
    return serverError(res, '更新用户信息失败');
  }
});

export default router;
