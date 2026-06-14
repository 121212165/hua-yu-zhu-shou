import { Router, Request, Response } from 'express';
import { authMiddleware } from '../middleware/auth';
import { query } from '../config/database';
import { success, error, created, notFound, serverError, forbidden } from '../utils/response';
import { AuthRequest } from '../types';

const router = Router();
router.use(authMiddleware);

router.post('/', async (req: Request, res: Response) => {
  try {
    const authReq = req as AuthRequest;
    const { recommendation_id, total_price, delivery_address } = req.body;

    if (!delivery_address?.trim()) return error(res, 'Delivery address required', 400);
    if (!total_price || total_price <= 0) return error(res, 'Invalid price', 400);

    const result = await query(
      `INSERT INTO orders (user_id, recommendation_id, status, total_price, delivery_address)
       VALUES ($1, $2, 'pending', $3, $4) RETURNING *`,
      [authReq.user!.userId, recommendation_id || null, total_price, delivery_address.trim()]
    );
    return created(res, result.rows[0]);
  } catch (err) {
    return serverError(res, 'Failed to create order');
  }
});

router.get('/', async (req: Request, res: Response) => {
  try {
    const authReq = req as AuthRequest;
    const page = Math.max(1, parseInt(req.query.page as string, 10) || 1);
    const pageSize = Math.min(50, parseInt(req.query.pageSize as string, 10) || 10);
    const offset = (page - 1) * pageSize;
    const { status } = req.query;

    let where = 'WHERE user_id = $1';
    const values: any[] = [authReq.user!.userId];
    if (status) { where += ' AND status = $2'; values.push(status); }

    const countResult = await query(`SELECT COUNT(*) as total FROM orders ${where}`, values);
    const total = parseInt(countResult.rows[0].total, 10);

    const dataResult = await query(
      `SELECT * FROM orders ${where} ORDER BY created_at DESC LIMIT $${values.length + 1} OFFSET $${values.length + 2}`,
      [...values, pageSize, offset]
    );

    return success(res, { items: dataResult.rows, pagination: { page, pageSize, total, totalPages: Math.ceil(total / pageSize) } });
  } catch (err) {
    return serverError(res, 'Failed to fetch orders');
  }
});

router.get('/:id', async (req: Request, res: Response) => {
  try {
    const authReq = req as AuthRequest;
    const result = await query('SELECT * FROM orders WHERE id = $1', [req.params.id]);
    if (result.rows.length === 0) return notFound(res, 'Not found');
    if (result.rows[0].user_id !== authReq.user!.userId) return forbidden(res, 'Forbidden');
    return success(res, result.rows[0]);
  } catch (err) {
    return serverError(res, 'Failed to fetch order');
  }
});

router.put('/:id/cancel', async (req: Request, res: Response) => {
  try {
    const authReq = req as AuthRequest;
    const result = await query('SELECT user_id, status FROM orders WHERE id = $1', [req.params.id]);
    if (result.rows.length === 0) return notFound(res, 'Not found');
    if (result.rows[0].user_id !== authReq.user!.userId) return forbidden(res, 'Forbidden');
    if (!['pending', 'paid'].includes(result.rows[0].status)) return error(res, 'Cannot cancel', 400);

    const updated = await query('UPDATE orders SET status = $1 WHERE id = $2 RETURNING *', ['cancelled', req.params.id]);
    return success(res, updated.rows[0]);
  } catch (err) {
    return serverError(res, 'Failed to cancel order');
  }
});

export default router;
