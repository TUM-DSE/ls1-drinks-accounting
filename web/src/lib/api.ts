const TOKEN_KEY = 'ls1-drinks-api-token';
const USERNAME_KEY = 'ls1-drinks-api-username';
const PASSWORD_KEY = 'ls1-drinks-api-password';

const defaultApiBaseUrl = import.meta.env.DEV ? 'http://localhost:8080' : '';
const apiBaseUrl = (import.meta.env.VITE_API_ENDPOINT || defaultApiBaseUrl).replace(/\/$/, '');

export type User = {
	id: string;
	first_name: string;
	last_name: string;
	email: string;
	balance: number;
	has_pin: boolean;
};

export type Drink = {
	id: string;
	name: string;
	price: number;
	icon: string;
};

export type AuthToken = {
	access_token: string;
	token_type: string;
	valid_until: string;
};

export type PurchaseTransaction = {
	Purchase: {
		icon: string;
		name: string;
	};
};

export type Transaction = {
	id: string;
	timestamp: string;
	amount: number;
	transaction_type: 'MoneyDeposit' | PurchaseTransaction;
};

export type WeeklyDrinkStatsPoint = {
	slot_index: number;
	day_label: string;
	count: number;
};

export type WeeklyDrinkStatsSeries = {
	title: string;
	range_label: string;
	total: number;
	points: WeeklyDrinkStatsPoint[];
};

export type WeeklyDrinkStatsResponse = {
	generated_at: string;
	current_week: WeeklyDrinkStatsSeries;
	previous_week: WeeklyDrinkStatsSeries;
};

export function displayName(user: User) {
	return `${user.last_name}, ${user.first_name}`;
}

export function logout() {
	localStorage.removeItem(TOKEN_KEY);
	localStorage.removeItem(USERNAME_KEY);
	localStorage.removeItem(PASSWORD_KEY);
}

export function hasStoredCredentials() {
	return Boolean(localStorage.getItem(TOKEN_KEY) || localStorage.getItem(USERNAME_KEY));
}

export async function login(username: string, password: string) {
	logout();

	const token = await request<AuthToken>('/api/auth/login', {
		method: 'POST',
		body: { username, password },
		auth: false
	});

	localStorage.setItem(TOKEN_KEY, JSON.stringify(token));
	localStorage.setItem(USERNAME_KEY, username);
	localStorage.setItem(PASSWORD_KEY, password);

	return token;
}

export async function validToken() {
	const token = readToken();
	if (token && new Date(token.valid_until).getTime() > Date.now()) {
		return token;
	}

	const username = localStorage.getItem(USERNAME_KEY);
	const password = localStorage.getItem(PASSWORD_KEY);
	if (!username || !password) {
		throw new Error('Missing credentials');
	}

	return login(username, password);
}

export async function getUsers() {
	return request<User[]>('/api/users');
}

export async function createUser(user: Pick<User, 'first_name' | 'last_name' | 'email'>) {
	return request<User>('/api/users', {
		method: 'POST',
		body: user
	});
}

export async function getDrinks() {
	return request<Drink[]>('/api/drinks');
}

export async function buyDrink(user: string, drink: string, userPin: string | null) {
	return request<User>('/api/transactions/buy', {
		method: 'POST',
		body: {
			user,
			drink,
			user_pin: userPin
		}
	});
}

export async function checkPin(user: string, pin: string) {
	return request<boolean>(`/api/users/${user}/check_pin`, {
		method: 'POST',
		body: { user_pin: pin }
	});
}

export async function updatePin(user: string, oldPin: string | null, newPin: string | null) {
	return request<boolean>(`/api/users/${user}/pin`, {
		method: 'PUT',
		body: {
			old_pin: oldPin,
			new_pin: newPin
		}
	});
}

export async function getTransactions(
	user: string,
	options: { limit?: number; before?: Transaction } = {}
) {
	const params = new URLSearchParams();

	if (options.limit) {
		params.set('limit', String(options.limit));
	}

	if (options.before) {
		params.set('before', options.before.timestamp);
		params.set('before_id', options.before.id);
	}

	const query = params.size ? `?${params.toString()}` : '';
	return request<Transaction[]>(`/api/users/${user}/transactions${query}`);
}

export async function getWeeklyDrinkStats() {
	return request<WeeklyDrinkStatsResponse>('/api/stats/weekly_drinks', { auth: false });
}

function readToken() {
	const stored = localStorage.getItem(TOKEN_KEY);
	if (!stored) {
		return null;
	}

	try {
		return JSON.parse(stored) as AuthToken;
	} catch {
		logout();
		return null;
	}
}

async function request<T>(
	path: string,
	options: {
		method?: string;
		body?: unknown;
		auth?: boolean;
		retried?: boolean;
	} = {}
): Promise<T> {
	const headers: Record<string, string> = {
		Accept: 'application/json'
	};

	if (options.body !== undefined) {
		headers['Content-Type'] = 'application/json';
	}

	if (options.auth !== false) {
		const token = await validToken();
		headers.Authorization = `${token.token_type} ${token.access_token}`;
	}

	const response = await fetch(`${apiBaseUrl}${path}`, {
		method: options.method ?? 'GET',
		headers,
		body: options.body === undefined ? undefined : JSON.stringify(options.body)
	});

	if (response.status === 401 && options.auth !== false && !options.retried) {
		await refreshToken();
		return request(path, { ...options, retried: true });
	}

	if (!response.ok) {
		const message = await response.text();
		throw new Error(message || `${response.status} ${response.statusText}`);
	}

	if (response.status === 204) {
		return undefined as T;
	}

	return response.json() as Promise<T>;
}

async function refreshToken() {
	const username = localStorage.getItem(USERNAME_KEY);
	const password = localStorage.getItem(PASSWORD_KEY);
	if (!username || !password) {
		throw new Error('Missing credentials');
	}

	return login(username, password);
}
