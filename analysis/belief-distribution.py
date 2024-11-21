import matplotlib.pyplot as plt
import pandas as pd

# SET THESE BEFORE RUNNING
seed = ""
algorithm = ""
folder = f'../results/seed-{seed}/{algorithm}/'

# Define the range of tick values
ticks = range(10, 51, 10)  # 10, 20, 30, 40, 50

# Create a figure with subplots (2 rows, 3 columns)
fig, axes = plt.subplots(2, 3, figsize=(10, 5))  # 2 rows, 3 columns
axes = axes.flatten()  # Flatten the 2D array of axes to make it easier to index

# Loop through each file for the corresponding ticks
for i, tick in enumerate(ticks):
    file = folder + f"belief-{tick}.csv"
    df = pd.read_csv(file)  # Assuming tab-separated values

    # Plot on the corresponding axis
    axes[i].hist(df['belief'], bins=10, color='skyblue', edgecolor='black')
    axes[i].set_title(f'{tick} ticks')
    axes[i].set_xlabel('Belief Value')
    axes[i].set_ylabel('Frequency')
    axes[i].grid(False)

fig.suptitle(f'[{seed}] {algorithm}', fontsize=16)
plt.tight_layout()

# Show the plot
plt.savefig(folder + "belief-distribution.png")
