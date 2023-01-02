<script setup lang="ts">
import { RouterView, useRouter } from "vue-router";
import EventBus from "@/common/EventBus";

EventBus.on("logout", () => {
  useRouter().push("/logout");
});
</script>

<template>
  <RouterView />
</template>

<style scoped></style>
