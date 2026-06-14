export const BASE_URL: string = 'http://localhost:3001/api';
export const DEFAULT_PAGE_SIZE: number = 20;
export const TOKEN_KEY: string = 'auth_token';
export const HTTP_TIMEOUT: number = 15000;
export const BANNER_INTERVAL: number = 3000;

export const SCENE_ICONS: Record<string, string> = {
  'birthday': '🎂', 'confession': '💕', 'anniversary': '🎁',
  'apology': '🙏', 'gratitude': '🌻', 'visit': '🏥'
};

export const SCENE_NAMES: Record<string, string> = {
  'birthday': '生日', 'confession': '表白', 'anniversary': '纪念日',
  'apology': '道歉', 'gratitude': '感谢', 'visit': '探望'
};

export const ORDER_STATUS_MAP: Record<string, string> = {
  'pending': '待支付', 'paid': '已支付', 'completed': '已完成', 'cancelled': '已取消'
};
