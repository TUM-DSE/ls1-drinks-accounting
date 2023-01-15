# Drinks Accounting Backend

## Requirements

```shell
rustup install nightly
rustup override set nightly

cargo install sqlx-cli
```

## SQLx

When running locally, please start a local instance of the database.
This is required for `sqlx` to be able to compile-time check your queries.

```shell
docker compose -f postgres-dev.yaml up -d
```

### Migrations

When adding migrations, the development database will be migrated automatically the next time you compile the project
via `build.rs`.
Before committing, run the following command and check-in `sqlx-data.json`.

```shell
cargo sqlx prepare
```
