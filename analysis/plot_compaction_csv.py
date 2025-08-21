import pandas as pd
import matplotlib.pyplot as plt
from pathlib import Path

paths = [
    "data/results_no_compact.csv",
    "data/results_manual_compact.csv",
    "data/results_auto_compact.csv",
]

dfs = []
for p in paths:
    if Path(p).exists():
        df = pd.read_csv(p)
        df['config'] = Path(p).stem.replace("results_", "")
        dfs.append(df)

if not dfs:
    raise SystemExit("No CSV files found. Run scripts first.")

data = pd.concat(dfs, ignore_index=True)

agg = data.groupby('config', as_index=False).agg({
    'before_heap_pages': 'mean',
    'after_heap_pages': 'mean',
    'major_before_s': 'mean',
    'compact_time_s': 'mean',
    'major_after_s': 'mean',
})

print(agg)

plt.figure(figsize=(8,5))
x = range(len(agg))
plt.bar([i-0.2 for i in x], agg['before_heap_pages'], width=0.4, label='Before (pages)')
plt.bar([i+0.2 for i in x], agg['after_heap_pages'],  width=0.4, label='After (pages)')
plt.xticks(list(x), agg['config'])
plt.title('Heap pages: before vs after (avg)')
plt.ylabel('Pages')
plt.legend()
plt.tight_layout()
plt.savefig('analysis/heap_pages_before_after.png')
plt.show()

plt.figure(figsize=(8,5))
plt.bar(agg['config'], agg['major_before_s'], label='Major GC (before)')
plt.bar(agg['config'], agg['compact_time_s'], bottom=0, alpha=0.5, label='Compaction time')
plt.bar(agg['config'], agg['major_after_s'], alpha=0.7, label='Major GC (after)')
plt.title('Timing (avg) by configuration')
plt.ylabel('Seconds')
plt.legend()
plt.tight_layout()
plt.savefig('analysis/timing_by_config.png')
plt.show()
