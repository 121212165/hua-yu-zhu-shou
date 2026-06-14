import { Router, Request, Response } from 'express';
import { success } from '../utils/response';
import authRoutes from './auth';
import recipientRoutes from './recipients';
import flowerRoutes from './flowers';
import recommendationRoutes from './recommendations';
import orderRoutes from './orders';

const router = Router();

router.get('/health', (_req: Request, res: Response) => {
  success(res, { status: 'ok', service: 'flower-backend' });
});

router.use('/auth', authRoutes);
router.use('/recipients', recipientRoutes);
router.use('/flowers', flowerRoutes);
router.use('/recommendations', recommendationRoutes);
router.use('/orders', orderRoutes);

export default router;
