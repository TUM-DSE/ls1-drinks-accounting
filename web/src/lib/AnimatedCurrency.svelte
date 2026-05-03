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
	const easeInOut = cubicBezier(.25,.1,.25,1);

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
			const easedProgress = easeInOut(progress);
			displayedValue = from + (to - from) * easedProgress;

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

	function cubicBezier(x1: number, y1: number, x2: number, y2: number) {
		const sampleCurveX = (t: number) =>
			((1 - 3 * x2 + 3 * x1) * t + (3 * x2 - 6 * x1)) * t * t + 3 * x1 * t;
		const sampleCurveY = (t: number) =>
			((1 - 3 * y2 + 3 * y1) * t + (3 * y2 - 6 * y1)) * t * t + 3 * y1 * t;
		const sampleCurveDerivativeX = (t: number) =>
			(3 * (1 - 3 * x2 + 3 * x1) * t + 2 * (3 * x2 - 6 * x1)) * t + 3 * x1;

		return (x: number) => {
			let t = x;
			for (let i = 0; i < 4; i += 1) {
				const currentX = sampleCurveX(t) - x;
				const derivative = sampleCurveDerivativeX(t);
				if (Math.abs(currentX) < 0.001 || Math.abs(derivative) < 0.001) {
					break;
				}
				t -= currentX / derivative;
			}

			return sampleCurveY(Math.max(0, Math.min(1, t)));
		};
	}
</script>

<span class={`${className} ${displayedValue < 0 ? negativeClass : ''}`}>
	{formatter.format(displayedValue)}
</span>
