import { Router, Request, Response } from 'express';
import { authMiddleware } from '../middleware/auth';
import { query } from '../config/database';
import { success, error, created, notFound, serverError, forbidden } from '../utils/response';
import { AuthRequest } from '../types';

const router = Router();

// 所有订单接口都需要认证
router.use(authMiddleware);

/**
 * POST /api/orders
 * 创建订单（关联recommendation_id, 选择的方案index, 配送信息）
 */
router.post('/', async (req: Request, res: Response) => {
  try {
    const authReq = req as AuthRequest;
    const userId = authReq.user!.userId;
    const {
      recommendation_id, selected_plan_index,
      total_price, delivery_address, delivery_time,
      greeting_card_message,
    } = req.body;

    // 必填字段验证
    if (!delivery_address || typeof delivery_address !== 'string' || delivery_address.trim().length === 0) {
      return error(res, '配送地址不能为空', 400);
    }
    if (total_price === undefined || typeof total_price !== 'number' || total_price <= 0) {
      return error(res, '订单金额必须大于0', 400);
    }

    // 如果关联了推荐记录，验证其存在性和所有权
    if (recommendation_id) {
      const recResult = await query(
        'SELECT user_id, ai_response FROM recommendations WHERE id = $1',
        [recommendation_id]
      );

      if (recResult.rows.length === 0) {
        return notFound(res, '推荐记录不存在');
      }

      if (recResult.rows[0].user_id !== userId) {
        return forbidden(res, '无权使用此推荐记录');
      }

      // 更新推荐记录的selected_plan_index
      if (selected_plan_index !== undefined) {
        await query(
          'UPDATE recommendations SET selected_plan_index = $1 WHERE id = $2',
          [selected_plan_index, recommendation_id]
        );
      }
    }

    // 创建订单
    const result = await query(
      `INSERT INTO orders (user_id, recommendation_id, status, total_price, delivery_address, delivery_time, greeting_card_message)
       VALUES ($1, $2, 'pending', $3, $4, $5, $6)
       RETURNING *`,
      [
        userId,
        recommendation_id || null,
        total_price,
        delivery_address.trim(),
        delivery_time || null,
        greeting_card_message || null,
      ]
    );

    return created(res, result.rows[0], '创建订单成功');
  } catch (err) {
    console.error('[创建订单] 错误:', err);
    return serverError(res, '创建订单失败');
  }
});

/**
 * GET /api/orders
 * 获取用户订单列表（分页，支持状态筛选）
 */
router.get('/', async (req: Request, res: Response) => {
  try {
    const authReq = req as AuthRequest;
    const userId = authReq.user!.userId;
    const { status, page: pageStr, pageSize: pageSizeStr } = req.query;

    const page = Math.max(1, parseInt(pageStr as string, 10) || 1);
    const pageSize = Math.min(50, Math.max(1, parseInt(pageSizeStr as string, 10) || 10));

    // 构建查询条件
    const conditions: string[] = ['o.user_id = $1'];
    const values: any[] = [userId];
    let paramIndex = 2;

    const validStatuses = ['pending', 'paid', 'preparing', 'delivering', 'completed', 'cancelled'];
    if (status && validStatuses.includes(status as string)) {
      conditions.push(`o.status = $${paramIndex++}`);
      values.push(status);
    }

    const whereClause = `WHERE ${conditions.join(' AND ')}`;

    // 查询总数
    const countResult = await query(
      `SELECT COUNT(*) as total FROM orders o ${whereClause}`,
      values
    );
    const total = parseInt(countResult.rows[0].total, 10);
    const totalPages = Math.ceil(total / pageSize);

    // 分页查询
    const offset = (page - 1) * pageSize;
    const dataResult = await query(
      `SELECT o.* FROM orders o ${whereClause} ORDER BY o.created_at DESC LIMIT $${paramIndex++} OFFSET $${paramIndex}`,
      [...values, pageSize, offset]
    );

    return success(res, {
      items: dataResult.rows,
      pagination: { page, pageSize, total, totalPages },
    }, '获取订单列表成功');
  } catch (err) {
    console.error('[获取订单列表] 错误:', err);
    return serverError(res, '获取订单列表失败');
  }
});

/**
 * GET /api/orders/:id
 * 获取订单详情
 */
router.get('/:id', async (req: Request, res: Response) => {
  try {
    const authReq = req as AuthRequest;
    const userId = authReq.user!.userId;
    const { id } = req.params;

    const result = await query(
      'SELECT * FROM orders WHERE id = $1',
      [id]
    );

    if (result.rows.length === 0) {
      return notFound(res, '订单不存在');
    }

    if (result.rows[0].user_id !== userId) {
      return forbidden(res, '无权访问此订单');
    }

    return success(res, result.rows[0], '获取订单详情成功');
  } catch (err) {
    console.error('[获取订单详情] 错误:', err);
    return serverError(res, '获取订单详情失败');
  }
});

/**
 * PUT /api/orders/:id/status
 * 更新订单状态（模拟）
 */
router.put('/:id/status', async (req: Request, res: Response) => {
  try {
    const authReq = req as AuthRequest;
    const userId = authReq.user!.userId;
    const { id } = req.params;
    const { status } = req.body;

    // 验证订单存在且属于当前用户
    const existing = await query('SELECT user_id, status FROM orders WHERE id = $1', [id]);
    if (existing.rows.length === 0) {
      return notFound(res, '订单不存在');
    }
    if (existing.rows[0].user_id !== userId) {
      return forbidden(res, '无权修改此订单');
    }

    // 验证状态值
    const validStatuses = ['pending', 'paid', 'preparing', 'delivering', 'completed', 'cancelled'];
    if (!status || !validStatuses.includes(status)) {
      return error(res, `状态值无效，可选值：${validStatuses.join(', ')}`, 400);
    }

    // 状态流转验证（模拟）
    const currentStatus = existing.rows[0].status;
    const statusFlow: Record<string, string[]> = {
      pending: ['paid', 'cancelled'],
      paid: ['preparing', 'cancelled'],
      preparing: ['delivering', 'cancelled'],
      delivering: ['completed'],
      completed: [],
      cancelled: [],
    };

    const allowedNext = statusFlow[currentStatus] || [];
    if (!allowedNext.includes(status)) {
      return error(res, `订单状态不能从"${currentStatus}"变更为"${status}"`, 400);
    }

    const result = await query(
      'UPDATE orders SET status = $1 WHERE id = $2 RETURNING *',
      [status, id]
    );

    return success(res, result.rows[0], '更新订单状态成功');
  } catch (err) {
    console.error('[更新订单状态] 错误:', err);
    return serverError(res, '更新订单状态失败');
  }
});

/**
 * PUT /api/orders/:id/cancel
 * 取消订单
 */
router.put('/:id/cancel', async (req: Request, res: Response) => {
  try {
    const authReq = req as AuthRequest;
    const userId = authReq.user!.userId;
    const { id } = req.params;

    // 验证订单存在且属于当前用户
    const existing = await query('SELECT user_id, status FROM orders WHERE id = $1', [id]);
    if (existing.rows.length === 0) {
      return notFound(res, '订单不存在');
    }
    if (existing.rows[0].user_id !== userId) {
      return forbidden(res, '无权取消此订单');
    }

    const currentStatus = existing.rows[0].status;

    // 只有特定状态可以取消
    const cancellableStatuses = ['pending', 'paid', 'preparing'];
    if (!cancellableStatuses.includes(currentStatus)) {
      return error(res, `订单状态为"${currentStatus}"，无法取消`, 400);
    }

    const result = await query(
      'UPDATE orders SET status = $1 WHERE id = $2 RETURNING *',
      ['cancelled', id]
    );

    return success(res, result.rows[0], '取消订单成功');
  } catch (err) {
    console.error('[取消订单] 错误:', err);
    return serverError(res, '取消订单失败');
  }
});

export default router;
