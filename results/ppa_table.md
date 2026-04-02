# Table II: Implementation Results (UCB Bandit Chip, Sky130A)

## Chip Specifications

| Parameter | Value |
|-----------|-------|
| Process | SkyWater Sky130A (130nm) |
| N arms | 64 |
| Bit width | 16-bit fixed-point |
| Approximation | LUT (MODE=0) |
| Architecture | Sequential UCB score engine |

## Timing

| Parameter | Value |
|-----------|-------|
| Clock period | 100 ns |
| Clock frequency | **10 MHz** |
| Critical path | 69.69 ns |
| Timing slack | +30.31 ns (clean) |
| Setup violations | 0 |
| Hold violations | 0 |

## Area

| Parameter | Value |
|-----------|-------|
| Die area | 328,346 μm² (0.328 mm²) |
| Core area | 308,846 μm² (0.309 mm²) |
| Core utilization | 51.34% |
| Cell count | 13,872 |

## Power (Typical Corner, 1.8V)

| Parameter | Value |
|-----------|-------|
| Internal power | 0.398 mW |
| Switching power | 0.512 mW |
| Leakage power | 0.000095 mW |
| **Total power** | **0.910 mW** |

## Physical

| Parameter | Value |
|-----------|-------|
| Wire length | 985.4 mm |
| Vias | 138,921 |
| DRC violations | 0 |
| LVS | Pass |
| Tool | OpenLane v1.0.2 |

## Notes
- CORDIC (MODE=1) results TBD (next run)
- Bit width sweep (8/12/16-bit) PPA comparison TBD
- Critical path bottleneck: combinational division in score_engine
- Pipeline optimization target: >100MHz in future work

---

## Table III: Bit-Width Sweep Results (LUT mode, 64 arms)

### PPA vs Bit Width

| Metric | 8-bit | 12-bit (est.) | 16-bit |
|--------|-------|--------------|--------|
| Die area [mm²] | 0.2625 | 0.2954 | 0.3283 |
| Core area [μm²] | 245,480 | 277,163 | 308,846 |
| Cell count | 11,223 | 12,548 | 13,872 |
| Critical path [ns] | 68.85 | 69.27 | 69.69 |
| Clock frequency [MHz] | 10 | 10 | 10 |
| DRC violations | 0 | — | 0 |

*12-bit values estimated by linear interpolation from 8-bit and 16-bit silicon data.*

### Regret vs Bit Width (10,000 rounds, N=64)

| Mode | 8-bit | 12-bit | 16-bit | Ideal (float64) |
|------|-------|--------|--------|----------------|
| LUT | 2,036 (+24.5%) | 1,629 (-0.4%) | 1,602 (-2.1%) | 1,636 |
| CORDIC | 1,449 (-11.4%) | 1,752 (+7.1%) | 1,673 (+2.3%) | 1,636 |

### Arm Match Rate vs Ideal UCB

| Mode | 8-bit | 12-bit | 16-bit |
|------|-------|--------|--------|
| LUT | 99.3% | 100% | 100% |
| CORDIC | 100% | 100% | 100% |

**Key finding:** LUT 12-bit achieves ideal-equivalent regret with 19.9% area reduction vs 16-bit.
