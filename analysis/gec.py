import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
from io import StringIO

seeds = ["47822", "13523", "31238", "98424", "64001"]

# WHEN PICKING WHICH CHANGE THE FILE NAME
# a) single algorithm
algorithms = ["popularity-1", "chronological-1", "randomised-1", "belief-local-1", "belief-global-1"]

# OR b) weighted algorithms
# algorithms = ["belief-local-0.5-popularity-0.5", "belief-local-0.5-randomised-0.5", "belief-local-0.5-chronological-0.5",
#               "belief-local-0.5-belief-global-0.5", "belief-global-0.5-popularity-0.5", "belief-global-0.5-randomised-0.5",
#               "chronological-0.5-popularity-0.5", "chronological-0.5-randomised-0.5", "randomised-0.5-popularity-0.5", "all"]

folder_base = "../results/"
# Determine the number of rows and columns for the grid
n_algorithms = len(algorithms)
n_cols = 3  # Number of columns in the grid
n_rows = (n_algorithms + n_cols - 1) // n_cols  # Calculate the required number of rows

# Create a figure and subplots (a grid of subplots)
fig, axes = plt.subplots(n_rows, n_cols, figsize=(12, 6 * n_rows))

# Flatten the axes array if it's a 2D grid
axes = axes.flatten()

# Initialize lists to store mean and std values for determining global y-limits
all_gec_means = []
all_gec_std = []

# Loop through each algorithm and its corresponding axis
for ax, algorithm in zip(axes, algorithms):
    gec_runs = []

    # Read and process the GEC data for each algorithm
    for seed in seeds:
        folder = f'{folder_base}/seed-{seed}/{algorithm}/'
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

    # Append the mean and std values to the lists for determining global y-limits
    all_gec_means.append(gec_mean)
    all_gec_std.append(gec_std)

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

# Convert lists to numpy arrays for easier manipulation
all_gec_means = np.array(all_gec_means)
all_gec_std = np.array(all_gec_std)

# Calculate global y-limits
y_min = 0
y_max = np.max(all_gec_means + all_gec_std)  # Max of gec_mean + gec_std

# Set the same y-limits for all subplots
for ax in axes:
    ax.set_ylim(y_min, y_max)  # Set y-axis limits based on calculated values

# Remove any unused subplots (axes that don't correspond to an algorithm)
for i in range(n_algorithms, len(axes)):
    fig.delaxes(axes[i])

# Adjust layout to prevent overlap
plt.suptitle("Global Echo Chamber (GEC) across algorithms and seeds", fontsize=18)
plt.tight_layout(rect=[0, 0, 1, 0.96])

# Save the figure with all subplots
plt.savefig(f'{folder_base}/single-algo-gec.png')

# Show the plot
plt.show()
