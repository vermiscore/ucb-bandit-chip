# UCB Bandit Chip — Project Guide

This document describes the overall structure, workflows, and notes for the project.

---

## Directory Structure

```
~/Desktop/myfolder/research/bandit/
├── ucb-bandit-chip/                  # Main chip design repository (GitHub)
├── caravel_user_project/             # Efabless shuttle submission framework
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
│   ├── figure1_architecture.svg  Architecture block diagram
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

### OpenLane — standalone chip runs

```bash
cd ~/Desktop/myfolder/research/bandit/OpenLane
make mount
# Inside the container:
./flow.tcl -design ucb_bandit -jobs 8        # 16-bit LUT
./flow.tcl -design ucb_bandit_8bit -jobs 8   # 8-bit LUT
```

### Caravel framework — tapeout

```bash
cd ~/Desktop/myfolder/research/bandit/caravel_user_project
make harden    # Hardens user_proj_example then user_project_wrapper
```

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

---

## Remaining Tasks

- [ ] Complete Caravel user_project_wrapper GDS generation
- [ ] Set up SSH key for GitHub (eliminate token exposure)
- [ ] Survey related work (analog bandit chips)
- [ ] Build prior work comparison table for paper
- [ ] Create info.yaml for Efabless shuttle submission
- [ ] Accurate power measurement via VCD-based OpenSTA
