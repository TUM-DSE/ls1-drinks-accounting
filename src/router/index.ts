import { createRouter, createWebHistory } from "vue-router";
import HomeView from "../views/HomeView.vue";
import LoginView from "@/views/LoginView.vue";
import AuthService from "@/network/services/AuthService";
import BalancesView from "@/views/BalancesView.vue";
import DrinksView from "@/views/DrinksView.vue";
import EditDrinksView from "@/views/EditDrinksView.vue";

const router = createRouter({
  history: createWebHistory(import.meta.env.BASE_URL),
  routes: [
    {
      path: "/",
      name: "home",
      component: HomeView,
    },
    {
      path: "/login",
      name: "login",
      component: LoginView,
    },
    {
      path: "/balances",
      name: "balances",
      component: BalancesView,
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
    // {
    //   path: "/about",
    //   name: "about",
    //   // route level code-splitting
    //   // this generates a separate chunk (About.[hash].js) for this route
    //   // which is lazy-loaded when the route is visited.
    //   component: () => import("../views/AboutView.vue"),
    // },
  ],
});

router.beforeEach(async (to, _) => {
  if (!AuthService.isLoggedIn() && to.name !== "login") {
    return { name: "login" };
  }
});

export default router;
