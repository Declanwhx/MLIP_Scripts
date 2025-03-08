#!/bin/sh
#SBATCH --job-name="install_pytorch"
#SBATCH --partition=gpu-a100-small
#SBATCH --time=01:00:00
#SBATCH --ntasks=1
#SBATCH --gpus-per-task=1
#SBATCH --cpus-per-task=10
#SBATCH --mem-per-cpu=5G
#SBATCH --account=research-me-pe

spack install -j10 --reuse py-torch +cuda +distributed cuda_arch=80
