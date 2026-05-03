<svelte:options runes={false} />

<script lang="ts">
	import { browser } from '$app/environment';
	import { onMount } from 'svelte';
	import PinPad from '$lib/PinPad.svelte';
	import {
		buyDrink,
		checkPin,
		displayName,
		getDrinks,
		getTransactions,
		getUsers,
		getWeeklyDrinkStats,
		hasStoredCredentials,
		login,
		updatePin,
		validToken,
		type Drink,
		type Transaction,
		type User,
		type WeeklyDrinkStatsResponse
	} from '$lib/api';

	const currencyFormatter = new Intl.NumberFormat(undefined, {
		style: 'currency',
		currency: 'EUR'
	});
	const timeFormatter = new Intl.DateTimeFormat(undefined, {
		hour: '2-digit',
		minute: '2-digit'
	});
	const dateFormatter = new Intl.DateTimeFormat(undefined, {
		dateStyle: 'medium'
	});
	const pageSize = 100;
	const statisticsDisabled = import.meta.env.VITE_DISABLE_STATISTICS !== 'false';

	let loggedIn: boolean | null = null;
	let username = '';
	let password = '';
	let loginLoading = false;
	let loginError: string | null = null;
	let people: User[] = [];
	let drinks: Drink[] = [];
	let selectedUserId: string | null = null;
	let currentPin: string | null = null;
	let search = '';
	let loadingOverview = false;
	let overviewError: string | null = null;
	let loadingDrinkId: string | null = null;
	let drinkError: string | null = null;
	let confirmingDrink: Drink | null = null;
	let pinValue = '';
	let pinError: string | null = null;
	let checkingPin = false;
	let showingSetPin = false;
	let newPin = '';
	let setPinError: string | null = null;
	let setPinLoading = false;
	let showingTransactions = false;
	let transactions: Transaction[] = [];
	let transactionsLoading = false;
	let transactionsLoadingMore = false;
	let transactionsError: string | null = null;
	let transactionsHasMore = true;
	let stats: WeeklyDrinkStatsResponse | null = null;
	let statsLoading = false;
	let statsError: string | null = null;
	let refreshTimer: ReturnType<typeof setInterval> | null = null;

	$: sortedPeople = [...people].sort((a, b) => displayName(a).localeCompare(displayName(b)));
	$: filteredPeople = sortedPeople.filter((person) =>
		displayName(person).toLowerCase().includes(search.toLowerCase())
	);
	$: sections = groupPeople(filteredPeople);
	$: sortedDrinks = [...drinks].sort((a, b) => a.name.localeCompare(b.name));
	$: selectedUser = people.find((person) => person.id === selectedUserId) ?? null;
	$: requiresPin = Boolean(selectedUser?.has_pin && currentPin === null);
	$: transactionSections = groupTransactions(transactions);
	$: chart = stats ? buildChart(stats) : null;

	onMount(() => {
		if (!browser) {
			return;
		}

		if (!hasStoredCredentials()) {
			loggedIn = false;
			loadStats();
			return;
		}

		validToken()
			.then(async () => {
				loggedIn = true;
				await loadOverview();
			})
			.catch(() => {
				loggedIn = false;
			})
			.finally(() => {
				loadStats();
			});
	});

	async function handleLogin() {
		if (loginLoading || !username || !password) {
			return;
		}

		loginLoading = true;
		loginError = null;

		try {
			await login(username, password);
			loggedIn = true;
			password = '';
			await loadOverview();
		} catch (error) {
			loginError = messageFor(error) || 'Incorrect username/password';
			loggedIn = false;
		} finally {
			loginLoading = false;
		}
	}

	async function loadOverview() {
		if (loadingOverview) {
			return;
		}

		loadingOverview = true;
		overviewError = null;

		try {
			const [usersResult, drinksResult] = await Promise.all([getUsers(), getDrinks()]);
			people = usersResult;
			drinks = drinksResult;
			if (selectedUserId && !people.some((person) => person.id === selectedUserId)) {
				clearSelection();
			}
			restartRefreshTimer();
		} catch (error) {
			overviewError = messageFor(error);
		} finally {
			loadingOverview = false;
		}
	}

	async function loadStats() {
		if (statisticsDisabled || statsLoading) {
			return;
		}

		statsLoading = true;
		statsError = null;

		try {
			stats = await getWeeklyDrinkStats();
		} catch (error) {
			statsError = messageFor(error);
		} finally {
			statsLoading = false;
		}
	}

	function restartRefreshTimer() {
		if (refreshTimer) {
			clearInterval(refreshTimer);
		}

		refreshTimer = setInterval(() => {
			loadOverview();
			if (!statisticsDisabled) {
				loadStats();
			}
		}, 300_000);
	}

	function selectUser(user: User) {
		selectedUserId = user.id;
		currentPin = null;
		pinValue = '';
		pinError = null;
		drinkError = null;
		showingTransactions = false;
	}

	function clearSelection() {
		selectedUserId = null;
		currentPin = null;
		pinValue = '';
		pinError = null;
		showingTransactions = false;
		transactions = [];
	}

	async function submitPin() {
		if (!selectedUser || checkingPin || pinValue.length !== 4) {
			return;
		}

		checkingPin = true;
		pinError = null;

		try {
			if (await checkPin(selectedUser.id, pinValue)) {
				currentPin = pinValue;
				pinValue = '';
			} else {
				pinError = 'Incorrect PIN';
				pinValue = '';
			}
		} catch (error) {
			pinError = messageFor(error);
		} finally {
			checkingPin = false;
		}
	}

	async function setPin() {
		if (!selectedUser || setPinLoading || newPin.length !== 4) {
			return;
		}

		setPinLoading = true;
		setPinError = null;

		try {
			await updatePin(selectedUser.id, currentPin, newPin);
			currentPin = newPin;
			newPin = '';
			showingSetPin = false;
			people = await getUsers();
		} catch (error) {
			setPinError = messageFor(error);
		} finally {
			setPinLoading = false;
		}
	}

	function appendPinDigit(target: 'unlock' | 'set', digit: number) {
		if (target === 'unlock') {
			if (checkingPin || pinValue.length >= 4) {
				return;
			}
			pinValue = `${pinValue}${digit}`;
			if (pinValue.length === 4) {
				void submitPin();
			}
			return;
		}

		if (setPinLoading || newPin.length >= 4) {
			return;
		}
		newPin = `${newPin}${digit}`;
		if (newPin.length === 4) {
			void setPin();
		}
	}

	function deletePinDigit(target: 'unlock' | 'set') {
		if (target === 'unlock') {
			if (!checkingPin) {
				pinValue = pinValue.slice(0, -1);
			}
			return;
		}

		if (!setPinLoading) {
			newPin = newPin.slice(0, -1);
		}
	}

	function clearPin(target: 'unlock' | 'set') {
		if (target === 'unlock') {
			if (!checkingPin) {
				pinValue = '';
			}
			return;
		}

		if (!setPinLoading) {
			newPin = '';
		}
	}

	async function buy(drink: Drink) {
		if (!selectedUser || loadingDrinkId) {
			return;
		}

		loadingDrinkId = drink.id;
		drinkError = null;

		try {
			const updatedUser = await buyDrink(selectedUser.id, drink.id, currentPin);
			people = [...people.filter((person) => person.id !== updatedUser.id), updatedUser];
		} catch (error) {
			drinkError = messageFor(error);
		} finally {
			loadingDrinkId = null;
			confirmingDrink = null;
		}
	}

	async function openTransactions() {
		if (!selectedUser) {
			return;
		}

		showingTransactions = true;
		await loadTransactions();
	}

	async function loadTransactions() {
		if (!selectedUser) {
			return;
		}

		transactionsLoading = true;
		transactionsError = null;
		transactionsHasMore = true;
		transactions = [];

		try {
			const items = await getTransactions(selectedUser.id, { limit: pageSize });
			transactions = items;
			transactionsHasMore = items.length === pageSize;
		} catch (error) {
			transactionsError = messageFor(error);
		} finally {
			transactionsLoading = false;
		}
	}

	async function loadMoreTransactions() {
		if (!selectedUser || !transactionsHasMore || transactionsLoadingMore || transactionsLoading) {
			return;
		}

		const before = transactions.at(-1);
		if (!before) {
			return;
		}

		transactionsLoadingMore = true;
		transactionsError = null;

		try {
			const items = await getTransactions(selectedUser.id, { limit: pageSize, before });
			transactions = [...transactions, ...items];
			transactionsHasMore = items.length === pageSize;
		} catch (error) {
			transactionsError = messageFor(error);
		} finally {
			transactionsLoadingMore = false;
		}
	}

	function handleTransactionsScroll(event: Event) {
		const target = event.currentTarget;
		if (!(target instanceof HTMLElement)) {
			return;
		}

		const remaining = target.scrollHeight - target.scrollTop - target.clientHeight;
		if (remaining < 180) {
			void loadMoreTransactions();
		}
	}

	function groupPeople(items: User[]) {
		return items.reduce<{ title: string; people: User[] }[]>((groups, person) => {
			const title = person.last_name.slice(0, 1).toUpperCase() || '#';
			let group = groups.find((item) => item.title === title);
			if (!group) {
				group = { title, people: [] };
				groups.push(group);
			}
			group.people.push(person);
			return groups.sort((a, b) => a.title.localeCompare(b.title));
		}, []);
	}

	function groupTransactions(items: Transaction[]) {
		return items.reduce<{ key: string; title: string; transactions: Transaction[] }[]>((groups, item) => {
			const date = new Date(item.timestamp);
			const key = date.toDateString();
			let group = groups.find((entry) => entry.key === key);
			if (!group) {
				const today = new Date().toDateString();
				group = {
					key,
					title: key === today ? 'today' : dateFormatter.format(date),
					transactions: []
				};
				groups.push(group);
			}
			group.transactions.push(item);
			return groups;
		}, []);
	}

	function isPurchase(transaction: Transaction): transaction is Transaction & {
		transaction_type: { Purchase: { icon: string; name: string } };
	} {
		return typeof transaction.transaction_type !== 'string';
	}

	function transactionLabel(transaction: Transaction) {
		if (isPurchase(transaction)) {
			return transaction.transaction_type.Purchase.name;
		}
		return 'Deposit';
	}

	function transactionIcon(transaction: Transaction) {
		if (isPurchase(transaction)) {
			return transaction.transaction_type.Purchase.icon;
		}
		return '€';
	}

	function buildChart(statistics: WeeklyDrinkStatsResponse) {
		const currentSlot = currentSlotIndex(statistics);
		const currentPoints = statistics.current_week.points.slice(0, currentSlot + 1);
		const previousPoints = statistics.previous_week.points;
		const maxCount = Math.max(
			1,
			...currentPoints.map((point) => point.count),
			...previousPoints.map((point) => point.count)
		);

		return {
			maxCount,
			currentPath: linePath(currentPoints, maxCount),
			previousPath: linePath(previousPoints, maxCount),
			labels: statistics.current_week.points.filter((_, index) => index % 24 === 0)
		};
	}

	function currentSlotIndex(statistics: WeeklyDrinkStatsResponse) {
		const now = new Date();
		const mondayBasedDay = (now.getDay() + 6) % 7;
		return Math.min(mondayBasedDay * 24 + now.getHours(), statistics.current_week.points.length - 1);
	}

	function linePath(points: { slot_index: number; count: number }[], maxCount: number) {
		return points
			.map((point, index) => {
				const x = (point.slot_index / 167) * 100;
				const y = 100 - (point.count / maxCount) * 92 - 4;
				return `${index === 0 ? 'M' : 'L'} ${x.toFixed(2)} ${y.toFixed(2)}`;
			})
			.join(' ');
	}

	function messageFor(error: unknown) {
		return error instanceof Error ? error.message : 'Unknown error';
	}

	function fullName(user: User) {
		return `${user.first_name} ${user.last_name}`;
	}
</script>

<svelte:head>
	<title>LS1 Drinks</title>
</svelte:head>

<main class="h-screen overflow-hidden bg-[radial-gradient(circle_at_top_left,#fef3c7,transparent_34rem),radial-gradient(circle_at_bottom_right,#dbeafe,transparent_32rem),linear-gradient(135deg,#f8fafc,#e2e8f0)] text-slate-950">
	{#if loggedIn === null}
		<div class="flex min-h-screen items-center justify-center p-8">
			<div class="glass-card px-8 py-6 text-lg font-semibold">Loading...</div>
		</div>
	{:else if !loggedIn}
		<section class="grid min-h-screen place-items-center p-6">
			<div class="grid w-full max-w-5xl gap-8 lg:grid-cols-[1fr_420px] lg:items-center">
				<div class="glass-card hidden p-10 lg:block">
					<p class="text-sm font-semibold uppercase tracking-[0.28em] text-amber-700">LS1 Drinks</p>
					<h1 class="mt-4 text-5xl font-black tracking-tight">Accounting without the queue.</h1>
					<p class="mt-5 text-xl text-slate-600">Sign in to access the drinks app.</p>
				</div>

				<form class="glass-card p-7" onsubmit={(event) => (event.preventDefault(), handleLogin())}>
					<div class="mb-7 text-center lg:text-left">
						<h1 class="text-4xl font-black tracking-tight">LS1 Drinks</h1>
						<p class="mt-2 text-slate-600">Sign in to access the accounting app.</p>
					</div>

					<label class="field-label" for="username">Username</label>
					<input id="username" class="glass-input" autocomplete="username" bind:value={username} />

					<label class="field-label mt-4" for="password">Password</label>
					<input
						id="password"
						class="glass-input"
						type="password"
						autocomplete="current-password"
						bind:value={password}
					/>

					{#if loginError}
						<p class="mt-4 rounded-2xl bg-red-50 px-4 py-3 text-sm text-red-700">
							Error logging in: {loginError}
						</p>
					{/if}

					<button class="primary-button mt-6 w-full" disabled={loginLoading || !username || !password}>
						{loginLoading ? 'Logging in...' : 'Login'}
					</button>
				</form>
			</div>
		</section>
	{:else}
		<section class="grid h-full min-h-0 grid-rows-[minmax(0,42vh)_minmax(0,1fr)] gap-4 p-3 md:grid-cols-[330px_minmax(0,1fr)] md:grid-rows-none md:p-5">
			<aside class="glass-card flex h-full min-h-0 flex-col overflow-hidden p-0">
				<div class="border-b border-white/50 p-4">
					<div class="flex items-center justify-between gap-3">
						<h1 class="text-2xl font-black">People</h1>
						<div class="flex gap-2">
							<button class="icon-button" title="Refresh" onclick={loadOverview}>↻</button>
						</div>
					</div>
					<input
						class="glass-input mt-4"
						placeholder="Search people"
						type="search"
						bind:value={search}
					/>
					{#if overviewError}
						<p class="mt-3 rounded-2xl bg-red-50 px-4 py-3 text-sm text-red-700">{overviewError}</p>
					{/if}
				</div>

				<div class="flex-1 overflow-auto p-3">
					{#if loadingOverview && people.length === 0}
						<p class="p-4 text-slate-600">Loading people...</p>
					{:else}
						{#each sections as section}
							<h2 class="px-3 pb-2 pt-4 text-xs font-bold uppercase tracking-[0.2em] text-slate-500">
								{section.title}
							</h2>
							<div class="space-y-1">
								{#each section.people as person}
									<button
										class:selected-person={selectedUserId === person.id}
										class="person-row"
										onclick={() => selectUser(person)}
									>
										<span>{displayName(person)}</span>
									</button>
								{/each}
							</div>
						{/each}
					{/if}
				</div>
			</aside>

			<section class="glass-card h-full min-h-0 overflow-hidden p-0">
				{#if selectedUser}
					<div class="flex h-full flex-col">
						<header class="flex items-center justify-between gap-4 border-b border-white/50 p-4">
							<div>
								<p class="text-sm font-semibold uppercase tracking-[0.22em] text-slate-500">Selected</p>
								<h2 class="text-2xl font-black">{fullName(selectedUser)}</h2>
							</div>
							<div class="flex items-center gap-2">
								{#if !requiresPin}
									<button class="secondary-button" onclick={() => (showingSetPin = true)}>
										{selectedUser.has_pin ? 'Change PIN' : 'Set PIN'}
									</button>
								{/if}
								<button class="icon-button" title="Lock" onclick={clearSelection}>×</button>
							</div>
						</header>

						{#if requiresPin}
							<div class="grid flex-1 place-items-center p-6">
								<div class="glass-card w-full max-w-md p-7">
									<div class="text-center">
										<div class="mx-auto grid h-12 w-12 place-items-center rounded-full bg-white/60 text-3xl">
											⌾
										</div>
										<h3 class="mt-3 text-2xl font-black">Enter your passcode</h3>
									</div>
									<div class:pin-shake={pinError} class="pin-slots mt-6">
										{#each Array(4) as _, index}
											<div class:filled={pinValue.length > index} class="pin-slot"></div>
										{/each}
									</div>
									{#if pinError}
										<p class="mt-4 rounded-2xl bg-red-50 px-4 py-3 text-sm text-red-700">{pinError}</p>
									{/if}
									<PinPad
										disabled={checkingPin}
										loading={checkingPin}
										onDigit={(digit: number) => appendPinDigit('unlock', digit)}
										onDelete={() => deletePinDigit('unlock')}
										onClear={() => clearPin('unlock')}
									/>
								</div>
							</div>
						{:else if showingTransactions}
							<div class="flex min-h-0 flex-1 flex-col">
								<div class="flex items-center justify-between border-b border-white/50 p-4">
									<h3 class="text-xl font-black">History</h3>
									<button class="secondary-button" onclick={() => (showingTransactions = false)}>Back</button>
								</div>
								<div class="flex-1 overflow-auto p-4" onscroll={handleTransactionsScroll}>
									{#if transactionsLoading}
										<p class="text-slate-600">Loading history...</p>
									{:else if transactionsError}
										<p class="rounded-2xl bg-red-50 px-4 py-3 text-sm text-red-700">{transactionsError}</p>
									{:else}
										{#each transactionSections as section}
											<h4 class="px-2 py-3 text-xs font-bold uppercase tracking-[0.2em] text-slate-500">
												{section.title}
											</h4>
											<div class="space-y-2">
												{#each section.transactions as transaction}
													<div class="transaction-row">
														<span class="grid h-9 w-9 place-items-center rounded-full bg-white/60 text-lg">
															{transactionIcon(transaction)}
														</span>
														<span class="font-semibold">{transactionLabel(transaction)}</span>
														<span class:negative={transaction.amount < 0} class="ml-auto font-bold">
															{currencyFormatter.format(transaction.amount)}
														</span>
														<span class="text-sm text-slate-500">
															{timeFormatter.format(new Date(transaction.timestamp))}
														</span>
													</div>
												{/each}
											</div>
										{/each}
										{#if transactionsHasMore}
											<div class="py-5 text-center text-sm font-semibold text-slate-500">
												{transactionsLoadingMore ? 'Loading more...' : 'Scroll for more'}
											</div>
										{/if}
									{/if}
								</div>
							</div>
						{:else}
							<div class="min-h-0 flex-1 overflow-auto p-4 md:p-6">
								<button class="balance-card w-full text-left" onclick={openTransactions}>
									<span>
										<span class="block text-sm font-semibold text-slate-500">Current balance</span>
										<span class:negative={selectedUser.balance < 0} class="mt-2 block text-4xl font-black">
											{currencyFormatter.format(selectedUser.balance)}
										</span>
									</span>
									<span class="text-3xl">›</span>
								</button>

								<div class="mt-6 flex items-center justify-between gap-3">
									<h3 class="text-2xl font-black">Select a drink</h3>
								</div>

								{#if drinkError}
									<p class="mt-4 rounded-2xl bg-red-50 px-4 py-3 text-sm text-red-700">
										Error selecting drink: {drinkError}
									</p>
								{/if}

								<div class="mt-4 grid grid-cols-2 gap-3 lg:grid-cols-4">
									{#each sortedDrinks as drink}
										<button
											class="drink-tile"
											disabled={Boolean(loadingDrinkId)}
											onclick={() => {
												drinkError = null;
												confirmingDrink = drink;
											}}
										>
											<span class="text-4xl">{drink.icon}</span>
											<span class="text-lg font-bold">{drink.name}</span>
											<span class="font-semibold text-slate-500">{currencyFormatter.format(drink.price)}</span>
											{#if loadingDrinkId === drink.id}
												<span class="tile-overlay">Loading...</span>
											{/if}
										</button>
									{/each}
								</div>
							</div>
						{/if}
					</div>
				{:else}
					<div class="h-full overflow-auto p-6">
						{#if statisticsDisabled}
							<div class="grid min-h-full place-items-center text-center">
								<p class="text-2xl font-black">Select a person</p>
							</div>
						{:else}
							<h2 class="text-4xl font-black tracking-tight">Coffee Statistics</h2>
							<p class="mt-2 text-slate-600">Cumulative drinks from Monday to Sunday.</p>

							{#if statsLoading && !stats}
							<div class="glass-card mt-6 p-8 text-center">Loading statistics...</div>
						{:else if statsError}
							<div class="glass-card mt-6 p-8">
								<p class="font-bold">Could not load statistics</p>
								<p class="mt-2 text-sm text-slate-600">{statsError}</p>
							</div>
						{:else if stats && chart}
							<div class="mt-6 grid gap-4 lg:grid-cols-2">
								<div class="summary-card border-amber-300">
									<p class="text-lg font-bold">{stats.current_week.title}</p>
									<p class="text-sm text-slate-500">{stats.current_week.range_label}</p>
									<p class="mt-4 text-5xl font-black">{stats.current_week.total}</p>
									<p class="text-sm text-slate-500">drinks</p>
								</div>
								<div class="summary-card border-slate-300">
									<p class="text-lg font-bold">{stats.previous_week.title}</p>
									<p class="text-sm text-slate-500">{stats.previous_week.range_label}</p>
									<p class="mt-4 text-5xl font-black">{stats.previous_week.total}</p>
									<p class="text-sm text-slate-500">drinks</p>
								</div>
							</div>

							<div class="glass-card mt-4 p-5">
								<div class="mb-3 flex gap-4 text-sm font-semibold">
									<span class="text-amber-600">This week</span>
									<span class="text-slate-500">Last week</span>
									<span class="ml-auto text-slate-500">max {chart.maxCount}</span>
								</div>
								<svg viewBox="0 0 100 112" class="h-[22rem] w-full overflow-visible">
									<path d="M 0 96 H 100" stroke="rgba(15,23,42,.16)" stroke-width="0.4" />
									{#each chart.labels as label}
										<line
											x1={(label.slot_index / 167) * 100}
											x2={(label.slot_index / 167) * 100}
											y1="4"
											y2="96"
											stroke="rgba(15,23,42,.12)"
											stroke-width="0.35"
										/>
										<text
											x={(label.slot_index / 167) * 100}
											y="109"
											text-anchor="middle"
											class="fill-slate-500 text-[3px] font-semibold"
										>
											{label.day_label}
										</text>
									{/each}
									<path d={chart.previousPath} fill="none" stroke="#64748b" stroke-width="1.4" />
									<path d={chart.currentPath} fill="none" stroke="#f59e0b" stroke-width="2.2" />
								</svg>
							</div>
						{/if}
						{/if}
					</div>
				{/if}
			</section>
		</section>
	{/if}
</main>

{#if confirmingDrink}
	<div class="modal-backdrop">
		<button
			class="modal-scrim"
			type="button"
			aria-label="Close buy confirmation"
			onclick={() => (confirmingDrink = null)}
		></button>
		<div class="modal-card">
			<div class="text-center">
				<div class="mx-auto text-6xl">{confirmingDrink.icon}</div>
				<h2 class="mt-4 text-2xl font-black">Buy {confirmingDrink.name}?</h2>
				<p class="mt-2 text-lg font-semibold text-slate-600">
					{currencyFormatter.format(confirmingDrink.price)}
				</p>
			</div>
			{#if drinkError}
				<p class="mt-4 rounded-2xl bg-red-50 px-4 py-3 text-sm text-red-700">
					Error selecting drink: {drinkError}
				</p>
			{/if}
			<div class="mt-6 flex gap-3">
				<button
					class="secondary-button flex-1"
					type="button"
					disabled={Boolean(loadingDrinkId)}
					onclick={() => (confirmingDrink = null)}
				>
					Cancel
				</button>
				<button
					class="primary-button flex-1"
					type="button"
					disabled={Boolean(loadingDrinkId)}
					onclick={() => confirmingDrink && buy(confirmingDrink)}
				>
					{loadingDrinkId === confirmingDrink.id ? 'Buying...' : `Buy ${confirmingDrink.name}`}
				</button>
			</div>
		</div>
	</div>
{/if}

{#if showingSetPin && selectedUser}
	<div class="modal-backdrop">
		<button
			class="modal-scrim"
			type="button"
			aria-label="Close set PIN dialog"
			onclick={() => (showingSetPin = false)}
		></button>
		<form class="modal-card" onsubmit={(event) => (event.preventDefault(), setPin())}>
			<div class="text-center">
				<div class="mx-auto grid h-12 w-12 place-items-center rounded-full bg-white/60 text-3xl">⌾</div>
				<h2 class="mt-3 text-2xl font-black">Set your passcode</h2>
			</div>
			<div class="pin-slots mt-6">
				{#each Array(4) as _, index}
					<div class:filled={newPin.length > index} class="pin-slot">
						{#if newPin[index]}{newPin[index]}{/if}
					</div>
				{/each}
			</div>
			{#if setPinError}
				<p class="mt-4 rounded-2xl bg-red-50 px-4 py-3 text-sm text-red-700">{setPinError}</p>
			{/if}
			<PinPad
				disabled={setPinLoading}
				loading={setPinLoading}
				onDigit={(digit: number) => appendPinDigit('set', digit)}
				onDelete={() => deletePinDigit('set')}
				onClear={() => clearPin('set')}
			/>
			<div class="mt-6 flex gap-3">
				<button class="secondary-button flex-1" type="button" onclick={() => (showingSetPin = false)}>
					Cancel
				</button>
			</div>
		</form>
	</div>
{/if}
