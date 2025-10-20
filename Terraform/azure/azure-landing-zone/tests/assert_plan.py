#!/usr/bin/env python3
import json, sys

if len(sys.argv) != 2:
  print("Usage: assert_plan.py plan.json"); sys.exit(2)

plan = json.load(open(sys.argv[1]))
root = plan.get("planned_values", {}).get("root_module", {}) or {}

def find(root, type_name):
  out = []
  def walk(m):
    for r in m.get("resources", []):
      if r.get("type") == type_name: out.append(r)
    for c in m.get("child_modules", []) or []: walk(c)
  walk(root)
  return out

errors = []
if not find(root, "azurerm_resource_group"): errors.append("No azurerm_resource_group planned.")
if not find(root, "azurerm_virtual_network"): errors.append("No azurerm_virtual_network planned.")
if len(find(root, "azurerm_subnet")) < 3: errors.append("Expected >= 3 subnets.")
if not find(root, "azurerm_log_analytics_workspace"): errors.append("No Log Analytics workspace planned.")

if errors: [print(f"[FAIL] {e}") for e in errors] or sys.exit(1)
print("All plan invariants passed.")
