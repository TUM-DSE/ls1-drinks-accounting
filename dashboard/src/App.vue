<script lang="ts">
import EventBus from "@/common/EventBus";
import { defineComponent } from "vue";

export default defineComponent({
  created() {
    EventBus.on("logout", () => {
      console.log("on logout");
      this.$router.push("/login");
    });
  },
});
</script>

<template>
  <RouterView />
</template>

<style scoped></style>
