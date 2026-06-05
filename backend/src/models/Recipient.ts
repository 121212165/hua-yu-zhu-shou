export interface RecipientRow {
  id: string;
  user_id: string;
  name: string;
  gender: string | null;
  age: number | null;
  relationship: string;
  relationship_duration: string | null;
  interests: string | null;
  personality: string | null;
  career: string | null;
  color_preference: string | null;
  style_preference: string | null;
  allergies: string | null;
  cultural_notes: string | null;
  notes: string | null;
  created_at: Date;
  updated_at: Date;
}

export interface CreateRecipientParams {
  user_id: string;
  name: string;
  gender?: string;
  age?: number;
  relationship: string;
  relationship_duration?: string;
  interests?: string;
  personality?: string;
  career?: string;
  color_preference?: string;
  style_preference?: string;
  allergies?: string;
  cultural_notes?: string;
  notes?: string;
}

export interface UpdateRecipientParams extends Partial<Omit<CreateRecipientParams, 'user_id'>> {}
