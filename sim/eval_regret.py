"""
eval_regret.py
--------------
Compare cumulative regret across:
  - Ideal UCB1 (float64)
  - Fixed-point UCB (LUT / CORDIC x 8 / 12 / 16 bit)

Outputs:
  - regret curves plot  (results/regret_curves.png)
  - arm match rate plot (results/arm_match.png)
  - summary CSV         (results/summary.csv)
"""

import numpy as np
import matplotlib.pyplot as plt
import csv
import os

from ucb_ideal import run_simulation as run_ideal
from ucb_fixed import run_simulation as run_fixed

# ---------------------------------------------------------------------------
# Config
# ---------------------------------------------------------------------------

N_ARMS   = 64
N_ROUNDS = 10_000
SEED     = 42
BITS     = [8, 12, 16]
MODES    = ["lut", "cordic"]

RESULTS_DIR = os.path.join(os.path.dirname(__file__), "../results")
os.makedirs(RESULTS_DIR, exist_ok=True)

# ---------------------------------------------------------------------------
# Generate shared environment
# ---------------------------------------------------------------------------

rng = np.random.default_rng(SEED)
true_means = rng.uniform(0.0, 1.0, size=N_ARMS)
best_arm   = int(np.argmax(true_means))
print(f"Best arm: {best_arm}  (mean={true_means[best_arm]:.4f})")

# ---------------------------------------------------------------------------
# Run all conditions
# ---------------------------------------------------------------------------

results = {}

# Ideal
r = run_ideal(N_ARMS, true_means, N_ROUNDS, seed=SEED)
results["ideal"] = r
print(f"[ideal       ]  regret={r['cumulative_regret'][-1]:.2f}")

# Fixed-point
for mode in MODES:
    for bits in BITS:
        key = f"{mode}_{bits}bit"
        r = run_fixed(N_ARMS, true_means, N_ROUNDS,
                      n_bits=bits, approx_mode=mode, seed=SEED)
        results[key] = r
        print(f"[{key:12s}]  regret={r['cumulative_regret'][-1]:.2f}")

# ---------------------------------------------------------------------------
# Plot 1: Cumulative regret curves
# ---------------------------------------------------------------------------

COLOR = {
    "ideal":        ("black",  "-",  2.0),
    "lut_8bit":     ("#E24B4A", "--", 1.2),
    "lut_12bit":    ("#E24B4A", "-.", 1.2),
    "lut_16bit":    ("#E24B4A", "-",  1.2),
    "cordic_8bit":  ("#378ADD", "--", 1.2),
    "cordic_12bit": ("#378ADD", "-.", 1.2),
    "cordic_16bit": ("#378ADD", "-",  1.2),
}

LABEL = {
    "ideal":        "Ideal UCB (float64)",
    "lut_8bit":     "LUT  8-bit",
    "lut_12bit":    "LUT 12-bit",
    "lut_16bit":    "LUT 16-bit",
    "cordic_8bit":  "CORDIC  8-bit",
    "cordic_12bit": "CORDIC 12-bit",
    "cordic_16bit": "CORDIC 16-bit",
}

fig, ax = plt.subplots(figsize=(8, 5))
rounds = np.arange(1, N_ROUNDS + 1)

for key, (color, ls, lw) in COLOR.items():
    ax.plot(rounds, results[key]["cumulative_regret"],
            color=color, linestyle=ls, linewidth=lw, label=LABEL[key])

ax.set_xlabel("Round")
ax.set_ylabel("Cumulative regret")
ax.set_title(f"UCB1 approximation comparison  (N={N_ARMS} arms)")
ax.legend(fontsize=8, loc="upper left")
ax.grid(True, alpha=0.3)
fig.tight_layout()
path1 = os.path.join(RESULTS_DIR, "regret_curves.png")
fig.savefig(path1, dpi=150)
plt.close(fig)
print(f"Saved: {path1}")

# ---------------------------------------------------------------------------
# Plot 2: Arm match rate vs ideal
# ---------------------------------------------------------------------------

fig, ax = plt.subplots(figsize=(8, 4))
window = 200  # rolling window for match rate

ideal_arms = results["ideal"]["chosen_arms"]

for key in [k for k in COLOR if k != "ideal"]:
    color, ls, lw = COLOR[key]
    approx_arms = results[key]["chosen_arms"]
    match = (approx_arms == ideal_arms).astype(float)
    # Rolling mean
    rolling = np.convolve(match, np.ones(window) / window, mode="valid")
    ax.plot(np.arange(window, N_ROUNDS + 1), rolling,
            color=color, linestyle=ls, linewidth=lw, label=LABEL[key])

ax.set_xlabel("Round")
ax.set_ylabel(f"Arm match rate (window={window})")
ax.set_title("Arm selection agreement with ideal UCB")
ax.set_ylim(0, 1.05)
ax.legend(fontsize=8, loc="lower right")
ax.grid(True, alpha=0.3)
fig.tight_layout()
path2 = os.path.join(RESULTS_DIR, "arm_match.png")
fig.savefig(path2, dpi=150)
plt.close(fig)
print(f"Saved: {path2}")

# ---------------------------------------------------------------------------
# CSV summary
# ---------------------------------------------------------------------------

csv_path = os.path.join(RESULTS_DIR, "summary.csv")
with open(csv_path, "w", newline="") as f:
    writer = csv.writer(f)
    writer.writerow(["condition", "final_regret", "regret_overhead_%", "arm_match_rate_%"])
    ideal_regret = results["ideal"]["cumulative_regret"][-1]
    ideal_arms   = results["ideal"]["chosen_arms"]
    for key in results:
        reg   = results[key]["cumulative_regret"][-1]
        overhead = (reg - ideal_regret) / ideal_regret * 100
        match = np.mean(results[key]["chosen_arms"] == ideal_arms) * 100
        writer.writerow([key, f"{reg:.2f}", f"{overhead:.1f}", f"{match:.1f}"])
print(f"Saved: {csv_path}")
