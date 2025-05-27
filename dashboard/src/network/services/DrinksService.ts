import client from "@/network/client";
import type { Drink } from "@/network/types/Drink";

export class DrinksService {
  static loadDrinks(): Promise<Drink[]> {
    return client.get("/api/admin/drinks").then((response) => {
      return response.data;
    });
  }

  static createDrink(drink: Object): Promise<void> {
    return client.post("/api/admin/drinks", drink);
  }

  static updateDrink(id: string, drink: Object): Promise<void> {
    return client.put(`/api/admin/drinks/${id}`, drink);
  }

  static deleteDrink(id: string): Promise<void> {
    return client.delete(`/api/admin/drinks/${id}`);
  }
}
