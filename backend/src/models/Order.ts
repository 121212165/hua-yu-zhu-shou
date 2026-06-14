export type OrderStatus = 'pending' | 'paid' | 'completed' | 'cancelled';

export interface OrderRow {
  id: string;
  user_id: string;
  recommendation_id: string | null;
  status: OrderStatus;
  total_price: number;
  delivery_address: string;
  created_at: Date;
  updated_at: Date;
}

export interface CreateOrderParams {
  user_id: string;
  recommendation_id?: string;
  total_price: number;
  delivery_address: string;
}
