import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
from pathlib import Path

seeds = ["47822", "13523", "31238", "98424", "64001"]

# WHEN PICKING WHICH CHANGE THE FILE NAME
# a) single algorithm
algorithms = ["popularity-1", "chronological-1", "randomised-1", "belief-local-1", "belief-global-1"]

# OR b) weighted algorithms
# algorithms = ["belief-local-0.5-popularity-0.5", "belief-local-0.5-randomised-0.5", "belief-local-0.5-chronological-0.5",
#               "belief-local-0.5-belief-global-0.5", "belief-global-0.5-popularity-0.5", "belief-global-0.5-randomised-0.5",
#               "chronological-0.5-popularity-0.5", "chronological-0.5-randomised-0.5", "randomised-0.5-popularity-0.5", "all"]

ticks = [10, 20, 30, 40, 50]
folder_base = "../results/"

# Initialize results container
algorithm_results = {}

# Loop through algorithms
for algorithm in algorithms:
    tick_results = {tick: [] for tick in ticks}

    # Loop through seeds
    for seed in seeds:
        folder = Path(f"{folder_base}/seed-{seed}/{algorithm}/")

        # Loop through tick files
        for tick in ticks:
            file = folder / f"opinion-sd-{tick}.csv"

            # Read the data
            if file.exists():
                df = pd.read_csv(file)
                tick_results[tick].append(df['opinion-sd'].values)

    # Calculate mean and std for each tick
    algorithm_results[algorithm] = {
        tick: {
            "mean": np.mean(tick_results[tick], axis=0),
            "std": np.std(tick_results[tick], axis=0)
        }
        for tick in ticks
    }

# Calculate the number of rows needed for 3 columns
ncols = 3
nrows = int(np.ceil(len(algorithms) / ncols))

# Create the figure and axes
fig, axes = plt.subplots(nrows=nrows, ncols=ncols, figsize=(16, nrows * 4), sharex=True)
fig.suptitle("Opinion SD Across Seeds for Each Algorithm", fontsize=16, fontweight='bold')

# Flatten the axes for easier iteration (handles cases where nrows > 1)
axes = axes.flatten()

# Plot data for each algorithm
for i, (algorithm, results) in enumerate(algorithm_results.items()):
    means = [results[tick]["mean"].mean() for tick in ticks]  # Mean across turtles
    stds = [results[tick]["std"].mean() for tick in ticks]    # Mean std across turtles

    ax = axes[i]
    ax.plot(ticks, means, label=f"{algorithm} Mean", marker='o', color='blue')
    ax.fill_between(
        ticks,
        np.array(means) - np.array(stds),
        np.array(means) + np.array(stds),
        color='blue',
        alpha=0.2,
        label=f"{algorithm} Mean ± SD"
    )
    ax.set_title(f"{algorithm}", fontsize=14)
    ax.set_ylim(0, 1)
    ax.set_xlabel("Ticks", fontsize=12)
    ax.set_ylabel("Opinion SD", fontsize=12)
    ax.set_xticks(ticks)
    ax.legend()
    ax.grid(False)

# Remove any empty subplots (if len(algorithms) is not a multiple of 3)
for j in range(i + 1, len(axes)):  # `i` will now always be defined
    fig.delaxes(axes[j])

# Adjust layout
plt.tight_layout(rect=[0, 0, 1, 0.96])
plt.savefig(f'{folder_base}/weighted-algo-sd-opinion-sd.png')
plt.show()

