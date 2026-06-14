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

export interface LoginParams {
  phone: string;
  password: string;
}

export interface RegisterParams {
  phone: string;
  password: string;
  nickname?: string;
}

export interface LoginResponse {
  token: string;
  user: UserInfo;
}

export interface RegisterResponse {
  token: string;
  user: UserInfo;
}

export interface RecipientInfo {
  id: number;
  name: string;
  relationship: string;
  notes: string;
  createdAt: string;
  updatedAt: string;
}

export interface CreateRecipientParams {
  name: string;
  relationship: string;
  notes?: string;
}
