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

MODULE_FILE="$HOME/software/spack/share/spack/lmod/linux-rhel8-x86_64/openmpi/4.1.6-h2uag4k/Core/py-torch/2.1.0.lua"

if [[ -f "$MODULE_FILE" ]]; then
    # Use sed to replace the OpenBLAS dependency line
    sed -i 's|depends_on("openblas/0.3.24")|depends_on("openblas/0.3.24_threads_openmp")|' "$MODULE_FILE"

    echo "Modification complete: OpenBLAS dependency updated in $MODULE_FILE"
else
    echo "Error: Module file not found at $MODULE_FILE"
    exit 1
fi
