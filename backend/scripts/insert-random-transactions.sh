#!/usr/bin/env bash

set -euo pipefail

MYDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TRANSACTION_COUNT="${1:-350}"

docker compose -f "$MYDIR/../postgres-dev.yaml" exec -T db \
  psql \
  -v transaction_count="$TRANSACTION_COUNT" \
  -d drinks-accounting \
  < "$MYDIR/insert-random-transactions.sql"
