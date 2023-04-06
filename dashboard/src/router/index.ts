import { createRouter, createWebHistory } from "vue-router";
import LoginView from "@/views/LoginView.vue";
import AuthService from "@/network/services/AuthService";
import UsersView from "@/views/UsersView.vue";
import DrinksView from "@/views/DrinksView.vue";
import EditDrinksView from "@/views/EditDrinksView.vue";
import EditUserView from "@/views/EditUserView.vue";
import EditUserBalanceView from "@/views/EditUserBalanceView.vue";
import StatsView from "@/views/StatsView.vue";

const router = createRouter({
  history: createWebHistory(import.meta.env.BASE_URL),
  routes: [
    {
      path: "/",
      name: "home",
      redirect: "stats",
      // component: HomeView,
    },
    {
      path: "/login",
      name: "login",
      component: LoginView,
    },
    {
      path: "/stats",
      name: "stats",
      component: StatsView,
    },
    {
      path: "/users",
      name: "users",
      component: UsersView,
    },
    {
      path: "/users/:id/balance",
      name: "editUserBalance",
      component: EditUserBalanceView,
    },
    {
      path: "/users/new",
      name: "addUser",
      component: EditUserView,
    },
    {
      path: "/drinks",
      name: "drinks",
      component: DrinksView,
    },
    {
      path: "/drinks/:id",
      name: "editDrink",
      component: EditDrinksView,
    },
    {
      path: "/drinks/new",
      name: "addDrink",
      component: EditDrinksView,
    },
  ],
});

router.beforeEach(async (to, _) => {
  if (!AuthService.isLoggedIn() && to.name !== "login") {
    return { name: "login" };
  }
});

export default router;
