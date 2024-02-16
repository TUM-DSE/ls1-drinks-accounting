# Coffee App for LS1

This monorepo hosts the code for the [coffee app](./ios), [backend](./backend), and [admin dashboard](./dashboard).

See the READMEs in the respective subdirectories for more information.

## Deployment

The backend, database, and admin dashboard are hosted in a VM provided by the chair admins.

## Contributing

To get a development instance up and running, you need Docker, Rust, npm (for the dashboard), and Xcode (for the app).

To start the backend, run:

```sh
cd backend
docker compose -f postgres-dev.yaml up -d
cargo run
```

To populate the database with some values (e.g. users, drinks, etc.), run the following.
This needs to be done **after** the backend has been run for the first time, as that takes care of running all migrations.
Alternatively, you can also run `cargo sqlx migrate run`.

```sh
./scripts/populate-dev-db.sh
```

To start the dashboard, run

```sh
cd dashboard
npm i
npm run dev
```

To run the ios app, open `ios/LS1DrinksAccounting.xcodeproj` in Xcode. If you're running the app on a real device, you need to update
`ios/LS1DrinksAccounting/Config/debug.xcconfig` to point at your machine.

You can then use the following credentials to log into the admin dashboard/ios app:


| Username |  Password  |  Purpose  |
| -------- | ---------- | --------- |
| `admin`  | `password` | Dashboard |
|  `user`  | `password` |  iOS App  |

### Links

- Dashboard: [https://ls1-coffee.dse.cit.tum.de](https://ls1-coffee.dse.cit.tum.de)
- Link to download the app: [https://ls1-coffee.dse.cit.tum.de/app/index.html](https://ls1-coffee.dse.cit.tum.de/app/index.html)

