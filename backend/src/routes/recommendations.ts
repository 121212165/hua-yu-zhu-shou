import { Router, Request, Response } from 'express';
import { authMiddleware } from '../middleware/auth';
import { query } from '../config/database';
import { success, error, created, notFound, serverError, forbidden } from '../utils/response';
import { AuthRequest } from '../types';
import { recommendationService } from '../services/qwen';

const router = Router();
router.use(authMiddleware);

router.post('/generate', async (req: Request, res: Response) => {
  try {
    const authReq = req as AuthRequest;
    const userId = authReq.user!.userId;
    const { recipientId, occasion, recipientName, recipientRelationship, notes, budget } = req.body;

    if (!occasion) return error(res, 'Occasion required', 400);

    let name = recipientName || '匿名';
    let relationship = recipientRelationship || '朋友';
    let recipientIdToSave: string | null = null;
    let recipientNotes = notes || null;

    if (recipientId) {
      const result = await query('SELECT * FROM recipients WHERE id = $1', [recipientId]);
      if (result.rows.length === 0) return notFound(res, 'Recipient not found');
      if (result.rows[0].user_id !== userId) return forbidden(res, 'Forbidden');
      name = result.rows[0].name;
      relationship = result.rows[0].relationship;
      recipientNotes = result.rows[0].notes || recipientNotes;
      recipientIdToSave = result.rows[0].id;
    } else {
      const created_recipient = await query(
        'INSERT INTO recipients (user_id, name, relationship, notes) VALUES ($1, $2, $3, $4) RETURNING id',
        [userId, name, relationship, recipientNotes]
      );
      recipientIdToSave = created_recipient.rows[0].id;
    }

    const plans = await recommendationService.generate({
      recipientInfo: { name, relationship, notes: recipientNotes || undefined },
      occasion,
      budget: budget || undefined,
    });

    const saved = await query(
      `INSERT INTO recommendations (user_id, recipient_id, occasion, input_context, ai_response)
       VALUES ($1, $2, $3, $4, $5) RETURNING id, created_at`,
      [userId, recipientIdToSave, occasion, JSON.stringify({ recipientInfo: { name, relationship } }), JSON.stringify(plans)]
    );

    return created(res, { recommendation: saved.rows[0], plans }, 'Generated');
  } catch (err) {
    console.error('[Recommend] Error:', err);
    return serverError(res, 'Recommendation failed');
  }
});

router.get('/', async (req: Request, res: Response) => {
  try {
    const authReq = req as AuthRequest;
    const userId = authReq.user!.userId;
    const page = Math.max(1, parseInt(req.query.page as string, 10) || 1);
    const pageSize = Math.min(50, parseInt(req.query.pageSize as string, 10) || 10);
    const offset = (page - 1) * pageSize;

    const countResult = await query('SELECT COUNT(*) as total FROM recommendations WHERE user_id = $1', [userId]);
    const total = parseInt(countResult.rows[0].total, 10);

    const dataResult = await query(
      `SELECT r.*, rec.name as recipient_name FROM recommendations r
       LEFT JOIN recipients rec ON r.recipient_id = rec.id
       WHERE r.user_id = $1 ORDER BY r.created_at DESC LIMIT $2 OFFSET $3`,
      [userId, pageSize, offset]
    );

    return success(res, { items: dataResult.rows, pagination: { page, pageSize, total, totalPages: Math.ceil(total / pageSize) } });
  } catch (err) {
    console.error('[Recommendations] Error:', err);
    return serverError(res, 'Failed to fetch recommendations');
  }
});

router.get('/:id', async (req: Request, res: Response) => {
  try {
    const authReq = req as AuthRequest;
    const userId = authReq.user!.userId;
    const result = await query(
      `SELECT r.*, rec.name as recipient_name FROM recommendations r
       LEFT JOIN recipients rec ON r.recipient_id = rec.id WHERE r.id = $1`,
      [req.params.id]
    );
    if (result.rows.length === 0) return notFound(res, 'Not found');
    if (result.rows[0].user_id !== userId) return forbidden(res, 'Forbidden');
    return success(res, result.rows[0]);
  } catch (err) {
    return serverError(res, 'Failed to fetch recommendation');
  }
});

export default router;
