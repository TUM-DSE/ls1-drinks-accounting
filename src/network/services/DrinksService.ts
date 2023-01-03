import client from "@/network/client";
import type { Drink } from "@/network/types/Drink";

export class DrinksService {
  static loadDrinks(): Promise<Drink[]> {
    return client.get("/api/admin/drinks").then((response) => {
      return response.data;
      // return JSON.parse(response.data);
    });
  }
}
