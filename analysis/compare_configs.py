import pandas as pd
from pathlib import Path

def load_csv(path, tag):
    if not Path(path).exists():
        return None
    df = pd.read_csv(path)
    df['config'] = tag
    return df

no = load_csv("data/results_no_compact.csv", "no_compact")
man = load_csv("data/results_manual_compact.csv", "manual_compact")
auto = load_csv("data/results_auto_compact.csv", "auto_compact")

dfs = [d for d in [no, man, auto] if d is not None]
if not dfs:
    raise SystemExit("No data")

df = pd.concat(dfs, ignore_index=True)

df['pages_delta'] = df['before_heap_pages'] - df['after_heap_pages']

summary = df.groupby('config', as_index=False).agg({
    'pages_delta': 'mean',
    'compact_time_s': 'mean',
    'major_before_s': 'mean',
    'major_after_s': 'mean'
}).sort_values('pages_delta', ascending=False)

print("\n=== Compaction summary (avg) ===")
print(summary.to_string(index=False))
