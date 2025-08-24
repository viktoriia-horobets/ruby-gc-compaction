import pandas as pd
from pathlib import Path

REQUIRED = [
    "before_heap_pages", "after_heap_pages",
    "compact_time_s", "major_before_s", "major_after_s"
]

def load_csv(path: str, tag: str) -> pd.DataFrame | None:
    p = Path(path)
    if not p.exists():
        print(f"[warn] Missing file: {p}")
        return None
    df = pd.read_csv(p)
    df["config"] = tag

    for col in REQUIRED:
        if col not in df.columns:
            df[col] = 0.0
        df[col] = pd.to_numeric(df[col], errors="coerce")

    df[["compact_time_s", "major_before_s", "major_after_s"]] = \
        df[["compact_time_s", "major_before_s", "major_after_s"]].fillna(0.0)

    df[["before_heap_pages", "after_heap_pages"]] = \
        df[["before_heap_pages", "after_heap_pages"]].fillna(0)

    return df

parts = [
    load_csv("data/results_no_compact.csv", "no_compact"),
    load_csv("data/results_manual_compact.csv", "manual_compact"),
    load_csv("data/results_auto_compact.csv", "auto_compact"),
]
dfs = [d for d in parts if d is not None]
if not dfs:
    raise SystemExit("No data found in any CSV.")

df = pd.concat(dfs, ignore_index=True)

df["pages_delta"] = df["before_heap_pages"] - df["after_heap_pages"]

summary = (
    df.groupby("config", as_index=False)
      .agg(
          before_pages_avg=("before_heap_pages", "mean"),
          after_pages_avg=("after_heap_pages", "mean"),
          delta_pages_avg=("pages_delta", "mean"),
          compact_time_s_avg=("compact_time_s", "mean"),
          major_gc_before_s_avg=("major_before_s", "mean"),
          major_gc_after_s_avg=("major_after_s", "mean"),
          runs=("config", "count"),
      )
      .sort_values("delta_pages_avg", ascending=False)
)

summary_rounded = summary.copy()
for col in ["before_pages_avg","after_pages_avg","delta_pages_avg",
            "compact_time_s_avg","major_gc_before_s_avg","major_gc_after_s_avg"]:
    summary_rounded[col] = summary_rounded[col].round(2)

print("\n=== Compaction summary (averages) ===")
print(summary_rounded.to_string(index=False))

out = Path("data/summary.csv")
out.parent.mkdir(parents=True, exist_ok=True)
summary.to_csv(out, index=False)
print(f"\nSaved: {out}")
