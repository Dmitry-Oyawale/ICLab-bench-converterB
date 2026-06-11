#!/usr/bin/env python3
"""
CVDP → ICLAB format converter.

Reads a CVDP benchmark folder and writes an ICLAB-compatible folder with:
    00_TESTBED/  TESTBED.v  PATTERN.v  filelist.f  makefile  shell scripts
    01_RTL/      <design>.v  shell scripts
    02_SYN/      syn.tcl  Netlist/  Report/  shell scripts
    03_GATE/     shell scripts

Usage:
    python converter.py <cvdp_folder> [output_folder]
"""

import re
import sys
import shutil
from pathlib import Path

SCRIPT_DIR = Path(__file__).resolve().parent
TEMPLATE_DIR = SCRIPT_DIR / "aes_test"

# Port names that are Verilog keywords — invalid as wire/signal identifiers
VERILOG_KEYWORDS = {
    'reg', 'wire', 'input', 'output', 'inout', 'integer', 'real', 'time',
    'logic', 'signed', 'unsigned', 'parameter', 'localparam', 'module',
    'endmodule', 'begin', 'end', 'if', 'else', 'case', 'casez', 'casex',
    'endcase', 'for', 'while', 'always', 'initial', 'assign',
}


def safe_signal(name):
    """Return a valid signal name: append _sig if name is a Verilog keyword."""
    return name + '_sig' if name in VERILOG_KEYWORDS else name


def get_preamble(text):
    """Return all lines before the first module declaration."""
    lines = text.splitlines(keepends=True)
    pre = []
    for line in lines:
        if re.match(r'\s*module\s+', line):
            break
        pre.append(line)
    return ''.join(pre)


def strip_preamble(text):
    """Return text starting from the first module declaration."""
    for i, line in enumerate(text.splitlines(keepends=True)):
        if re.match(r'\s*module\s+', line):
            return ''.join(text.splitlines(keepends=True)[i:])
    return text


def merge_preambles(*texts):
    """Collect and deduplicate include/define lines from multiple preambles."""
    seen, result = set(), []
    for text in texts:
        for line in get_preamble(text).splitlines(keepends=True):
            stripped = line.strip()
            if stripped and stripped not in seen:
                seen.add(stripped)
                result.append(line)
    return ''.join(result)


def prepend_missing_includes(preamble, rtl_content):
    """Prepend include lines from preamble to rtl_content if not already present."""
    if not preamble.strip():
        return rtl_content
    missing = []
    for line in preamble.splitlines():
        stripped = line.strip()
        if re.match(r'`include\s+', stripped) and stripped not in rtl_content:
            missing.append(line)
    if missing:
        return '\n'.join(missing) + '\n' + rtl_content
    return rtl_content


def find_clock_port(ports):
    """Return the clock port name, matching case-insensitively."""
    names = [n for _, _, n in ports]
    for name in names:
        if name.lower() == 'clk':
            return name
    for name in names:
        if 'clk' in name.lower() or 'clock' in name.lower():
            return name
    return 'clk'


def find_module_instantiations(text, known_modules):
    """Return subset of known_modules that appear to be instantiated in text."""
    found = set()
    for mod in known_modules:
        if re.search(r'\b' + re.escape(mod) + r'\s+\w', text):
            found.add(mod)
    return found


# ---------------------------------------------------------------------------
# Verilog parsing
# ---------------------------------------------------------------------------

def split_into_modules(content):
    """Return [(module_name, module_text), ...] for each module in content."""
    modules, cur_lines, cur_name = [], [], None
    for line in content.splitlines(keepends=True):
        m = re.match(r'\s*module\s+(\w+)', line)
        if m and cur_name is None:
            cur_name = m.group(1)
            cur_lines = [line]
        elif re.match(r'\s*endmodule\b', line) and cur_name is not None:
            cur_lines.append(line)
            modules.append((cur_name, ''.join(cur_lines)))
            cur_lines, cur_name = [], None
        elif cur_name is not None:
            cur_lines.append(line)
    return modules


def parse_module_ports(module_text):
    """
    Return [(direction, width, name), ...].
    Tries ANSI-style header first, then non-ANSI body declarations.
    """
    tok = re.compile(
        r'\b(input|output|inout)\s+'
        r'(?:wire\s+|reg\s+|logic\s+)*'
        r'(\[[\w\s:\-+*`]+\]\s*)?'
        r'(\w+)',
        re.MULTILINE
    )

    header = re.search(
        r'module\s+\w+\s*(?:#\s*\([^)]*\)\s*)?\s*\(([^;]*)\)\s*;',
        module_text, re.DOTALL
    )
    if header:
        seen_ansi = set()
        ports = []
        for m in tok.finditer(header.group(1)):
            name = m.group(3)
            if name not in seen_ansi:
                seen_ansi.add(name)
                ports.append((m.group(1), (m.group(2) or '').strip(), name))
        if ports:
            return ports

    _KW = {'input', 'output', 'inout', 'wire', 'reg', 'logic', 'parameter',
           'signed', 'unsigned', 'integer', 'real', 'time', 'realtime'}
    header_names = set()
    if header:
        header_names = {
            p for p in re.findall(r'\b(\w+)\b', header.group(1))
            if p not in _KW
        }

    body_decl = re.compile(
        r'^\s*(input|output|inout)\s+'
        r'(?:wire\s+|reg\s+|logic\s+)*'
        r'(\[[\w\s:\-+*`]+\]\s*)?'
        r'([\w\s,]+?)\s*;',
        re.MULTILINE
    )
    body_start = module_text.find(';')
    body = module_text[body_start + 1:] if body_start >= 0 else module_text

    ports, seen = [], set()
    for m in body_decl.finditer(body):
        direction = m.group(1)
        width = (m.group(2) or '').strip()
        for name in m.group(3).split(','):
            name = name.strip()
            if re.match(r'^\w+$', name) and name not in seen:
                if not header_names or name in header_names:
                    seen.add(name)
                    ports.append((direction, width, name))
    return ports


def find_reset_port(ports):
    names = {n for _, _, n in ports}
    for candidate in ['rst_n', 'rst', 'reset_n', 'resetn', 'reset', 'arst_n', 'arst']:
        if candidate in names:
            return candidate
    for n in names:
        if 'rst' in n.lower() or 'reset' in n.lower():
            return n
    return 'rst_n'


# ---------------------------------------------------------------------------
# Design name
# ---------------------------------------------------------------------------

def get_design_name(cvdp_folder):
    """Extract design name from the CVDP folder name or from RTL filenames."""
    folder = Path(cvdp_folder)
    m = re.match(r'cvdp_copilot_(.+?)_\d+$', folder.name)
    if m:
        return m.group(1)
    rtl_dir = folder / '01_RTL'
    for f in sorted(rtl_dir.glob('*.v')):
        if '.empty' not in f.name and '.bak' not in f.name:
            return f.stem
    raise ValueError(f"Cannot determine design name from: {cvdp_folder}")


# ---------------------------------------------------------------------------
# File generators
# ---------------------------------------------------------------------------

def make_testbed_v(design, ports, clk_port):
    """
    Generate TESTBED.v.
    - clk_port: actual clock port name (may be 'CLK', not always 'clk')
    - safe_signal: keyword port names are renamed as signal identifiers
    """
    dut_conn = ',\n\t\t'.join(f'.{n}({safe_signal(n)})' for _, _, n in ports)

    pat_conns = []
    for d, _, n in ports:
        sn = safe_signal(n)
        if n == clk_port:
            pat_conns.append(f'.{clk_port}({clk_port})')
        elif d == 'input':
            pat_conns.append(f'.{sn}({sn})')
        else:
            pat_conns.append(f'.{sn}_dut({sn})')
    pat_conn = ',\n\t\t'.join(pat_conns)

    wires = '\n'.join(f'wire {(w + " ") if w else ""}{safe_signal(n)};' for _, w, n in ports)

    return f"""`timescale 1ns/10ps

`include "PATTERN.v"

`ifdef RTL
    `include "{design}.v"
`elsif GATE
    `include "Netlist/{design}_SYN.v"
`endif

module TESTBED;

{wires}

initial begin
\t`ifdef RTL
\t\t$fsdbDumpfile("{design}.fsdb");
\t\t$fsdbDumpvars(0,"+mda");
\t\t$fsdbDumpvars();
\t`endif
\t`ifdef GATE
\t\t$sdf_annotate("Netlist/{design}_SYN.sdf", u_DUT);
\t\t$fsdbDumpfile("{design}_SYN.fsdb");
\t\t$fsdbDumpvars();
\t`endif
end

`ifdef RTL
\t{design} u_DUT(
\t\t{dut_conn}
\t);
`elsif GATE
\t{design} u_DUT(
\t\t{dut_conn}
\t);
`endif

PATTERN u_PATTERN(
\t\t{pat_conn}
);

endmodule
"""


def normalize_ref_model(ref_text, rtl_mod_names, design):
    """
    Replace ref_X instantiation names with X when X is a known RTL submodule.
    Returns (normalized_text, set_of_rtl_submodules_now_needed_by_ref).
    """
    needed = set()
    submods = rtl_mod_names - {design}
    for mod_name in submods:
        ref_name = f'ref_{mod_name}'
        if ref_name in ref_text:
            ref_text = ref_text.replace(ref_name, mod_name)
            needed.add(mod_name)
    return ref_text, needed


def make_pattern_v(design, ports, stim_text, ref_text, rtl_mod_names,
                   rtl_content='', clk_port='clk'):
    """
    Assemble PATTERN.v with all fixes applied:
      - Preamble (e.g. `include "sd_defines.v") placed at top of file
      - $random[n] → ($random)[n] for VCS T-2022.06 compatibility
      - Keyword-named ports renamed as signal identifiers (e.g. reg → reg_sig)
      - Duplicate stimulus_gen port connections deduplicated
      - `ifdef GATE section includes all RTL submodule deps needed by ref model
        (BFS transitive closure so nested deps are captured too)
      - Clock port name used consistently (handles CLK, clk, clock, etc.)
    """
    # Fix VCS T-2022.06 rejection of bit-select on $random
    stim_text = stim_text.replace('$random[', '($random)[')

    # Preamble from ref/stim (e.g. `include "sd_defines.v") goes at top of file
    # so macros are defined before both the stimulus_gen and ref model modules.
    preamble = merge_preambles(ref_text, stim_text)

    ref_text, rtl_mods_used_by_ref = normalize_ref_model(ref_text, rtl_mod_names, design)

    ref_mods  = split_into_modules(ref_text)
    stim_mods = split_into_modules(stim_text)

    # Ref modules whose names clash with RTL go in `ifdef GATE so they don't
    # cause redefinition errors during RTL sim (where the RTL includes them).
    gate_only  = [(n, t) for n, t in ref_mods if n in rtl_mod_names]
    public_ref = [(n, t) for n, t in ref_mods if n not in rtl_mod_names]

    # BFS: find all RTL modules transitively needed by the ref model for GATE sim.
    # During GATE sim the DUT RTL files are not compiled, so any RTL submodule
    # instantiated by the ref model must be injected into the `ifdef GATE section.
    all_rtl_mods_map = ({n: t for n, t in split_into_modules(rtl_content)}
                        if rtl_content else {})
    gate_mod_names = {n for n, _ in gate_only}

    ref_all_text = '\n'.join(t for _, t in ref_mods)
    seed = find_module_instantiations(ref_all_text, set(all_rtl_mods_map.keys()))
    seed |= (rtl_mods_used_by_ref & set(all_rtl_mods_map.keys()))

    queue = list(seed - gate_mod_names - {design})
    while queue:
        mod = queue.pop(0)
        if mod in gate_mod_names or mod not in all_rtl_mods_map:
            continue
        gate_mod_names.add(mod)
        gate_only.append((mod, all_rtl_mods_map[mod]))
        transitive = find_module_instantiations(
            all_rtl_mods_map[mod], set(all_rtl_mods_map.keys()))
        queue.extend(transitive - gate_mod_names - {design})

    # Identify the primary ref module
    ref_mod_name = next((n for n, _ in public_ref if n.startswith('ref_')), None)
    if ref_mod_name is None and public_ref:
        ref_mod_name = public_ref[-1][0]
    if ref_mod_name is None:
        raise ValueError("Could not find ref module in ref.sv")

    ref_mod_text = next(t for n, t in public_ref if n == ref_mod_name)
    ref_ports = parse_module_ports(ref_mod_text) or ports

    dut_in  = [(d, w, n) for d, w, n in ports if d == 'input']
    dut_out = [(d, w, n) for d, w, n in ports if d == 'output']

    # PATTERN port list uses clk_port as-is; other ports use safe signal names
    port_name_list = (
        [clk_port]
        + [safe_signal(n) for _, _, n in dut_in if n != clk_port]
        + [safe_signal(n) + '_dut' for _, _, n in dut_out]
    )
    port_decls = (
        [f'    output logic {clk_port}']
        + [f'    output logic {(w + " ") if w else ""}{safe_signal(n)}'
           for _, w, n in dut_in if n != clk_port]
        + [f'    input  logic {(w + " ") if w else ""}{safe_signal(n)}_dut'
           for _, w, n in dut_out]
    )

    stats_fields = '\n'.join(
        f'        int errors_{n};\n        int errortime_{n};'
        for _, _, n in dut_out
    )

    ref_sig_decls = '\n'.join(
        f'    logic {(w + " ") if w else ""}{safe_signal(n)}_ref;'
        for _, w, n in dut_out
    )

    match_wire_lines = '\n'.join(
        f'    wire tb_match_{n} = ({safe_signal(n)}_ref === {safe_signal(n)}_dut);'
        for _, _, n in dut_out
    )
    tb_match_expr = ' & '.join(f'tb_match_{n}' for _, _, n in dut_out) or "1'b1"

    # Stimulus_gen connections — deduplicate to handle duplicate port declarations
    stim_mod_text = next((t for nm, t in stim_mods if nm == 'stimulus_gen'), stim_text)
    stim_ports = parse_module_ports(stim_mod_text)
    seen_stim, stim_conns = set(), []
    for _, _, sn in stim_ports:
        if sn not in seen_stim:
            seen_stim.add(sn)
            stim_conns.append(f'.{sn}({safe_signal(sn)})')
    stim_conn = ',\n\t\t'.join(stim_conns)

    # Ref model connections
    ref_conns = []
    dut_out_names = {n for _, _, n in dut_out}
    for _, _, rn in ref_ports:
        if rn in dut_out_names:
            ref_conns.append(f'.{rn}({safe_signal(rn)}_ref)')
        else:
            ref_conns.append(f'.{rn}({safe_signal(rn)})')
    ref_conn = ',\n\t\t'.join(ref_conns)

    error_block = '\n'.join(
        f'        if (!tb_match_{n}) begin\n'
        f'            if (stats1.errors_{n} == 0) stats1.errortime_{n} = $time;\n'
        f'            stats1.errors_{n}++;\n'
        f'        end'
        for _, _, n in dut_out
    )

    report_block = '\n'.join(
        f'        if (stats1.errors_{n})\n'
        f'            $display("Hint: Output {n} has %0d mismatches. First at time %0d",\n'
        f'                    stats1.errors_{n}, stats1.errortime_{n});\n'
        f'        else\n'
        f'            $display("Hint: Output \'{n}\' has no mismatches.");'
        for _, _, n in dut_out
    )

    gate_section = ''
    if gate_only:
        gate_section = '`ifdef GATE\n' + ''.join(t for _, t in gate_only) + '`endif\n\n'

    ref_section = '\n\n'.join(t.strip() for _, t in public_ref) + '\n\n'

    # Strip preamble from stim body (preamble is now at the top of PATTERN.v)
    stim_body = strip_preamble(stim_text).strip()

    pattern_mod = f"""module PATTERN({', '.join(port_name_list)});
{chr(10).join(d + ';' for d in port_decls)}

    typedef struct packed {{
        int errors;
        int errortime;
{stats_fields}
        int clocks;
    }} stats;

    stats stats1;

    initial begin
        {clk_port} = 0;
        forever #5 {clk_port} = ~{clk_port};
    end

    logic [511:0] wavedrom_title;
    logic         wavedrom_enable;
{ref_sig_decls}
{match_wire_lines}
    wire tb_match = {tb_match_expr};

    stimulus_gen stim1 (
\t\t{stim_conn}
    );

    {ref_mod_name} good1 (
\t\t{ref_conn}
    );

    initial begin
        $dumpfile("wave.vcd");
        $dumpvars(0);
    end

    always @(posedge {clk_port}) begin
        stats1.clocks++;
        if (!tb_match) begin
            if (stats1.errors == 0) stats1.errortime = $time;
            stats1.errors++;
        end
{error_block}
    end

    final begin
        $display("\\nTest Results:");
{report_block}
        $display("\\nHint: Total mismatched samples is %1d out of %1d samples\\n",
                stats1.errors, stats1.clocks);
        $display("Simulation finished at %0d ps", $time);
    end

    initial begin
        #1000000
        $display("TIMEOUT");
        $finish();
    end

endmodule
"""

    return preamble + gate_section + stim_body + '\n\n' + ref_section + pattern_mod


def make_syn_tcl(design, reset_port, clk_port='clk'):
    tcl = (TEMPLATE_DIR / '02_SYN' / 'syn.tcl').read_text()
    tcl = re.sub(r'set DESIGN ".*?"', f'set DESIGN "{design}"', tcl)
    # Update all [get_ports clk] references to use the actual clock port name
    if clk_port != 'clk':
        tcl = tcl.replace('[get_ports clk]', f'[get_ports {clk_port}]')
        # set_input_delay 0 -clock clk clk  →  set_input_delay 0 -clock clk CLK
        tcl = re.sub(r'(set_input_delay\s+0\s+-clock\s+\S+\s+)clk\b',
                     rf'\g<1>{clk_port}', tcl)
    # Update the reset port in set_input_delay 0 (keeps clock excluded from delay)
    tcl = re.sub(r'(set_input_delay\s+0\s+-clock\s+\S+\s+)rst_n\b',
                 rf'\g<1>{reset_port}', tcl)
    return tcl


def make_makefile(design):
    mk = (TEMPLATE_DIR / '00_TESTBED' / 'makefile').read_text()
    return re.sub(r'^top_design=\S+', f'top_design={design}', mk, flags=re.MULTILINE)


_SKIP_SUFFIXES = {'.v', '.sv', '.tcl', '.f', '.vcd'}
_SKIP_NAMES    = {'makefile', 'TESTBED.v', 'PATTERN.v', 'filelist.f', 'syn.tcl'}

_STUB_MAKEFILE = """\
%:
\t$(MAKE) -C ../00_TESTBED $@
.PHONY: %
"""


def copy_scripts(src_dir, dst_dir, design=None):
    """Copy shell scripts from template directory, make them executable."""
    for f in sorted(Path(src_dir).iterdir()):
        if f.is_file() and f.suffix not in _SKIP_SUFFIXES and f.name not in _SKIP_NAMES:
            dst = Path(dst_dir) / f.name
            if design and f.name == '08_check':
                text = f.read_text()
                text = text.replace('Design="TMIP"', f'Design="{design}"')
                dst.write_text(text)
            else:
                shutil.copy2(f, dst)
            dst.chmod(dst.stat().st_mode | 0o111)


# ---------------------------------------------------------------------------
# Main converter
# ---------------------------------------------------------------------------

def convert(cvdp_folder, output_folder=None):
    cvdp   = Path(cvdp_folder).resolve()
    design = get_design_name(cvdp)
    out    = Path(output_folder) if output_folder else Path(f'iclab_{design}')

    print(f"Design  : {design}")
    print(f"Input   : {cvdp}")
    print(f"Output  : {out}")

    tb_dir  = cvdp / '00_TESTBED'
    rtl_dir = cvdp / '01_RTL'

    rtl_files = sorted(
        f for f in rtl_dir.glob('*.v')
        if '.empty' not in f.name and '.bak' not in f.name
    )
    if not rtl_files:
        raise FileNotFoundError(f"No RTL .v files found in {rtl_dir}")

    rtl_content   = '\n\n'.join(f.read_text() for f in rtl_files)
    rtl_mod_names = {n for n, _ in split_into_modules(rtl_content)}

    top_mods = split_into_modules(rtl_files[0].read_text())
    top_text = next((t for n, t in top_mods if n == design),
                    top_mods[0][1] if top_mods else '')
    ports = parse_module_ports(top_text)
    if not ports:
        raise ValueError(f"Could not parse ports for module '{design}' in {rtl_files[0]}")

    clk_port   = find_clock_port(ports)
    reset_port = find_reset_port(ports)
    print(f"Ports   : {[n for _, _, n in ports]}")
    print(f"Clock   : {clk_port}")
    print(f"Reset   : {reset_port}")

    def read_tb(glob_pattern):
        matches = sorted(tb_dir.glob(glob_pattern))
        if not matches:
            raise FileNotFoundError(f"No file matching '{glob_pattern}' in {tb_dir}")
        return matches[0].read_text()

    stim_text = read_tb(f'{design}_stimulus_gen.sv')
    ref_text  = read_tb(f'{design}_ref.sv')

    # Prepend preamble includes to the DUT RTL so DC can compile designs
    # that use macro-defined constants (e.g. MEM_OFFSET in sd_fifo_tx_filler.v)
    preamble = merge_preambles(ref_text, stim_text)
    rtl_content = prepend_missing_includes(preamble, rtl_content)

    for sub in ['00_TESTBED', '01_RTL', '02_SYN/Netlist', '02_SYN/Report', '03_GATE']:
        (out / sub).mkdir(parents=True, exist_ok=True)

    (out / '00_TESTBED' / 'TESTBED.v').write_text(
        make_testbed_v(design, ports, clk_port))
    (out / '00_TESTBED' / 'PATTERN.v').write_text(
        make_pattern_v(design, ports, stim_text, ref_text, rtl_mod_names,
                       rtl_content, clk_port))
    (out / '00_TESTBED' / 'filelist.f').write_text('TESTBED.v\n')
    (out / '00_TESTBED' / 'makefile').write_text(make_makefile(design))

    (out / '01_RTL'     / f'{design}.v').write_text(rtl_content)
    (out / '00_TESTBED' / f'{design}.v').write_text(rtl_content)

    syn_tcl_content = make_syn_tcl(design, reset_port, clk_port)
    (out / '02_SYN'     / 'syn.tcl').write_text(syn_tcl_content)
    (out / '00_TESTBED' / 'syn.tcl').write_text(syn_tcl_content)

    (out / '00_TESTBED' / 'Netlist').mkdir(exist_ok=True)
    (out / '00_TESTBED' / 'Report').mkdir(exist_ok=True)

    # Copy auxiliary .v/.sv files from CVDP 00_TESTBED/ (e.g. sd_defines.v).
    # These are header/define files needed by VCS and DC but are not the generated
    # PATTERN.v or the ref/stim sources we already consumed.
    _gen_names = {'TESTBED.v', 'PATTERN.v', f'{design}.v',
                  f'{design}_ref.sv', f'{design}_stimulus_gen.sv'}
    for aux in sorted(tb_dir.iterdir()):
        if aux.is_file() and aux.suffix in {'.v', '.sv'} and aux.name not in _gen_names:
            shutil.copy2(aux, out / '00_TESTBED' / aux.name)

    copy_scripts(TEMPLATE_DIR / '00_TESTBED', out / '00_TESTBED')
    copy_scripts(TEMPLATE_DIR / '01_RTL',     out / '01_RTL',  design=design)
    copy_scripts(TEMPLATE_DIR / '02_SYN',     out / '02_SYN',  design=design)
    copy_scripts(TEMPLATE_DIR / '03_GATE',    out / '03_GATE', design=design)

    dc_setup_src = TEMPLATE_DIR / '02_SYN' / '.synopsys_dc.setup'
    if dc_setup_src.exists():
        shutil.copy2(dc_setup_src, out / '00_TESTBED' / '.synopsys_dc.setup')

    for sub in ['01_RTL', '02_SYN', '03_GATE']:
        (out / sub / 'makefile').write_text(_STUB_MAKEFILE)

    print("Done.")
    return out


if __name__ == '__main__':
    if len(sys.argv) < 2:
        print(f"Usage: python {sys.argv[0]} <cvdp_folder> [output_folder]")
        sys.exit(1)
    convert(sys.argv[1], sys.argv[2] if len(sys.argv) > 2 else None)
