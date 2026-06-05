import { Pool, PoolConfig } from 'pg';

const poolConfig: PoolConfig = {
  host: process.env.DB_HOST || 'localhost',
  port: parseInt(process.env.DB_PORT || '5432', 10),
  database: process.env.DB_NAME || 'flower_db',
  user: process.env.DB_USER || 'postgres',
  password: process.env.DB_PASSWORD || '',
  max: 20,
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 2000,
};

const pool = new Pool(poolConfig);

pool.on('error', (err) => {
  console.error('[数据库] 连接池发生意外错误:', err.message);
});

/**
 * 执行SQL查询
 */
export async function query(text: string, params?: any[]) {
  const start = Date.now();
  const result = await pool.query(text, params);
  const duration = Date.now() - start;
  console.log(`[数据库] 执行查询: ${text.slice(0, 80)}... 耗时: ${duration}ms, 行数: ${result.rowCount}`);
  return result;
}

/**
 * 获取数据库连接池
 */
export function getPool(): Pool {
  return pool;
}

/**
 * 测试数据库连接
 */
export async function testConnection(): Promise<boolean> {
  try {
    const client = await pool.connect();
    client.release();
    console.log('[数据库] 连接成功');
    return true;
  } catch (err) {
    console.error('[数据库] 连接失败:', (err as Error).message);
    return false;
  }
}

export default pool;
