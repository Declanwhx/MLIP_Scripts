#!/bin/sh
# May not need to send to GPU for installation but also not a bad idea?

#SBATCH --job-name="install_deepmd"
#SBATCH --partition=gpu-a100-small
#SBATCH --time=03:00:00
#SBATCH --ntasks=1
#SBATCH --gpus-per-task=1
#SBATCH --cpus-per-task=2
#SBATCH --mem-per-cpu=7G
#SBATCH --account=research-me-pe

# get modules
module load 2023r1-gcc11
module load miniconda3/4.12.0
# module load cuda/12.5

conda activate deepmd
pip install deepmd-kit[gpu,cu12,lmp,ipi]
conda deactivate







