from typing import Dict, Any, List
import socket
try:
    import dns.resolver, dns.reversename
except Exception:
    dns = None

def reverse_lookup(ip: str, cfg: Dict[str, Any]) -> str:
    # Try dnspython if configured, else socket.gethostbyaddr
    if not cfg or not cfg.get('enabled', True):
        return ""
    servers = cfg.get('servers') or []
    # dnspython path
    if dns:
        try:
            resolver = dns.resolver.Resolver()
            if servers:
                resolver.nameservers = servers
            rev = dns.reversename.from_address(ip)
            ans = resolver.resolve(rev, "PTR", lifetime=2.0)
            if ans and len(ans) > 0:
                return str(ans[0]).rstrip('.')
        except Exception:
            pass
    # socket fallback
    try:
        return socket.gethostbyaddr(ip)[0]
    except Exception:
        return ""
