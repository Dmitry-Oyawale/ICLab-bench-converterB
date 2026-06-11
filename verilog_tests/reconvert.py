#!/usr/bin/env python3
"""
Regenerate TESTBED.v, PATTERN.v, syn.tcl, and {design}.v in existing
iclab_*_test folders using the updated converter without needing the
original CVDP input folders.

Stim and ref modules are extracted from the existing PATTERN.v.
RTL is taken from the existing 00_TESTBED/{design}.v.

Usage:
    python reconvert.py                        # all iclab_*_test in current dir
    python reconvert.py iclab_aes_sbox_test    # specific folder(s)
"""

import re
import sys
import shutil
from pathlib import Path

from converter import (
    split_into_modules, parse_module_ports,
    find_clock_port, find_reset_port,
    make_testbed_v, make_pattern_v, make_syn_tcl,
    prepend_missing_includes, merge_preambles,
)


def extract_stim_ref(pattern_text):
    """
    Extract (stim_text, ref_text) from an existing PATTERN.v.

    PATTERN.v structure (old or new converter):
        [`ifdef GATE ... `endif]
        <stimulus_gen module(s)>
        <ref model module(s)>
        <PATTERN module>
    """
    # Drop `ifdef GATE ... `endif block (may span multiple paragraphs)
    body = re.sub(r'`ifdef\s+GATE\b.*?`endif', '', pattern_text,
                  flags=re.DOTALL)

    # Drop the PATTERN module and everything after it
    m = re.search(r'\bmodule\s+PATTERN\b', body)
    if m:
        body = body[:m.start()]

    mods = split_into_modules(body)
    stim = [(n, t) for n, t in mods if n == 'stimulus_gen']
    refs = [(n, t) for n, t in mods if n != 'stimulus_gen']

    return ('\n\n'.join(t for _, t in stim),
            '\n\n'.join(t for _, t in refs))


def build_preamble_for_design(design, testbed_dir):
    """
    Return preamble string (e.g. `include "sd_defines.v") for a design.

    Looks for auxiliary .v files already in 00_TESTBED/ that are not the
    main RTL and not the generated TESTBED/PATTERN/filelist.
    """
    skip = {'TESTBED.v', 'PATTERN.v', 'filelist.f',
            f'{design}.v', f'{design}_SYN.v'}
    lines = []
    for f in sorted(Path(testbed_dir).glob('*.v')):
        if f.name not in skip and not f.name.endswith('_SYN.v'):
            lines.append(f'`include "{f.name}"')
    return '\n'.join(lines) + '\n' if lines else ''


def detect_design(folder):
    """Infer design name: try folder name pattern first, then scan RTL files."""
    m = re.match(r'iclab_(.+)_test$', Path(folder).name)
    if m:
        candidate = m.group(1)
        if (Path(folder) / '00_TESTBED' / f'{candidate}.v').exists():
            return candidate
    # Fallback: find the RTL .v file (not TESTBED/PATTERN/SYN)
    skip = {'TESTBED.v', 'PATTERN.v', 'filelist.f'}
    testbed = Path(folder) / '00_TESTBED'
    for f in sorted(testbed.glob('*.v')):
        if f.name not in skip and not f.name.endswith('_SYN.v'):
            # Check it actually defines a module matching the stem
            mods = [n for n, _ in split_into_modules(f.read_text())]
            if f.stem in mods:
                return f.stem
    return None


def reconvert_folder(folder):
    folder = Path(folder)
    if not re.match(r'iclab_.+_test$', folder.name):
        print(f"[skip] {folder.name}: not iclab_*_test")
        return False

    design = detect_design(folder)
    if not design:
        print(f"[skip] {folder.name}: could not detect design name")
        return False

    testbed   = folder / '00_TESTBED'
    rtl_file  = testbed / f'{design}.v'
    pat_file  = testbed / 'PATTERN.v'

    for f, label in [(rtl_file, 'RTL'), (pat_file, 'PATTERN.v')]:
        if not f.exists():
            print(f"[skip] {design}: {label} not found at {f}")
            return False

    rtl_content   = rtl_file.read_text()
    rtl_mod_names = {n for n, _ in split_into_modules(rtl_content)}

    top_mods = split_into_modules(rtl_content)
    top_text = next((t for n, t in top_mods if n == design),
                    top_mods[0][1] if top_mods else '')
    ports = parse_module_ports(top_text)
    if not ports:
        print(f"[skip] {design}: could not parse ports")
        return False

    clk_port   = find_clock_port(ports)
    reset_port = find_reset_port(ports)

    stim_text, ref_text = extract_stim_ref(pat_file.read_text())
    if not stim_text or not ref_text:
        print(f"[skip] {design}: could not extract stim/ref from PATTERN.v")
        return False

    # If the existing PATTERN.v has no preamble (old converter), reconstruct
    # one from any auxiliary .v files already present in 00_TESTBED/
    aux_preamble = build_preamble_for_design(design, testbed)
    if aux_preamble:
        # Inject into ref_text so merge_preambles picks it up
        ref_text = aux_preamble + ref_text

    preamble    = merge_preambles(ref_text, stim_text)
    rtl_content = prepend_missing_includes(preamble, rtl_content)

    new_testbed = make_testbed_v(design, ports, clk_port)
    new_pattern = make_pattern_v(design, ports, stim_text, ref_text,
                                 rtl_mod_names, rtl_content, clk_port)
    new_syn_tcl = make_syn_tcl(design, reset_port, clk_port)

    (testbed / 'TESTBED.v').write_text(new_testbed)
    (testbed / 'PATTERN.v').write_text(new_pattern)
    (testbed / 'syn.tcl').write_text(new_syn_tcl)
    (testbed / f'{design}.v').write_text(rtl_content)

    rtl_copy = folder / '01_RTL' / f'{design}.v'
    if rtl_copy.exists():
        rtl_copy.write_text(rtl_content)

    syn_tcl_copy = folder / '02_SYN' / 'syn.tcl'
    if syn_tcl_copy.exists():
        syn_tcl_copy.write_text(new_syn_tcl)

    print(f"[done] {design:30s}  clk={clk_port}  rst={reset_port}")
    return True


if __name__ == '__main__':
    targets = sys.argv[1:] if len(sys.argv) > 1 else sorted(Path('.').glob('iclab_*_test'))
    ok = fail = 0
    for t in targets:
        if reconvert_folder(t):
            ok += 1
        else:
            fail += 1
    print(f"\n{ok} reconverted, {fail} skipped.")
