from typing import List, Dict, Any
import ipaddress, subprocess, platform, concurrent.futures, socket

def _ping(ip: str, timeout_ms: int) -> bool:
    system = platform.system().lower()
    if system == 'windows':
        cmd = ['ping', '-n', '1', '-w', str(timeout_ms), ip]
    else:
        tsec = max(1, int((timeout_ms + 999) / 1000))
        cmd = ['ping', '-c', '1', '-W', str(tsec), ip]
    try:
        res = subprocess.run(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        return res.returncode == 0
    except Exception:
        return False

def _tcp_probe(ip: str, ports: list, per_port_timeout_ms: int) -> List[int]:
    open_ports = []
    tout = per_port_timeout_ms / 1000.0
    for p in ports:
        try:
            with socket.create_connection((ip, int(p)), timeout=tout):
                open_ports.append(int(p))
        except Exception:
            pass
    return open_ports

def discover(config: dict) -> List[Dict[str, Any]]:
    out: List[Dict[str, Any]] = []
    if not config.get('enabled'): 
        return out
    targets = config.get('targets') or []
    timeout_ms = int(config.get('timeout_ms', 500))
    threads = int(config.get('threads', 200))
    ping_only = bool(config.get('ping_only', True))
    tcp_cfg = config.get('tcp_probe', {}) or {}
    tcp_enabled = bool(tcp_cfg.get('enabled', False))
    tcp_ports = tcp_cfg.get('ports', [22, 80, 443])
    per_port_timeout_ms = int(tcp_cfg.get('per_port_timeout_ms', 400))

    ips = []
    for t in targets:
        try:
            net = ipaddress.ip_network(t, strict=False)
            for ip in net.hosts():
                ips.append(str(ip))
        except Exception:
            try:
                _ = ipaddress.ip_address(t); ips.append(str(t))
            except:
                continue
    ips = list(dict.fromkeys(ips))

    responsive = []
    with concurrent.futures.ThreadPoolExecutor(max_workers=threads) as ex:
        futs = {ex.submit(_ping, ip, timeout_ms): ip for ip in ips}
        for fut in concurrent.futures.as_completed(futs):
            ip = futs[fut]
            try:
                if fut.result():
                    responsive.append(ip)
            except Exception:
                pass

    for ip in responsive:
        entry = {
            'host': ip,
            'ips': [ip],
            'source': 'subnet_scan',
            'provider': 'local-network',
            'open_ports': []
        }
        if not ping_only and tcp_enabled:
            entry['open_ports'] = _tcp_probe(ip, tcp_ports, per_port_timeout_ms)
        out.append(entry)
    return out
