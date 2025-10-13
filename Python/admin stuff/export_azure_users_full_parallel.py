#!/usr/bin/env python3
"""
Export all Entra ID (Azure AD) users to CSV with:
- DisplayName
- UPN
- Email
- SecurityGroups (semicolon-delimited)
- DirectoryRoles (semicolon-delimited)
- RBACRoles across ALL accessible subscriptions ("RoleName @ Scope" semicolon-delimited)

Features:
- Parallelized per-user fetching (bounded thread pool)
- Resilient Graph calls with retry/backoff
- Reads role assignments from every subscription the identity can list

Auth: DefaultAzureCredential (SP, Managed Identity, Azure CLI, VS Code, etc.)
Required for SP auth:
  export AZURE_TENANT_ID="<tenant-id>"
  export AZURE_CLIENT_ID="<client-id>"
  export AZURE_CLIENT_SECRET="<client-secret>"

Permissions:
- Microsoft Graph (app or delegated): User.Read.All, Group.Read.All, Directory.Read.All
- Azure: Reader (or Microsoft.Authorization/roleAssignments/read) in the subscriptions you want to inventory

Usage:
  python export_azure_users_full_parallel.py --out users_full.csv --workers 8
"""

import argparse
import csv
import os
import sys
import time
from typing import Dict, List, Tuple
from concurrent.futures import ThreadPoolExecutor, as_completed

import requests
from azure.identity import DefaultAzureCredential
from azure.mgmt.authorization import AuthorizationManagementClient
from azure.mgmt.resource.subscriptions import SubscriptionClient

GRAPH_SCOPE = "https://graph.microsoft.com/.default"
GRAPH_BASE = "https://graph.microsoft.com/v1.0"

# -------------------- HTTP utils -------------------- #

def _sleep_backoff(attempt: int, retry_after: int = 2):
    time.sleep(max(retry_after, 2) * (attempt + 1))

def graph_get(session: requests.Session, url: str) -> dict:
    """GET with retry/backoff for Graph."""
    for attempt in range(6):
        resp = session.get(url, headers={"ConsistencyLevel": "eventual"})
        if resp.status_code in (429,) or 500 <= resp.status_code < 600:
            _sleep_backoff(attempt, int(resp.headers.get("Retry-After", "2")))
            continue
        resp.raise_for_status()
        return resp.json()
    resp.raise_for_status()
    return {}

def graph_paged(session: requests.Session, url: str):
    """Yield items across @odata.nextLink pages."""
    while url:
        data = graph_get(session, url)
        for item in data.get("value", []):
            yield item
        url = data.get("@odata.nextLink")

# -------------------- Graph: users & memberships -------------------- #

def fetch_all_users(session: requests.Session):
    url = f"{GRAPH_BASE}/users?$select=id,displayName,userPrincipalName,mail"
    yield from graph_paged(session, url)

def fetch_user_groups_and_dir_roles(token: str, user_id: str) -> Tuple[List[str], List[str]]:
    """Per-user fetch (separate session per thread for safety)."""
    s = requests.Session()
    s.headers.update({"Authorization": f"Bearer {token}"})
    groups, dir_roles = set(), set()
    url = f"{GRAPH_BASE}/users/{user_id}/memberOf?$select=displayName"
    for obj in graph_paged(s, url):
        otype = (obj.get("@odata.type") or "").lower()
        name = obj.get("displayName") or ""
        if not name:
            continue
        if "microsoft.graph.group" in otype:
            groups.add(name)
        elif "microsoft.graph.directoryrole" in otype:
            dir_roles.add(name)
    return sorted(groups), sorted(dir_roles)

# -------------------- RBAC helpers -------------------- #

def build_role_name_cache(auth_client: AuthorizationManagementClient) -> Dict[str, str]:
    """roleDefinitionId -> roleName for one subscription."""
    cache: Dict[str, str] = {}
    scope = f"/subscriptions/{auth_client.config.subscription_id}"
    for rd in auth_client.role_definitions.list(scope=scope):
        cache[rd.id] = rd.role_name
    return cache

def fetch_user_role_assignments_for_sub(
    auth_client: AuthorizationManagementClient,
    role_name_cache: Dict[str, str],
    principal_id: str,
) -> List[str]:
    """Return formatted 'RoleName @ Scope' for one subscription."""
    roles = set()
    for ra in auth_client.role_assignments.list(filter=f"principalId eq '{principal_id}'"):
        role_def_id = ra.role_definition_id
        role_name = role_name_cache.get(
            role_def_id,
            (role_def_id.split('/')[-1] if role_def_id else "UnknownRole")
        )
        scope = ra.scope or ""
        roles.add(f"{role_name} @ {scope}")
    return sorted(roles)

# -------------------- Worker -------------------- #

def process_user(
    token: str,
    user: dict,
    sub_clients: Dict[str, AuthorizationManagementClient],
    role_caches: Dict[str, Dict[str, str]],
) -> dict:
    """Return CSV row dict for a single user."""
    user_id = user.get("id")
    display_name = user.get("displayName") or ""
    upn = user.get("userPrincipalName") or ""
    email = user.get("mail") or ""

    # Groups + Directory Roles
    try:
        groups, dir_roles = fetch_user_groups_and_dir_roles(token, user_id)
    except Exception as e:
        groups, dir_roles = [], []
        print(f"Warning: memberOf failed for {upn}: {e}", file=sys.stderr)

    # RBAC across all subs
    roles_all: List[str] = []
    for sub_id, ac in sub_clients.items():
        try:
            roles_all.extend(fetch_user_role_assignments_for_sub(ac, role_caches[sub_id], user_id))
        except Exception as e:
            print(f"Warning: RBAC read failed for {upn} in {sub_id}: {e}", file=sys.stderr)

    roles_all = sorted(set(roles_all))
    return {
        "DisplayName": display_name,
        "UPN": upn,
        "Email": email,
        "SecurityGroups": "; ".join(groups),
        "DirectoryRoles": "; ".join(dir_roles),
        "RBACRoles": "; ".join(roles_all),
    }

# -------------------- main -------------------- #

def main():
    ap = argparse.ArgumentParser(description="Export users with groups, directory roles, and RBAC (all subscriptions) to CSV (parallel).")
    ap.add_argument("--out", "-o", default="azure_users_full.csv", help="Output CSV path")
    ap.add_argument("--workers", "-w", type=int, default=8, help="Max concurrent workers")
    args = ap.parse_args()

    credential = DefaultAzureCredential()

    # Graph token (shared across threads; each thread uses its own Session)
    token = credential.get_token(GRAPH_SCOPE).token

    # Enumerate subscriptions
    sub_client = SubscriptionClient(credential)
    subs = list(sub_client.subscriptions.list())
    if not subs:
        print("No subscriptions found or insufficient permissions.", file=sys.stderr)

    # Build per-subscription RBAC clients and role caches
    sub_clients: Dict[str, AuthorizationManagementClient] = {}
    role_caches: Dict[str, Dict[str, str]] = {}
    for s in subs:
        sid = s.subscription_id
        try:
            ac = AuthorizationManagementClient(credential, sid)
            sub_clients[sid] = ac
            role_caches[sid] = build_role_name_cache(ac)
        except Exception as e:
            print(f"Warning: init RBAC client failed for {sid}: {e}", file=sys.stderr)

    # Get all users (serial listing)
    s = requests.Session()
    s.headers.update({"Authorization": f"Bearer {token}"})
    users = list(fetch_all_users(s))
    print(f"Discovered {len(users)} users. Processing with {args.workers} workers...", file=sys.stderr)

    rows: List[dict] = []
    with ThreadPoolExecutor(max_workers=max(1, args.workers)) as ex:
        futs = [ex.submit(process_user, token, u, sub_clients, role_caches) for u in users]
        for i, fut in enumerate(as_completed(futs), 1):
            try:
                rows.append(fut.result())
            except Exception as e:
                print(f"Error processing user #{i}: {e}", file=sys.stderr)
            if i % 100 == 0:
                print(f"  processed {i}/{len(users)} users...", file=sys.stderr)

    # Write CSV
    fieldnames = ["DisplayName", "UPN", "Email", "SecurityGroups", "DirectoryRoles", "RBACRoles"]
    with open(args.out, "w", newline="", encoding="utf-8") as f:
        w = csv.DictWriter(f, fieldnames=fieldnames)
        w.writeheader()
        w.writerows(rows)

    print(f"Wrote {len(rows)} users to {args.out}")

if __name__ == "__main__":
    main()
