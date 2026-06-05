import { Router, Request, Response } from 'express';
import { authMiddleware } from '../middleware/auth';
import { query } from '../config/database';
import { success, error, created, notFound, serverError, forbidden } from '../utils/response';
import { AuthRequest } from '../types';

const router = Router();

// 所有收花人接口都需要认证
router.use(authMiddleware);

/**
 * GET /api/recipients
 * 获取当前用户的所有收花人列表（需认证）
 */
router.get('/', async (req: Request, res: Response) => {
  try {
    const authReq = req as AuthRequest;
    const userId = authReq.user!.userId;

    const result = await query(
      'SELECT * FROM recipients WHERE user_id = $1 ORDER BY created_at DESC',
      [userId]
    );

    return success(res, result.rows, '获取收花人列表成功');
  } catch (err) {
    console.error('[获取收花人列表] 错误:', err);
    return serverError(res, '获取收花人列表失败');
  }
});

/**
 * GET /api/recipients/:id
 * 获取单个收花人详情
 */
router.get('/:id', async (req: Request, res: Response) => {
  try {
    const authReq = req as AuthRequest;
    const userId = authReq.user!.userId;
    const { id } = req.params;

    const result = await query(
      'SELECT * FROM recipients WHERE id = $1',
      [id]
    );

    if (result.rows.length === 0) {
      return notFound(res, '收花人不存在');
    }

    // 权限校验：只能查看自己的收花人
    if (result.rows[0].user_id !== userId) {
      return forbidden(res, '无权访问此收花人档案');
    }

    return success(res, result.rows[0], '获取收花人详情成功');
  } catch (err) {
    console.error('[获取收花人详情] 错误:', err);
    return serverError(res, '获取收花人详情失败');
  }
});

/**
 * POST /api/recipients
 * 创建收花人档案
 */
router.post('/', async (req: Request, res: Response) => {
  try {
    const authReq = req as AuthRequest;
    const userId = authReq.user!.userId;
    const {
      name, gender, age, relationship, relationship_duration,
      interests, personality, career, color_preference,
      style_preference, allergies, cultural_notes, notes,
    } = req.body;

    // 必填字段验证
    if (!name || typeof name !== 'string' || name.trim().length === 0) {
      return error(res, '收花人姓名不能为空', 400);
    }
    if (!relationship || typeof relationship !== 'string' || relationship.trim().length === 0) {
      return error(res, '与收花人的关系不能为空', 400);
    }

    // 类型验证
    if (gender && !['male', 'female', 'other'].includes(gender)) {
      return error(res, '性别字段无效，可选值：male, female, other', 400);
    }
    if (age !== undefined && (typeof age !== 'number' || age < 0 || age > 200)) {
      return error(res, '年龄格式不正确', 400);
    }

    const result = await query(
      `INSERT INTO recipients (user_id, name, gender, age, relationship, relationship_duration,
        interests, personality, career, color_preference, style_preference, allergies, cultural_notes, notes)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14)
       RETURNING *`,
      [
        userId, name.trim(), gender || null, age || null, relationship.trim(),
        relationship_duration || null, interests || null, personality || null,
        career || null, color_preference || null, style_preference || null,
        allergies || null, cultural_notes || null, notes || null,
      ]
    );

    return created(res, result.rows[0], '创建收花人成功');
  } catch (err) {
    console.error('[创建收花人] 错误:', err);
    return serverError(res, '创建收花人失败');
  }
});

/**
 * PUT /api/recipients/:id
 * 更新收花人档案
 */
router.put('/:id', async (req: Request, res: Response) => {
  try {
    const authReq = req as AuthRequest;
    const userId = authReq.user!.userId;
    const { id } = req.params;

    // 先检查存在性和权限
    const existing = await query('SELECT user_id FROM recipients WHERE id = $1', [id]);
    if (existing.rows.length === 0) {
      return notFound(res, '收花人不存在');
    }
    if (existing.rows[0].user_id !== userId) {
      return forbidden(res, '无权修改此收花人档案');
    }

    const {
      name, gender, age, relationship, relationship_duration,
      interests, personality, career, color_preference,
      style_preference, allergies, cultural_notes, notes,
    } = req.body;

    // 类型验证
    if (gender && !['male', 'female', 'other'].includes(gender)) {
      return error(res, '性别字段无效，可选值：male, female, other', 400);
    }
    if (age !== undefined && age !== null && (typeof age !== 'number' || age < 0 || age > 200)) {
      return error(res, '年龄格式不正确', 400);
    }

    // 构建动态更新
    const updates: string[] = [];
    const values: any[] = [];
    let paramIndex = 1;

    const fields: Record<string, any> = {
      name: name !== undefined ? (typeof name === 'string' ? name.trim() : name) : undefined,
      gender: gender !== undefined ? gender : undefined,
      age: age !== undefined ? age : undefined,
      relationship: relationship !== undefined ? (typeof relationship === 'string' ? relationship.trim() : relationship) : undefined,
      relationship_duration,
      interests,
      personality,
      career,
      color_preference,
      style_preference,
      allergies,
      cultural_notes,
      notes,
    };

    for (const [key, value] of Object.entries(fields)) {
      if (value !== undefined) {
        updates.push(`${key} = $${paramIndex++}`);
        values.push(value);
      }
    }

    if (updates.length === 0) {
      return error(res, '没有需要更新的字段', 400);
    }

    values.push(id);

    const result = await query(
      `UPDATE recipients SET ${updates.join(', ')} WHERE id = $${paramIndex} RETURNING *`,
      values
    );

    return success(res, result.rows[0], '更新收花人成功');
  } catch (err) {
    console.error('[更新收花人] 错误:', err);
    return serverError(res, '更新收花人失败');
  }
});

/**
 * DELETE /api/recipients/:id
 * 删除收花人
 */
router.delete('/:id', async (req: Request, res: Response) => {
  try {
    const authReq = req as AuthRequest;
    const userId = authReq.user!.userId;
    const { id } = req.params;

    // 先检查存在性和权限
    const existing = await query('SELECT user_id FROM recipients WHERE id = $1', [id]);
    if (existing.rows.length === 0) {
      return notFound(res, '收花人不存在');
    }
    if (existing.rows[0].user_id !== userId) {
      return forbidden(res, '无权删除此收花人档案');
    }

    await query('DELETE FROM recipients WHERE id = $1', [id]);

    return success(res, null, '删除收花人成功');
  } catch (err) {
    console.error('[删除收花人] 错误:', err);
    return serverError(res, '删除收花人失败');
  }
});

export default router;
