export interface RecommendationRow {
  id: string;
  user_id: string;
  recipient_id: string;
  occasion: string;
  input_context: any; // JSONB
  ai_response: any; // JSONB
  selected_plan_index: number | null;
  created_at: Date;
}

export interface CreateRecommendationParams {
  user_id: string;
  recipient_id: string;
  occasion: string;
  input_context: Record<string, any>;
  ai_response: Record<string, any>;
}
