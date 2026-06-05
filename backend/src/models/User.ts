export interface UserRow {
  id: string;
  phone: string;
  password_hash: string;
  nickname: string | null;
  avatar: string | null;
  created_at: Date;
  updated_at: Date;
}

export interface CreateUserParams {
  phone: string;
  password_hash: string;
  nickname?: string;
}

export interface FindUserByPhoneParams {
  phone: string;
}

export interface UpdateUserParams {
  nickname?: string;
  avatar?: string;
}
