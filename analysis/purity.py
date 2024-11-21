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

folder_base = '../results/'

# Initialize container for results
belief_purity_results = {}

# Loop through algorithms to process data
for algorithm in algorithms:
    purity_data_list = []

    for seed in seeds:
        folder = f'{folder_base}/seed-{seed}/{algorithm}/'

        # Process Belief Purity data
        with open(folder + "belief-purity.csv", 'r') as file:
            lines = file.readlines()
        data_start_line = next(i for i, line in enumerate(lines) if line.strip().startswith('"x","y"'))
        purity_df = pd.read_csv(StringIO(''.join(lines[data_start_line:])))
        purity_data_list.append({
            'mean': purity_df['y'].values,
            '+sd': purity_df['y.1'].values,
            '-sd': purity_df['y.2'].values,
        })

    # Average the purity data across seeds
    belief_purity_results[algorithm] = {
        'mean': np.mean([p['mean'] for p in purity_data_list], axis=0),
        '+sd': np.mean([p['+sd'] for p in purity_data_list], axis=0),
        '-sd': np.mean([p['-sd'] for p in purity_data_list], axis=0),
    }

# Plot the averaged results in subplots
n_algorithms = len(algorithms)
n_cols = 3  # Number of columns for subplots
n_rows = (n_algorithms + n_cols - 1) // n_cols  # Calculate rows based on total algorithms

fig, axes = plt.subplots(n_rows, n_cols, figsize=(15, 5 * n_rows), sharex=True, sharey=True)
axes = axes.flatten()  # Flatten the axes array for easy indexing

# Plot Belief Purity for each algorithm
for i, (algorithm, data) in enumerate(belief_purity_results.items()):
    ax = axes[i]
    ticks = np.arange(len(data['mean']))
    ax.plot(ticks, data['mean'], label='Mean', linewidth=2, color='blue')
    ax.fill_between(
        ticks,
        data['+sd'],
        data['-sd'],
        alpha=0.2,
        color='blue',
        label='Mean ± SD'
    )
    ax.set_title(algorithm, fontsize=12)
    ax.set_xlabel("Ticks", fontsize=10)
    ax.set_ylabel("Belief Purity", fontsize=10)
    ax.legend(fontsize=8)
    ax.grid(True)

# Remove unused axes if algorithms < n_cols * n_rows
for j in range(i + 1, len(axes)):
    fig.delaxes(axes[j])

# Set the main title
fig.suptitle("Belief Purity Averaged Across Seeds (Subplots by Algorithm)", fontsize=16)
plt.tight_layout(rect=[0, 0, 1, 0.96])
plt.savefig(f'{folder_base}/single-algo-belief-purity.png')
plt.show()
