export interface DrinkStats {
  id: string;
  name: string;
  data: { date: Date; count: number }[];
}

export interface DrinkStatsResponse {
  from: Date;
  to: Date;
  drinks: DrinkStats[];
}
