import dotenv from 'dotenv';
import express from 'express';
import cors from 'cors';
import { testConnection } from './config/database';
import { errorHandler, notFoundHandler } from './middleware/errorHandler';
import { apiLimiter } from './middleware/rateLimiter';
import routes from './routes';

// 加载环境变量
dotenv.config();

const app = express();
const PORT = parseInt(process.env.PORT || '3001', 10);

// ==================== 中间件配置 ====================

// CORS跨域
app.use(cors({
  origin: process.env.NODE_ENV === 'production'
    ? ['https://your-domain.com']
    : ['http://localhost:3000', 'http://localhost:5173'],
  credentials: true,
}));

// JSON解析
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true }));

// 全局限流
app.use(apiLimiter);

// 请求日志
app.use((req, _res, next) => {
  console.log(`[请求] ${req.method} ${req.path} - ${req.ip}`);
  next();
});

// ==================== 路由挂载 ====================

app.use('/api', routes);

// ==================== 错误处理 ====================

// 404处理
app.use(notFoundHandler);

// 统一错误处理
app.use(errorHandler);

// ==================== 启动服务器 ====================

async function startServer() {
  try {
    // 测试数据库连接
    const dbConnected = await testConnection();
    if (!dbConnected) {
      console.warn('[启动] 数据库连接失败，部分功能可能不可用');
    }

    app.listen(PORT, () => {
      console.log(`[启动] 花语心选后端服务运行在 http://localhost:${PORT}`);
      console.log(`[启动] 环境: ${process.env.NODE_ENV || 'development'}`);
      console.log(`[启动] API文档: http://localhost:${PORT}/api/health`);
    });
  } catch (err) {
    console.error('[启动] 服务器启动失败:', err);
    process.exit(1);
  }
}

startServer();

export default app;
