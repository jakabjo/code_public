from typing import Dict, Any

def apply_transforms(row: Dict[str, Any], transforms: Dict[str, Any]) -> Dict[str, Any]:
    # Apply Azure tag_map
    try:
        if row.get('provider') == 'azure' and transforms.get('azure'):
            tag_map = transforms['azure'].get('tag_map', {})
            tags = row.get('tags') or []
            # tags may be list of "k=v" strings
            kv = {}
            for t in tags:
                if isinstance(t, str) and '=' in t:
                    k,v = t.split('=',1); kv[k]=v
            for src_key, dst in tag_map.items():
                if src_key in kv:
                    row[dst] = kv[src_key]
    except Exception:
        pass

    # vSphere tag_map (if tags list exists)
    try:
        if row.get('provider') == 'vsphere' and transforms.get('vsphere'):
            tag_map = transforms['vsphere'].get('tag_map', {})
            tags = row.get('tags') or []
            kv = {}
            for t in tags:
                if isinstance(t, str) and '=' in t:
                    k,v = t.split('=',1); kv[k]=v
            for src_key, dst in tag_map.items():
                if src_key in kv:
                    row[dst] = kv[src_key]
    except Exception:
        pass

    # AD attribute_map: map ad attributes to normalized fields
    try:
        if row.get('provider') in ('onprem','active_directory') and transforms.get('active_directory'):
            attr_map = transforms['active_directory'].get('attribute_map', {})
            for src_attr, dst in attr_map.items():
                val = row.get(src_attr) or row.get(src_attr.lower()) or None
                if val:
                    row[dst] = val
    except Exception:
        pass

    return row
