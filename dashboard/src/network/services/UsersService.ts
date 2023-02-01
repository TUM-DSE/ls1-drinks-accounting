import client from "@/network/client";
import type { User } from "@/network/types/User";
import type { Transaction } from "@/network/types/Transaction";

export class UsersService {
  static loadAll(): Promise<User[]> {
    return client.get("/api/users").then((response) => {
      const data = response.data;
      data.sort((lhs: User, rhs: User) => {
        const lhsName = `${lhs.last_name}, ${lhs.first_name}`;
        const rhsName = `${rhs.last_name}, ${rhs.first_name}`;

        if (lhsName < rhsName) {
          return -1;
        } else if (lhsName > rhsName) {
          return 1;
        } else {
          return 0;
        }
      });
      return data;
    });
  }

  static createUser(user: Object): Promise<void> {
    return client.post("/api/users", user);
  }

  static updateUser(id: string, user: Object): Promise<void> {
    return client.put(`/api/users/${id}`, user);
  }

  static getTransactions(id: string): Promise<Transaction[]> {
    return client.get(`/api/users/${id}/transactions`).then((response) => {
      const data = response.data;
      data.map((transaction: Record<string, any>) => {
        transaction.timestamp = new Date(
          Date.parse(transaction.timestamp as string)
        );
        return transaction;
      });

      data.sort((lhs: Transaction, rhs: Transaction) => {
        if (lhs.timestamp < rhs.timestamp) {
          return 1;
        } else if (lhs.timestamp > rhs.timestamp) {
          return -1;
        } else {
          return 0;
        }
      });

      return data;
    });
  }

  static depositMoney(payload: {
    user: string;
    amount: number;
  }): Promise<void> {
    return client.post("/api/transactions/deposit", payload);
  }
}
