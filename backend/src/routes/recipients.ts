import { Router, Request, Response } from 'express';
import { authMiddleware } from '../middleware/auth';
import { query } from '../config/database';
import { success, error, created, notFound, serverError, forbidden } from '../utils/response';
import { AuthRequest } from '../types';

const router = Router();
router.use(authMiddleware);

router.get('/', async (req: Request, res: Response) => {
  try {
    const authReq = req as AuthRequest;
    const result = await query(
      'SELECT * FROM recipients WHERE user_id = $1 ORDER BY created_at DESC',
      [authReq.user!.userId]
    );
    return success(res, result.rows);
  } catch (err) {
    return serverError(res, 'Failed to fetch recipients');
  }
});

router.post('/', async (req: Request, res: Response) => {
  try {
    const authReq = req as AuthRequest;
    const { name, relationship, notes } = req.body;
    if (!name || !relationship) return error(res, 'Name and relationship required', 400);

    const result = await query(
      'INSERT INTO recipients (user_id, name, relationship, notes) VALUES ($1, $2, $3, $4) RETURNING *',
      [authReq.user!.userId, name.trim(), relationship.trim(), notes || null]
    );
    return created(res, result.rows[0]);
  } catch (err) {
    return serverError(res, 'Failed to create recipient');
  }
});

router.put('/:id', async (req: Request, res: Response) => {
  try {
    const authReq = req as AuthRequest;
    const { id } = req.params;
    const existing = await query('SELECT user_id FROM recipients WHERE id = $1', [id]);
    if (existing.rows.length === 0) return notFound(res, 'Not found');
    if (existing.rows[0].user_id !== authReq.user!.userId) return forbidden(res, 'Forbidden');

    const { name, relationship, notes } = req.body;
    const result = await query(
      'UPDATE recipients SET name = COALESCE($1, name), relationship = COALESCE($2, relationship), notes = $3 WHERE id = $4 RETURNING *',
      [name, relationship, notes ?? null, id]
    );
    return success(res, result.rows[0]);
  } catch (err) {
    return serverError(res, 'Failed to update recipient');
  }
});

router.delete('/:id', async (req: Request, res: Response) => {
  try {
    const authReq = req as AuthRequest;
    const existing = await query('SELECT user_id FROM recipients WHERE id = $1', [req.params.id]);
    if (existing.rows.length === 0) return notFound(res, 'Not found');
    if (existing.rows[0].user_id !== authReq.user!.userId) return forbidden(res, 'Forbidden');
    await query('DELETE FROM recipients WHERE id = $1', [req.params.id]);
    return success(res, null, 'Deleted');
  } catch (err) {
    return serverError(res, 'Failed to delete recipient');
  }
});

export default router;
