"""
Generates two schematic figures for the thesis:
- before_compaction_schematic.(png|svg): fragmented heap
- after_compaction_schematic.(png|svg): packed pages after compaction
"""

import math
import random
from pathlib import Path
import matplotlib.pyplot as plt

PAGES = 6              # how many heap pages to draw
SLOTS_PER_PAGE = 12    # slots per page (drawn as a small grid)
FILL_RATIO = 0.60      # ~60% of slots considered "live"
GRID_COLS = 3          # how many page-columns in the layout grid
RANDOM_SEED = 42       # for reproducibility of the "random" before state
OUT_DIR = Path("analysis")
EXPORT_SVG = True      # export crisp vector graphics for print


OUT_DIR.mkdir(parents=True, exist_ok=True)

def draw_heap(ax, pages, slots_per_page, pattern="random", fill_ratio=0.6, seed=None):
    """Draws a heap as several 'pages'; each page is a small grid of slots."""
    if seed is not None:
        random.seed(seed)

    total_slots = pages * slots_per_page
    live_count = int(total_slots * fill_ratio)

    if pattern == "random":
        filled = set(random.sample(range(total_slots), live_count))
    elif pattern == "packed":
        filled = set(range(live_count))
    else:
        raise ValueError("pattern must be 'random' or 'packed'")

    rows = math.ceil(pages / GRID_COLS)
    page_w, page_h = 1.8, 1.0
    gap_x, gap_y = 0.4, 0.5
    pad_x, pad_y = 0.12, 0.12

    spc = math.ceil(math.sqrt(slots_per_page))       
    slot_w = (page_w - 2 * pad_x) / spc
    slot_h = (page_h - 2 * pad_y) / spc

    ax.set_aspect("equal")
    ax.axis("off")

    for p in range(pages):
        r = p // GRID_COLS
        c = p % GRID_COLS
        x0 = c * (page_w + gap_x)
        y0 = -r * (page_h + gap_y)

        ax.add_patch(plt.Rectangle((x0, y0), page_w, page_h, fill=False, linewidth=1.5))

        for s in range(slots_per_page):
            sr = s // spc
            sc = s % spc
            xs = x0 + pad_x + sc * slot_w
            ys = y0 + pad_y + sr * slot_h

            global_index = p * slots_per_page + s
            is_live = global_index in filled

            ax.add_patch(
                plt.Rectangle(
                    (xs, ys),
                    slot_w * 0.9,
                    slot_h * 0.9,
                    fill=is_live,
                    linewidth=0.8
                )
            )

def save_figure(fig, basename):
    png_path = OUT_DIR / f"{basename}.png"
    fig.tight_layout()
    fig.savefig(png_path, dpi=160)
    if EXPORT_SVG:
        svg_path = OUT_DIR / f"{basename}.svg"
        fig.savefig(svg_path)
    plt.close(fig)
    print(f"Saved {png_path}" + (" and SVG" if EXPORT_SVG else ""))

def make_before_after():
    fig1, ax1 = plt.subplots(figsize=(8, 6))
    draw_heap(ax1, PAGES, SLOTS_PER_PAGE, pattern="random", fill_ratio=FILL_RATIO, seed=RANDOM_SEED)
    plt.title("Before Compaction: fragmented heap (schematic)")
    save_figure(fig1, "before_compaction_schematic")

    fig2, ax2 = plt.subplots(figsize=(8, 6))
    draw_heap(ax2, PAGES, SLOTS_PER_PAGE, pattern="packed", fill_ratio=FILL_RATIO)
    plt.title("After Compaction: packed pages, free pages released (schematic)")
    save_figure(fig2, "after_compaction_schematic")

if __name__ == "__main__":
    make_before_after()
