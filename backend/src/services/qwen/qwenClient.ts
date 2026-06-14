import https from 'https';
import { URL } from 'url';
import { ChatMessage } from './types';

export class QwenApiError extends Error {
  public code: string;
  constructor(message: string, code: string = 'UNKNOWN') {
    super(message);
    this.name = 'QwenApiError';
    this.code = code;
  }
}

export class QwenClient {
  private apiKey: string;
  private apiUrl: string;
  private model: string;

  constructor() {
    this.apiKey = process.env.QWEN_API_KEY || '';
    this.apiUrl = process.env.QWEN_API_URL || 'https://dashscope.aliyuncs.com/compatible-mode/v1/chat/completions';
    this.model = process.env.QWEN_MODEL || 'qwen-plus';
    if (!this.apiKey) console.warn('[Qwen] QWEN_API_KEY not set');
  }

  async chat(messages: ChatMessage[]): Promise<string> {
    if (!this.apiKey) throw new QwenApiError('QWEN_API_KEY not configured', 'NO_API_KEY');
    const body = JSON.stringify({ model: this.model, messages, temperature: 0.8, max_tokens: 4096 });
    const url = new URL(this.apiUrl);

    return new Promise((resolve, reject) => {
      const req = https.request({
        hostname: url.hostname, port: 443, path: url.pathname,
        method: 'POST',
        headers: { 'Content-Type': 'application/json', 'Authorization': `Bearer ${this.apiKey}`, 'Content-Length': Buffer.byteLength(body) },
      }, (res) => {
        let data = '';
        res.on('data', (chunk) => data += chunk);
        res.on('end', () => {
          try {
            const parsed = JSON.parse(data);
            if (parsed.error) reject(new QwenApiError(parsed.error.message, parsed.error.code));
            else resolve(parsed.choices[0].message.content);
          } catch (e) { reject(new QwenApiError('Parse error')); }
        });
      });
      req.on('error', (e) => reject(new QwenApiError(e.message)));
      req.setTimeout(30000, () => { req.destroy(); reject(new QwenApiError('Timeout', 'TIMEOUT')); });
      req.write(body);
      req.end();
    });
  }
}

export const qwenClient = new QwenClient();
