import client from "@/network/client";
import type { DrinkStatsResponse } from "@/network/types/Stats";

export class StatsService {
  static getStats(from: Date, to: Date): Promise<DrinkStatsResponse> {
    const fromDate = from.toISOString().split("T")[0];
    const toDate = to.toISOString().split("T")[0];
    return client
      .get(`/api/stats/drinks/${fromDate}/${toDate}`)
      .then((response) => {
        const data = response.data;
        data.from = new Date(Date.parse(data.from as string));
        data.to = new Date(Date.parse(data.to as string));
        data.drinks.map((d: any) => {
          d.data.map((datapoint: any) => {
            datapoint.date = new Date(Date.parse(datapoint.date as string));
          });
        });
        return response.data;
      });
  }
}
