export interface FlowerRow {
  id: string;
  name: string;
  name_en: string;
  meaning: string;
  color: string;
  category: string;
  price_per_stem: number;
  season: string;
  image_url: string | null;
  description: string | null;
  available: boolean;
}

export interface FlowerFilterParams {
  category?: string;
  color?: string;
  season?: string;
  available?: boolean;
  limit?: number;
  offset?: number;
}
