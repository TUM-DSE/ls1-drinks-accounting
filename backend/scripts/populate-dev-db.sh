#!/usr/bin/env bash

set -euxo pipefail

MYDIR="$(dirname "$(which "$0")")"

docker compose -f "$MYDIR/../postgres-dev.yaml" exec -T db psql -d drinks-accounting < "$MYDIR/populate-dev-db.sql"

