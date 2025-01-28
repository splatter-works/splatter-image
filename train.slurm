#!/bin/bash
# Node specification:
#SBATCH --partition=plgrid-gpu-a100    # Specify the partition
#SBATCH --nodes=1                      # Number of nodes
#SBATCH --ntasks-per-node=1            # Number of tasks per node
#SBATCH --mem=64G                      # Memory allocation
#SBATCH --gres=gpu:1                   # Number of GPUs  
#SBATCH --output=runs/output_%j.log    # Output and error log
#SBATCH --error=runs/output_%j.log     # Redirect error to the same file
#SBATCH --time=04:00:00                # Walltime
#SBATCH --job-name=baseline25k 	       # Name of job

#Load modules
module load CUDA/11.6.0 \
	GCCcore/11.2.0 \
	Ninja/1.10.2 \
	Miniconda3/23.3.1-0  

# Activate the conda environment
eval "$(conda shell.bash hook)"
conda activate splatter-image

# Go to the root of the git repo
GIT_ROOT=$(git rev-parse --show-toplevel)
cd "$GIT_ROOT"

# Run the training script
echo "Stage one training:\n"
python train_network.py +dataset=hydrants