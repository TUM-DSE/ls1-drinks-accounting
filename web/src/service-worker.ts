import { base, build, files, version } from '$service-worker';

const worker = self as unknown as ServiceWorkerGlobalScope;
const cacheName = `ls1-drinks-${version}`;
const appShell = `${base}/`;
const staticAssets = new Set([...build, ...files]);

worker.addEventListener('install', (event) => {
	event.waitUntil(
		caches
			.open(cacheName)
			.then((cache) => cache.addAll([...staticAssets, appShell]))
			.then(() => worker.skipWaiting())
	);
});

worker.addEventListener('activate', (event) => {
	event.waitUntil(
		caches
			.keys()
			.then((keys) =>
				Promise.all(keys.filter((key) => key !== cacheName).map((key) => caches.delete(key)))
			)
			.then(() => worker.clients.claim())
	);
});

worker.addEventListener('fetch', (event) => {
	if (event.request.method !== 'GET') {
		return;
	}

	const url = new URL(event.request.url);
	if (url.origin !== location.origin) {
		return;
	}

	if (event.request.mode === 'navigate') {
		event.respondWith(networkFirst(event.request));
		return;
	}

	if (staticAssets.has(url.pathname)) {
		event.respondWith(cacheFirst(event.request));
	}
});

async function networkFirst(request: Request) {
	const cache = await caches.open(cacheName);

	try {
		const response = await fetch(new Request(request, { cache: 'no-store' }));
		if (response.ok) {
			await cache.put(request, response.clone());
			await cache.put(appShell, response.clone());
		}
		return response;
	} catch {
		return (await cache.match(request)) ?? (await cache.match(appShell)) ?? Response.error();
	}
}

async function cacheFirst(request: Request) {
	const cached = await caches.match(request);
	if (cached) {
		return cached;
	}

	const response = await fetch(request);
	if (response.ok) {
		const cache = await caches.open(cacheName);
		await cache.put(request, response.clone());
	}
	return response;
}
