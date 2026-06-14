import dotenv from 'dotenv';
import express from 'express';
import cors from 'cors';
import { testConnection } from './config/database';
import { errorHandler, notFoundHandler } from './middleware/errorHandler';
import { apiLimiter } from './middleware/rateLimiter';
import routes from './routes';

dotenv.config();

const app = express();
const PORT = parseInt(process.env.PORT || '3001', 10);

app.use(cors({ origin: '*', credentials: true }));
app.use(express.json({ limit: '10mb' }));
app.use(apiLimiter);
app.use('/api', routes);
app.use(notFoundHandler);
app.use(errorHandler);

async function startServer() {
  const dbOk = await testConnection();
  if (!dbOk) console.warn('[Startup] DB connection failed, some features unavailable');

  app.listen(PORT, () => {
    console.log(`Flower backend running at http://localhost:${PORT}`);
  });
}

startServer();
export default app;
