import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
from io import StringIO

seeds = ["47822", "13523", "31238", "98424", "64001"]
algorithms = ["popularity-1", "chronological-1", "randomised-1", "belief-local-1", "belief-global-1"]

# Determine the number of rows and columns for the grid
n_algorithms = len(algorithms)
n_cols = 3  
n_rows = (n_algorithms + n_cols - 1) // n_cols  

# Create a figure and subplots (a grid of subplots)
fig, axes = plt.subplots(n_rows, n_cols, figsize=(12, 6 * n_rows))

# Flatten the axes array if it's a 2D grid
axes = axes.flatten()

# Loop through each algorithm and its corresponding axis
for ax, algorithm in zip(axes, algorithms):
    gec_runs = []

    # Read and process the GEC data for each algorithm
    for seed in seeds:
        folder = f'../results/seed-{seed}/{algorithm}/'
        with open(folder + "gec.csv", 'r') as file:
            lines = file.readlines()

        # Find where the "default" pen data starts
        data_start_line = None
        for i, line in enumerate(lines):
            if line.strip().startswith('"x","y"'):
                data_start_line = i
                break

        gec_data = lines[data_start_line:]

        gec_df = pd.read_csv(StringIO(''.join(gec_data)))
        gec_runs.append(gec_df["y"].values)

    # Convert to NumPy array for easier calculations
    gec_data = np.array(gec_runs)

    # Calculate mean and standard deviation
    gec_std = np.std(gec_data, axis=0)
    gec_mean = np.mean(gec_data, axis=0)

    # Plot on the corresponding axis
    ax.plot(range(0, 51), gec_mean, label="Average GEC", color="blue", linewidth=2)
    ax.fill_between(
        range(0, 51),
        gec_mean - gec_std,
        gec_mean + gec_std,
        color="blue",
        alpha=0.2,
        label="Standard Deviation"
    )
    ax.set_title(f"{algorithm}", fontsize=15)
    ax.set_xlabel("Ticks", fontsize=12)
    ax.set_ylabel("GEC", fontsize=12)
    ax.grid(True)
    ax.legend(fontsize=12)

# Adjust layout to prevent overlap
plt.suptitle("Global Echo Chamber (GEC) across algorithms and seeds", fontsize=18)
plt.tight_layout(rect=[0, 0, 1, 0.96])

# Save the figure with all subplots
plt.savefig('../results/single-algo-gec.png')

# Show the plot
plt.show()
