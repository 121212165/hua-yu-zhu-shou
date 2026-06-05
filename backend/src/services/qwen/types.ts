// ==================== 推荐输入类型 ====================

/** 收花人基本信息 */
export interface RecipientInfo {
  name: string;
  gender?: 'male' | 'female' | 'other';
  age?: number;
  relationship: string;
}

/** 关系进展史 */
export interface RelationshipContext {
  duration?: string;           // 交往时长，如"3天"、"2年"
  previousFlowers?: string;    // 之前送过的花
  recentEvents?: string;       // 最近发生的事件
}

/** 文化/地域因素 */
export interface CulturalFactors {
  taboos?: string;             // 花材禁忌
  customs?: string;            // 地方习俗
}

/** 对方画像 */
export interface RecipientProfile {
  interests?: string;          // 兴趣爱好
  career?: string;             // 职业
  personality?: string;        // 性格特点
}

/** 个性化偏好 */
export interface Preferences {
  favoriteColors?: string;     // 喜欢的颜色
  style?: string;              // 风格偏好
  allergies?: string;          // 过敏信息
}

/** 预算范围 */
export interface BudgetRange {
  min: number;
  max: number;
}

/** 推荐服务输入 - 完整的推荐请求参数 */
export interface RecommendationInput {
  recipientInfo: RecipientInfo;
  occasion: string;
  relationshipContext?: RelationshipContext;
  culturalFactors?: CulturalFactors;
  recipientProfile?: RecipientProfile;
  preferences?: Preferences;
  budget?: BudgetRange;
  additionalNotes?: string;
}

// ==================== 推荐输出类型 ====================

/** 花材组成 */
export interface FlowerItem {
  name: string;         // 花材名称
  count: number;        // 数量
  color: string;        // 颜色
  meaning: string;      // 选择此花的寓意
}

/** 包装信息 */
export interface WrappingInfo {
  style: string;        // 包装风格
  color: string;        // 包装颜色
  material: string;     // 包装材质
}

/** 花束推荐方案 */
export interface BouquetPlan {
  name: string;           // 花束名称（诗意化）
  theme: string;          // 主题
  flowers: FlowerItem[];  // 花材组成
  wrapping: WrappingInfo; // 包装信息
  flowerLanguage: string; // 整体花语解读
  reason: string;         // 为什么适合此场景的详细解释
  estimatedPrice: number; // 预估价格
  cardSuggestion: string; // 贺卡文案建议
}

// ==================== 通义千问API相关类型 ====================

/** OpenAI兼容格式的消息 */
export interface ChatMessage {
  role: 'system' | 'user' | 'assistant';
  content: string;
}

/** 非流式请求参数 */
export interface QwenChatRequest {
  model: string;
  messages: ChatMessage[];
  temperature?: number;
  top_p?: number;
  max_tokens?: number;
  stream?: boolean;
}

/** 非流式响应中的选择项 */
export interface QwenChoice {
  index: number;
  message: ChatMessage;
  finish_reason: string;
}

/** Token使用量 */
export interface QwenUsage {
  prompt_tokens: number;
  completion_tokens: number;
  total_tokens: number;
}

/** 通义千问非流式响应 */
export interface QwenResponse {
  id: string;
  object: string;
  created: number;
  model: string;
  choices: QwenChoice[];
  usage: QwenUsage;
}

/** 流式响应Delta */
export interface QwenStreamDelta {
  role?: string;
  content?: string;
}

/** 流式响应选择项 */
export interface QwenStreamChoice {
  index: number;
  delta: QwenStreamDelta;
  finish_reason: string | null;
}

/** 通义千问流式响应（SSE数据） */
export interface QwenStreamResponse {
  id: string;
  object: string;
  created: number;
  model: string;
  choices: QwenStreamChoice[];
}

/** API错误响应 */
export interface QwenErrorResponse {
  error: {
    message: string;
    type: string;
    code: string;
  };
}

// ==================== 缓存相关类型 ====================

/** 缓存条目 */
export interface CacheEntry {
  plans: BouquetPlan[];
  cachedAt: number;
  inputHash: string;
}
