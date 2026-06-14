export interface RecipientRow {
  id: string;
  user_id: string;
  name: string;
  relationship: string;
  notes: string | null;
  created_at: Date;
  updated_at: Date;
}

export interface CreateRecipientParams {
  user_id: string;
  name: string;
  relationship: string;
  notes?: string;
}
