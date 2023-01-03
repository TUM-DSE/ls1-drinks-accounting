<script lang="ts">
import { defineComponent } from "vue";
import type { Drink } from "@/network/types/Drink";
import { DrinksService } from "@/network/services/DrinksService";
import ProgressView from "@/components/ProgressView.vue";
import HeaderView from "@/components/HeaderView.vue";

export default defineComponent({
  components: { HeaderView, ProgressView },
  data() {
    return {
      loading: false,
      submitting: false,
      drink: null as Drink | null,
      error: null as string | null,
      adding: false,
      formData: {
        icon: "",
        name: "",
        sale_price: 0,
        buy_price: 0 as number | "",
        stock: 0 as number | "",
      },
    };
  },
  created() {
    const id = this.$route.params["id"] as string;
    if (!id) {
      this.adding = true;
    } else {
      this.adding = false;
      this.loadDrink(id);
    }
  },
  methods: {
    loadDrink(id: string) {
      this.loading = true;
      DrinksService.loadDrinks()
        .then((drinks) => {
          this.drink = drinks.find((d) => d.id === id) ?? null;
          this.loading = false;

          if (this.drink) {
            this.formData.icon = this.drink.icon;
            this.formData.name = this.drink.name;
            this.formData.sale_price = this.drink.sale_price;
            this.formData.buy_price = this.drink.buy_price ?? "";
            this.formData.stock = this.drink.stock ?? "";
          }
        })
        .catch((e) => {
          this.error = e;
          this.loading = false;
        });
    },
    submit(e: Event) {
      e.preventDefault();
      if (this.submitting) {
        return;
      }
      this.submitting = true;

      const payload = {
        name: this.formData.name,
        icon: this.formData.icon,
        sale_price: this.formData.sale_price,
        buy_price:
          this.formData.buy_price !== "" ? this.formData.buy_price : null,
        stock: this.formData.stock !== "" ? this.formData.stock : null,
      };

      let promise;
      if (this.adding) {
        promise = DrinksService.createDrink(payload);
      } else {
        promise = DrinksService.updateDrink(this.drink!.id, payload);
      }

      promise
        .then(() => {
          this.submitting = false;
          this.$router.push("/drinks");
        })
        .catch((e) => {
          this.error = e;
          this.submitting = false;
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
      <div v-else>
        <p v-if="!adding && !drink">Drink not found.</p>
        <div
          v-else
          class="flex min-h-full items-center justify-center py-12 px-4 sm:px-6 lg:px-8"
        >
          <div class="w-full max-w-md space-y-8">
            <h2
              class="mt-6 text-center text-3xl font-bold tracking-tight text-gray-900"
            >
              <span v-if="adding">Add</span>
              <span v-else>Edit</span>
              Drink
            </h2>
            <form class="mt-8 space-y-6">
              <div class="-space-y-px rounded-md shadow-sm">
                <div>
                  <label for="icon" class="sr-only">Icon</label>
                  <input
                    id="icon"
                    name="icon"
                    class="relative inline-block w-1/6 appearance-none rounded-none rounded-tl-md border border-gray-300 px-3 py-2 text-gray-900 placeholder-gray-500 focus:z-10 focus:border-indigo-500 focus:outline-none focus:ring-indigo-500 sm:text-sm"
                    placeholder="Icon"
                    v-model="formData.icon"
                  />
                  <label for="name" class="sr-only">Name</label>
                  <input
                    id="name"
                    name="name"
                    required=""
                    class="relative inline-block w-5/6 appearance-none rounded-none rounded-tr-md border border-gray-300 px-3 py-2 text-gray-900 placeholder-gray-500 focus:z-10 focus:border-indigo-500 focus:outline-none focus:ring-indigo-500 sm:text-sm"
                    placeholder="Name"
                    v-model="formData.name"
                  />
                </div>
                <div>
                  <label for="sale-price" class="sr-only">Sale price</label>
                  <input
                    id="sale-price"
                    name="sale-price"
                    type="number"
                    step="0.1"
                    required=""
                    class="relative inline-block w-2/5 appearance-none rounded-none rounded-bl-md border border-gray-300 px-3 py-2 text-gray-900 placeholder-gray-500 focus:z-10 focus:border-indigo-500 focus:outline-none focus:ring-indigo-500 sm:text-sm"
                    placeholder="Sale price"
                    v-model="formData.sale_price"
                  />
                  <label for="retail-price" class="sr-only">Retail price</label>
                  <input
                    id="retail-price"
                    name="retail-price"
                    type="number"
                    step="0.1"
                    class="relative inline-block w-2/5 appearance-none rounded-none border border-gray-300 px-3 py-2 text-gray-900 placeholder-gray-500 focus:z-10 focus:border-indigo-500 focus:outline-none focus:ring-indigo-500 sm:text-sm"
                    placeholder="Retail price"
                    v-model="formData.buy_price"
                  />
                  <label for="Stock" class="sr-only">Stock</label>
                  <input
                    id="Stock"
                    name="Stock"
                    type="number"
                    required=""
                    class="relative inline-block w-1/5 appearance-none rounded-none rounded-br-md border border-gray-300 px-3 py-2 text-gray-900 placeholder-gray-500 focus:z-10 focus:border-indigo-500 focus:outline-none focus:ring-indigo-500 sm:text-sm"
                    placeholder="Stock"
                    v-model="formData.stock"
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
                  Save
                </button>
                <div
                  v-if="submitting"
                  class="flex items-center justify-center my-4"
                >
                  <ProgressView />
                </div>
              </div>
            </form>
          </div>
        </div>
      </div>
    </div>
  </main>
</template>

<style scoped></style>
