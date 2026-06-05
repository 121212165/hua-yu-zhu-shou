export interface BouquetTemplateRow {
  id: string;
  name: string;
  description: string | null;
  occasion: string;
  style: string;
  price_range_min: number;
  price_range_max: number;
  flower_composition: any; // JSONB
  image_url: string | null;
}

export interface FlowerCompositionItem {
  flower_id: string;
  flower_name: string;
  quantity: number;
}
