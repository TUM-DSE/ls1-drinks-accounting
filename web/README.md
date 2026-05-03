# sv

Everything you need to build a Svelte project, powered by [`sv`](https://github.com/sveltejs/cli).

## Creating a project

If you're seeing this, you've probably already done this step. Congrats!

```sh
# create a new project
npx sv create my-app
```

To recreate this project with the same configuration:

```sh
# recreate this project
npx sv@0.15.2 create --template minimal --types ts --add prettier eslint tailwindcss="plugins:typography" --install npm web
```

## Developing

Once you've created a project and installed dependencies with `npm install` (or `pnpm install` or `yarn`), start a development server:

```sh
npm run dev

# or start the server and open the app in a new browser tab
npm run dev -- --open
```

## Configuration

The web app reads these public environment variables:

- `VITE_API_ENDPOINT`: backend URL. When omitted, dev uses `http://localhost:8080` and production uses relative `/api/...` paths like the dashboard.
- `VITE_DISABLE_STATISTICS=false`: enables the weekly statistics panel. Statistics are disabled by default.
- `VITE_BASE_PATH=/web`: builds the app for a subpath. Leave unset when serving at the domain root.

## Building

To create a production version of your app:

```sh
npm run build
```

You can preview the production build with `npm run preview`.

> To deploy your app, you may need to install an [adapter](https://svelte.dev/docs/kit/adapters) for your target environment.
