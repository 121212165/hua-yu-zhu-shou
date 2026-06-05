import { Request } from 'express';

// ==================== 通用类型 ====================

export interface ApiResponse<T = any> {
  code: number;
  message: string;
  data?: T;
  errors?: any[];
}

export interface PaginatedResponse<T = any> {
  items: T[];
  total: number;
  page: number;
  pageSize: number;
}

// ==================== 认证相关 ====================

export interface JwtPayload {
  userId: string;
  phone: string;
}

export interface AuthRequest extends Request {
  user?: JwtPayload;
}

// ==================== 用户 ====================

export interface User {
  id: string;
  phone: string;
  password_hash: string;
  nickname: string | null;
  avatar: string | null;
  created_at: Date;
  updated_at: Date;
}

export interface CreateUserInput {
  phone: string;
  password: string;
  nickname?: string;
}

export interface LoginInput {
  phone: string;
  password: string;
}

export interface LoginResponse {
  token: string;
  user: Omit<User, 'password_hash'>;
}

// ==================== 收花人 ====================

export interface Recipient {
  id: string;
  user_id: string;
  name: string;
  gender: 'male' | 'female' | 'other' | null;
  age: number | null;
  relationship: string;
  relationship_duration: string | null;
  interests: string | null;
  personality: string | null;
  career: string | null;
  color_preference: string | null;
  style_preference: string | null;
  allergies: string | null;
  cultural_notes: string | null;
  notes: string | null;
  created_at: Date;
  updated_at: Date;
}

export interface CreateRecipientInput {
  name: string;
  gender?: 'male' | 'female' | 'other';
  age?: number;
  relationship: string;
  relationship_duration?: string;
  interests?: string;
  personality?: string;
  career?: string;
  color_preference?: string;
  style_preference?: string;
  allergies?: string;
  cultural_notes?: string;
  notes?: string;
}

export interface UpdateRecipientInput extends Partial<CreateRecipientInput> {}

// ==================== 花材 ====================

export interface Flower {
  id: string;
  name: string;
  name_en: string;
  meaning: string;
  color: string;
  category: string;
  price_per_stem: number;
  season: string;
  image_url: string | null;
  description: string | null;
  available: boolean;
}

export interface FlowerQueryParams {
  category?: string;
  color?: string;
  season?: string;
  available?: boolean;
  page?: number;
  pageSize?: number;
}

// ==================== 花束模板 ====================

export interface BouquetTemplate {
  id: string;
  name: string;
  description: string | null;
  occasion: string;
  style: string;
  price_range_min: number;
  price_range_max: number;
  flower_composition: FlowerComposition[];
  image_url: string | null;
}

export interface FlowerComposition {
  flower_id: string;
  flower_name: string;
  quantity: number;
}

// ==================== 订单 ====================

export type OrderStatus = 'pending' | 'paid' | 'preparing' | 'delivering' | 'completed' | 'cancelled';

export interface Order {
  id: string;
  user_id: string;
  recommendation_id: string | null;
  status: OrderStatus;
  total_price: number;
  delivery_address: string;
  delivery_time: Date | null;
  greeting_card_message: string | null;
  created_at: Date;
  updated_at: Date;
}

export interface CreateOrderInput {
  recommendation_id?: string;
  total_price: number;
  delivery_address: string;
  delivery_time?: string;
  greeting_card_message?: string;
}

// ==================== 推荐 ====================

export interface Recommendation {
  id: string;
  user_id: string;
  recipient_id: string;
  occasion: string;
  input_context: Record<string, any>;
  ai_response: AiRecommendationResponse;
  selected_plan_index: number | null;
  created_at: Date;
}

export interface AiRecommendationResponse {
  plans: AiPlan[];
  reasoning: string;
}

export interface AiPlan {
  name: string;
  description: string;
  flowers: AiPlanFlower[];
  style: string;
  estimated_price: number;
  occasion_match: string;
}

export interface AiPlanFlower {
  flower_name: string;
  quantity: number;
  reason: string;
}

export interface CreateRecommendationInput {
  recipient_id: string;
  occasion: string;
  budget?: number;
  additional_notes?: string;
}

// ==================== 用户反馈 ====================

export interface UserFeedback {
  id: string;
  user_id: string;
  recommendation_id: string;
  rating: number;
  comment: string | null;
  created_at: Date;
}

export interface CreateFeedbackInput {
  recommendation_id: string;
  rating: number;
  comment?: string;
}
