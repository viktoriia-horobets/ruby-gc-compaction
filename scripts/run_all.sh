#!/usr/bin/env bash
set -euo pipefail

mkdir -p data

COMMON="RUNS=5 N_OBJECTS=1200000 KEEP_EVERY=5 CHURN=1 CHURN_PASSES=4 CHURN_BATCHES=12 CHURN_ARR_SIZE_BIG=120000 CHURN_ARR_SIZE_SML=8000"

echo "[1/3] No compaction..."
env $COMMON DO_COMPACT=0 AUTO_MODE=0 CSV_OUT=data/results_no_compact.csv \
ruby scripts/compaction_experiment.rb

echo "[2/3] Manual compaction (double)..."
env $COMMON DO_COMPACT=1 DOUBLE_COMPACT=1 AUTO_MODE=0 CSV_OUT=data/results_manual_compact.csv \
ruby scripts/compaction_experiment.rb

echo "[3/3] Auto compaction..."
env $COMMON DO_COMPACT=0 AUTO_MODE=1 CSV_OUT=data/results_auto_compact.csv \
ruby scripts/compaction_experiment.rb

echo "Done. CSV files in ./data"
