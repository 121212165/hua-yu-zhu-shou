import crypto from 'crypto';
import Redis from 'ioredis';
import { RecommendationInput, BouquetPlan, CacheEntry } from './types';

/** 缓存配置 */
interface CacheConfig {
  host: string;
  port: number;
  password: string;
  db: number;
  ttl: number;  // 缓存有效期（秒）
  keyPrefix: string;
}

/**
 * Redis缓存服务
 * 为AI推荐结果提供缓存层，避免重复调用API
 * 如果Redis不可用，自动降级为无缓存模式
 */
export class CacheService {
  private redis: Redis | null = null;
  private config: CacheConfig;
  private isConnected: boolean = false;
  private connectionPromise: Promise<void> | null = null;

  constructor() {
    this.config = {
      host: process.env.REDIS_HOST || 'localhost',
      port: parseInt(process.env.REDIS_PORT || '6379', 10),
      password: process.env.REDIS_PASSWORD || '',
      db: parseInt(process.env.REDIS_DB || '0', 10),
      ttl: 4 * 60 * 60,  // 4小时，单位秒
      keyPrefix: 'flower:rec:',
    };

    this.initConnection();
  }

  /**
   * 初始化Redis连接
   */
  private initConnection(): void {
    try {
      const redisOptions: any = {
        host: this.config.host,
        port: this.config.port,
        db: this.config.db,
        retryStrategy: (times: number) => {
          // 最多重试5次，间隔递增
          if (times > 5) {
            console.warn('[Redis缓存] 连接重试次数已达上限，降级为无缓存模式');
            return null; // 停止重试
          }
          return Math.min(times * 1000, 5000);
        },
        maxRetriesPerRequest: 2,
        enableReadyCheck: true,
        lazyConnect: true, // 延迟连接，首次使用时才连接
      };

      // 有密码时才设置
      if (this.config.password) {
        redisOptions.password = this.config.password;
      }

      this.redis = new Redis(redisOptions);

      this.redis.on('ready', () => {
        this.isConnected = true;
        console.log('[Redis缓存] 连接成功');
      });

      this.redis.on('error', (err) => {
        this.isConnected = false;
        // 只在非连接阶段打印错误，避免启动时刷屏
        if (this.isConnected) {
          console.warn('[Redis缓存] 连接错误:', err.message);
        }
      });

      this.redis.on('close', () => {
        this.isConnected = false;
      });

      // 尝试连接
      this.connectionPromise = this.redis.connect().catch((err) => {
        console.warn(`[Redis缓存] 连接失败，将使用无缓存模式: ${err.message}`);
        this.isConnected = false;
      });
    } catch (err) {
      console.warn(`[Redis缓存] 初始化失败，将使用无缓存模式: ${(err as Error).message}`);
      this.redis = null;
      this.isConnected = false;
    }
  }

  /**
   * 获取缓存
   * @param input 推荐输入参数
   * @returns 缓存的推荐方案，无缓存返回null
   */
  async get(input: RecommendationInput): Promise<BouquetPlan[] | null> {
    if (!this.redis || !this.isConnected) {
      return null;
    }

    try {
      const key = this.generateKey(input);
      const cached = await this.redis.get(key);

      if (!cached) {
        return null;
      }

      const entry: CacheEntry = JSON.parse(cached);

      // 检查缓存是否过期（双重检查，虽然Redis TTL已经处理）
      if (Date.now() - entry.cachedAt > this.config.ttl * 1000) {
        await this.redis.del(key);
        return null;
      }

      console.log(`[Redis缓存] 命中缓存: ${key}`);
      return entry.plans;
    } catch (err) {
      console.warn(`[Redis缓存] 读取缓存失败: ${(err as Error).message}`);
      return null;
    }
  }

  /**
   * 设置缓存
   * @param input 推荐输入参数
   * @param plans 推荐方案
   */
  async set(input: RecommendationInput, plans: BouquetPlan[]): Promise<void> {
    if (!this.redis || !this.isConnected) {
      return;
    }

    try {
      const key = this.generateKey(input);
      const entry: CacheEntry = {
        plans,
        cachedAt: Date.now(),
        inputHash: this.hashInput(input),
      };

      await this.redis.setex(key, this.config.ttl, JSON.stringify(entry));
      console.log(`[Redis缓存] 已缓存: ${key}，有效期${this.config.ttl / 3600}小时`);
    } catch (err) {
      console.warn(`[Redis缓存] 写入缓存失败: ${(err as Error).message}`);
      // 缓存写入失败不影响主流程
    }
  }

  /**
   * 删除指定缓存
   */
  async delete(input: RecommendationInput): Promise<void> {
    if (!this.redis || !this.isConnected) {
      return;
    }

    try {
      const key = this.generateKey(input);
      await this.redis.del(key);
    } catch (err) {
      console.warn(`[Redis缓存] 删除缓存失败: ${(err as Error).message}`);
    }
  }

  /**
   * 清除所有推荐缓存
   */
  async clearAll(): Promise<void> {
    if (!this.redis || !this.isConnected) {
      return;
    }

    try {
      const pattern = `${this.config.keyPrefix}*`;
      const keys = await this.redis.keys(pattern);
      if (keys.length > 0) {
        await this.redis.del(...keys);
        console.log(`[Redis缓存] 已清除${keys.length}条缓存`);
      }
    } catch (err) {
      console.warn(`[Redis缓存] 清除缓存失败: ${(err as Error).message}`);
    }
  }

  /**
   * 检查缓存服务是否可用
   */
  isAvailable(): boolean {
    return this.isConnected && this.redis !== null;
  }

  /**
   * 生成缓存Key
   * 基于输入参数生成唯一的MD5 hash
   */
  private generateKey(input: RecommendationInput): string {
    const hash = this.hashInput(input);
    return `${this.config.keyPrefix}${hash}`;
  }

  /**
   * 对输入参数进行MD5 hash
   * 确保相同输入生成相同的key
   */
  private hashInput(input: RecommendationInput): string {
    // 将输入序列化为确定性字符串（排序key保证一致性）
    const normalized = JSON.stringify(input, Object.keys(input).sort());
    return crypto.createHash('md5').update(normalized, 'utf8').digest('hex');
  }

  /**
   * 关闭Redis连接
   */
  async disconnect(): Promise<void> {
    if (this.redis) {
      try {
        await this.redis.quit();
      } catch {
        // 忽略关闭错误
      }
      this.redis = null;
      this.isConnected = false;
    }
  }
}

/** 导出单例 */
export const cacheService = new CacheService();
