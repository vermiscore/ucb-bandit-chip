"""
ucb_fixed.py
------------
Fixed-point UCB1 simulator with approximate ln and sqrt.
Models the quantization and approximation errors that occur in the chip.

Approximation modes:
    'lut'    : lookup-table based (uniform quantization of input range)
    'cordic' : CORDIC-style iterative approximation

Bit widths to sweep: 8, 12, 16
"""

import numpy as np


# ---------------------------------------------------------------------------
# Fixed-point quantization helper
# ---------------------------------------------------------------------------

def quantize(x: np.ndarray, n_bits: int, x_min: float, x_max: float) -> np.ndarray:
    """Quantize x to n_bits uniform levels in [x_min, x_max]."""
    n_levels = 2 ** n_bits
    step = (x_max - x_min) / (n_levels - 1)
    clipped = np.clip(x, x_min, x_max)
    indices = np.round((clipped - x_min) / step).astype(np.int64)
    return x_min + indices * step


# ---------------------------------------------------------------------------
# Approximate ln
# ---------------------------------------------------------------------------

def approx_ln_lut(x: np.ndarray, n_bits: int) -> np.ndarray:
    """
    LUT-based ln approximation.
    Input range: [1, 10000] (covers t up to 10000 rounds)
    """
    x_min, x_max = 1.0, 10000.0
    x_q = quantize(x, n_bits, x_min, x_max)
    return np.log(x_q)  # ideal ln applied after quantization of input


def approx_ln_cordic(x: np.ndarray, n_bits: int) -> np.ndarray:
    """
    CORDIC-style ln approximation.
    Uses iterative halving: ln(x) approximated with n_bits iterations.
    """
    n_iter = n_bits  # more bits = more iterations = higher precision
    result = np.zeros_like(x, dtype=np.float64)
    x_work = x.copy().astype(np.float64)

    # Range reduction: ln(x) = ln(x/2^k) + k*ln(2)
    k = np.floor(np.log2(x_work)).astype(np.int64)
    x_work = x_work / (2.0 ** k)
    result += k * np.log(2.0)

    # Iterative refinement (simplified CORDIC-like)
    # Truncate precision based on n_bits
    scale = 2 ** n_bits
    x_work = np.round(x_work * scale) / scale  # quantize mantissa
    result += np.log(np.clip(x_work, 1e-10, None))

    return result


# ---------------------------------------------------------------------------
# Approximate sqrt
# ---------------------------------------------------------------------------

def approx_sqrt_lut(x: np.ndarray, n_bits: int) -> np.ndarray:
    """
    LUT-based sqrt approximation.
    Input range: [0, 20] (covers 2*ln(t)/n for typical ranges)
    """
    x_min, x_max = 0.0, 20.0
    x_q = quantize(x, n_bits, x_min, x_max)
    return np.sqrt(np.clip(x_q, 0.0, None))


def approx_sqrt_cordic(x: np.ndarray, n_bits: int) -> np.ndarray:
    """
    CORDIC-style sqrt approximation (Newton-Raphson iterations).
    Number of iterations determined by n_bits.
    """
    n_iter = max(1, n_bits // 4)
    x_c = np.clip(x, 0.0, None)

    # Initial estimate (1-bit approximation)
    y = np.where(x_c > 0, 2.0 ** (np.floor(np.log2(np.clip(x_c, 1e-10, None))) / 2), 0.0)
    y = np.clip(y, 1e-10, None)

    # Newton-Raphson refinement
    for _ in range(n_iter):
        y = 0.5 * (y + x_c / y)
        # Quantize after each iteration to model register truncation
        scale = 2 ** n_bits
        y = np.round(y * scale) / scale

    return y


# ---------------------------------------------------------------------------
# Fixed-point UCB agent
# ---------------------------------------------------------------------------

class UCBFixed:
    def __init__(
        self,
        n_arms: int,
        n_bits: int,
        approx_mode: str = "lut",  # 'lut' or 'cordic'
        seed: int = 0,
    ):
        """
        Parameters
        ----------
        n_arms      : number of arms
        n_bits      : bit width for fixed-point representation (8, 12, 16)
        approx_mode : approximation method ('lut' or 'cordic')
        seed        : random seed
        """
        assert approx_mode in ("lut", "cordic"), "approx_mode must be 'lut' or 'cordic'"
        self.n_arms = n_arms
        self.n_bits = n_bits
        self.approx_mode = approx_mode
        self.rng = np.random.default_rng(seed)

        # Fixed-point state (quantized)
        self.mu_hat = np.zeros(n_arms, dtype=np.float64)
        self.n_pulls = np.zeros(n_arms, dtype=np.int64)
        self.t = 0

        # Select approximation functions
        if approx_mode == "lut":
            self._ln = approx_ln_lut
            self._sqrt = approx_sqrt_lut
        else:
            self._ln = approx_ln_cordic
            self._sqrt = approx_sqrt_cordic

    def reset(self):
        self.mu_hat[:] = 0.0
        self.n_pulls[:] = 0
        self.t = 0

    def select_arm(self) -> int:
        self.t += 1

        if self.t <= self.n_arms:
            return self.t - 1

        # Approximate UCB score computation
        ln_t = self._ln(np.array([float(self.t)]), self.n_bits)[0]
        bonus_input = 2.0 * ln_t / self.n_pulls  # shape: [n_arms]
        bonus = self._sqrt(bonus_input, self.n_bits)

        # Quantize mu_hat
        mu_q = quantize(self.mu_hat, self.n_bits, x_min=-2.0, x_max=2.0)

        scores = mu_q + bonus
        return int(np.argmax(scores))

    def update(self, arm: int, reward: float):
        self.n_pulls[arm] += 1
        self.mu_hat[arm] += (reward - self.mu_hat[arm]) / self.n_pulls[arm]
        # Quantize mu_hat after update
        self.mu_hat[arm] = quantize(
            np.array([self.mu_hat[arm]]), self.n_bits, x_min=-2.0, x_max=2.0
        )[0]


# ---------------------------------------------------------------------------
# Run simulation
# ---------------------------------------------------------------------------

def run_simulation(
    n_arms: int,
    true_means: np.ndarray,
    n_rounds: int,
    n_bits: int,
    approx_mode: str = "lut",
    seed: int = 0,
) -> dict:
    agent = UCBFixed(n_arms=n_arms, n_bits=n_bits, approx_mode=approx_mode, seed=seed)
    rng = np.random.default_rng(seed + 1)

    best_mean = np.max(true_means)

    chosen_arms = np.zeros(n_rounds, dtype=np.int64)
    rewards = np.zeros(n_rounds, dtype=np.float64)
    cumulative_regret = np.zeros(n_rounds, dtype=np.float64)

    for r in range(n_rounds):
        arm = agent.select_arm()
        reward = rng.normal(loc=true_means[arm], scale=1.0)
        agent.update(arm, reward)

        chosen_arms[r] = arm
        rewards[r] = reward
        instant_regret = best_mean - true_means[arm]
        cumulative_regret[r] = (cumulative_regret[r - 1] if r > 0 else 0.0) + instant_regret

    return {
        "chosen_arms": chosen_arms,
        "rewards": rewards,
        "cumulative_regret": cumulative_regret,
    }


# ---------------------------------------------------------------------------
# Quick smoke test
# ---------------------------------------------------------------------------
if __name__ == "__main__":
    N_ARMS = 64
    N_ROUNDS = 10_000
    SEED = 42

    rng = np.random.default_rng(SEED)
    true_means = rng.uniform(0.0, 1.0, size=N_ARMS)

    for mode in ("lut", "cordic"):
        for bits in (8, 12, 16):
            results = run_simulation(
                n_arms=N_ARMS,
                true_means=true_means,
                n_rounds=N_ROUNDS,
                n_bits=bits,
                approx_mode=mode,
                seed=SEED,
            )
            print(f"[{mode:6s} {bits:2d}bit]  regret={results['cumulative_regret'][-1]:.2f}")
