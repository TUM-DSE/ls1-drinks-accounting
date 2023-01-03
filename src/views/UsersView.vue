<script setup lang="ts">
import HeaderView from "@/components/HeaderView.vue";
import ProgressView from "@/components/ProgressView.vue";
import { PencilIcon, PlusIcon, UserIcon, CurrencyEuroIcon } from "@heroicons/vue/20/solid";
import CurrencyFormatter from "../format/CurrencyFormatter";
</script>

<script lang="ts">
import { defineComponent } from "vue";
import type { User } from "@/network/types/User";
import { UsersService } from "@/network/services/UsersService";

export default defineComponent({
  props: {},
  data() {
    return {
      users: [] as User[],
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
      UsersService.loadAll()
        .then((users) => {
          this.users = users;
          this.loading = false;
        })
        .catch((e) => {
          this.error = e;
          this.loading = false;
        });
    },
    editUserBalance(id: string) {
      this.$router.push({ name: "editUserBalance", params: { id } });
    },
    newUser() {
      this.$router.push({ name: "addUser" });
    },
  },
});
</script>

<template>
  <HeaderView path="/users" />
  <main>
    <div class="container mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
      <h2
        class="mt-6 text-center text-3xl font-bold tracking-tight text-gray-900"
      >
        Users
      </h2>
      <div v-if="loading" class="flex items-center justify-center h-screen">
        <ProgressView />
      </div>
      <div class="flex items-end justify-end py-4">
        <button
          class="bg-gray-300 hover:bg-gray-400 text-gray-800 font-bold py-2 px-4 rounded inline-flex items-center"
          @click="newUser()"
        >
          <PlusIcon class="block h-4 w-4" />
        </button>
      </div>
      <ul v-if="!loading" class="my-6 divide-y divide-gray-200">
        <li v-for="user in users" v-bind:key="user.id" class="py-2">
          <div class="flex items-center space-x-4">
            <div class="flex-shrink-0">
              <div class="rounded-lg bg-cyan-800 p-2">
                <UserIcon class="block h-6 w-6 text-white" />
              </div>
            </div>
            <div class="flex-1 min-w-0">
              <p class="text-sm font-medium text-gray-900 truncate">
                {{ user.last_name }}, {{ user.first_name }}
              </p>
              <p class="text-sm text-gray-500 truncate">
                {{ user.email }}
              </p>
            </div>
            <div
              class="inline-flex items-center text-sm text-gray-500 truncate"
            >
              <span v-bind:class="{ 'text-red-400': user.balance < 0 }">{{
                CurrencyFormatter.format(user.balance)
              }}</span>
            </div>
            <div
              class="inline-flex items-center text-sm text-gray-500 truncate"
            >
              <button
                class="bg-gray-300 hover:bg-gray-400 text-gray-800 font-bold py-2 px-4 rounded inline-flex items-center"
                @click="editUserBalance(user.id)"
              >
                <CurrencyEuroIcon class="block h-4 w-4" />
              </button>
<!--              <button-->
<!--                class="bg-gray-300 hover:bg-gray-400 text-gray-800 font-bold py-2 px-4 rounded inline-flex items-center ml-2"-->
<!--                @click="editUser(user.id)"-->
<!--              >-->
<!--                <PencilIcon class="block h-4 w-4" />-->
<!--              </button>-->
            </div>
          </div>
        </li>
      </ul>
    </div>
  </main>
</template>
