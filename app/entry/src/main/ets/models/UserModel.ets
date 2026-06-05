// 用户数据模型

// 用户接口定义
export interface UserInfo {
  id: number;
  username: string;
  nickname: string;
  avatarUrl: string;
  phone: string;
  email: string;
  createdAt: string;
  updatedAt: string;
}

// 登录请求参数
export interface LoginParams {
  username: string;
  password: string;
}

// 注册请求参数
export interface RegisterParams {
  username: string;
  password: string;
  nickname?: string;
  phone?: string;
}

// 登录响应
export interface LoginResponse {
  token: string;
  user: UserInfo;
}

// 注册响应
export interface RegisterResponse {
  token: string;
  user: UserInfo;
}

// 收件人信息
export interface RecipientInfo {
  id: number;
  userId: number;
  name: string;           // 收件人姓名
  gender: 'male' | 'female' | 'other';
  ageRange: string;       // 年龄段: '20-30', '30-40' 等
  relationship: string;   // 关系: 伴侣, 朋友, 父母 等
  personality: string;    // 性格特点
  preferences: string;    // 花材偏好
  createdAt: string;
  updatedAt: string;
}

// 创建收件人请求
export interface CreateRecipientParams {
  name: string;
  gender: 'male' | 'female' | 'other';
  ageRange: string;
  relationship: string;
  personality?: string;
  preferences?: string;
}