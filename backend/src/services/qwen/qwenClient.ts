import https from 'https';
import http from 'http';
import { URL } from 'url';
import { ChatMessage, QwenChatRequest, QwenResponse, QwenStreamResponse, QwenErrorResponse } from './types';

/** 客户端配置 */
interface QwenClientConfig {
  apiKey: string;
  apiUrl: string;
  model: string;
  timeout: number;        // 请求超时时间（毫秒）
  maxRetries: number;     // 最大重试次数
}

/** 流式回调类型 */
export type StreamCallback = (chunk: string, done: boolean) => void;

/** 自定义错误类型 */
export class QwenApiError extends Error {
  public code: string;
  public statusCode: number;

  constructor(message: string, code: string = 'UNKNOWN', statusCode: number = 500) {
    super(message);
    this.name = 'QwenApiError';
    this.code = code;
    this.statusCode = statusCode;
  }
}

/**
 * 通义千问API客户端
 * 使用OpenAI兼容格式调用通义千问API
 */
export class QwenClient {
  private config: QwenClientConfig;

  constructor() {
    this.config = {
      apiKey: process.env.QWEN_API_KEY || '',
      apiUrl: process.env.QWEN_API_URL || 'https://dashscope.aliyuncs.com/compatible-mode/v1/chat/completions',
      model: process.env.QWEN_MODEL || 'qwen-plus',
      timeout: 30000,
      maxRetries: 2,
    };

    if (!this.config.apiKey) {
      console.warn('[通义千问] 未配置QWEN_API_KEY，AI推荐功能将不可用');
    }
  }

  /**
   * 检查API Key是否已配置
   */
  isConfigured(): boolean {
    return !!this.config.apiKey;
  }

  /**
   * 非流式聊天请求
   * @param messages 消息数组
   * @param options 可选请求参数
   * @returns API响应
   */
  async chat(
    messages: ChatMessage[],
    options?: { temperature?: number; max_tokens?: number; top_p?: number }
  ): Promise<QwenResponse> {
    if (!this.isConfigured()) {
      throw new QwenApiError('未配置QWEN_API_KEY，请设置环境变量后重试', 'NO_API_KEY', 401);
    }

    const requestBody: QwenChatRequest = {
      model: this.config.model,
      messages,
      temperature: options?.temperature ?? 0.7,
      top_p: options?.top_p ?? 0.9,
      max_tokens: options?.max_tokens ?? 4096,
      stream: false,
    };

    return this.requestWithRetry<QwenResponse>(requestBody);
  }

  /**
   * 流式聊天请求
   * @param messages 消息数组
   * @param onChunk 流式数据回调
   * @param options 可选请求参数
   * @returns 完整的拼接文本
   */
  async chatStream(
    messages: ChatMessage[],
    onChunk: StreamCallback,
    options?: { temperature?: number; max_tokens?: number; top_p?: number }
  ): Promise<string> {
    if (!this.isConfigured()) {
      throw new QwenApiError('未配置QWEN_API_KEY，请设置环境变量后重试', 'NO_API_KEY', 401);
    }

    const requestBody: QwenChatRequest = {
      model: this.config.model,
      messages,
      temperature: options?.temperature ?? 0.7,
      top_p: options?.top_p ?? 0.9,
      max_tokens: options?.max_tokens ?? 4096,
      stream: true,
    };

    return this.streamRequest(requestBody, onChunk);
  }

  /**
   * 带重试的请求
   */
  private async requestWithRetry<T>(requestBody: QwenChatRequest): Promise<T> {
    let lastError: Error | null = null;

    for (let attempt = 0; attempt <= this.config.maxRetries; attempt++) {
      try {
        return await this.sendRequest<T>(requestBody);
      } catch (err) {
        lastError = err as Error;

        // 不可重试的错误直接抛出
        if (err instanceof QwenApiError) {
          if (err.code === 'NO_API_KEY' || err.code === 'INVALID_REQUEST' || err.statusCode === 401) {
            throw err;
          }
        }

        // 最后一轮不等待
        if (attempt < this.config.maxRetries) {
          const delay = Math.min(1000 * Math.pow(2, attempt), 5000);
          console.warn(`[通义千问] 请求失败，${delay}ms后第${attempt + 1}次重试: ${(err as Error).message}`);
          await this.sleep(delay);
        }
      }
    }

    throw lastError || new QwenApiError('请求失败，已达到最大重试次数', 'MAX_RETRIES', 500);
  }

  /**
   * 发送HTTP请求（非流式）
   */
  private sendRequest<T>(requestBody: QwenChatRequest): Promise<T> {
    return new Promise((resolve, reject) => {
      const url = new URL(this.config.apiUrl);
      const postData = JSON.stringify(requestBody);

      const options = {
        hostname: url.hostname,
        port: url.port || 443,
        path: url.pathname + url.search,
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${this.config.apiKey}`,
          'Content-Length': Buffer.byteLength(postData),
        },
      };

      const httpModule = url.protocol === 'https:' ? https : http;

      const req = httpModule.request(options, (res) => {
        let data = '';

        res.on('data', (chunk: Buffer) => {
          data += chunk.toString();
        });

        res.on('end', () => {
          try {
            const parsed = JSON.parse(data);

            // 检查API错误响应
            if (parsed.error) {
              const errorResp = parsed as QwenErrorResponse;
              const errorMsg = errorResp.error.message || '未知API错误';
              const errorCode = errorResp.error.code || 'API_ERROR';

              // 常见错误码映射
              if (errorCode === 'InsufficientBalance' || errorMsg.includes('余额')) {
                reject(new QwenApiError('通义千问API余额不足，请充值后重试', 'INSUFFICIENT_BALANCE', 402));
                return;
              }
              if (res.statusCode === 429) {
                reject(new QwenApiError('API请求频率超限，请稍后重试', 'RATE_LIMITED', 429));
                return;
              }
              if (res.statusCode === 401) {
                reject(new QwenApiError('API Key无效或已过期', 'INVALID_API_KEY', 401));
                return;
              }

              reject(new QwenApiError(errorMsg, errorCode, res.statusCode || 500));
              return;
            }

            resolve(parsed as T);
          } catch (parseErr) {
            reject(new QwenApiError(`API响应解析失败: ${(parseErr as Error).message}`, 'PARSE_ERROR', 500));
          }
        });
      });

      // 超时处理
      req.setTimeout(this.config.timeout, () => {
        req.destroy();
        reject(new QwenApiError(`请求超时（${this.config.timeout / 1000}秒）`, 'TIMEOUT', 408));
      });

      // 网络错误处理
      req.on('error', (err) => {
        reject(new QwenApiError(`网络请求失败: ${err.message}`, 'NETWORK_ERROR', 503));
      });

      req.write(postData);
      req.end();
    });
  }

  /**
   * 流式请求
   */
  private async streamRequest(requestBody: QwenChatRequest, onChunk: StreamCallback): Promise<string> {
    return new Promise((resolve, reject) => {
      const url = new URL(this.config.apiUrl);
      const postData = JSON.stringify(requestBody);
      let fullContent = '';

      const options = {
        hostname: url.hostname,
        port: url.port || 443,
        path: url.pathname + url.search,
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${this.config.apiKey}`,
          'Content-Length': Buffer.byteLength(postData),
        },
      };

      const httpModule = url.protocol === 'https:' ? https : http;

      const req = httpModule.request(options, (res) => {
        let buffer = '';

        res.on('data', (chunk: Buffer) => {
          buffer += chunk.toString();
          const lines = buffer.split('\n');
          // 保留最后一个可能不完整的行
          buffer = lines.pop() || '';

          for (const line of lines) {
            const trimmed = line.trim();
            if (!trimmed || trimmed === 'data: [DONE]') {
              continue;
            }
            if (trimmed.startsWith('data: ')) {
              try {
                const jsonStr = trimmed.slice(6);
                const parsed: QwenStreamResponse = JSON.parse(jsonStr);

                // 检查错误
                if ((parsed as any).error) {
                  const errResp = parsed as unknown as QwenErrorResponse;
                  reject(new QwenApiError(errResp.error.message || '流式请求错误', errResp.error.code || 'STREAM_ERROR', 500));
                  req.destroy();
                  return;
                }

                const delta = parsed.choices?.[0]?.delta;
                if (delta?.content) {
                  fullContent += delta.content;
                  onChunk(delta.content, false);
                }
              } catch {
                // 忽略无法解析的行
              }
            }
          }
        });

        res.on('end', () => {
          // 处理buffer中剩余的数据
          if (buffer.trim() && buffer.trim() !== 'data: [DONE]') {
            const trimmed = buffer.trim();
            if (trimmed.startsWith('data: ')) {
              try {
                const jsonStr = trimmed.slice(6);
                if (jsonStr !== '[DONE]') {
                  const parsed: QwenStreamResponse = JSON.parse(jsonStr);
                  const delta = parsed.choices?.[0]?.delta;
                  if (delta?.content) {
                    fullContent += delta.content;
                  }
                }
              } catch {
                // 忽略
              }
            }
          }
          onChunk('', true);
          resolve(fullContent);
        });
      });

      req.setTimeout(this.config.timeout, () => {
        req.destroy();
        reject(new QwenApiError(`流式请求超时（${this.config.timeout / 1000}秒）`, 'TIMEOUT', 408));
      });

      req.on('error', (err) => {
        reject(new QwenApiError(`流式网络请求失败: ${err.message}`, 'NETWORK_ERROR', 503));
      });

      req.write(postData);
      req.end();
    });
  }

  /**
   * 工具方法：延迟
   */
  private sleep(ms: number): Promise<void> {
    return new Promise((resolve) => setTimeout(resolve, ms));
  }
}

/** 导出单例 */
export const qwenClient = new QwenClient();
