<script lang="ts">
import { defineComponent } from "vue";
import ProgressView from "@/components/ProgressView.vue";
import HeaderView from "@/components/HeaderView.vue";
import type { User } from "@/network/types/User";
import { UsersService } from "@/network/services/UsersService";

export default defineComponent({
  components: { HeaderView, ProgressView },
  data() {
    return {
      loading: false,
      submitting: false,
      user: null as User | null,
      error: null as string | null,
      adding: false,
      formData: {
        first_name: "",
        last_name: "",
        email: "",
      },
    };
  },
  created() {
    const id = this.$route.params["id"] as string;
    if (!id) {
      this.adding = true;
    } else {
      this.adding = false;
      this.loadUser(id);
    }
  },
  methods: {
    loadUser(id: string) {
      this.loading = true;
      UsersService.loadAll()
        .then((users) => {
          this.user = users.find((d) => d.id === id) ?? null;
          this.loading = false;

          if (this.user) {
            this.formData.first_name = this.user.first_name;
            this.formData.last_name = this.user.last_name;
            this.formData.email = this.user.email;
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
      this.error = null;
      if (!this.formData.first_name) {
        this.error = "Field 'first name' is required";
        return;
      }
      if (!this.formData.last_name) {
        this.error = "Field 'last name' is required";
        return;
      }
      if (!this.formData.email) {
        this.error = "Field 'email' is required";
        return;
      }

      this.submitting = true;

      const payload = {
        first_name: this.formData.first_name,
        last_name: this.formData.last_name,
        email: this.formData.email,
      };

      let promise;
      if (this.adding) {
        promise = UsersService.createUser(payload);
      } else {
        promise = UsersService.updateUser(this.user!.id, payload);
      }

      promise
        .then(() => {
          this.submitting = false;
          this.$router.push("/users");
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
  <HeaderView path="/users" />
  <main>
    <div class="container mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
      <div v-if="loading" class="flex items-center justify-center h-screen">
        <ProgressView />
      </div>
      <div v-else>
        <p v-if="!adding && !user">User not found.</p>
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
              User
            </h2>
            <form class="mt-8 space-y-3">
              <div class="-space-y-px rounded-md shadow-sm">
                <div>
                  <label for="first_name" class="sr-only">First name</label>
                  <input
                    id="first_name"
                    name="first_name"
                    required
                    class="relative inline-block w-1/2 appearance-none rounded-none rounded-tl-md border border-gray-300 px-3 py-2 text-gray-900 placeholder-gray-500 focus:z-10 focus:border-indigo-500 focus:outline-none focus:ring-indigo-500 sm:text-sm"
                    placeholder="First name"
                    v-model="formData.first_name"
                  />
                  <label for="last_name" class="sr-only">Last name</label>
                  <input
                    id="last_name"
                    name="last_name"
                    required
                    class="relative inline-block w-1/2 appearance-none rounded-none rounded-tr-md border border-gray-300 px-3 py-2 text-gray-900 placeholder-gray-500 focus:z-10 focus:border-indigo-500 focus:outline-none focus:ring-indigo-500 sm:text-sm"
                    placeholder="Last name"
                    v-model="formData.last_name"
                  />
                </div>
                <div>
                  <label for="email" class="sr-only">E-Mail</label>
                  <input
                    id="email"
                    name="email"
                    type="email"
                    required
                    class="relative inline-block w-full appearance-none rounded-none rounded-bl-md border border-gray-300 px-3 py-2 text-gray-900 placeholder-gray-500 focus:z-10 focus:border-indigo-500 focus:outline-none focus:ring-indigo-500 sm:text-sm"
                    placeholder="E-Mail"
                    v-model="formData.email"
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
