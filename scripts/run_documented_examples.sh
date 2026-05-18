#!/usr/bin/env bash
set -euo pipefail

examples=(
  examples/resource_app
  examples/orm_migration
  examples/auth_policy
  examples/rails_ops
  examples/production_stack
  examples/production_api
  examples/process_topology
)

for example in "${examples[@]}"; do
  echo "==> moon run ${example}"
  moon run "${example}"
done
