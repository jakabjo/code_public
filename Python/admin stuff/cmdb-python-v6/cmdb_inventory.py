import argparse, os, json, csv, time, math
from concurrent.futures import ThreadPoolExecutor, as_completed
from contextlib import nullcontext

from modules.config import load_config
from modules.discovery.azure_discovery import discover as azure_discover
from modules.discovery.ad_discovery import discover as ad_discover
from modules.discovery.ad_enricher import enrich as ad_enrich
from modules.discovery.vsphere_discovery import discover as vs_discover
from modules.discovery.subnet_scan import discover as subnet_discover
from modules.collect.windows_collect import collect as win_collect
from modules.collect.linux_collect import collect as lin_collect
from modules.export.csv_export import export_csv
from modules.export.html_export import export_html
from modules.export.servicenow_export import export_servicenow
from modules.export.sqlite_export import export_sqlite
from modules.transforms import apply_transforms
from modules.dns_enrich import reverse_lookup

try:
    from rich.progress import Progress, TimeElapsedColumn, TimeRemainingColumn, BarColumn, SpinnerColumn, TextColumn
    from rich.console import Console
    RICH_AVAILABLE = True
except Exception:
    RICH_AVAILABLE = False

def _feat(cfg, path, default=True):
    node = cfg.get('features', {})
    for key in path.split('.'):
        node = node.get(key, {} if key != path.split('.')[-1] else default)
    return bool(node) if isinstance(node, (bool,int)) else bool(default)

def load_targets_csv(path):
    targets = []
    if not path or not os.path.exists(path): return targets
    with open(path, newline='', encoding='utf-8') as f:
        reader = csv.DictReader(f)
        for r in reader:
            targets.append({'host': r.get('host'), 'os_hint': r.get('os_hint'), 'source': r.get('source') or 'manual', 'provider': r.get('provider') or 'manual'})
    return targets

def do_discovery(cfg, extra_targets, console=None):
    disc = cfg.get('discovery', {})
    feats = cfg.get('features', {}).get('discovery', {})
    all_targets = []

    steps = []
    if feats.get('ad', True) and disc.get('active_directory', {}).get('enabled', True):
        steps.append(('Active Directory', lambda: ad_discover(disc.get('active_directory', {}))))
    if feats.get('azure', True) and disc.get('azure', {}).get('enabled', True):
        steps.append(('Azure', lambda: azure_discover(disc.get('azure', {}))))
    if feats.get('vsphere', True) and disc.get('vsphere', {}).get('enabled', True):
        steps.append(('vSphere', lambda: vs_discover(disc.get('vsphere', {}))))
    if feats.get('subnet_scan', True) and disc.get('subnet_scan', {}).get('enabled', True):
        steps.append(('Subnet scan', lambda: subnet_discover(disc.get('subnet_scan', {}))))
    if feats.get('static', True):
        steps.append(('Static targets', lambda: (cfg.get('static_targets') or [])))
    if feats.get('csv_targets', True):
        steps.append(('CSV targets', lambda: (extra_targets or [])))

    if RICH_AVAILABLE and console:
        with Progress(SpinnerColumn(), TextColumn("{task.description}"), BarColumn(), TimeElapsedColumn(), transient=True, console=console) as progress:
            for name, fn in steps:
                task = progress.add_task(f"[cyan]Discovering: {name}...", total=None)
                try:
                    res = fn() or []
                    all_targets += res
                finally:
                    progress.update(task, completed=1)
    else:
        for _, fn in steps:
            all_targets += fn() or []

    # Deduplicate
    seen = set(); uniq = []
    for t in all_targets:
        h = t.get('host')
        if not h: continue
        key = h.lower()
        if key in seen: continue
        seen.add(key); uniq.append(t)
    return uniq

def collect_one(cfg, t, software_enabled, sw_filters, ad_cfg, dry_run, transforms, dns_cfg, feats):
    host = t.get('host'); hint = (t.get('os_hint') or '').lower(); provider = t.get('provider')
    row = dict(t)

    if feats.get('dns', True) and (cfg.get('dns') or {}).get('enabled', True):
        ips = row.get('ips') or []
        if isinstance(ips, str) and ips:
            ips = [ips]
        names = []
        for ip in ips[:2]:
            name = reverse_lookup(ip, cfg.get('dns', {}))
            if name: names.append(name)
        if names and not row.get('resolved_name'):
            row['resolved_name'] = names[0]

    if dry_run:
        if feats.get('ad_ou', True) and ad_cfg.get('enabled') and ad_cfg.get('enrich_non_ad'):
            try:
                enr = ad_enrich(ad_cfg, host); row.update(enr)
            except Exception: pass
        if feats.get('transforms', True):
            try:
                row = apply_transforms(row, transforms)
            except Exception:
                pass
        return row

    wcfg = (cfg.get('collect') or {}).get('windows', {}).copy()
    lcfg = (cfg.get('collect') or {}).get('linux', {}).copy()
    wcfg['__software_enabled__'] = software_enabled
    lcfg['__software_enabled__'] = software_enabled
    wcfg['__software_filters__'] = sw_filters
    lcfg['__software_filters__'] = sw_filters

    # Feature toggles for collection
    data = {}
    if (feats.get('windows', True) and (hint == 'windows' or (provider == 'azure' and 'win' in hint))):
        data = win_collect(host, wcfg)
    elif (feats.get('linux', True) and (hint == 'linux' or provider in ('vsphere','onprem','local-network'))):
        data = lin_collect(host, lcfg)
    else:
        if feats.get('windows', True):
            data = win_collect(host, wcfg)
        if (not data or data.get('error')) and feats.get('linux', True):
            data = lin_collect(host, lcfg)

    if feats.get('ad_ou', True) and not row.get('ad_ou') and ad_cfg.get('enabled') and ad_cfg.get('enrich_non_ad'):
        try:
            enr = ad_enrich(ad_cfg, host); row.update(enr)
        except Exception: pass

    row.update(data or {})
    if feats.get('transforms', True):
        try:
            row = apply_transforms(row, transforms)
        except Exception:
            pass
    return row

def _autotune_workers(targets_len, fast=False):
    # Heuristic: more targets -> more workers, cap at 64 (or 48 in fast mode)
    if targets_len <= 50: base = 16
    elif targets_len <= 200: base = 24
    elif targets_len <= 1000: base = 32
    else: base = 48
    cap = 48 if fast else 64
    try:
        import multiprocessing
        cpu = multiprocessing.cpu_count()
    except Exception:
        cpu = 4
    base = max(base, cpu * 4)
    return min(base, cap)

def _apply_field_filters(rows, include, exclude):
    if not rows: return rows
    if include:
        include_set = set(include)
        rows = [{k:v for k,v in r.items() if k in include_set} for r in rows]
    if exclude:
        ex = set(exclude)
        rows = [{k:v for k,v in r.items() if k not in ex} for r in rows]
    return rows

def collect_hosts(cfg, targets, workers=8, dry_run=False, console=None, fast=False):
    rows = []
    software_cfg = ((cfg.get('collect') or {}).get('software') or {})
    software_enabled = bool(software_cfg.get('enabled', False))
    if fast:
        software_enabled = False  # fast mode: disable software inventory
        # also consider trimming transforms/DNS done via feats below

    ad_cfg = (cfg.get('discovery') or {}).get('active_directory', {})
    transforms = cfg.get('transforms', {})
    feats = cfg.get('features', {}).get('enrichment', {}).copy()
    feats.update(cfg.get('features', {}).get('collection', {}))

    if fast:
        feats['dns'] = False
        # transforms still helpful; keep enabled

    if RICH_AVAILABLE and console:
        total = len(targets)
        with Progress(
            SpinnerColumn(),
            TextColumn("[green]Collecting hosts"),
            BarColumn(),
            TextColumn("{task.completed}/{task.total}"),
            TimeElapsedColumn(),
            TimeRemainingColumn(),
            console=console
        ) as progress:
            task = progress.add_task("collect", total=total)
            with ThreadPoolExecutor(max_workers=workers) as ex:
                futs = [ex.submit(collect_one, cfg, t, software_enabled, software_cfg, ad_cfg, dry_run, transforms, cfg.get('dns', {}), feats) for t in targets]
                for fut in as_completed(futs):
                    rows.append(fut.result())
                    progress.update(task, advance=1)
    else:
        with ThreadPoolExecutor(max_workers=workers) as ex:
            futs = [ex.submit(collect_one, cfg, t, software_enabled, software_cfg, ad_cfg, dry_run, transforms, cfg.get('dns', {}), feats) for t in targets]
            for fut in as_completed(futs):
                rows.append(fut.result())
    return rows

def main():
    ap = argparse.ArgumentParser(description="Modular CMDB inventory")
    ap.add_argument("--config","-c", default="config.yaml", help="Config YAML path")
    ap.add_argument("--out","-o", default="out", help="Output folder")
    ap.add_argument("--workers","-w", default="8", help="Parallel collection workers (int or 'auto')")
    ap.add_argument("--autotune", action="store_true", help="Auto-pick worker count based on target size")
    ap.add_argument("--dry-run", action="store_true", help="Discovery only; do not perform WinRM/SSH collection")
    ap.add_argument("--targets", type=str, help="CSV file with additional targets (host,os_hint,source,provider)")
    ap.add_argument("--tui", action="store_true", help="Show a terminal UI with progress bars and ETA")
    ap.add_argument("--fast", action="store_true", help="Fast mode: disable software inventory, DNS reverse, TCP probes")
    ap.add_argument("--include-fields", type=str, help="Comma-separated list of fields to include in outputs")
    ap.add_argument("--exclude-fields", type=str, help="Comma-separated list of fields to exclude from outputs")
    args = ap.parse_args()

    cfg = load_config(args.config)
    os.makedirs(args.out, exist_ok=True)

    # Fast mode: override some config flags
    if args.fast:
        # disable software inv
        cfg.setdefault('collect', {}).setdefault('software', {})['enabled'] = False
        # disable tcp probe if present
        if 'discovery' in cfg and 'subnet_scan' in cfg['discovery']:
            cfg['discovery']['subnet_scan'].setdefault('tcp_probe', {})['enabled'] = False
        # disable DNS reverse
        cfg.setdefault('dns', {})['reverse_lookup'] = False

    console = Console() if (args.tui and RICH_AVAILABLE) else None
    if console:
        console.print("[bold cyan]CMDB Inventory[/] starting…")
        console.print("Phase: [bold]Discovery[/]")

    extra = load_targets_csv(args.targets) if args.targets else []
    targets = do_discovery(cfg, extra, console=console)
    if console:
        console.print(f"Discovered [bold]{len(targets)}[/] unique targets.")
        console.print("Phase: [bold]Collection[/]" if not args.dry_run else "Phase: [bold]Collection[/] [dim](skipped — dry run)[/]")

    # Autotune workers
    if args.autotune or (isinstance(args.workers, str) and args.workers.lower() == 'auto'):
        workers = _autotune_workers(len(targets), fast=args.fast)
    else:
        try:
            workers = int(args.workers)
        except:
            workers = 8

    rows = collect_hosts(cfg, targets, workers=workers, dry_run=args.dry_run, console=console, fast=args.fast)

    # Field filters
    include = []
    exclude = []
    if 'fields' in cfg:
        include = cfg['fields'].get('include') or []
        exclude = cfg['fields'].get('exclude') or []
    if args.include_fields:
        include = [x.strip() for x in args.include_fields.split(',') if x.strip()]
    if args.exclude_fields:
        exclude = [x.strip() for x in args.exclude_fields.split(',') if x.strip()]
    rows = _apply_field_filters(rows, include, exclude)

    if (cfg.get('export') or {}).get('json', True):
        with open(os.path.join(args.out,"inventory.json"),"w",encoding="utf-8") as f:
            json.dump(rows, f, indent=2)
    if (cfg.get('export') or {}).get('csv', True):
        export_csv(rows, os.path.join(args.out,"inventory.csv"))
    if (cfg.get('export') or {}).get('html', True):
        export_html(rows, os.path.join(args.out,"inventory.html"), template_dir="templates", title=(cfg.get('report') or {}).get('title',"CMDB Inventory Report"))
    export_servicenow(rows, (cfg.get('export') or {}).get('servicenow'))
    export_sqlite(rows, (cfg.get('export') or {}).get('sqlite'))

    if console:
        console.print(f"[bold green]Done.[/] Outputs in: {os.path.abspath(args.out)}  (workers={workers})")

if __name__ == "__main__":
    main()
