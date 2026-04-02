# ucb-bandit-chip

64-arm UCB1 bandit chip — digital fixed-point implementation on Sky130A.  
Evaluates approximation error impact (LUT vs CORDIC, 8/12/16-bit) on bandit performance.

## Research target

- Application: 64-channel wireless channel selection
- Goal: ISSCC / VLSI / CICC
- Key claim: first real-chip quantification of UCB approximation error vs cumulative regret

## Chip specs

| Item | Value |
|------|-------|
| Process | SkyWater Sky130A (130nm) |
| Architecture | Sequential, fixed-point digital |
| N arms | 64 |
| Bit width | 8 / 12 / 16 (parameterized) |
| Approximation | LUT / CORDIC (parameterized) |
| Clock | 10MHz (100ns, timing clean) |
| Die area | 700×700 μm |
| Tool | OpenLane v1.0.2 |
| DRC | Clean |
| LVS | Pass |

## Directory structure

```
sim/      Python bandit simulator (ideal + fixed-point models)
rtl/      Verilog RTL (approx_ln, approx_sqrt, reg_bank, score_engine, ucb_top)
tb/       Testbench (iverilog, 300/300 arm selection verified)
syn/      Synthesis constraints (SDC)
gds/      GDS layout (Sky130A, OpenLane)
docs/     Design notes, paper draft
results/  Output CSVs and plots
```

## Quick start

### Python simulation

```bash
cd sim
python3 eval_regret.py
# outputs: ../results/regret_curves.png, arm_match.png, summary.csv
```

### RTL simulation

```bash
BASE=~/path/to/ucb-bandit-chip
iverilog -o /tmp/ucb_sim \
  $BASE/rtl/approx_ln.v $BASE/rtl/approx_sqrt.v \
  $BASE/rtl/reg_bank.v  $BASE/rtl/argmax.v \
  $BASE/rtl/score_engine.v $BASE/rtl/ucb_top.v \
  $BASE/tb/tb_ucb_top.v && vvp /tmp/ucb_sim
```

## Key parameters

| Parameter | Values | Description |
|-----------|--------|-------------|
| N_ARMS | 64 | Number of arms |
| WIDTH | 8 / 12 / 16 | Fixed-point bit width |
| FRAC | WIDTH/2 | Fractional bits |
| MODE | 0=LUT, 1=CORDIC | Approximation mode |

## RTL simulation results (300 rounds, 64 arms)

| Mode | Bits | Best arm rate |
|------|------|--------------|
| LUT | 8 | 99.3% |
| LUT | 12 | 100.0% |
| LUT | 16 | 100.0% |
| CORDIC | 8 | 100.0% |
| CORDIC | 12 | 100.0% |
| CORDIC | 16 | 100.0% |

## OpenLane flow results

| Item | Result |
|------|--------|
| Synthesis | Pass |
| Floorplan | 556.6 × 554.88 μm |
| Placement | Pass |
| CTS | Pass |
| Routing | Pass (No DRC violations) |
| Setup timing | Clean (no violations) |
| Hold timing | Clean (no violations) |
| DRC | Clean |
| LVS | Pass |
| GDS | Generated |
