#!/bin/sh
#SBATCH --job-name="deepmd train"
#SBATCH --partition=gpu-a100
#SBATCH --time=04:00:00
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=2
#SBATCH --gpus-per-task=2
#SBATCH --mem-per-cpu=35G
#SBATCH --account=research-me-pe
#SBATCH --mail-type=FAIL
#SBATCH --output=output.log
#SBATCH --error=error.log

# Expected directory structure:
#
# project/
# ├── input_files/
# │   ├── si.data
# │   └── Si_data
# │       └── /Si_data
# ├── input.yaml
# ├── inputlammps
# └── run_allegro.sh

# project -> e.g H2O
# inputlammps -> LAMMPS input settings file
# input.yaml -> Allegro input settings file
# si.data -> Initializing snapshot of system for MD
# Si_data -> Training and validation data for Allegro

# Change run no. accordingly
lmp_path=/scratch/dwee/software/deepmd_lammps/bin/build

# ======================
# 🔧 Load System Modules
# ======================
module purge
module load DefaultModules

module use /home/dwee/software/spack/share/spack/lmod/linux-rhel8-x86_64/Core
module use /home/dwee/software/spack/share/spack/lmod/linux-rhel8-x86_64/openmpi/4.1.6-h2uag4k/Core

module load 2024r1
module load python/3.10.13
module load openmpi/4.1.6
module load py-torch/2.1.0
# module load fftw/3.3.10_openmp_True
# module load gcc/11.3.0

# ============================
# 🔧 Set PyTorch Paths Explicitly
# ============================
# Ensure Spack uses the correct PyTorch version
export SPACK_PYTORCH_PATH=$(spack location -i /v6gfbmm)

# Set PyTorch library path
export PYTORCH_LIB_PATH=$(python -c "import torch; print(torch.__path__[0])")/lib
export LD_LIBRARY_PATH=$PYTORCH_LIB_PATH:$LD_LIBRARY_PATH

export TORCH_DISTRIBUTED_DEBUG=DETAIL

export GPUS_PER_NODE=${SLURM_GPUS_PER_TASK}
export OMP_NUM_THREADS=1
export DP_INTRA_OP_PARALLELISM_THREADS=2
export DP_INTER_OP_PARALLELISM_THREADS=1
export XLA_FLAGS=--xla_gpu_cuda_data_dir=/beegfs/apps/generic/cuda-11.6
export CUDA_VISIBLE_DEVICES=$(echo $SLURM_JOB_GPUS | tr ',' '\n' | paste -sd ',')
export CUDA_LAUNCH_BLOCKING=1

echo "CUDA_VISIBLE_DEVICES: $CUDA_VISIBLE_DEVICES"
echo "SLURM_JOB_GPUS: $SLURM_JOB_GPUS"

# Activate your environment
source /scratch/dwee/software/deepmd/deepmd_venv/bin/activate

############################################################# TRAINING ############################################################
torchrun --nproc_per_node=2 --no-python dp --pt train input_dpa1_test.json
echo "Training done"
####################################################################################################################################

deactivate

