<script setup lang="ts">
import HeaderView from "@/components/HeaderView.vue";
import ProgressView from "@/components/ProgressView.vue";
import CurrencyFormatter from "../format/CurrencyFormatter";
import { PencilIcon, PlusIcon, TrashIcon } from "@heroicons/vue/20/solid";
</script>

<script lang="ts">
import { defineComponent } from "vue";
import { DrinksService } from "@/network/services/DrinksService";
import type { Drink } from "@/network/types/Drink";
import { UsersService } from "@/network/services/UsersService";

export default defineComponent({
  props: {},
  data() {
    return {
      drinks: [] as Drink[],
      error: null,
      loading: false,
      deleting: null as Drink | null,
    };
  },
  created() {
    this.fetch();
  },
  methods: {
    fetch() {
      this.loading = true;
      this.deleting = null;
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
    editDrink(id: string) {
      this.$router.push({ name: "editDrink", params: { id } });
    },
    newDrink() {
      this.$router.push({ name: "addDrink" });
    },
    deleteDrink() {
      const deleting = this.deleting;
      if (!deleting) {
        return;
      }

      DrinksService.deleteDrink(deleting.id).then(() => this.fetch());
    },
  },
});
</script>

<template>
  <HeaderView path="/drinks" />
  <main>
    <div class="container mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
      <h2
        class="mt-6 text-center text-3xl font-bold tracking-tight text-gray-900"
      >
        Drinks
      </h2>
      <div v-if="loading" class="flex items-center justify-center h-screen">
        <ProgressView />
      </div>
      <div v-if="error" class="my-6">
        <p class="text-red-400">Could not load drinks: {{ error }}</p>
      </div>
      <div v-if="!loading && !error" class="flex items-end justify-end py-4">
        <button
          class="bg-gray-300 hover:bg-gray-400 text-gray-800 font-bold py-2 px-4 rounded inline-flex items-center"
          @click="newDrink()"
        >
          <PlusIcon class="block h-4 w-4" />
        </button>
      </div>
      <ul v-if="!loading && !error" class="my-6 divide-y divide-gray-200">
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
                class="bg-gray-300 hover:bg-gray-400 text-gray-800 font-bold py-2 px-4 rounded inline-flex items-center mr-2"
                @click="editDrink(drink.id)"
              >
                <PencilIcon class="block h-4 w-4" />
              </button>
              <button
                class="bg-gray-300 hover:bg-gray-400 text-gray-800 font-bold py-2 px-4 rounded inline-flex items-center"
                @click="deleting = drink"
              >
                <TrashIcon class="block h-4 w-4" />
              </button>
            </div>
          </div>
        </li>
      </ul>
    </div>
    <div
      v-if="!!deleting"
      class="bg-white rounded-lg md:max-w-md md:mx-auto p-4 fixed inset-x-0 bottom-0 z-50 mb-4 mx-4 md:relative"
    >
      <div class="md:flex items-center">
        <div class="mt-4 md:mt-0 text-center md:text-left">
          <p class="font-bold">Delete {{ deleting.name }}</p>
          <p class="text-sm text-gray-700 mt-1">
            {{ deleting.name }} will be deleted. Past transactions will not be
            deleted, but the item will not be visible anymore. It will still
            show up in user transactions.
          </p>
        </div>
      </div>
      <div class="text-center md:text-right mt-4 md:flex md:justify-end">
        <button
          class="block w-full md:inline-block md:w-auto px-4 py-3 md:py-2 bg-red-200 text-red-700 rounded-lg font-semibold text-sm md:ml-2 md:order-2"
          @click="deleteDrink()"
        >
          Delete
        </button>
        <button
          class="block w-full md:inline-block md:w-auto px-4 py-3 md:py-2 bg-gray-200 rounded-lg font-semibold text-sm mt-4 md:mt-0 md:order-1"
          @click="deleting = null"
        >
          Cancel
        </button>
      </div>
    </div>
  </main>
</template>
