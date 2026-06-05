// 常量定义

// API基础地址
export const BASE_URL: string = 'http://localhost:3000/api';

// 分页默认值
export const DEFAULT_PAGE_SIZE: number = 20;
export const DEFAULT_PAGE: number = 1;

// Token存储键名
export const TOKEN_KEY: string = 'auth_token';
export const USER_INFO_KEY: string = 'user_info';

// 请求超时时间(毫秒)
export const HTTP_TIMEOUT: number = 15000;

// Banner自动轮播间隔(毫秒)
export const BANNER_INTERVAL: number = 3000;

// 场景类型常量
export const SCENE_TYPES: string[] = [
  'birthday',     // 生日
  'confession',   // 表白
  'anniversary',  // 纪念日
  'apology',      // 道歉
  'gratitude',    // 感谢
  'visit'         // 探望
];

// 场景图标映射
export const SCENE_ICONS: Record<string, string> = {
  'birthday': '🎂',
  'confession': '💕',
  'anniversary': '🎁',
  'apology': '🙏',
  'gratitude': '🌻',
  'visit': '🏥'
};

// 场景名称映射
export const SCENE_NAMES: Record<string, string> = {
  'birthday': '生日',
  'confession': '表白',
  'anniversary': '纪念日',
  'apology': '道歉',
  'gratitude': '感谢',
  'visit': '探望'
};

// 订单状态映射
export const ORDER_STATUS_MAP: Record<string, string> = {
  'pending': '待确认',
  'confirmed': '已确认',
  'delivering': '配送中',
  'completed': '已完成',
  'cancelled': '已取消'
};