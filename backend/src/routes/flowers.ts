import { Router, Request, Response } from 'express';
import { query } from '../config/database';
import { success, error, notFound, serverError } from '../utils/response';

const router = Router();

/**
 * GET /api/flowers/categories
 * 获取所有分类（必须在 /:id 之前定义，避免路由冲突）
 */
router.get('/categories', async (req: Request, res: Response) => {
  try {
    const result = await query(
      'SELECT DISTINCT category FROM flowers WHERE available = true ORDER BY category'
    );

    const categories = result.rows.map((row) => row.category);

    return success(res, categories, '获取分类列表成功');
  } catch (err) {
    console.error('[获取花材分类] 错误:', err);
    return serverError(res, '获取花材分类失败');
  }
});

/**
 * GET /api/flowers
 * 获取花材列表（支持查询参数：color, category, season, keyword, page, pageSize）
 */
router.get('/', async (req: Request, res: Response) => {
  try {
    const {
      color, category, season, keyword,
      page: pageStr, pageSize: pageSizeStr,
    } = req.query;

    const page = Math.max(1, parseInt(pageStr as string, 10) || 1);
    const pageSize = Math.min(50, Math.max(1, parseInt(pageSizeStr as string, 10) || 20));

    // 构建查询条件
    const conditions: string[] = ['available = true'];
    const values: any[] = [];
    let paramIndex = 1;

    if (color) {
      conditions.push(`color = $${paramIndex++}`);
      values.push(color);
    }
    if (category) {
      conditions.push(`category = $${paramIndex++}`);
      values.push(category);
    }
    if (season) {
      conditions.push(`season = $${paramIndex++}`);
      values.push(season);
    }
    if (keyword) {
      conditions.push(`(name LIKE $${paramIndex} OR name_en LIKE $${paramIndex} OR meaning LIKE $${paramIndex})`);
      values.push(`%${keyword}%`);
      paramIndex++;
    }

    const whereClause = conditions.length > 0 ? `WHERE ${conditions.join(' AND ')}` : '';

    // 查询总数
    const countResult = await query(
      `SELECT COUNT(*) as total FROM flowers ${whereClause}`,
      values
    );
    const total = parseInt(countResult.rows[0].total, 10);
    const totalPages = Math.ceil(total / pageSize);

    // 分页查询
    const offset = (page - 1) * pageSize;
    const dataResult = await query(
      `SELECT * FROM flowers ${whereClause} ORDER BY name LIMIT $${paramIndex++} OFFSET $${paramIndex}`,
      [...values, pageSize, offset]
    );

    return success(res, {
      items: dataResult.rows,
      pagination: { page, pageSize, total, totalPages },
    }, '获取花材列表成功');
  } catch (err) {
    console.error('[获取花材列表] 错误:', err);
    return serverError(res, '获取花材列表失败');
  }
});

/**
 * GET /api/flowers/:id
 * 获取花材详情
 */
router.get('/:id', async (req: Request, res: Response) => {
  try {
    const { id } = req.params;

    const result = await query(
      'SELECT * FROM flowers WHERE id = $1',
      [id]
    );

    if (result.rows.length === 0) {
      return notFound(res, '花材不存在');
    }

    return success(res, result.rows[0], '获取花材详情成功');
  } catch (err) {
    console.error('[获取花材详情] 错误:', err);
    return serverError(res, '获取花材详情失败');
  }
});

export default router;
