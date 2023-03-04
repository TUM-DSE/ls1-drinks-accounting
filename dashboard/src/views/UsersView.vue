<script setup lang="ts">
import HeaderView from "@/components/HeaderView.vue";
import ProgressView from "@/components/ProgressView.vue";
import {
  PencilIcon,
  PlusIcon,
  UserIcon,
  CurrencyEuroIcon,
  TrashIcon,
  LockClosedIcon,
  LockOpenIcon,
} from "@heroicons/vue/20/solid";
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
      deleting: null as User | null,
      editing: null as User | null,
    };
  },
  created() {
    this.fetch();
  },
  methods: {
    fetch() {
      this.loading = true;
      this.deleting = null;
      this.editing = null;
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
    deleteUser() {
      const deleting = this.deleting;
      if (!deleting) {
        return;
      }

      UsersService.deleteUser(deleting.id).then(() => this.fetch());
    },
    resetPassword() {
      const editing = this.editing;
      if (!editing) {
        return;
      }

      UsersService.resetUserPin(editing.id).then(() => this.fetch());
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
      <div v-if="!loading && !error" class="flex items-end justify-end py-4">
        <button
          class="bg-gray-300 hover:bg-gray-400 text-gray-800 font-bold py-2 px-4 rounded inline-flex items-center"
          @click="newUser()"
        >
          <PlusIcon class="block h-4 w-4" />
        </button>
      </div>
      <div v-if="error" class="my-6">
        <p class="text-red-400">Could not load users: {{ error }}</p>
      </div>
      <ul v-if="!loading && !error" class="my-6 divide-y divide-gray-200">
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
                <LockClosedIcon
                  title="User has set a pin"
                  class="inline-block align-middle h-4 w-4"
                  v-if="user.has_pin"
                ></LockClosedIcon>
                <LockOpenIcon
                  title="User has not set a pin"
                  class="inline-block align-middle h-4 w-4"
                  v-else
                ></LockOpenIcon>
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
                class="bg-gray-300 hover:bg-gray-400 text-gray-800 font-bold py-2 px-4 rounded inline-flex items-center mr-2"
                @click="editUserBalance(user.id)"
              >
                <CurrencyEuroIcon class="block h-4 w-4" />
              </button>
              <button
                class="bg-gray-300 hover:bg-gray-400 text-gray-800 font-bold py-2 px-4 rounded inline-flex items-center mr-2"
                @click="
                  deleting = user;
                  editing = null;
                "
              >
                <TrashIcon class="block h-4 w-4" />
              </button>
              <button
                class="bg-gray-300 hover:bg-gray-400 text-gray-800 font-bold py-2 px-4 rounded inline-flex items-center"
                @click="
                  deleting = null;
                  editing = user;
                "
              >
                <PencilIcon class="block h-4 w-4" />
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
          <p class="font-bold">
            Delete {{ deleting.last_name }}, {{ deleting.first_name }}
          </p>
          <p class="text-sm text-gray-700 mt-1">
            {{ deleting.last_name }}, {{ deleting.first_name }} will be deleted.
            Past transactions will not be deleted, but the user will not be
            visible anymore.
          </p>
        </div>
      </div>
      <div class="text-center md:text-right mt-4 md:flex md:justify-end">
        <button
          class="block w-full md:inline-block md:w-auto px-4 py-3 md:py-2 bg-red-200 text-red-700 rounded-lg font-semibold text-sm md:ml-2 md:order-2"
          @click="deleteUser()"
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
    <div
      v-if="!!editing"
      class="bg-white rounded-lg md:max-w-md md:mx-auto p-4 fixed inset-x-0 bottom-0 z-50 mb-4 mx-4 md:relative"
    >
      <div class="md:flex items-center">
        <div class="mt-4 md:mt-0 text-center md:text-left">
          <p class="font-bold mb-4">
            Edit {{ editing.last_name }}, {{ editing.first_name }}
          </p>
          <p class="text-sm text-gray-700 mt-1">
            The following actions cannot be undone.
          </p>
        </div>
      </div>
      <div class="text-center md:text-right mt-4 md:flex md:justify-end">
        <button
          class="block w-full md:inline-block md:w-auto px-4 py-3 md:py-2 bg-blue-200 rounded-lg font-semibold text-sm md:ml-2 md:order-2"
          @click="resetPassword()"
        >
          Reset password
        </button>
        <button
          class="block w-full md:inline-block md:w-auto px-4 py-3 md:py-2 bg-gray-200 rounded-lg font-semibold text-sm mt-4 md:mt-0 md:order-1"
          @click="editing = null"
        >
          Cancel
        </button>
      </div>
    </div>
  </main>
</template>
