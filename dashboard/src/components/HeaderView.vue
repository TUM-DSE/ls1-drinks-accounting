<script lang="ts">
import {
  Disclosure,
  DisclosureButton,
  DisclosurePanel,
  Menu,
  MenuButton,
  MenuItem,
  MenuItems,
} from "@headlessui/vue";
import {
  Bars3Icon,
  UserCircleIcon,
  XMarkIcon,
} from "@heroicons/vue/24/outline";
import { defineComponent } from "vue";
import AuthService from "@/network/services/AuthService";

export default defineComponent({
  components: {
    DisclosureButton,
    DisclosurePanel,
    // eslint-disable-next-line vue/no-reserved-component-names
    Menu,
    MenuItem,
    MenuItems,
    MenuButton,
    Disclosure,
    Bars3Icon,
    UserCircleIcon,
    XMarkIcon,
  },
  props: {
    path: String,
  },
  data() {
    return {
      navigation: [
        { name: "Statistics", href: "/stats" },
        { name: "Users", href: "/users" },
        { name: "Drinks", href: "/drinks" },
      ].map((item) => {
        return {
          name: item.name,
          href: item.href,
          current: item.href == this.$props.path,
        };
      }) as { name: string; href: string; current: boolean }[],
      userNavigation: [
        {
          name: "Sign out",
          onClick: () => {
            AuthService.logout();
          },
        },
      ] as { name: string; onClick: () => void }[],
    };
  },
});
</script>

<template>
  <div class="min-h-full">
    <Disclosure as="nav" class="bg-gray-800" v-slot="{ open }">
      <div class="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
        <div class="flex h-16 items-center justify-between">
          <div class="flex items-center">
            <div class="flex-shrink-0">
              <!--              <img-->
              <!--                class="h-8 w-8"-->
              <!--                src="https://tailwindui.com/img/logos/mark.svg?color=indigo&shade=500"-->
              <!--                alt="LS1 Drinks Accounting"-->
              <!--              />-->
            </div>
            <div class="hidden md:block">
              <div class="ml-10 flex items-baseline space-x-4">
                <a
                  v-for="item in navigation"
                  :key="item.name"
                  :href="item.href"
                  :class="[
                    item.current
                      ? 'bg-gray-900 text-white'
                      : 'text-gray-300 hover:bg-gray-700 hover:text-white',
                    'px-3 py-2 rounded-md text-sm font-medium',
                  ]"
                  :aria-current="item.current ? 'page' : undefined"
                  >{{ item.name }}</a
                >
              </div>
            </div>
          </div>
          <div class="hidden md:block">
            <div class="ml-4 flex items-center md:ml-6">
              <!-- Profile dropdown -->
              <Menu as="div" class="relative ml-3">
                <div>
                  <MenuButton
                    class="flex max-w-xs items-center rounded-full bg-gray-800 text-sm focus:outline-none focus:ring-2 focus:ring-white focus:ring-offset-2 focus:ring-offset-gray-800"
                  >
                    <span class="sr-only">Open user menu</span>
                    <UserCircleIcon class="h-8 w-8 rounded-full text-white" />
                  </MenuButton>
                </div>
                <transition
                  enter-active-class="transition ease-out duration-100"
                  enter-from-class="transform opacity-0 scale-95"
                  enter-to-class="transform opacity-100 scale-100"
                  leave-active-class="transition ease-in duration-75"
                  leave-from-class="transform opacity-100 scale-100"
                  leave-to-class="transform opacity-0 scale-95"
                >
                  <MenuItems
                    class="absolute right-0 z-10 mt-2 w-48 origin-top-right rounded-md bg-white py-1 shadow-lg ring-1 ring-black ring-opacity-5 focus:outline-none"
                  >
                    <MenuItem
                      v-for="item in userNavigation"
                      :key="item.name"
                      v-slot="{ active }"
                    >
                      <a
                        @click="item.onClick"
                        :class="[
                          active ? 'bg-gray-100' : '',
                          'block px-4 py-2 text-sm text-gray-700',
                        ]"
                        >{{ item.name }}</a
                      >
                    </MenuItem>
                  </MenuItems>
                </transition>
              </Menu>
            </div>
          </div>
          <div class="-mr-2 flex md:hidden">
            <!-- Mobile menu button -->
            <DisclosureButton
              class="inline-flex items-center justify-center rounded-md bg-gray-800 p-2 text-gray-400 hover:bg-gray-700 hover:text-white focus:outline-none focus:ring-2 focus:ring-white focus:ring-offset-2 focus:ring-offset-gray-800"
            >
              <span class="sr-only">Open main menu</span>
              <Bars3Icon
                v-if="!open"
                class="block h-6 w-6"
                aria-hidden="true"
              />
              <XMarkIcon v-else class="block h-6 w-6" aria-hidden="true" />
            </DisclosureButton>
          </div>
        </div>
      </div>

      <DisclosurePanel class="md:hidden">
        <div class="space-y-1 px-2 pt-2 pb-3 sm:px-3">
          <DisclosureButton
            v-for="item in navigation"
            :key="item.name"
            as="a"
            :href="item.href"
            :class="[
              item.current
                ? 'bg-gray-900 text-white'
                : 'text-gray-300 hover:bg-gray-700 hover:text-white',
              'block px-3 py-2 rounded-md text-base font-medium',
            ]"
            :aria-current="item.current ? 'page' : undefined"
            >{{ item.name }}
          </DisclosureButton>
        </div>
        <div class="border-t border-gray-700 pt-4 pb-3">
          <div class="flex items-center px-5">
            <div class="flex-shrink-0">
              <UserCircleIcon />
            </div>
          </div>
          <div class="mt-3 space-y-1 px-2">
            <DisclosureButton
              v-for="item in userNavigation"
              :key="item.name"
              @click="item.onClick"
              as="a"
              class="block rounded-md px-3 py-2 text-base font-medium text-gray-400 hover:bg-gray-700 hover:text-white"
            >
              {{ item.name }}
            </DisclosureButton>
          </div>
        </div>
      </DisclosurePanel>
    </Disclosure>

    <!--    <header class="bg-white shadow">-->
    <!--      <div class="mx-auto max-w-7xl py-6 px-4 sm:px-6 lg:px-8">-->
    <!--        <h1 class="text-3xl font-bold tracking-tight text-gray-900">Dashboard</h1>-->
    <!--      </div>-->
    <!--    </header>-->
    <!--    <main>-->
    <!--      <div class="mx-auto max-w-7xl py-6 sm:px-6 lg:px-8">-->
    <!--        &lt;!&ndash; Replace with your content &ndash;&gt;-->
    <!--        <div class="px-4 py-6 sm:px-0">-->
    <!--          <div class="h-96 rounded-lg border-4 border-dashed border-gray-200"/>-->
    <!--        </div>-->
    <!--        &lt;!&ndash; /End replace &ndash;&gt;-->
    <!--      </div>-->
    <!--    </main>-->
  </div>
</template>

<style scoped></style>
