import adapter from '@sveltejs/adapter-static';

const basePath = process.env.VITE_BASE_PATH ?? '';

/** @type {import('@sveltejs/kit').Config} */
const config = {
	compilerOptions: {
		// Force runes mode for the project, except for libraries. Can be removed in svelte 6.
		runes: ({ filename }) => (filename.split(/[/\\]/).includes('node_modules') ? undefined : true)
	},
	kit: {
		adapter: adapter({
			fallback: 'index.html'
		}),
		paths: {
			base: basePath
		}
	}
};

export default config;
