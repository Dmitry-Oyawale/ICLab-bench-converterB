#!/usr/bin/env python3
"""
Extract a single CVDP dataset entry into a local folder.

Usage:
    python3 extract_cvdp.py <design_id> [output_folder]

Example:
    python3 extract_cvdp.py cvdp_copilot_16qam_mapper_0001
"""

import sys
import json
from pathlib import Path
import urllib.request
import io

try:
    import pandas as pd
except ImportError:
    sys.exit("ERROR: pandas not installed. Run: pip install pandas pyarrow")

DATASET = "nvidia/cvdp-benchmark-dataset"

SUBSETS = [
    'cvdp_nonagentic_code_generation_no_commercial',
    'cvdp_nonagentic_code_generation_commercial',
    'cvdp_agentic_code_generation_no_commercial',
    'cvdp_agentic_code_generation_commercial',
    'cvdp_agentic_heavy_code_generation',
]

HF_API = "https://huggingface.co/api/datasets"


def parquet_url(subset):
    return f"{HF_API}/{DATASET}/parquet/{subset}/eval/0.parquet"


def find_entry(design_id):
    for subset in SUBSETS:
        url = parquet_url(subset)
        print(f"Checking {subset}...")
        try:
            req = urllib.request.urlopen(url, timeout=30)
            data = io.BytesIO(req.read())
            df = pd.read_parquet(data)
            matches = df[df['id'] == design_id]
            if not matches.empty:
                print(f"  Found in {subset}")
                return matches.iloc[0].to_dict()
        except Exception as e:
            print(f"  Skipped: {e}")
    return None


def write_files(file_dict, base_dir):
    if not isinstance(file_dict, dict):
        return
    for rel_path, content in file_dict.items():
        out = Path(base_dir) / rel_path
        out.parent.mkdir(parents=True, exist_ok=True)
        if isinstance(content, bytes):
            out.write_bytes(content)
        else:
            out.write_text(str(content))


def extract(design_id, output_folder=None):
    entry = find_entry(design_id)
    if entry is None:
        print(f"\nERROR: '{design_id}' not found in any subset.")
        sys.exit(1)

    out = Path(output_folder) if output_folder else Path(design_id)
    out.mkdir(parents=True, exist_ok=True)
    print(f"\nExtracting to: {out}/")
    print(f"Fields in entry: {list(entry.keys())}")

    for field in ['context', 'harness']:
        val = entry.get(field)
        if val is None:
            continue
        # May be a dict or a JSON string
        if isinstance(val, str):
            try:
                val = json.loads(val)
            except Exception:
                pass
        if isinstance(val, dict):
            write_files(val, out)
            print(f"  {field}: {list(val.keys())}")

    # patch field — the gold RTL solution
    patch = entry.get('patch', '')
    if patch:
        (out / 'patch.txt').write_text(str(patch))
        print(f"  patch: written to patch.txt")

    print(f"\nFolder contents:")
    for f in sorted(out.rglob('*')):
        if f.is_file():
            print(f"  {f.relative_to(out)}")


if __name__ == '__main__':
    if len(sys.argv) < 2:
        print(f"Usage: python3 {sys.argv[0]} <design_id> [output_folder]")
        sys.exit(1)
    extract(sys.argv[1], sys.argv[2] if len(sys.argv) > 2 else None)
