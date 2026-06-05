// ==================== 通义千问AI推荐服务 ====================
// 统一导出入口

// 类型导出
export type {
  RecipientInfo,
  RelationshipContext,
  CulturalFactors,
  RecipientProfile,
  Preferences,
  BudgetRange,
  RecommendationInput,
  FlowerItem,
  WrappingInfo,
  BouquetPlan,
  ChatMessage,
  QwenChatRequest,
  QwenResponse,
  QwenStreamResponse,
  QwenErrorResponse,
  CacheEntry,
} from './types';

// 服务导出
export { QwenClient, QwenApiError, qwenClient } from './qwenClient';
export type { StreamCallback } from './qwenClient';
export { buildMessages, getSceneEnhancement, getSystemPrompt } from './prompts';
export { CacheService, cacheService } from './cacheService';
export { RecommendationService, RecommendationError, recommendationService } from './recommendationService';
