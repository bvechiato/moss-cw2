import matplotlib.pyplot as plt
import pandas as pd
import numpy as np

seeds = ["47822", "13523", "31238", "98424", "64001"]

# WHEN PICKING WHICH CHANGE THE FILE NAME
# single algorithm
algorithms = ["popularity-1", "chronological-1", "randomised-1", "belief-local-1", "belief-global-1"]

# weighted algorithms
# algorithms = ["belief-local-0.5-popularity-0.5", "belief-local-0.5-randomised-0.5", "belief-local-0.5-chronological-0.5",
#               "belief-local-0.5-belief-global-0.5", "belief-global-0.5-popularity-0.5", "belief-global-0.5-randomised-0.5",
#               "chronological-0.5-popularity-0.5", "chronological-0.5-randomised-0.5", "randomised-0.5-popularity-0.5", "all"]

folder_base = f"../results/"
ticks = range(10, 51, 10)  # 10, 20, 30, 40, 50

# Create a figure and subplots for each algorithm (one row per algorithm)
n_algorithms = len(algorithms)
n_ticks = len(ticks)
fig, axes = plt.subplots(n_algorithms, n_ticks,
                         figsize=(15, 5 * n_algorithms))  # 1 row per algorithm, multiple columns for ticks
axes = axes.flatten()  # Flatten the axes to make indexing easier

# Initialize tick index
tick_idx = 0

# Loop through each algorithm
for algorithm in algorithms:
    # Loop through each tick
    for i, tick in enumerate(ticks):
        all_beliefs = []

        # Loop through seeds and load the data for the current algorithm and tick
        for seed in seeds:
            folder = f'{folder_base}/seed-{seed}/{algorithm}/'
            file = folder + f"belief-{tick}.csv"
            df = pd.read_csv(file)

            # Collect belief data
            all_beliefs.append(df['belief'].values)

        # Convert to a NumPy array for easier manipulation
        all_beliefs = np.array(all_beliefs)

        # Calculate the average belief distribution across seeds
        avg_beliefs = np.mean(all_beliefs, axis=0)

        # Plot on the corresponding subplot (for the current algorithm and tick)
        ax = axes[tick_idx]
        ax.hist(avg_beliefs, bins=10, color='skyblue', edgecolor='black')
        ax.set_title(f'{tick} ticks', fontsize=12)
        ax.set_xlabel('Belief Value', fontsize=10)
        ax.set_ylabel('Frequency', fontsize=10)
        ax.grid(False)

        # Increment the tick index
        tick_idx += 1

    # After finishing all ticks for this algorithm, add a title for the algorithm itself
    # We calculate the position of the algorithm title in the middle of the row of subplots
    start_idx = tick_idx - n_ticks  # The starting index of this algorithm's subplots
    end_idx = tick_idx - 1  # The last subplot index for this algorithm
    algorithm_title_pos = (start_idx + end_idx) / 2  # The middle subplot index for title placement
    axes[int(algorithm_title_pos)].set_title(f'{algorithm}', fontsize=14, fontweight='bold', loc='center')

# Add a super title and adjust layout
fig.suptitle(f'Belief Distributions Across Algorithms and Seeds', fontsize=16)
plt.tight_layout(rect=[0, 0, 1, 0.96])  # To make room for the super title

# Save the figure
plt.savefig(f'{folder_base}/single-algo-belief_dist.png')

# Show the plot
plt.show()
