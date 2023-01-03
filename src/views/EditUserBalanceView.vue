<script lang="ts">
import { defineComponent } from "vue";
import ProgressView from "@/components/ProgressView.vue";
import HeaderView from "@/components/HeaderView.vue";
import type { User } from "@/network/types/User";
import { UsersService } from "@/network/services/UsersService";
import type { Transaction } from "@/network/types/Transaction";
import CurrencyFormatter from "../format/CurrencyFormatter";
import { CurrencyEuroIcon } from "@heroicons/vue/20/solid";

export default defineComponent({
  computed: {
    CurrencyFormatter() {
      return CurrencyFormatter;
    },
  },
  components: { HeaderView, ProgressView, CurrencyEuroIcon },
  data() {
    return {
      loading: false,
      loadingTransactions: false,
      submitting: false,
      user: null as User | null,
      userTransactions: [] as Transaction[],
      error: null as string | null,
      formData: {
        amount: 0 as number | "",
      },
    };
  },
  created() {
    const id = this.$route.params["id"] as string;
    this.loadUser(id);
  },
  methods: {
    loadUser(id: string) {
      this.error = null;
      this.loading = true;
      this.loadingTransactions = true;
      UsersService.loadAll()
        .then((users) => {
          this.user = users.find((d) => d.id === id) ?? null;
          this.loading = false;
        })
        .catch((e) => {
          this.error = this.error ? `${this.error}\n${e}` : e;
          this.loading = false;
        });

      UsersService.getTransactions(id)
        .then((transactions) => {
          this.userTransactions = transactions;
          this.loadingTransactions = false;
        })
        .catch((e) => {
          this.error = this.error ? `${this.error}\n${e}` : e;
          this.loadingTransactions = false;
        });
    },
    submit(e: Event) {
      e.preventDefault();
      if (this.submitting) {
        return;
      }
      this.error = null;
      if (this.formData.amount === "") {
        this.error = "Field 'amount' is required";
        return;
      }

      this.submitting = true;

      const payload = {
        user: this.user!.id,
        amount: this.formData.amount,
      };

      UsersService.depositMoney(payload)
        .then(() => {
          this.submitting = false;
          this.loadUser(this.user!.id);
        })
        .catch((e) => {
          this.submitting = false;
          this.error = e;
        });
    },
  },
});
</script>

<template>
  <HeaderView path="/users" />
  <main>
    <div class="container mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
      <div v-if="loading" class="flex items-center justify-center h-screen">
        <ProgressView />
      </div>
      <div v-else>
        <p v-if="!user">User not found.</p>
        <div
          v-else
          class="flex min-h-full items-center justify-center py-12 px-4 sm:px-6 lg:px-8"
        >
          <div class="w-full max-w-md space-y-4">
            <h2
              class="mt-6 text-center text-3xl font-bold tracking-tight text-gray-900"
            >
              {{ user.last_name }}, {{ user.first_name }}
            </h2>
            <h3
              class="text-center text-md font-medium tracking-tight text-gray-900"
            >
              Balance:
              <span v-bind:class="{ 'text-red-400': user.balance < 0 }">{{
                CurrencyFormatter.format(user.balance)
              }}</span>
            </h3>

            <form class="mt-8 space-y-3">
              <div class="-space-y-px rounded-md shadow-sm">
                <div>
                  <label for="amount" class="sr-only">Amount</label>
                  <input
                    id="amount"
                    name="amount"
                    required=""
                    type="number"
                    step="0.01"
                    class="relative inline-block w-full appearance-none rounded border border-gray-300 px-3 py-2 text-gray-900 placeholder-gray-500 focus:z-10 focus:border-indigo-500 focus:outline-none focus:ring-indigo-500 sm:text-sm"
                    placeholder="Amount"
                    v-model="formData.amount"
                  />
                </div>
              </div>

              <div v-if="error">
                <p class="text-red-400 text-sm">
                  Error submitting: {{ error }}
                </p>
              </div>

              <div>
                <button
                  v-bind:disabled="submitting"
                  type="submit"
                  class="group relative flex w-full justify-center rounded-md border border-transparent bg-indigo-600 py-2 px-4 text-sm font-medium text-white hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:ring-offset-2"
                  @click="submit"
                >
                  Deposit money
                </button>
                <div
                  v-if="submitting"
                  class="flex items-center justify-center my-4"
                >
                  <ProgressView />
                </div>
              </div>
            </form>

            <h2
              class="mt-6 text-center text-2xl font-bold tracking-tight text-gray-900"
            >
              Transactions
            </h2>
            <div
              v-if="loading"
              class="flex items-center justify-center h-screen"
            >
              <ProgressView />
            </div>
            <ul
              v-if="!loadingTransactions"
              class="my-6 divide-y divide-gray-200"
            >
              <li
                v-for="transaction in userTransactions"
                v-bind:key="transaction.id"
                class="py-2"
              >
                <div class="flex items-center space-x-4">
                  <div class="flex-shrink-0">
                    <div
                      v-if="transaction.transaction_type === 'MoneyDeposit'"
                      class="rounded-lg bg-cyan-800 p-2"
                    >
                      <CurrencyEuroIcon class="block h-6 w-6 text-white" />
                    </div>
                    <label
                      v-else
                      class="text-2xl icon-bg p-2 w-3 h-3 rounded-lg bg-cyan-800"
                      >{{ transaction.transaction_type.Purchase.icon }}</label
                    >
                  </div>
                  <div class="flex-1 min-w-0">
                    <p class="text-sm font-medium text-gray-900 truncate">
                      <label
                        v-if="transaction.transaction_type === 'MoneyDeposit'"
                        >Deposit</label
                      >
                      <label v-else>{{
                        transaction.transaction_type.Purchase.name
                      }}</label>
                    </p>
                    <p class="text-sm text-gray-500 truncate">
                      {{ transaction.timestamp.toLocaleString() }}
                    </p>
                  </div>
                  <div
                    class="inline-flex items-center text-sm truncate"
                    v-bind:class="{
                      'text-red-400': transaction.amount < 0,
                      'text-gray-500': transaction.amount >= 0,
                    }"
                  >
                    <span>{{
                      CurrencyFormatter.format(transaction.amount)
                    }}</span>
                  </div>
                </div>
              </li>
            </ul>
          </div>
        </div>
      </div>
    </div>
  </main>
</template>

<style scoped></style>
