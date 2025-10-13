#!/usr/bin/env python3
"""
Inventory Viewer (stdlib only)

Usage:
  python inventory_viewer.py out/inventory.json
  # Keys inside the viewer:
  #   n         next page
  #   p         previous page
  #   g <num>   go to page number (1-based)
  #   f <text>  filter rows by substring across visible columns
  #   c         clear filter
  #   q         quit
"""

from __future__ import annotations

import argparse
import json
import os
import sys
from typing import List, Dict, Any, Sequence

DEFAULT_COLUMNS: Sequence[str] = (
    "host",
    "provider",
    "OS",
    "Version",
    "IPs",
    "environment",
    "ad_ou",
    "resolved_name",
)

PAGE_SIZE_DEFAULT = 20
MIN_COL_WIDTH = 6
MAX_COL_WIDTH = 40


def load_rows(path: str) -> List[Dict[str, Any]]:
    if not os.path.exists(path):
        sys.stderr.write(f"ERROR: file not found: {path}\n")
        sys.exit(2)
    with open(path, "r", encoding="utf-8") as f:
        data = json.load(f)
    if isinstance(data, dict):
        # support accidental dict-wrapped payloads
        data = data.get("rows") or data.get("items") or []
    if not isinstance(data, list):
        sys.stderr.write("ERROR: JSON must be a list of objects\n")
        sys.exit(2)
    # Normalize a bit
    norm: List[Dict[str, Any]] = []
    for r in data:
        if not isinstance(r, dict):
            continue
        # Ensure IPs is printable
        v = r.get("IPs")
        if isinstance(v, (list, tuple)):
            r["IPs"] = ", ".join(str(x) for x in v)
        norm.append(r)
    return norm


def pick_columns(rows: List[Dict[str, Any]], requested: Sequence[str] | None) -> List[str]:
    if requested:
        return list(requested)
    # Choose defaults but include any obviously present keys like 'name' if 'host' missing
    cols = list(DEFAULT_COLUMNS)
    if rows:
        sample = rows[0]
        if "host" not in sample and "name" in sample and "name" not in cols:
            cols.insert(0, "name")
    # Keep only columns that exist in at least one row
    existing = set()
    for r in rows:
        existing.update(k for k in r.keys())
    cols = [c for c in cols if c in existing]
    # Always ensure at least one column
    return cols or sorted(list(existing))[:8]


def truncate(val: Any, width: int) -> str:
    s = "" if val is None else str(val)
    if len(s) <= width:
        return s
    if width <= 1:
        return s[:width]
    # ellipsis
    return s[: max(0, width - 1)] + "…"


def compute_widths(rows: List[Dict[str, Any]], cols: Sequence[str], max_width: int) -> List[int]:
    # simple greedy: try to fit columns into max_width
    # start with header widths
    widths = [max(MIN_COL_WIDTH, min(MAX_COL_WIDTH, len(c))) for c in cols]
    # sample limited number of rows for width estimation
    sample_rows = rows[: min(200, len(rows))]
    for i, c in enumerate(cols):
        max_cell = widths[i]
        for r in sample_rows:
            v = r.get(c)
            if isinstance(v, (list, tuple)):
                v = ", ".join(str(x) for x in v)
            max_cell = max(max_cell, len(str(v)) if v is not None else 0)
            if max_cell >= MAX_COL_WIDTH:
                max_cell = MAX_COL_WIDTH
                break
        widths[i] = max(MIN_COL_WIDTH, min(MAX_COL_WIDTH, max_cell))

    total = sum(widths) + 3 * (len(cols) - 1)  # padding between cols
    if total <= max_width:
        return widths

    # If too wide, proportionally shrink but keep MIN_COL_WIDTH
    over = total - max_width
    while over > 0:
        changed = False
        for i in range(len(widths) - 1, -1, -1):
            if over <= 0:
                break
            if widths[i] > MIN_COL_WIDTH:
                widths[i] -= 1
                over -= 1
                changed = True
        if not changed:
            break
    return widths


def render_page(rows: List[Dict[str, Any]], cols: Sequence[str], page: int, page_size: int, term_width: int) -> str:
    total_pages = max(1, (len(rows) + page_size - 1) // page_size)
    page = max(1, min(page, total_pages))
    start = (page - 1) * page_size
    end = min(len(rows), start + page_size)
    view = rows[start:end]

    widths = compute_widths(view, cols, max_width=term_width)
    sep = " | "

    def fmt_row(r: Dict[str, Any]) -> str:
        parts = []
        for i, c in enumerate(cols):
            parts.append(truncate(r.get(c, ""), widths[i]).ljust(widths[i]))
        return sep.join(parts)

    header = sep.join(c.ljust(widths[i]) for i, c in enumerate(cols))
    line = "-" * min(term_width, max(len(header), 3))
    body = "\n".join(fmt_row(r) for r in view)
    footer = f"[{start + 1}-{end} of {len(rows)}]  page {page}/{total_pages}"
    helpbar = "Commands: n=next, p=prev, g <num>=goto, f <text>=filter, c=clear, q=quit"
    rendered = f"{header}\n{line}\n{body}\n{line}\n{footer}\n{helpbar}"
    return rendered, total_pages


def filter_rows(rows: List[Dict[str, Any]], cols: Sequence[str], needle: str) -> List[Dict[str, Any]]:
    if not needle:
        return rows
    n = needle.lower()
    out: List[Dict[str, Any]] = []
    for r in rows:
        hay = []
        for c in cols:
            v = r.get(c, "")
            if isinstance(v, (list, tuple)):
                v = ", ".join(str(x) for x in v)
            hay.append(str(v))
        if any(n in h.lower() for h in hay):
            out.append(r)
    return out


def main() -> None:
    ap = argparse.ArgumentParser(description="Simple inventory viewer")
    ap.add_argument("json_path", help="Path to inventory.json")
    ap.add_argument("--columns", help="Comma-separated list of columns to display")
    ap.add_argument("--page-size", type=int, default=PAGE_SIZE_DEFAULT, help="Rows per page")
    ap.add_argument("--width", type=int, default=120, help="Target terminal width for rendering")
    args = ap.parse_args()

    rows = load_rows(args.json_path)
    cols = pick_columns(rows, args.columns.split(",") if args.columns else None)
    page = 1
    page_size = max(1, args.page_size)
    current = rows
    filter_text = ""

    while True:
        rendered, total_pages = render_page(current, cols, page, page_size, args.width)
        print(rendered)
        try:
            cmd = input("> ").strip()
        except (EOFError, KeyboardInterrupt):
            print()
            break

        if not cmd:
            page = min(page + 1, total_pages)
            continue

        if cmd == "q":
            break
        elif cmd == "n":
            page = min(page + 1, total_pages)
        elif cmd == "p":
            page = max(1, page - 1)
        elif cmd.startswith("g "):
            try:
                num = int(cmd.split(None, 1)[1])
                page = max(1, min(num, total_pages))
            except Exception:
                print("Invalid page number")
        elif cmd.startswith("f "):
            filter_text = cmd.split(None, 1)[1].strip()
            current = filter_rows(rows, cols, filter_text)
            page = 1
        elif cmd == "c":
            filter_text = ""
            current = rows
            page = 1
        else:
            print("Unknown command. Use: n, p, g <num>, f <text>, c, q")


if __name__ == "__main__":
    main()
