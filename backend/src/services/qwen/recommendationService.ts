import { qwenClient, QwenApiError } from './qwenClient';
import { buildMessages } from './prompts';
import { RecommendationInput, BouquetPlan } from './types';

export class RecommendationService {
  async generate(input: RecommendationInput): Promise<BouquetPlan[]> {
    if (!input.recipientInfo?.name) throw new Error('Recipient name required');
    if (!input.occasion) throw new Error('Occasion required');

    const messages = buildMessages(input);
    const content = await qwenClient.chat(messages);
    return this.parse(content);
  }

  private parse(content: string): BouquetPlan[] {
    let text = content.replace(/```json\s*/g, '').replace(/```\s*/g, '').trim();
    const first = text.indexOf('{');
    const last = text.lastIndexOf('}');
    if (first !== -1 && last > first) text = text.slice(first, last + 1);

    const parsed = JSON.parse(text);
    const plans = Array.isArray(parsed) ? parsed : parsed.plans;
    if (!Array.isArray(plans) || plans.length === 0) throw new Error('No plans in response');

    return plans.slice(0, 3).map((p: any, i: number) => ({
      name: p.name || `方案${i + 1}`,
      flowers: Array.isArray(p.flowers) ? p.flowers.map((f: any) => ({
        name: f.name || '花材', count: f.count || 3, color: f.color || '混合', meaning: f.meaning || '祝福',
      })) : [{ name: '玫瑰', count: 9, color: '红色', meaning: '爱情' }],
      flowerLanguage: p.flowerLanguage || '美好祝福',
      reason: p.reason || '精心搭配',
      estimatedPrice: typeof p.estimatedPrice === 'number' ? p.estimatedPrice : 200,
      cardSuggestion: p.cardSuggestion || '愿你每天如花般灿烂',
    }));
  }
}

export const recommendationService = new RecommendationService();
