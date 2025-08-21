# Ruby GC Compaction Experiments

This project demonstrates and analyzes the **Compaction algorithm** introduced in Ruby 2.7+ for reducing heap fragmentation.  
It contains Ruby scripts to generate fragmentation, Python scripts for visualization, and an interactive Chart.js dashboard.

Requirements

- **Ruby 2.7+** (Ruby 3.x recommended)  
- **Python 3.8+** with `pandas` and `matplotlib`  
  ```bash
  pip install pandas matplotlib

  Run all experiments (no compaction, manual compaction, auto compaction):
  chmod +x scripts/run_all.sh
  ./scripts/run_all.sh

This will generate CSV files in the data/ folder:
  results_no_compact.csv
  results_manual_compact.csv
  results_auto_compact.csv

You can also run a single configuration manually:
RUNS=5 N_OBJECTS=300000 KEEP_EVERY=3 DO_COMPACT=1 \
  CSV_OUT=data/results_manual_compact.csv \
  ruby scripts/compaction_experiment.rb


Analysis with Python
  Generate charts from CSV data:
  python3 analysis/plot_compaction_csv.py
  python3 analysis/compare_configs.py

Outputs include:
  heap_pages_before_after.png — pages before vs after compaction
  timing_by_config.png — timing comparison across configurations

Interactive Dashboard
  Open in browser:
  web/compaction_dashboard.html
  
Features:
  Upload one or multiple CSV files from data/
  Interactive bar charts for heap pages and timings
  Summary table with averages
  Easy configuration comparison
