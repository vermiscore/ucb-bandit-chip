# UCB Bandit Chip — Project Guide

This document describes the overall structure, workflows, and notes for the project.

---

## Directory Structure

```
~/Desktop/myfolder/research/bandit/
├── ucb-bandit-chip/                  # Main chip design repository (GitHub)
├── caravel_user_project/             # Efabless shuttle submission framework (active)
├── caravel_user_project_v1_backup/   # Backup — do not modify
└── OpenLane/                         # OpenLane v1.0.2 for standalone runs
```

---

## ucb-bandit-chip Layout

```
ucb-bandit-chip/
├── sim/              # Python bandit simulator
│   ├── ucb_ideal.py      Ideal UCB (float64 reference)
│   ├── ucb_fixed.py      Fixed-point model (LUT/CORDIC × 8/12/16-bit)
│   └── eval_regret.py    Regret comparison and plot output
├── rtl/              # Verilog RTL
│   ├── approx_ln.v       ln approximation (MODE=0: LUT, MODE=1: CORDIC)
│   ├── approx_sqrt.v     sqrt approximation
│   ├── reg_bank.v        Register bank (μ̂ and n for 64 arms)
│   ├── argmax.v          ArgMax unit
│   ├── score_engine.v    Sequential UCB score engine
│   └── ucb_top.v         Top-level module
├── tb/               # Testbench
│   └── tb_ucb_top.v      iverilog simulation testbench
├── gds/              # GDS layout files
│   ├── ucb_top.gds       16-bit LUT (main, DRC clean)
│   └── ucb_top_8bit.gds  8-bit LUT (DRC clean)
├── results/          # Evaluation data
│   ├── regret_curves.png     Regret comparison plot
│   ├── arm_match.png         Arm match rate plot
│   ├── summary.csv           Python simulation results
│   ├── ppa_table.md          Area/timing comparison (paper Table II)
│   └── openlane_metrics.csv  OpenLane metrics (16-bit run)
├── docs/             # Documentation
│   ├── paper_draft.md            Paper draft (ISSCC/VLSI target)
│   ├── figure1_architecture.svg  Architecture block diagram (serif, paper style)
│   ├── ucb_chip.png              KLayout screenshot (GDS)
│   └── project_guide.md          This file
└── syn/
    └── constraints.sdc   Timing constraints (100 ns = 10 MHz)
```

---

## Common Commands

### Python simulation

```bash
cd ~/Desktop/myfolder/research/bandit/ucb-bandit-chip/sim
python3 eval_regret.py
# Outputs: ../results/regret_curves.png, arm_match.png, summary.csv
```

### RTL simulation (iverilog)

```bash
BASE=~/Desktop/myfolder/research/bandit/ucb-bandit-chip
iverilog -o /tmp/ucb_sim \
  $BASE/rtl/approx_ln.v $BASE/rtl/approx_sqrt.v \
  $BASE/rtl/reg_bank.v  $BASE/rtl/argmax.v \
  $BASE/rtl/score_engine.v $BASE/rtl/ucb_top.v \
  $BASE/tb/tb_ucb_top.v && vvp /tmp/ucb_sim
```

### OpenLane — standalone chip runs (v1.0.2)

```bash
cd ~/Desktop/myfolder/research/bandit/OpenLane
make mount
# Inside the container:
./flow.tcl -design ucb_bandit -jobs 8        # 16-bit LUT
./flow.tcl -design ucb_bandit_8bit -jobs 8   # 8-bit LUT
```

### Caravel framework — tapeout

```bash
# Full build (user_proj_example + user_project_wrapper, ~2 hours)
cd ~/Desktop/myfolder/research/bandit/caravel_user_project
make harden

# user_project_wrapper only (skip user_proj_example, ~50 min)
cd ~/Desktop/myfolder/research/bandit/caravel_user_project
make -C openlane user_project_wrapper \
  UPRJ_ROOT=$(pwd) \
  OPEN_PDKS_COMMIT=78b7bc32ddb4b6f14f76883c2e2dc5b5de9d1cbc \
  CARAVEL_ROOT=$(pwd)/caravel \
  PDK_ROOT=/home/user/.volare/volare/sky130/versions/0fe599b2afb6708d281543108caf8310912f54af \
  PDK=sky130A \
  MCW_ROOT=$(pwd)/mgmt_core_wrapper \
  OPENLANE_ROOT=$(pwd)/dependencies/openlane_src
```

### Caravel — key files

| File | Description |
|------|-------------|
| `verilog/rtl/user_project_wrapper.v` | Top-level wrapper (maps ucb_top to Caravel IOs) |
| `openlane/user_project_wrapper/config.tcl` | OpenLane config for wrapper |
| `lef/ucb_top.lef` | LEF macro from standalone run |
| `gds/ucb_top.gds` | GDS macro from standalone run |
| `spef/ucb_top.{min,nom,max}.spef` | SPEF for multi-corner STA |
| `spi/lvs/ucb_top.spice` | SPICE netlist for LVS |

### Caravel — signal mapping

| Caravel signal | ucb_top signal |
|---------------|----------------|
| `la_data_in[0]` | `start` |
| `la_data_in[1]` | `reward_valid` |
| `la_data_in[7:2]` | `reward_arm[5:0]` |
| `la_data_in[23:8]` | `reward_val[15:0]` |
| `io_out[5:0]` | `selected_arm[5:0]` |
| `io_out[6]` | `valid_out` |
| `wb_clk_i` | `clk` |
| `wb_rst_i` (inverted) | `rst_n` |

### Open GDS in KLayout

```bash
klayout ~/Desktop/myfolder/research/bandit/ucb-bandit-chip/gds/ucb_top.gds
# To set dark background: File → Setup → Display → Background color → Black
```

### Git push to GitHub

```bash
cd ~/Desktop/myfolder/research/bandit/ucb-bandit-chip
git add .
git commit -m "commit message"
git push
# Username: vermiscore
# Password: GitHub Personal Access Token (regenerate if expired)
# Recommended: switch to SSH authentication to avoid token exposure
```

---

## Chip Parameters

| Parameter | Value | Description |
|-----------|-------|-------------|
| N_ARMS | 64 | Number of arms (wireless channels) |
| WIDTH | 8 / 12 / 16 | Fixed-point bit width |
| FRAC | WIDTH/2 | Fractional bits |
| MODE | 0=LUT, 1=CORDIC | Approximation method |

---

## Implementation Results Summary

| Bit width | Die area [mm²] | Cell count | Critical path [ns] | DRC |
|-----------|---------------|------------|-------------------|-----|
| 8-bit  | 0.2625 | 11,223 | 68.85 | Clean |
| 12-bit | 0.2954 (est.) | 12,548 (est.) | 69.27 (est.) | — |
| 16-bit | 0.3283 | 13,872 | 69.69 | Clean |

Clock frequency: 10 MHz (100 ns period, timing clean for 8-bit and 16-bit).

---

## Regret Results (10,000 rounds, N=64 arms)

| Mode | 8-bit | 12-bit | 16-bit | Ideal (float64) |
|------|-------|--------|--------|----------------|
| LUT | 2,036 (+24.5%) | 1,629 (-0.4%) | 1,602 (-2.1%) | 1,636 |
| CORDIC | 1,449 (-11.4%) | 1,752 (+7.1%) | 1,673 (+2.3%) | 1,636 |

**Key finding:** LUT 12-bit achieves ideal-equivalent regret with ~20% area reduction vs 16-bit.

---

## Important Notes

### GitHub token
Personal Access Tokens are used for HTTPS authentication. Tokens appear in terminal output — avoid sharing screenshots that include a git push session. Consider switching to SSH authentication.

### Power values
OpenLane power analysis (`power_typical_*_uW`) is unreliable due to missing `VSRC_LOC_FILES`. Power values are not included in the paper (marked N/A). Accurate power requires VCD-based simulation with OpenSTA.

### Caravel OpenLane version
The Caravel framework uses its own OpenLane version (2023.07.19-1) located at `caravel_user_project/dependencies/openlane_src`. This is separate from `OpenLane/` (v1.0.2). Do not mix the two.

### 12-bit GDS
GDS generation failed due to routing congestion. PPA values for 12-bit are linearly interpolated from 8-bit and 16-bit silicon data.

### CORDIC synthesis
CORDIC mode (MODE=1) caused ABC crash during synthesis (19k+ gates). Not implemented in silicon. Regret data from Python simulation only.

---

## Remaining Tasks

- [ ] Confirm Caravel user_project_wrapper LVS pass (run in progress)
- [ ] Set up SSH key for GitHub (eliminate token exposure)
- [ ] Survey related work (analog bandit chips) for paper Related Work
- [ ] Build prior work comparison table for paper
- [ ] Create info.yaml for Efabless shuttle submission
- [ ] Accurate power measurement via VCD-based OpenSTA
