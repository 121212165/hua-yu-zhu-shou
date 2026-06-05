// 花材数据模型

// 花材分类枚举
export enum FlowerCategory {
  ROSE = 'rose',           // 玫瑰
  LILY = 'lily',           // 百合
  TULIP = 'tulip',         // 郁金香
  CARNATION = 'carnation', // 康乃馨
  SUNFLOWER = 'sunflower', // 向日葵
  HYDRANGEA = 'hydrangea', // 绣球
  PEONY = 'peony',         // 牡丹
  CHRYSANTHEMUM = 'chrysanthemum', // 菊花
  ORCHID = 'orchid',       // 兰花
  OTHER = 'other'          // 其他
}

// 花材颜色枚举
export enum FlowerColor {
  RED = 'red',
  WHITE = 'white',
  YELLOW = 'yellow',
  PINK = 'pink',
  PURPLE = 'purple',
  ORANGE = 'orange',
  BLUE = 'blue',
  MIXED = 'mixed'
}

// 花材接口定义
export interface FlowerInfo {
  id: number;
  name: string;               // 花材名称
  category: FlowerCategory;   // 花材分类
  color: FlowerColor;         // 主要颜色
  description: string;        // 花材描述
  meaning: string;            // 花语含义
  price: number;              // 单支价格
  season: string;             // 适合季节
  imageUrl: string;           // 图片URL
  popularity: number;         // 热度评分(0-100)
  createdAt: string;
  updatedAt: string;
}

// 花材列表请求参数
export interface GetFlowersParams {
  category?: FlowerCategory;
  color?: FlowerColor;
  keyword?: string;
  page?: number;
  pageSize?: number;
}

// 花材列表响应
export interface GetFlowersResponse {
  flowers: FlowerInfo[];
  total: number;
  page: number;
  pageSize: number;
}