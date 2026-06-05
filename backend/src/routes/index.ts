import { Router, Request, Response } from 'express';
import { success } from '../utils/response';
import authRoutes from './auth';
import recipientRoutes from './recipients';
import flowerRoutes from './flowers';
import recommendationRoutes from './recommendations';
import orderRoutes from './orders';

const router = Router();

// 健康检查
router.get('/health', (_req: Request, res: Response) => {
  success(res, {
    status: 'ok',
    timestamp: new Date().toISOString(),
    service: 'flower-backend',
  }, '服务运行正常');
});

// API版本前缀
router.use('/auth', authRoutes);
router.use('/recipients', recipientRoutes);
router.use('/flowers', flowerRoutes);
router.use('/recommendations', recommendationRoutes);
router.use('/orders', orderRoutes);

export default router;
