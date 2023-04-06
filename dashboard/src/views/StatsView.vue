<script setup lang="ts">
import HeaderView from "@/components/HeaderView.vue";
import ProgressView from "@/components/ProgressView.vue";
import {
  BarElement,
  CategoryScale,
  Chart as ChartJS,
  Legend,
  LinearScale,
  LineElement,
  PointElement,
  Title,
  Tooltip,
} from "chart.js";

ChartJS.register(
  Title,
  Tooltip,
  Legend,
  BarElement,
  CategoryScale,
  LinearScale,
  PointElement,
  LineElement
);
</script>

<script lang="ts">
import { defineComponent } from "vue";
import { StatsService } from "@/network/services/StatsService";
import type { DrinkStats } from "@/network/types/Stats";
import { Line } from "vue-chartjs";

export default defineComponent({
  props: {},
  data() {
    return {
      from: new Date(),
      to: new Date(),
      drinks: [] as DrinkStats[],
      error: null,
      loading: false,
      chartOptions: {
        responsive: true,
      },
    };
  },
  computed: {
    chartData() {
      const toDate = (d: Date) => d.toISOString().split("T")[0];

      const labels: string[] = [];
      for (
        const i = new Date(this.from.getTime());
        i <= this.to;
        i.setDate(i.getDate() + 1)
      ) {
        labels.push(toDate(i));
      }

      let datasets: {
        label: string;
        data: number[];
        borderColor: string;
        tension: number;
      }[] = [];

      let i = 0;
      this.drinks.forEach((d) => {
        let groupedByDate = this.groupBy(
          d.data.map((d) => {
            return { date: toDate(d.date), count: d.count };
          }),
          "date"
        );

        let lastVal = 0;
        let data: number[] = [];

        for (const label of labels) {
          if (groupedByDate[label]) {
            const count = groupedByDate[label][0].count;
            lastVal += count;
          }
          data.push(lastVal);
        }

        datasets.push({
          label: d.name,
          data,
          borderColor: this.rainbow(this.drinks.length, i),
          tension: 0.1,
        });
        i++;
      });

      return {
        labels,
        datasets,
      };
    },
  },
  created() {
    this.from = new Date(this.to.getTime());
    this.from.setDate(this.from.getDate() - 30);
    this.fetch();
  },
  methods: {
    fetch() {
      this.loading = true;
      StatsService.getStats(this.from, this.to)
        .then((stats) => {
          this.drinks = stats.drinks;
          this.loading = false;
        })
        .catch((e) => {
          this.error = e;
          this.loading = false;
        });
    },
    groupBy<T extends Record<string, any>>(
      xs: T[],
      key: keyof T
    ): Record<string, T[]> {
      return xs.reduce(function (rv, x) {
        (rv[x[key] as string] = rv[x[key] as string] || []).push(x);
        return rv;
      }, {} as Record<string, T[]>);
    },
    rainbow(numOfSteps: number, step: number) {
      // This function generates vibrant, "evenly spaced" colours (i.e. no clustering). This is ideal for creating easily distinguishable vibrant markers in Google Maps and other apps.
      // Adam Cole, 2011-Sept-14
      // HSV to RBG adapted from: http://mjijackson.com/2008/02/rgb-to-hsl-and-rgb-to-hsv-color-model-conversion-algorithms-in-javascript
      let r = 0,
        g = 0,
        b = 0;
      let h = step / numOfSteps;
      let i = ~~(h * 6);
      let f = h * 6 - i;
      let q = 1 - f;
      switch (i % 6) {
        case 0:
          r = 1;
          g = f;
          b = 0;
          break;
        case 1:
          r = q;
          g = 1;
          b = 0;
          break;
        case 2:
          r = 0;
          g = 1;
          b = f;
          break;
        case 3:
          r = 0;
          g = q;
          b = 1;
          break;
        case 4:
          r = f;
          g = 0;
          b = 1;
          break;
        case 5:
          r = 1;
          g = 0;
          b = q;
          break;
      }
      return (
        "#" +
        ("00" + (~~(r * 255)).toString(16)).slice(-2) +
        ("00" + (~~(g * 255)).toString(16)).slice(-2) +
        ("00" + (~~(b * 255)).toString(16)).slice(-2) +
        "AA"
      );
    },
  },
});
</script>

<template>
  <HeaderView path="/stats" />
  <main>
    <div class="container mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
      <h2
        class="mt-6 text-center text-3xl font-bold tracking-tight text-gray-900"
      >
        Statistics
      </h2>
      <div v-if="loading" class="flex items-center justify-center h-screen">
        <ProgressView />
      </div>
      <div v-if="error" class="my-6">
        <p class="text-red-400">Could not load statistics: {{ error }}</p>
      </div>
      <div v-if="!loading && !error" class="my-6">
        <Line id="my-chart-id" :options="chartOptions" :data="chartData" />
      </div>
    </div>
  </main>
</template>
