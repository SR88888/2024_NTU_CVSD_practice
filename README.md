# 2024 NTU CVSD Practice

Practice work from the 2024 **Computer-Aided VLSI System Design (CVSD)** course at National Taiwan University. This repository contains four homework assignments and an elliptic-curve cryptographic processor final project, including Verilog/SystemVerilog RTL, testbenches, synthesis scripts, and selected physical design and simulation artifacts.

## Projects

| Assignment | Topic | Main implementation | Specification |
| --- | --- | --- | --- |
| HW1 | Fixed-point arithmetic logic unit (ALU) | [alu.v](Homework/1/01_RTL/alu.v) | [Assignment specification](Homework/1/113-1_HW1_v2.pdf) |
| HW2 | Simplified RISC-V CPU with floating-point operations | [core.v](Homework/2/01_RTL/core.v) | [Assignment specification](Homework/2/1131_HW2_v2.pdf) |
| HW3 | Convolution and image processing engine with SRAM, median filtering, and Sobel operations | [core.v](Homework/3/01_RTL/core.v) | [Assignment specification](Homework/3/1131_hw3_v1.pdf) |
| HW4 | IoT Data Filtering with DES, CRC, and data comparison | [IOTDF.v](Homework/4/01_RTL/IOTDF.v) | [Assignment specification](Homework/4/1131_hw4_v3.pdf) |
| Final | Ed25519-related elliptic-curve scalar multiplication core | [ed25519.sv](Final/01_RTL/ed25519.sv) | [Project specification](Final/1131_final_note_v3.pdf) |

The final project accelerates the elliptic-curve operations used in EdDSA and includes a [Python reference model](Final/ed25519.py). Refer to the project specification for the interface and supported operations.

## Repository Layout

```text
.
├── Homework/
│   ├── 1/              # ALU and test data
│   ├── 2/              # CPU and testbench
│   ├── 3/              # Image processing, SRAM, and synthesis settings
│   └── 4/              # IoT data processing and power analysis settings
└── Final/
    ├── 00_TESTBED/     # Testbench and patterns
    ├── 01_RTL/         # RTL and simulation file list
    ├── 02_SYN/         # Design Compiler scripts and timing constraints
    ├── 03_GATE/        # Gate-level simulation settings
    ├── 04_APR/         # Physical design data and artifacts
    ├── 05_POST/        # Post-layout simulation settings
    └── ed25519.py      # Software reference model
```

The available design stages vary by assignment. Start with the file lists and documentation in the corresponding directory.

## Requirements

- A Linux/Unix shell and an available Synopsys VCS installation.
- Verdi/FSDB for waveform debugging. The existing file lists reference PLI paths on the course workstations.
- Synopsys Design Compiler for synthesis. APR and subsequent analysis require the corresponding EDA tools, standard-cell libraries, and SRAM models.
- Python 3 for the software reference model.

Paths such as `/usr/cad/...` and `/home/raid...` belong to the original course environment and must be adjusted on other workstations. The floating-point addition/subtraction in HW2 also references a DesignWare simulation model.

## Quick Start: Final Project RTL Simulation

Set up the course tool environment, then run:

```bash
git clone https://github.com/SR88888/2024_NTU_CVSD_practice.git
cd 2024_NTU_CVSD_practice/Final/01_RTL

vcs -R -full64 -f rtl_sim.f +define+PAT0
```

- `rtl_sim.f` specifies the RTL, testbench, and simulation options. Its relative paths assume `Final/01_RTL` as the working directory.
- Replace `PAT0` to select another test index, ensuring that it is available in `00_TESTBED/pattern/tb_dat.sv`.
- [testbed.sv](Final/00_TESTBED/testbed.sv) also contains include options for edge, random, and combined patterns. Check the data and test indices when switching between them.
- [01_run](Final/01_RTL/01_run) contains batch simulation commands.

## Synthesis and Subsequent Stages

Follow `01_RTL → 02_SYN → 03_GATE → 04_APR → 05_POST` for the final project flow. The synthesis script, [syn.tcl](Final/02_SYN/syn.tcl), loads the timing constraints from the same directory. Check the library paths and tool versions before running it.

Existing netlists, reports, and APR data document previous development runs. Evaluate changes using the test results, timing reports, and area reports from a new run.
