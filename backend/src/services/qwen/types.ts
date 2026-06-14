export interface RecipientInfo {
  name: string;
  relationship: string;
  notes?: string;
}

export interface RecommendationInput {
  recipientInfo: RecipientInfo;
  occasion: string;
  budget?: { min: number; max: number };
}

export interface FlowerItem {
  name: string;
  count: number;
  color: string;
  meaning: string;
}

export interface BouquetPlan {
  name: string;
  flowers: FlowerItem[];
  flowerLanguage: string;
  reason: string;
  estimatedPrice: number;
  cardSuggestion: string;
}

export interface ChatMessage {
  role: 'system' | 'user' | 'assistant';
  content: string;
}
