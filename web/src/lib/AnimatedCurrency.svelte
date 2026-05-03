<svelte:options runes={false} />

<script lang="ts">
	import { onDestroy, onMount } from 'svelte';

	export let value: number;
	export let className = '';
	export let negativeClass = 'negative';

	const formatter = new Intl.NumberFormat(undefined, {
		style: 'currency',
		currency: 'EUR'
	});
	const durationMs = 350;

	let displayedValue = value;
	let mounted = false;
	let animationFrame: number | null = null;
	let animationTarget: number | null = null;

	$: if (mounted && animationTarget !== value && Math.abs(displayedValue - value) >= 0.005) {
		animate(displayedValue, value);
	} else if (!mounted) {
		displayedValue = value;
	}

	onMount(() => {
		mounted = true;
		displayedValue = value;
	});

	onDestroy(() => {
		cancelAnimation();
	});

	function animate(from: number, to: number) {
		cancelAnimation();
		animationTarget = to;

		if (window.matchMedia('(prefers-reduced-motion: reduce)').matches) {
			displayedValue = to;
			animationTarget = null;
			return;
		}

		const startedAt = performance.now();
		const tick = (now: number) => {
			const progress = Math.min((now - startedAt) / durationMs, 1);
			displayedValue = from + (to - from) * progress;

			if (progress < 1) {
				animationFrame = requestAnimationFrame(tick);
				return;
			}

			displayedValue = to;
			animationFrame = null;
			animationTarget = null;
		};

		animationFrame = requestAnimationFrame(tick);
	}

	function cancelAnimation() {
		if (animationFrame !== null) {
			cancelAnimationFrame(animationFrame);
			animationFrame = null;
		}
	}
</script>

<span class={`${className} ${displayedValue < 0 ? negativeClass : ''}`}>
	{formatter.format(displayedValue)}
</span>
