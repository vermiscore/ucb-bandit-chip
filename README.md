# ucb-bandit-chip

64-arm UCB1 bandit chip — digital fixed-point implementation.  
Evaluates approximation error impact (LUT vs CORDIC, 8/12/16-bit) on bandit performance.

## Research target

- Application: 64-channel wireless channel selection
- Goal: ISSCC / VLSI / CICC
- Key claim: first real-chip quantification of UCB approximation error vs cumulative regret

## Directory structure

```
sim/   Python bandit simulator (ideal + fixed-point models)
rtl/   Verilog RTL (approx_ln, approx_sqrt, reg_bank, score_engine, ucb_top)
tb/    Testbench (iverilog)
syn/   Synthesis constraints (SDC)
docs/  Design notes, paper draft
results/ Output CSVs and plots
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
BASE=~/Desktop/myfolder/research/bandit/ucb-bandit-chip
iverilog -o /tmp/ucb_sim \
  $BASE/rtl/approx_ln.v $BASE/rtl/approx_sqrt.v \
  $BASE/rtl/reg_bank.v  $BASE/rtl/argmax.v \
  $BASE/rtl/score_engine.v $BASE/rtl/ucb_top.v \
  $BASE/tb/tb_ucb_top.v && vvp /tmp/ucb_sim
```

## Key parameters

| Parameter | Values       | Description          |
|-----------|-------------|----------------------|
| N_ARMS    | 64          | Number of arms       |
| WIDTH     | 8 / 12 / 16 | Fixed-point bit width|
| FRAC      | WIDTH/2     | Fractional bits      |
| MODE      | 0=LUT, 1=CORDIC | Approximation mode |

## RTL simulation results

| Mode   | Bits | Best arm rate |
|--------|------|--------------|
| LUT    | 8    | 99.3%        |
| LUT    | 12   | 100.0%       |
| LUT    | 16   | 100.0%       |
| CORDIC | 8    | 100.0%       |
| CORDIC | 12   | 100.0%       |
| CORDIC | 16   | 100.0%       |
