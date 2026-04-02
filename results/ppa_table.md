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
