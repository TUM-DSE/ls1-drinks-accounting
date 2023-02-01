export interface Transaction {
  id: string;
  timestamp: Date;
  amount: number;
  transaction_type:
    | "MoneyDeposit"
    | {
        Purchase: {
          icon: string;
          name: string;
        };
      };
}
