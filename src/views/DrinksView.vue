<script setup lang="ts">
import HeaderView from "@/components/HeaderView.vue";
import ProgressView from "@/components/ProgressView.vue";
import CurrencyFormatter from "../format/CurrencyFormatter";
import { PencilIcon } from "@heroicons/vue/20/solid";
</script>

<script lang="ts">
import { defineComponent } from "vue";
import { DrinksService } from "@/network/services/DrinksService";
import type { Drink } from "@/network/types/Drink";

export default defineComponent({
  props: {},
  data() {
    return {
      drinks: [] as Drink[],
      error: null,
      loading: false,
    };
  },
  created() {
    this.fetch();
  },
  methods: {
    fetch() {
      this.loading = true;
      DrinksService.loadDrinks()
        .then((drinks) => {
          this.drinks = drinks;
          this.loading = false;
        })
        .catch((e) => {
          this.error = e;
          this.loading = false;
        });
    },
  },
});
</script>

<template>
  <HeaderView path="/drinks" />
  <main>
    <div class="container mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
      <div v-if="loading" class="flex items-center justify-center h-screen">
        <ProgressView />
      </div>
      <ul v-if="!loading" class="my-6 divide-y divide-gray-200">
        <li v-for="drink in drinks" v-bind:key="drink.id" class="py-2">
          <div class="flex items-center space-x-4">
            <div class="flex-shrink-0">
              <label
                class="text-2xl icon-bg p-2 w-3 h-3 rounded-lg bg-cyan-800"
                >{{ drink.icon }}</label
              >
            </div>
            <div class="flex-1 min-w-0">
              <p class="text-sm font-medium text-gray-900 truncate">
                {{ drink.name }}
              </p>
              <p class="text-sm text-gray-500 truncate">
                {{ CurrencyFormatter.format(drink.sale_price) }}
                <span v-if="drink.buy_price">
                  / Retail:
                  {{ CurrencyFormatter.format(drink.buy_price) }}</span
                >
              </p>
            </div>
            <div
              class="inline-flex items-center text-sm text-gray-500 truncate"
            >
              <span v-if="drink.stock">{{ drink.stock }} in stock</span>
              <span v-else>Stock not tracked</span>
            </div>
            <div
              class="inline-flex items-center text-sm text-gray-500 truncate"
            >
              <button
                class="bg-gray-300 hover:bg-gray-400 text-gray-800 font-bold py-2 px-4 rounded inline-flex items-center"
              >
                <PencilIcon class="block h-4 w-4 mr-2" />
                <span>Edit</span>
              </button>
            </div>
          </div>
        </li>
      </ul>
    </div>
  </main>
</template>
