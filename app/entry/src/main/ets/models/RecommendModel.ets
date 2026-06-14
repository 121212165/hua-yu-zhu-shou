export enum SceneType {
  BIRTHDAY = 'birthday',
  CONFESSION = 'confession',
  ANNIVERSARY = 'anniversary',
  APOLOGY = 'apology',
  GRATITUDE = 'gratitude',
  VISIT = 'visit'
}

export interface GenerateRecommendationParams {
  recipientId?: number;
  occasion: string;
  recipientName?: string;
  recipientRelationship?: string;
  notes?: string;
  budget?: { min: number; max: number };
}

export interface BouquetScheme {
  id: number;
  name: string;
  description: string;
  flowers: FlowerItem[];
  totalPrice: number;
  style: string;
  meaning: string;
  imageUrl: string;
  matchScore: number;
}

export interface FlowerItem {
  flowerId: number;
  flowerName: string;
  quantity: number;
  unitPrice: number;
  color: string;
  meaning: string;
}

export interface RecommendationResponse {
  schemes: BouquetScheme[];
  reason: string;
  sceneAnalysis: string;
}

export interface OrderInfo {
  id: string;
  user_id: string;
  recommendation_id: string | null;
  status: 'pending' | 'paid' | 'completed' | 'cancelled';
  total_price: number;
  delivery_address: string;
  created_at: string;
  updated_at: string;
}

export interface CreateOrderParams {
  recommendation_id?: string;
  total_price: number;
  delivery_address: string;
}

export interface OrderListResponse {
  items: OrderInfo[];
  pagination: { page: number; pageSize: number; total: number; totalPages: number; };
}
