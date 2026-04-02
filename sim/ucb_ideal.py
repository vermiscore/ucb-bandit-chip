"""
ucb_ideal.py
------------
Ideal UCB1 bandit simulator (float64, no approximation).
Used as the golden reference for comparing fixed-point approximations.

UCB score: mu_hat[i] + sqrt(2 * ln(t) / n[i])
"""

import numpy as np


class UCBIdeal:
    def __init__(self, n_arms: int, seed: int = 0):
        """
        Parameters
        ----------
        n_arms : int
            Number of arms (e.g. 64 for 64-channel wireless selection)
        seed : int
            Random seed for reproducibility
        """
        self.n_arms = n_arms
        self.rng = np.random.default_rng(seed)

        # Internal state
        self.mu_hat = np.zeros(n_arms, dtype=np.float64)  # estimated mean reward
        self.n_pulls = np.zeros(n_arms, dtype=np.int64)   # pull count per arm
        self.t = 0                                          # total rounds

    def reset(self):
        self.mu_hat[:] = 0.0
        self.n_pulls[:] = 0
        self.t = 0

    def select_arm(self) -> int:
        self.t += 1

        # Initialization: pull each arm once
        if self.t <= self.n_arms:
            return self.t - 1

        # UCB score
        scores = self.mu_hat + np.sqrt(2.0 * np.log(self.t) / self.n_pulls)
        return int(np.argmax(scores))

    def update(self, arm: int, reward: float):
        self.n_pulls[arm] += 1
        # Incremental mean update
        self.mu_hat[arm] += (reward - self.mu_hat[arm]) / self.n_pulls[arm]


def run_simulation(
    n_arms: int,
    true_means: np.ndarray,
    n_rounds: int,
    seed: int = 0,
) -> dict:
    """
    Run ideal UCB1 and return results.

    Parameters
    ----------
    n_arms      : number of arms
    true_means  : true mean reward for each arm (shape: [n_arms])
    n_rounds    : total number of rounds
    seed        : random seed

    Returns
    -------
    dict with keys:
        'chosen_arms'       : array of selected arm indices
        'rewards'           : array of observed rewards
        'cumulative_regret' : cumulative regret over rounds
    """
    assert len(true_means) == n_arms

    agent = UCBIdeal(n_arms=n_arms, seed=seed)
    rng = np.random.default_rng(seed + 1)

    best_mean = np.max(true_means)

    chosen_arms = np.zeros(n_rounds, dtype=np.int64)
    rewards = np.zeros(n_rounds, dtype=np.float64)
    cumulative_regret = np.zeros(n_rounds, dtype=np.float64)

    for r in range(n_rounds):
        arm = agent.select_arm()
        reward = rng.normal(loc=true_means[arm], scale=1.0)  # Gaussian reward
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
    best_arm = int(np.argmax(true_means))
    print(f"Best arm: {best_arm}  (mean={true_means[best_arm]:.4f})")

    results = run_simulation(
        n_arms=N_ARMS,
        true_means=true_means,
        n_rounds=N_ROUNDS,
        seed=SEED,
    )

    final_regret = results["cumulative_regret"][-1]
    print(f"Cumulative regret after {N_ROUNDS} rounds: {final_regret:.2f}")
    print(f"Most selected arm: {np.bincount(results['chosen_arms']).argmax()}")
