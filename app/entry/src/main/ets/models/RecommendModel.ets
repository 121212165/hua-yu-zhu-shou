// 推荐数据模型

// 场景枚举
export enum SceneType {
  BIRTHDAY = 'birthday',     // 生日
  CONFESSION = 'confession',  // 表白
  ANNIVERSARY = 'anniversary', // 纪念日
  APOLOGY = 'apology',       // 道歉
  GRATITUDE = 'gratitude',   // 感谢
  VISIT = 'visit'            // 探望
}

// 推荐请求参数
export interface GenerateRecommendationParams {
  recipientId?: number;      // 收件人ID
  scene: SceneType;          // 场景类型
  budget?: number;           // 预算
  stylePreference?: string;  // 风格偏好
  specialRequirements?: string; // 特殊要求
}

// 花束方案
export interface BouquetScheme {
  id: number;
  name: string;              // 方案名称
  description: string;       // 方案描述
  flowers: FlowerItem[];     // 花材列表
  totalPrice: number;        // 总价
  style: string;             // 风格
  meaning: string;           // 整体花语
  imageUrl: string;          // 效果图URL
  matchScore: number;        // 匹配度评分(0-100)
}

// 方案中的花材项
export interface FlowerItem {
  flowerId: number;
  flowerName: string;
  quantity: number;           // 数量
  unitPrice: number;          // 单价
  color: string;              // 颜色
  meaning: string;            // 花语
}

// 推荐响应
export interface RecommendationResponse {
  schemes: BouquetScheme[];
  reason: string;            // 推荐理由
  sceneAnalysis: string;     // 场景分析
}

// 订单接口定义 - 与后端对齐
export interface OrderInfo {
  id: string;
  user_id: string;
  recommendation_id: string | null;
  status: 'pending' | 'paid' | 'preparing' | 'delivering' | 'completed' | 'cancelled';
  total_price: number;
  delivery_address: string;
  delivery_time: string | null;
  greeting_card_message: string | null;
  created_at: string;
  updated_at: string;
}

// 订单列表响应（分页）
export interface OrderListResponse {
  items: OrderInfo[];
  pagination: {
    page: number;
    pageSize: number;
    total: number;
    totalPages: number;
  };
}

// 创建订单请求 - 与后端对齐
export interface CreateOrderParams {
  recommendation_id?: string;
  selected_plan_index?: number;
  total_price: number;
  delivery_address: string;
  delivery_time?: string;
  greeting_card_message?: string;
}

// 更新订单状态请求
export interface UpdateOrderStatusParams {
  status: 'pending' | 'paid' | 'preparing' | 'delivering' | 'completed' | 'cancelled';
}

// 反馈接口定义
export interface FeedbackInfo {
  id: number;
  userId: number;
  orderId: number;
  rating: number;             // 评分(1-5)
  content: string;            // 反馈内容
  images?: string[];          // 反馈图片
  createdAt: string;
}

// 提交反馈请求
export interface SubmitFeedbackParams {
  orderId: number;
  rating: number;
  content: string;
  images?: string[];
}