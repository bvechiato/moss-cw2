import pandas as pd
import matplotlib.pyplot as plt
from io import StringIO

# SET THESE BEFORE RUNNING
seed = ""
algorithm = ""

folder = f'../results/{seed}/{algorithm}/'

# Read and process the GEC data
with open(folder + "gec.csv", 'r') as file:
    lines = file.readlines()

# Locate the start of the data for the pens
data_start_line = None
for i, line in enumerate(lines):
    if line.strip().startswith('"x","y"'):
        data_start_line = i
        break

gec_data = lines[data_start_line:]
gec_df = pd.read_csv(StringIO(''.join(gec_data)))

# Read and process belief purity data
with open(folder + "belief-purity.csv", 'r') as file:
    lines = file.readlines()

data_start_line = None
for i, line in enumerate(lines):
    if line.strip().startswith('"x","y"'):
        data_start_line = i
        break

purity_data = lines[data_start_line:]
purity_df = pd.read_csv(StringIO(''.join(purity_data)))

# Create subplots
fig, axes = plt.subplots(2, 1, figsize=(12, 10), sharex=False)
fig.suptitle(f'[{seed}] {algorithm}', fontsize=16, fontweight='bold')

# Subplot 1: Global Echo Chamber (GEC)
axes[0].plot(gec_df['x'], gec_df['y'], color='blue')
axes[0].set_title('Global Echo Chamber Evaluation @ 50 Ticks', fontsize=14)
axes[0].set_xlabel('Ticks')
axes[0].set_ylabel('GEC Value')
axes[0].grid(True)
axes[0].legend()

# Subplot 2: Belief Purity
axes[1].plot(purity_df['x'], purity_df['y'], label='Average', color='blue')
axes[1].plot(purity_df['x.1'], purity_df['y.1'], label='+SD', color='green')
axes[1].plot(purity_df['x.2'], purity_df['y.2'], label='-SD', color='red')
axes[1].set_title('Belief Purity @ 50 Ticks', fontsize=14)
axes[1].set_xlabel('Ticks')
axes[1].set_ylabel('Belief Purity')
axes[1].legend()
axes[1].grid(True)

# Adjust layout and save the figure
plt.tight_layout(rect=[0, 0, 1, 0.96])  # Adjust for suptitle
plt.savefig(folder + 'purity-gec.png')
plt.show()
