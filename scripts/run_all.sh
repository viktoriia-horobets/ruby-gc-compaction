#!/usr/bin/env bash
set -euo pipefail

mkdir -p data

echo "[1/3] No compaction..."
RUNS=5 N_OBJECTS=300000 KEEP_EVERY=3 DO_COMPACT=0 CSV_OUT=data/results_no_compact.csv ruby scripts/compaction_experiment.rb

echo "[2/3] Manual compaction..."
RUNS=5 N_OBJECTS=300000 KEEP_EVERY=3 DO_COMPACT=1 CSV_OUT=data/results_manual_compact.csv ruby scripts/compaction_experiment.rb

echo "[3/3] Auto compaction..."
RUNS=5 N_OBJECTS=300000 KEEP_EVERY=3 CSV_OUT=data/results_auto_compact.csv ruby scripts/compaction_experiment_auto.rb

echo "Done. CSV files in ./data"
