import { qwenClient, QwenApiError } from './qwenClient';
import { buildMessages, getSceneEnhancement } from './prompts';
import { cacheService } from './cacheService';
import { RecommendationInput, BouquetPlan, ChatMessage } from './types';

/** 推荐服务配置 */
const RECOMMENDATION_CONFIG = {
  maxPlans: 3,                    // 必须返回的方案数
  maxRetries: 1,                  // 解析失败最大重试次数
  defaultBudgetMin: 50,           // 默认最低预算
  defaultBudgetMax: 500,          // 默认最高预算
  priceTolerancePercent: 0.15,    // 价格超出预算的容忍度（15%）
};

/**
 * 推荐服务错误
 */
export class RecommendationError extends Error {
  public code: string;
  public retryable: boolean;

  constructor(message: string, code: string, retryable: boolean = false) {
    super(message);
    this.name = 'RecommendationError';
    this.code = code;
    this.retryable = retryable;
  }
}

/**
 * AI推荐服务
 * 核心业务逻辑：组装Prompt → 调用通义千问 → 解析结果 → 验证 → 缓存
 */
export class RecommendationService {
  /**
   * 生成花束推荐方案
   * @param input 推荐输入参数
   * @returns 3个花束推荐方案
   */
  async generateRecommendation(input: RecommendationInput): Promise<BouquetPlan[]> {
    // 1. 参数预处理
    this.validateInput(input);
    const normalizedInput = this.normalizeInput(input);

    // 2. 检查缓存
    try {
      const cached = await cacheService.get(normalizedInput);
      if (cached && cached.length > 0) {
        console.log('[推荐服务] 命中缓存，直接返回');
        return cached;
      }
    } catch {
      // 缓存读取失败不影响主流程
    }

    // 3. 构建消息（含场景增强）
    const enhancement = getSceneEnhancement(input.occasion, input.additionalNotes);
    let messages = buildMessages(normalizedInput);

    // 如果有场景增强，注入到system prompt中
    if (enhancement) {
      messages = this.injectEnhancement(messages, enhancement);
    }

    // 4. 调用通义千问API
    let rawContent: string;
    try {
      console.log('[推荐服务] 开始调用通义千问API...');
      const response = await qwenClient.chat(messages, {
        temperature: 0.8,  // 适中的创造性
        max_tokens: 4096,
      });

      const choice = response.choices?.[0];
      if (!choice?.message?.content) {
        throw new RecommendationError('AI返回了空内容', 'EMPTY_RESPONSE', true);
      }

      rawContent = choice.message.content;
      console.log(`[推荐服务] API调用成功，token使用: ${response.usage?.total_tokens || '未知'}`);
    } catch (err) {
      if (err instanceof QwenApiError) {
        throw new RecommendationError(
          `通义千问API调用失败: ${err.message}`,
          err.code,
          err.code !== 'INSUFFICIENT_BALANCE' && err.code !== 'INVALID_API_KEY'
        );
      }
      throw new RecommendationError(
        `AI服务异常: ${(err as Error).message}`,
        'AI_SERVICE_ERROR',
        true
      );
    }

    // 5. 解析AI响应
    let plans: BouquetPlan[];
    try {
      plans = this.parseAiResponse(rawContent);
    } catch (parseErr) {
      // 解析失败时，尝试一次重试
      console.warn(`[推荐服务] 响应解析失败，尝试重试: ${(parseErr as Error).message}`);
      try {
        const retryMessages: ChatMessage[] = [
          ...messages,
          { role: 'assistant', content: rawContent },
          {
            role: 'user',
            content: '你刚才的返回格式不正确，请严格按照JSON格式返回，不要添加markdown标记或其他多余文字。只返回包含plans数组的JSON对象。',
          },
        ];

        const retryResponse = await qwenClient.chat(retryMessages, {
          temperature: 0.3,  // 降低温度以获取更规范的输出
          max_tokens: 4096,
        });

        const retryContent = retryResponse.choices?.[0]?.message?.content;
        if (!retryContent) {
          throw new RecommendationError('重试后AI仍返回空内容', 'RETRY_EMPTY_RESPONSE', false);
        }

        plans = this.parseAiResponse(retryContent);
      } catch (retryErr) {
        if (retryErr instanceof RecommendationError) {
          throw retryErr;
        }
        throw new RecommendationError(
          `AI响应格式异常，重试后仍无法解析: ${(retryErr as Error).message}`,
          'PARSE_FAILED_AFTER_RETRY',
          false
        );
      }
    }

    // 6. 结果验证和修正
    plans = this.validateAndFixPlans(plans, normalizedInput);

    // 7. 写入缓存
    try {
      await cacheService.set(normalizedInput, plans);
    } catch {
      // 缓存写入失败不影响主流程
    }

    console.log(`[推荐服务] 成功生成${plans.length}个推荐方案`);
    return plans;
  }

  /**
   * 输入参数验证
   */
  private validateInput(input: RecommendationInput): void {
    if (!input.recipientInfo?.name) {
      throw new RecommendationError('收花人姓名不能为空', 'INVALID_INPUT', false);
    }
    if (!input.recipientInfo?.relationship) {
      throw new RecommendationError('与收花人的关系不能为空', 'INVALID_INPUT', false);
    }
    if (!input.occasion) {
      throw new RecommendationError('送花场景不能为空', 'INVALID_INPUT', false);
    }
    if (input.budget) {
      if (input.budget.min < 0 || input.budget.max < 0) {
        throw new RecommendationError('预算不能为负数', 'INVALID_INPUT', false);
      }
      if (input.budget.min > input.budget.max) {
        throw new RecommendationError('最低预算不能高于最高预算', 'INVALID_INPUT', false);
      }
    }
  }

  /**
   * 输入参数标准化
   * 填充默认值，规范化格式
   */
  private normalizeInput(input: RecommendationInput): RecommendationInput {
    return {
      ...input,
      occasion: input.occasion.trim(),
      recipientInfo: {
        ...input.recipientInfo,
        name: input.recipientInfo.name.trim(),
        relationship: input.recipientInfo.relationship.trim(),
      },
      budget: input.budget || {
        min: RECOMMENDATION_CONFIG.defaultBudgetMin,
        max: RECOMMENDATION_CONFIG.defaultBudgetMax,
      },
      additionalNotes: input.additionalNotes?.trim() || undefined,
    };
  }

  /**
   * 将场景增强注入到system prompt中
   */
  private injectEnhancement(messages: ChatMessage[], enhancement: string): ChatMessage[] {
    return messages.map((msg) => {
      if (msg.role === 'system') {
        return {
          ...msg,
          content: msg.content + '\n\n## 本次推荐的特殊注意\n' + enhancement,
        };
      }
      return msg;
    });
  }

  /**
   * 解析AI返回的文本为BouquetPlan数组
   * 包含多种容错策略
   */
  private parseAiResponse(content: string): BouquetPlan[] {
    // 策略1：直接解析整个响应
    try {
      const parsed = JSON.parse(content);
      if (parsed.plans && Array.isArray(parsed.plans)) {
        return this.validatePlansStructure(parsed.plans);
      }
      // 可能直接返回的是数组
      if (Array.isArray(parsed)) {
        return this.validatePlansStructure(parsed);
      }
    } catch {
      // 直接解析失败，尝试提取
    }

    // 策略2：提取JSON代码块（```json ... ```）
    const codeBlockMatch = content.match(/```(?:json)?\s*\n?([\s\S]*?)\n?\s*```/);
    if (codeBlockMatch) {
      try {
        const parsed = JSON.parse(codeBlockMatch[1]);
        if (parsed.plans && Array.isArray(parsed.plans)) {
          return this.validatePlansStructure(parsed.plans);
        }
        if (Array.isArray(parsed)) {
          return this.validatePlansStructure(parsed);
        }
      } catch {
        // 代码块解析失败
      }
    }

    // 策略3：提取最外层的花括号内容
    const braceMatch = this.extractOutermostBraces(content);
    if (braceMatch) {
      try {
        const parsed = JSON.parse(braceMatch);
        if (parsed.plans && Array.isArray(parsed.plans)) {
          return this.validatePlansStructure(parsed.plans);
        }
        if (Array.isArray(parsed)) {
          return this.validatePlansStructure(parsed);
        }
      } catch {
        // 花括号提取解析失败
      }
    }

    // 策略4：修复常见JSON格式问题
    const fixedJson = this.attemptJsonRepair(content);
    if (fixedJson) {
      try {
        const parsed = JSON.parse(fixedJson);
        if (parsed.plans && Array.isArray(parsed.plans)) {
          return this.validatePlansStructure(parsed.plans);
        }
        if (Array.isArray(parsed)) {
          return this.validatePlansStructure(parsed);
        }
      } catch {
        // 修复后仍解析失败
      }
    }

    throw new RecommendationError(
      '无法从AI响应中解析出有效的花束推荐方案',
      'PARSE_ERROR',
      true
    );
  }

  /**
   * 提取最外层花括号内容
   */
  private extractOutermostBraces(text: string): string | null {
    const firstBrace = text.indexOf('{');
    const lastBrace = text.lastIndexOf('}');

    if (firstBrace === -1 || lastBrace === -1 || firstBrace >= lastBrace) {
      // 尝试数组
      const firstBracket = text.indexOf('[');
      const lastBracket = text.lastIndexOf(']');
      if (firstBracket !== -1 && lastBracket !== -1 && firstBracket < lastBracket) {
        return text.slice(firstBracket, lastBracket + 1);
      }
      return null;
    }

    return text.slice(firstBrace, lastBrace + 1);
  }

  /**
   * 尝试修复常见的JSON格式问题
   */
  private attemptJsonRepair(text: string): string | null {
    let repaired = text;

    // 移除markdown代码块标记
    repaired = repaired.replace(/```(?:json)?\s*/g, '').replace(/```\s*/g, '');

    // 移除BOM标记
    repaired = repaired.replace(/^\uFEFF/, '');

    // 移除控制字符（保留换行和制表符）
    repaired = repaired.replace(/[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]/g, '');

    // 尝试修复尾部逗号问题（JSON标准不允许尾部逗号）
    repaired = repaired.replace(/,\s*([}\]])/g, '$1');

    // 尝试修复未加引号的键名
    repaired = repaired.replace(/([{,]\s*)(\w+)(\s*:)/g, '$1"$2"$3');

    // 尝试修复单引号到双引号
    repaired = repaired.replace(/'/g, '"');

    const extracted = this.extractOutermostBraces(repaired);
    return extracted;
  }

  /**
   * 验证plans数组结构
   * 确保每个plan有必需的字段
   */
  private validatePlansStructure(plans: any[]): BouquetPlan[] {
    if (!Array.isArray(plans) || plans.length === 0) {
      throw new RecommendationError('AI返回的方案列表为空', 'EMPTY_PLANS', true);
    }

    return plans.map((plan, index) => {
      try {
        return this.validateSinglePlan(plan, index);
      } catch (err) {
        console.warn(`[推荐服务] 方案${index + 1}验证失败: ${(err as Error).message}`);
        // 返回一个标记为需修正的方案
        return plan as BouquetPlan;
      }
    });
  }

  /**
   * 验证单个方案结构
   */
  private validateSinglePlan(plan: any, index: number): BouquetPlan {
    const errors: string[] = [];

    if (!plan.name || typeof plan.name !== 'string') {
      errors.push(`方案${index + 1}缺少name字段`);
      plan.name = plan.name || `花束方案${index + 1}`;
    }
    if (!plan.theme || typeof plan.theme !== 'string') {
      errors.push(`方案${index + 1}缺少theme字段`);
      plan.theme = plan.theme || '温馨花束';
    }
    if (!Array.isArray(plan.flowers) || plan.flowers.length === 0) {
      errors.push(`方案${index + 1}缺少flowers字段`);
      plan.flowers = plan.flowers || [{ name: '玫瑰', count: 9, color: '红色', meaning: '爱情' }];
    } else {
      // 验证每个花材
      plan.flowers = plan.flowers.map((f: any, fi: number) => ({
        name: f.name || `花材${fi + 1}`,
        count: typeof f.count === 'number' && f.count > 0 ? f.count : 3,
        color: f.color || '混合',
        meaning: f.meaning || '美好祝福',
      }));
    }
    if (!plan.wrapping || typeof plan.wrapping !== 'object') {
      plan.wrapping = { style: '简约', color: '素雅', material: '韩式包装纸' };
    } else {
      plan.wrapping = {
        style: plan.wrapping.style || '简约',
        color: plan.wrapping.color || '素雅',
        material: plan.wrapping.material || '韩式包装纸',
      };
    }
    if (!plan.flowerLanguage || typeof plan.flowerLanguage !== 'string') {
      plan.flowerLanguage = plan.flowerLanguage || '美好的祝福与心意';
    }
    if (!plan.reason || typeof plan.reason !== 'string') {
      plan.reason = plan.reason || '精心搭配的花束方案';
    }
    if (typeof plan.estimatedPrice !== 'number' || plan.estimatedPrice <= 0) {
      plan.estimatedPrice = plan.estimatedPrice || 200;
    }
    if (!plan.cardSuggestion || typeof plan.cardSuggestion !== 'string') {
      plan.cardSuggestion = plan.cardSuggestion || '愿你每天如花般灿烂';
    }

    if (errors.length > 0) {
      console.warn(`[推荐服务] 方案${index + 1}存在字段缺失: ${errors.join(', ')}`);
    }

    return plan as BouquetPlan;
  }

  /**
   * 验证并修正完整的方案列表
   * 确保返回3个方案，价格在预算范围内
   */
  private validateAndFixPlans(plans: BouquetPlan[], input: RecommendationInput): BouquetPlan[] {
    const budget = input.budget || { min: RECOMMENDATION_CONFIG.defaultBudgetMin, max: RECOMMENDATION_CONFIG.defaultBudgetMax };

    // 修正价格超出预算的方案
    plans = plans.map((plan) => {
      // 对价格给予一定容忍度
      const maxAllowed = budget.max * (1 + RECOMMENDATION_CONFIG.priceTolerancePercent);
      const minAllowed = budget.min * (1 - RECOMMENDATION_CONFIG.priceTolerancePercent);

      if (plan.estimatedPrice > maxAllowed) {
        console.log(`[推荐服务] 方案"${plan.name}"价格${plan.estimatedPrice}超出预算上限${budget.max}，已调整`);
        plan.estimatedPrice = Math.round(budget.max);
      } else if (plan.estimatedPrice < minAllowed && budget.min > 0) {
        console.log(`[推荐服务] 方案"${plan.name}"价格${plan.estimatedPrice}低于预算下限${budget.min}，已调整`);
        plan.estimatedPrice = Math.round(budget.min);
      }

      return plan;
    });

    // 确保恰好3个方案
    if (plans.length > RECOMMENDATION_CONFIG.maxPlans) {
      plans = plans.slice(0, RECOMMENDATION_CONFIG.maxPlans);
    }

    // 如果方案不足3个，这已经是我们能提供的最好结果
    if (plans.length < RECOMMENDATION_CONFIG.maxPlans) {
      console.warn(`[推荐服务] AI只返回了${plans.length}个方案（期望${RECOMMENDATION_CONFIG.maxPlans}个）`);
    }

    return plans;
  }
}

/** 导出单例 */
export const recommendationService = new RecommendationService();
