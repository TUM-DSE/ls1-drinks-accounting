import { createRouter, createWebHistory } from "vue-router";
import HomeView from "../views/HomeView.vue";
import LoginView from "@/views/LoginView.vue";
import AuthService from "@/network/services/AuthService";
import UsersView from "@/views/UsersView.vue";
import DrinksView from "@/views/DrinksView.vue";
import EditDrinksView from "@/views/EditDrinksView.vue";
import EditUserView from "@/views/EditUserView.vue";
import EditUserBalanceView from "@/views/EditUserBalanceView.vue";

const router = createRouter({
  history: createWebHistory(import.meta.env.BASE_URL),
  routes: [
    {
      path: "/",
      name: "home",
      redirect: "users",
      // component: HomeView,
    },
    {
      path: "/login",
      name: "login",
      component: LoginView,
    },
    {
      path: "/users",
      name: "users",
      component: UsersView,
    },
    // {
    //   path: "/users/:id",
    //   name: "editUser",
    //   component: EditUserView,
    // },
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
