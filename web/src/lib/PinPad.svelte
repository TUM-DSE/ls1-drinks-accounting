<svelte:options runes={false} />

<script lang="ts">
	export let disabled = false;
	export let loading = false;
	export let onDigit: (digit: number) => void;
	export let onDelete: () => void;
	export let onClear: () => void;
</script>

<div class:pin-pad-disabled={disabled} class="pin-pad mt-7">
	{#each [1, 2, 3, 4, 5, 6, 7, 8, 9] as digit}
		<button class="pin-key" type="button" {disabled} on:click={() => onDigit(digit)}>{digit}</button>
	{/each}
	<button class="pin-key pin-key-secondary" type="button" {disabled} on:click={onClear}>Clear</button>
	<button class="pin-key" type="button" {disabled} on:click={() => onDigit(0)}>0</button>
	<button class="pin-key pin-key-secondary text-2xl" type="button" {disabled} on:click={onDelete}>
		⌫
	</button>
	{#if loading}
		<div class="pin-loading">Loading...</div>
	{/if}
</div>
