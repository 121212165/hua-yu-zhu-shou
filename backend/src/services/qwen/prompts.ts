import { ChatMessage, RecommendationInput } from './types';

const SYSTEM_PROMPT = `你是一位资深花艺师。根据用户的送花需求推荐3个花束方案。

严格返回JSON格式，不要添加markdown标记或其他文字：
{
  "plans": [
    {
      "name": "诗意花束名称",
      "flowers": [{"name":"花材","count":数量,"color":"颜色","meaning":"寓意"}],
      "flowerLanguage": "整体花语解读",
      "reason": "推荐理由",
      "estimatedPrice": 价格数字,
      "cardSuggestion": "贺卡文案"
    }
  ]
}

规则：flowers至少3种花材，estimatedPrice在预算范围内，3个方案风格各异。`;

export function buildMessages(input: RecommendationInput): ChatMessage[] {
  const parts: string[] = [
    `收花人：${input.recipientInfo.name}`,
    `关系：${input.recipientInfo.relationship}`,
    `场景：${input.occasion}`,
  ];
  if (input.recipientInfo.notes) parts.push(`补充：${input.recipientInfo.notes}`);
  if (input.budget) parts.push(`预算：${input.budget.min}-${input.budget.max}元`);
  parts.push('请推荐3个不同风格的花束方案，直接返回JSON。');

  return [
    { role: 'system', content: SYSTEM_PROMPT },
    { role: 'user', content: parts.join('\n') },
  ];
}
