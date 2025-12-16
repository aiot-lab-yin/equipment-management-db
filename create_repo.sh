#!/usr/bin/env bash
set -euo pipefail

REPO="./"

# --- directories ---
mkdir -p "$REPO"/docs
mkdir -p "$REPO"/sql
mkdir -p "$REPO"/tests
mkdir -p "$REPO"/evidence/screenshots

# --- top files ---
touch "$REPO"/README.md

# --- docs files ---
touch "$REPO"/docs/00_overview.md
touch "$REPO"/docs/01_requirements.md
touch "$REPO"/docs/02_use_cases.md
touch "$REPO"/docs/03_er_diagram.md
touch "$REPO"/docs/04_logical_design.md
touch "$REPO"/docs/05_physical_design.md
touch "$REPO"/docs/06_transaction_design.md
touch "$REPO"/docs/07_query_design.md
touch "$REPO"/docs/08_validation_plan.md
touch "$REPO"/docs/09_conclusion.md

# --- sql files ---
touch "$REPO"/sql/01_schema.sql
touch "$REPO"/sql/02_seed.sql
touch "$REPO"/sql/03_basic_operations.sql
touch "$REPO"/sql/04_transaction_cases.sql
touch "$REPO"/sql/05_free_queries.sql

# --- tests files ---
touch "$REPO"/tests/01_constraints.sql
touch "$REPO"/tests/02_basic_crud.sql
touch "$REPO"/tests/03_loan_return.sql
touch "$REPO"/tests/04_discard.sql
touch "$REPO"/tests/05_search.sql
touch "$REPO"/tests/06_transaction_rollback.sql
touch "$REPO"/tests/07_concurrency_locking.md

echo "✅ Created repo skeleton: $REPO"
echo "Next:"
echo "  cd $REPO"
echo "  git init"