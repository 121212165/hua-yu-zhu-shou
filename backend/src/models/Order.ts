export type OrderStatus = 'pending' | 'paid' | 'preparing' | 'delivering' | 'completed' | 'cancelled';

export interface OrderRow {
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

export interface CreateOrderParams {
  user_id: string;
  recommendation_id?: string;
  total_price: number;
  delivery_address: string;
  delivery_time?: Date;
  greeting_card_message?: string;
}

export interface UpdateOrderStatusParams {
  status: OrderStatus;
}
