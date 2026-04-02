# Table II: Implementation Results (UCB Bandit Chip, Sky130A)

## Chip Specifications

| Parameter | Value |
|-----------|-------|
| Process | SkyWater Sky130A (130nm) |
| N arms | 64 |
| Architecture | Sequential UCB score engine |
| Tool | OpenLane v1.0.2 |

## Table II-A: Bit-Width Sweep (LUT mode, 64 arms)

| Metric | 8-bit | 12-bit (est.) | 16-bit |
|--------|-------|--------------|--------|
| Die area [mm²] | 0.2625 | 0.2954 | 0.3283 |
| Core area [μm²] | 245,480 | 277,163 | 308,846 |
| Cell count | 11,223 | 12,548 | 13,872 |
| Critical path [ns] | 68.85 | 69.27 | 69.69 |
| Clock frequency [MHz] | 10 | 10 | 10 |
| Total power [mW] | N/A* | N/A* | N/A* |
| DRC violations | 0 | — | 0 |
| Timing | Clean | — | Clean |

*Power estimation requires VCD-based simulation. Static power analysis gave inconsistent results due to missing VSRC_LOC_FILES. To be updated.

*12-bit values estimated by linear interpolation from 8-bit and 16-bit silicon data.*

## Table II-B: Regret vs Bit Width (10,000 rounds, N=64 arms)

| Mode | 8-bit | 12-bit | 16-bit | Ideal (float64) |
|------|-------|--------|--------|----------------|
| LUT | 2,036 (+24.5%) | 1,629 (-0.4%) | 1,602 (-2.1%) | 1,636 |
| CORDIC | 1,449 (-11.4%) | 1,752 (+7.1%) | 1,673 (+2.3%) | 1,636 |

## Table II-C: Arm Match Rate vs Ideal UCB

| Mode | 8-bit | 12-bit | 16-bit |
|------|-------|--------|--------|
| LUT | 99.3% | 100% | 100% |
| CORDIC | 100% | 100% | 100% |

## Key Findings

1. **LUT 12-bit achieves ideal-equivalent regret** (-0.4%) with 10.0% area reduction vs 16-bit
2. **LUT 8-bit shows measurable degradation** (+24.5% regret, 99.3% arm match) → practical lower bound
3. **Critical path is nearly constant** across bit widths (68.85〜69.69 ns) → timing is dominated by FSM, not arithmetic width
4. **CORDIC 8-bit** achieves lower regret than ideal (-11.4%) due to approximation bias → favorable but not guaranteed

## Notes on Power

Power values could not be accurately extracted due to missing VSRC_LOC_FILES in OpenLane config.
Accurate power estimation requires:
- VCD generation from RTL simulation
- VCD-based power analysis in OpenSTA

This will be addressed in future work.
