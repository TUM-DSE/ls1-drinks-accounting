export interface Drink {
  id: string;
  name: string;
  icon: string;
  sale_price: number;
  buy_price: number | null;
  stock: number | null;
}
