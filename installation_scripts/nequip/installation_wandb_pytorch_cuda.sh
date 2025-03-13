#!/bin/sh
#SBATCH --job-name="install_pytorch_wandb"
#SBATCH --partition=gpu-a100-small
#SBATCH --time=00:30:00
#SBATCH --ntasks=1
#SBATCH --gpus-per-task=1
#SBATCH --cpus-per-task=10
#SBATCH --mem-per-cpu=8G
#SBATCH --account=research-me-pe

spack install -j${SLURM_CPUS_PER_TASK} --reuse py-torch@1.11.0 +cuda ~gloo cuda_arch=80
spack install -j${SLURM_CPUS_PER_TASK}  --reuse py-wandb
