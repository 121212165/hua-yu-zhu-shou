import { Router, Request, Response } from 'express';
import { authMiddleware } from '../middleware/auth';
import { aiLimiter } from '../middleware/rateLimiter';
import { query } from '../config/database';
import { success, error, created, notFound, serverError, forbidden } from '../utils/response';
import { AuthRequest } from '../types';
import { recommendationService, RecommendationError } from '../services/qwen';
import { RecommendationInput, BouquetPlan } from '../services/qwen/types';

const router = Router();

// 所有推荐接口都需要认证
router.use(authMiddleware);

/**
 * POST /api/recommendations/generate
 * 生成AI推荐
 */
router.post('/generate', aiLimiter, async (req: Request, res: Response) => {
  try {
    const authReq = req as AuthRequest;
    const userId = authReq.user!.userId;
    const {
      recipientId, occasion, relationshipContext, culturalFactors,
      recipientProfile, preferences, budget, additionalNotes,
    } = req.body;

    // 必填字段验证
    if (!occasion) {
      return error(res, '送花场景不能为空', 400);
    }

    // 构建推荐输入
    let recommendationInput: RecommendationInput;
    let recipientIdToSave: string;

    if (recipientId) {
      // 从数据库读取收花人档案
      const recipientResult = await query(
        'SELECT * FROM recipients WHERE id = $1',
        [recipientId]
      );

      if (recipientResult.rows.length === 0) {
        return notFound(res, '收花人不存在');
      }

      const recipient = recipientResult.rows[0];

      // 权限校验
      if (recipient.user_id !== userId) {
        return forbidden(res, '无权访问此收花人档案');
      }

      recipientIdToSave = recipient.id;

      recommendationInput = {
        recipientInfo: {
          name: recipient.name,
          gender: recipient.gender || undefined,
          age: recipient.age || undefined,
          relationship: recipient.relationship,
        },
        occasion,
        relationshipContext: {
          duration: recipient.relationship_duration || undefined,
          previousFlowers: undefined,
          recentEvents: undefined,
        },
        culturalFactors: {
          taboos: undefined,
          customs: recipient.cultural_notes || undefined,
        },
        recipientProfile: {
          interests: recipient.interests || undefined,
          career: recipient.career || undefined,
          personality: recipient.personality || undefined,
        },
        preferences: {
          favoriteColors: recipient.color_preference || undefined,
          style: recipient.style_preference || undefined,
          allergies: recipient.allergies || undefined,
        },
        budget: budget ? { min: budget.min || 50, max: budget.max || 500 } : undefined,
        additionalNotes: additionalNotes || recipient.notes || undefined,
      };
    } else {
      // 没有recipientId，使用请求体中的数据
      // 需要创建一个临时收花人记录以满足数据库NOT NULL约束
      if (!recipientProfile && !req.body.recipientInfo) {
        return error(res, '请提供recipientId或recipientProfile/recipientInfo', 400);
      }

      const recipientInfo = req.body.recipientInfo || {
        name: recipientProfile?.name || '匿名收花人',
        gender: recipientProfile?.gender,
        age: recipientProfile?.age,
        relationship: relationshipContext?.relationship || '朋友',
      };

      // 创建临时收花人记录
      const createResult = await query(
        `INSERT INTO recipients (user_id, name, gender, age, relationship, relationship_duration,
          interests, personality, career, color_preference, style_preference, allergies, cultural_notes, notes)
         VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14)
         RETURNING id`,
        [
          userId,
          recipientInfo.name || '匿名收花人',
          recipientInfo.gender || null,
          recipientInfo.age || null,
          recipientInfo.relationship || '朋友',
          relationshipContext?.duration || null,
          recipientProfile?.interests || null,
          recipientProfile?.personality || null,
          recipientProfile?.career || null,
          preferences?.favoriteColors || null,
          preferences?.style || null,
          preferences?.allergies || null,
          culturalFactors?.taboos || culturalFactors?.customs || null,
          additionalNotes || null,
        ]
      );

      recipientIdToSave = createResult.rows[0].id;

      recommendationInput = {
        recipientInfo: {
          name: recipientInfo.name || '匿名收花人',
          gender: recipientInfo.gender || undefined,
          age: recipientInfo.age || undefined,
          relationship: recipientInfo.relationship || '朋友',
        },
        occasion,
        relationshipContext: relationshipContext || undefined,
        culturalFactors: culturalFactors || undefined,
        recipientProfile: recipientProfile ? {
          interests: recipientProfile.interests,
          career: recipientProfile.career,
          personality: recipientProfile.personality,
        } : undefined,
        preferences: preferences ? {
          favoriteColors: preferences.favoriteColors,
          style: preferences.style,
          allergies: preferences.allergies,
        } : undefined,
        budget: budget ? { min: budget.min || 50, max: budget.max || 500 } : undefined,
        additionalNotes: additionalNotes || undefined,
      };
    }

    // 合并请求体中额外提供的字段（覆盖从DB读取的值）
    if (relationshipContext && recipientId) {
      recommendationInput.relationshipContext = {
        ...recommendationInput.relationshipContext,
        ...relationshipContext,
      };
    }
    if (culturalFactors && recipientId) {
      recommendationInput.culturalFactors = {
        ...recommendationInput.culturalFactors,
        ...culturalFactors,
      };
    }
    if (recipientProfile && recipientId) {
      recommendationInput.recipientProfile = {
        ...recommendationInput.recipientProfile,
        ...recipientProfile,
      };
    }
    if (preferences && recipientId) {
      recommendationInput.preferences = {
        ...recommendationInput.preferences,
        ...preferences,
      };
    }

    // 调用AI推荐服务
    let plans: BouquetPlan[];
    try {
      plans = await recommendationService.generateRecommendation(recommendationInput);
    } catch (aiErr) {
      if (aiErr instanceof RecommendationError) {
        return error(res, `AI推荐失败: ${aiErr.message}`, 500);
      }
      throw aiErr;
    }

    // 保存推荐记录到数据库
    const inputContext = {
      occasion,
      relationshipContext: recommendationInput.relationshipContext,
      culturalFactors: recommendationInput.culturalFactors,
      recipientProfile: recommendationInput.recipientProfile,
      preferences: recommendationInput.preferences,
      budget: recommendationInput.budget,
      additionalNotes: recommendationInput.additionalNotes,
    };

    const saveResult = await query(
      `INSERT INTO recommendations (user_id, recipient_id, occasion, input_context, ai_response)
       VALUES ($1, $2, $3, $4, $5)
       RETURNING id, user_id, recipient_id, occasion, input_context, ai_response, selected_plan_index, created_at`,
      [userId, recipientIdToSave, occasion, JSON.stringify(inputContext), JSON.stringify(plans)]
    );

    const recommendation = saveResult.rows[0];

    return created(res, {
      recommendation,
      plans,
    }, 'AI推荐生成成功');
  } catch (err) {
    console.error('[AI推荐] 错误:', err);
    return serverError(res, 'AI推荐生成失败');
  }
});

/**
 * GET /api/recommendations
 * 获取用户历史推荐列表（分页）
 */
router.get('/', async (req: Request, res: Response) => {
  try {
    const authReq = req as AuthRequest;
    const userId = authReq.user!.userId;

    const page = Math.max(1, parseInt(req.query.page as string, 10) || 1);
    const pageSize = Math.min(50, Math.max(1, parseInt(req.query.pageSize as string, 10) || 10));

    // 查询总数
    const countResult = await query(
      'SELECT COUNT(*) as total FROM recommendations WHERE user_id = $1',
      [userId]
    );
    const total = parseInt(countResult.rows[0].total, 10);
    const totalPages = Math.ceil(total / pageSize);

    // 分页查询
    const offset = (page - 1) * pageSize;
    const dataResult = await query(
      `SELECT r.*, rec.name as recipient_name
       FROM recommendations r
       LEFT JOIN recipients rec ON r.recipient_id = rec.id
       WHERE r.user_id = $1
       ORDER BY r.created_at DESC
       LIMIT $2 OFFSET $3`,
      [userId, pageSize, offset]
    );

    return success(res, {
      items: dataResult.rows,
      pagination: { page, pageSize, total, totalPages },
    }, '获取推荐历史成功');
  } catch (err) {
    console.error('[获取推荐历史] 错误:', err);
    return serverError(res, '获取推荐历史失败');
  }
});

/**
 * GET /api/recommendations/:id
 * 获取推荐详情
 */
router.get('/:id', async (req: Request, res: Response) => {
  try {
    const authReq = req as AuthRequest;
    const userId = authReq.user!.userId;
    const { id } = req.params;

    const result = await query(
      `SELECT r.*, rec.name as recipient_name
       FROM recommendations r
       LEFT JOIN recipients rec ON r.recipient_id = rec.id
       WHERE r.id = $1`,
      [id]
    );

    if (result.rows.length === 0) {
      return notFound(res, '推荐记录不存在');
    }

    if (result.rows[0].user_id !== userId) {
      return forbidden(res, '无权访问此推荐记录');
    }

    return success(res, result.rows[0], '获取推荐详情成功');
  } catch (err) {
    console.error('[获取推荐详情] 错误:', err);
    return serverError(res, '获取推荐详情失败');
  }
});

/**
 * POST /api/recommendations/:id/feedback
 * 提交反馈评分
 */
router.post('/:id/feedback', async (req: Request, res: Response) => {
  try {
    const authReq = req as AuthRequest;
    const userId = authReq.user!.userId;
    const { id } = req.params;
    const { rating, comment } = req.body;

    // 验证推荐记录存在且属于当前用户
    const recResult = await query(
      'SELECT user_id FROM recommendations WHERE id = $1',
      [id]
    );

    if (recResult.rows.length === 0) {
      return notFound(res, '推荐记录不存在');
    }

    if (recResult.rows[0].user_id !== userId) {
      return forbidden(res, '无权对此推荐记录提交反馈');
    }

    // 输入验证
    if (!rating || typeof rating !== 'number' || rating < 1 || rating > 5) {
      return error(res, '评分必须为1-5的整数', 400);
    }

    if (!Number.isInteger(rating)) {
      return error(res, '评分必须为整数', 400);
    }

    // 检查是否已提交过反馈
    const existingFeedback = await query(
      'SELECT id FROM user_feedback WHERE recommendation_id = $1 AND user_id = $2',
      [id, userId]
    );

    if (existingFeedback.rows.length > 0) {
      return error(res, '已对此推荐提交过反馈', 409);
    }

    // 保存反馈
    const result = await query(
      `INSERT INTO user_feedback (user_id, recommendation_id, rating, comment)
       VALUES ($1, $2, $3, $4)
       RETURNING id, user_id, recommendation_id, rating, comment, created_at`,
      [userId, id, rating, comment || null]
    );

    return created(res, result.rows[0], '提交反馈成功');
  } catch (err) {
    console.error('[提交反馈] 错误:', err);
    return serverError(res, '提交反馈失败');
  }
});

export default router;
