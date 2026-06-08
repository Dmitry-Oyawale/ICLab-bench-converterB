from datasets import load_dataset

ds = load_dataset("nvidia/cvdp-benchmark-dataset", "non_agentic_non_commercial", split="eval")
entry = ds[0]

print("=== ID ===")
print(entry["id"])

print("\n=== context files ===")
for k in entry["context"].keys():
    print(" ", k)

print("\n=== patch (first 2000 chars) ===")
print(repr(entry["patch"])[:2000])

print("\n=== harness files ===")
if isinstance(entry["harness"], dict):
    for k in entry["harness"].keys():
        print(" ", k)
else:
    print(type(entry["harness"]), repr(entry["harness"])[:200])

print("\n=== testbench content ===")
for k, v in entry["context"].items():
    if "tb" in k or "verif" in k or ".sv" in k:
        print("--- " + k + " ---")
        print(v[:3000])
