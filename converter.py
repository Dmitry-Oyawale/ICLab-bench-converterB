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
    For non-ANSI, restricts to names listed in the module header to avoid
    picking up port declarations from inlined submodule definitions.
    """
    tok = re.compile(
        r'\b(input|output|inout)\s+'
        r'(?:wire\s+|reg\s+|logic\s+)*'
        r'(\[[\w\s:\-+*`]+\]\s*)?'
        r'(\w+)',
        re.MULTILINE
    )

    # ANSI: direction declarations live inside the port-list parentheses
    header = re.search(
        r'module\s+\w+\s*(?:#\s*\([^)]*\)\s*)?\s*\(([^;]*)\)\s*;',
        module_text, re.DOTALL
    )
    if header:
        ports = [(m.group(1), (m.group(2) or '').strip(), m.group(3))
                 for m in tok.finditer(header.group(1))]
        if ports:
            return ports

    # Non-ANSI: extract port names from the module header line first,
    # then only accept body declarations for those names.
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
    # Only scan the module body (after the first ';')
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

def make_testbed_v(design, ports):
    dut_conn = ',\n\t\t'.join(f'.{n}({n})' for _, _, n in ports)

    pat_conns = []
    for d, _, n in ports:
        if n == 'clk':
            pat_conns.append('.clk(clk)')
        elif d == 'input':
            pat_conns.append(f'.{n}({n})')
        else:
            pat_conns.append(f'.{n}_dut({n})')
    pat_conn = ',\n\t\t'.join(pat_conns)

    wires = '\n'.join(f'wire {(w + " ") if w else ""}{n};' for _, w, n in ports)

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
    Some CVDP ref models prefix all sub-instantiations with ref_ even though
    those modules only exist in the RTL under their original names.
    Skips the top design module itself so the ref model's own name is preserved.
    Returns (normalized_text, set_of_rtl_submodules_now_needed_by_ref).
    """
    needed = set()
    submods = rtl_mod_names - {design}   # never rename the top module
    for mod_name in submods:
        ref_name = f'ref_{mod_name}'
        if ref_name in ref_text:
            ref_text = ref_text.replace(ref_name, mod_name)
            needed.add(mod_name)
    return ref_text, needed


def make_pattern_v(design, ports, stim_text, ref_text, rtl_mod_names, rtl_content=''):
    """
    Assemble PATTERN.v:
      1. `ifdef GATE section  — ref.sv modules that clash with RTL module names
      2. stimulus_gen          — verbatim from CVDP *_stimulus_gen.sv
      3. ref model             — verbatim non-clashing modules from CVDP *_ref.sv
      4. PATTERN wrapper       — generated from port list
    """
    # Normalize ref model: some CVDP ref models instantiate ref_X where X is
    # a plain RTL submodule. Strip the prefix so the ref model uses the same
    # module names as the RTL (those modules are provided during RTL sim by the
    # RTL include, and during gate sim by the ifdef GATE section below).
    ref_text, rtl_mods_used_by_ref = normalize_ref_model(ref_text, rtl_mod_names, design)

    ref_mods = split_into_modules(ref_text)
    stim_mods = split_into_modules(stim_text)

    # Ref.sv modules whose names clash with RTL go in ifdef GATE (would cause
    # redefinition during RTL sim if included unconditionally).
    gate_only  = [(n, t) for n, t in ref_mods if n in rtl_mod_names]
    public_ref = [(n, t) for n, t in ref_mods if n not in rtl_mod_names]

    # RTL submodule implementations needed by the ref model during gate sim
    # (when the RTL files are NOT compiled).  Pull from the combined RTL content.
    if rtl_content:
        all_rtl_mods = {n: t for n, t in split_into_modules(rtl_content)}
        for sub in rtl_mods_used_by_ref:
            if sub != design and sub in all_rtl_mods:
                gate_only.append((sub, all_rtl_mods[sub]))

    # Find the primary ref module (the one named ref_*)
    ref_mod_name = next((n for n, _ in public_ref if n.startswith('ref_')), None)
    if ref_mod_name is None and public_ref:
        ref_mod_name = public_ref[-1][0]
    if ref_mod_name is None:
        raise ValueError("Could not find ref module in ref.sv")

    ref_mod_text = next(t for n, t in public_ref if n == ref_mod_name)
    ref_ports = parse_module_ports(ref_mod_text) or ports

    dut_in  = [(d, w, n) for d, w, n in ports if d == 'input']
    dut_out = [(d, w, n) for d, w, n in ports if d == 'output']

    # PATTERN module port list and declarations
    port_name_list = (
        ['clk']
        + [n for _, _, n in dut_in if n != 'clk']
        + [n + '_dut' for _, _, n in dut_out]
    )
    port_decls = (
        ['    output logic clk']
        + [f'    output logic {(w + " ") if w else ""}{n}'
           for _, w, n in dut_in if n != 'clk']
        + [f'    input  logic {(w + " ") if w else ""}{n}_dut'
           for _, w, n in dut_out]
    )

    # Stats struct fields
    stats_fields = '\n'.join(
        f'        int errors_{n};\n        int errortime_{n};'
        for _, _, n in dut_out
    )

    # Ref output signal declarations (internal to PATTERN)
    ref_sig_decls = '\n'.join(
        f'    logic {(w + " ") if w else ""}{n}_ref;'
        for _, w, n in dut_out
    )

    # tb_match wires
    match_wire_lines = '\n'.join(
        f'    wire tb_match_{n} = ({n}_ref === {n}_dut);'
        for _, _, n in dut_out
    )
    tb_match_expr = ' & '.join(f'tb_match_{n}' for _, _, n in dut_out) or "1'b1"

    # stimulus_gen connections — connect every port by matching name
    stim_mod_text = next((t for nm, t in stim_mods if nm == 'stimulus_gen'), stim_text)
    stim_ports = parse_module_ports(stim_mod_text)
    stim_conn = ',\n\t\t'.join(f'.{sn}({sn})' for _, _, sn in stim_ports)

    # ref model connections
    ref_conns = []
    dut_out_names = {n for _, _, n in dut_out}
    for _, _, rn in ref_ports:
        if rn in dut_out_names:
            ref_conns.append(f'.{rn}({rn}_ref)')
        else:
            ref_conns.append(f'.{rn}({rn})')
    ref_conn = ',\n\t\t'.join(ref_conns)

    # Always-block error counting
    error_block = '\n'.join(
        f'        if (!tb_match_{n}) begin\n'
        f'            if (stats1.errors_{n} == 0) stats1.errortime_{n} = $time;\n'
        f'            stats1.errors_{n}++;\n'
        f'        end'
        for _, _, n in dut_out
    )

    # Final report
    report_block = '\n'.join(
        f'        if (stats1.errors_{n})\n'
        f'            $display("Hint: Output {n} has %0d mismatches. First at time %0d",\n'
        f'                    stats1.errors_{n}, stats1.errortime_{n});\n'
        f'        else\n'
        f'            $display("Hint: Output \'{n}\' has no mismatches.");'
        for _, _, n in dut_out
    )

    # Assemble sections
    gate_section = ''
    if gate_only:
        gate_section = '`ifdef GATE\n' + ''.join(t for _, t in gate_only) + '`endif\n\n'

    ref_section = '\n\n'.join(t.strip() for _, t in public_ref) + '\n\n'

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
        clk = 0;
        forever #5 clk = ~clk;
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

    always @(posedge clk) begin
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

    return gate_section + stim_text.strip() + '\n\n' + ref_section + pattern_mod


def make_syn_tcl(design, reset_port):
    tcl = (TEMPLATE_DIR / '02_SYN' / 'syn.tcl').read_text()
    tcl = re.sub(r'set DESIGN ".*?"', f'set DESIGN "{design}"', tcl)
    # Replace the reset-port line only (skip the 'clk clk' line)
    tcl = re.sub(r'set_input_delay 0 -clock clk (?!clk\b)\w+',
                 f'set_input_delay 0 -clock clk {reset_port}', tcl)
    return tcl


def make_makefile(design):
    mk = (TEMPLATE_DIR / '00_TESTBED' / 'makefile').read_text()
    return re.sub(r'^top_design=\S+', f'top_design={design}', mk, flags=re.MULTILINE)


# Files that belong to the design or are regenerated — skip when copying scripts
_SKIP_SUFFIXES = {'.v', '.sv', '.tcl', '.f', '.vcd'}
_SKIP_NAMES    = {'makefile', 'TESTBED.v', 'PATTERN.v', 'filelist.f', 'syn.tcl'}

# Stub makefile written to each subdirectory so that scripts like
# ./01_run_vcs_rtl can be run directly from 01_RTL/ (or 02_SYN/, 03_GATE/).
# All targets are delegated to 00_TESTBED/ where the real makefile and all
# simulation files live.
_STUB_MAKEFILE = """\
%:
\t$(MAKE) -C ../00_TESTBED $@
.PHONY: %
"""


def copy_scripts(src_dir, dst_dir, design=None):
    """Copy shell scripts from template directory, make them executable.
    If design is provided, replaces hardcoded design name 'TMIP' in 08_check."""
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

    # Collect non-stub RTL files
    rtl_files = sorted(
        f for f in rtl_dir.glob('*.v')
        if '.empty' not in f.name and '.bak' not in f.name
    )
    if not rtl_files:
        raise FileNotFoundError(f"No RTL .v files found in {rtl_dir}")

    # Combine all RTL into one string (usually a single file)
    rtl_content  = '\n\n'.join(f.read_text() for f in rtl_files)
    rtl_mod_names = {n for n, _ in split_into_modules(rtl_content)}

    # Parse top module ports
    top_mods = split_into_modules(rtl_files[0].read_text())
    top_text = next((t for n, t in top_mods if n == design),
                    top_mods[0][1] if top_mods else '')
    ports = parse_module_ports(top_text)
    if not ports:
        raise ValueError(f"Could not parse ports for module '{design}' in {rtl_files[0]}")

    reset_port = find_reset_port(ports)
    print(f"Ports   : {[n for _, _, n in ports]}")
    print(f"Reset   : {reset_port}")

    # Load CVDP verification files
    def read_tb(glob_pattern):
        matches = sorted(tb_dir.glob(glob_pattern))
        if not matches:
            raise FileNotFoundError(f"No file matching '{glob_pattern}' in {tb_dir}")
        return matches[0].read_text()

    stim_text = read_tb(f'{design}_stimulus_gen.sv')
    ref_text  = read_tb(f'{design}_ref.sv')

    # Create output directory tree
    for sub in ['00_TESTBED', '01_RTL', '02_SYN/Netlist', '02_SYN/Report', '03_GATE']:
        (out / sub).mkdir(parents=True, exist_ok=True)

    # Write generated files
    (out / '00_TESTBED' / 'TESTBED.v').write_text(
        make_testbed_v(design, ports))
    (out / '00_TESTBED' / 'PATTERN.v').write_text(
        make_pattern_v(design, ports, stim_text, ref_text, rtl_mod_names, rtl_content))
    (out / '00_TESTBED' / 'filelist.f').write_text('TESTBED.v\n')
    (out / '00_TESTBED' / 'makefile').write_text(make_makefile(design))

    # RTL file goes in both 01_RTL/ (source) and 00_TESTBED/ (VCS include path)
    (out / '01_RTL'     / f'{design}.v').write_text(rtl_content)
    (out / '00_TESTBED' / f'{design}.v').write_text(rtl_content)

    # syn.tcl goes in both 02_SYN/ (reference) and 00_TESTBED/ (DC runs from there)
    syn_tcl_content = make_syn_tcl(design, reset_port)
    (out / '02_SYN'     / 'syn.tcl').write_text(syn_tcl_content)
    (out / '00_TESTBED' / 'syn.tcl').write_text(syn_tcl_content)

    # Netlist/ and Report/ must exist under 00_TESTBED/ since DC runs from there
    (out / '00_TESTBED' / 'Netlist').mkdir(exist_ok=True)
    (out / '00_TESTBED' / 'Report').mkdir(exist_ok=True)

    # Copy shell scripts from templates (pass design so 08_check gets the right name)
    copy_scripts(TEMPLATE_DIR / '00_TESTBED', out / '00_TESTBED')
    copy_scripts(TEMPLATE_DIR / '01_RTL',     out / '01_RTL',  design=design)
    copy_scripts(TEMPLATE_DIR / '02_SYN',     out / '02_SYN',  design=design)
    copy_scripts(TEMPLATE_DIR / '03_GATE',    out / '03_GATE', design=design)

    # .synopsys_dc.setup must be in 00_TESTBED/ because DC runs from there
    # (make syn invokes dcnxt_shell from the 00_TESTBED/ working directory).
    dc_setup_src = TEMPLATE_DIR / '02_SYN' / '.synopsys_dc.setup'
    if dc_setup_src.exists():
        shutil.copy2(dc_setup_src, out / '00_TESTBED' / '.synopsys_dc.setup')

    # Stub makefiles in each subdirectory delegate to 00_TESTBED/ so that
    # scripts like ./01_run_vcs_rtl can be executed directly from their directory.
    stub = _STUB_MAKEFILE
    for sub in ['01_RTL', '02_SYN', '03_GATE']:
        (out / sub / 'makefile').write_text(stub)

    print("Done.")
    return out


if __name__ == '__main__':
    if len(sys.argv) < 2:
        print(f"Usage: python {sys.argv[0]} <cvdp_folder> [output_folder]")
        sys.exit(1)
    convert(sys.argv[1], sys.argv[2] if len(sys.argv) > 2 else None)
