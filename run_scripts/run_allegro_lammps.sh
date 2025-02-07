#!/bin/sh
#SBATCH --job-name="allegro_run_gpu"
#SBATCH --partition=gpu-a100-small
#SBATCH --time=00:05:00
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --gpus-per-task=1
#SBATCH --mem-per-cpu=8G
#SBATCH --account=research-me-pe
#SBATCH --mail-type=FAIL

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
run_no=1

# PLEASE CHANGE THIS PATH ACCORDINGLY
lmp_path=/scratch/dwee/software/allegro/lammps_allegro/build

# Get modules
module load 2023r1-gcc11
module load openmpi/4.1.4
module load miniconda3
module load cuda/11.6
module load cmake/3.24.3
module load fftw/3.3.10

# Add conda correctly to the paths, this will be needed in runscripts later
export LD_LIBRARY_PATH=$CONDA_PREFIX/lib:$LD_LIBRARY_PATH
export CUDNN_INCLUDE_DIR=$CONDA_PREFIX/include
export CUDNN_LIBRARY=$CONDA_PREFIX/lib

# Activate your environment
conda activate allegro_main 

# Copy to temporary directory
start1=$(date +%s)
echo "Starting to copy"
cp -r ${SLURM_SUBMIT_DIR} /tmp/${SLURM_JOBID}
cd /tmp/${SLURM_JOBID}
# rm slurm-${SLURM_JOBID}.out
stop1=$(date +%s)
echo "Copying done, simulation starting, time elapsed is $(($stop1-$start1)) seconds"

############################################################# TRAINING ############################################################
srun --output=training.out nequip-train ./input.yaml
echo "Training done"
####################################################################################################################################

############################################################ PRE-DEPLOY ############################################################
srun --output=pre-deploy.out nequip-deploy build --train-dir results/Si/run-Si/ si-deployed.pth
echo "Deployment done"
####################################################################################################################################

############################################################## DEPLOY ##############################################################
# run the simulation with ntasks*cpus-per-task cores
srun --output=deploy.out $lmp_path/lmp -in ./inputlammps # -sf kk -k on gpus 1 -pk kokkos newton on neigh full
####################################################################################################################################

# Delete old output files, comment out if you want to retain them
rm -rf output_files*
mkdir output_files_$run_no
mv results wandb si-deployed.pth si.rdf log.lammps training.out pre-deploy.out deploy.out output_files_$run_no

echo "Simulation done, copying back" 
# copy back
rm slurm-${SLURM_JOBID}.out
rsync -a "$(pwd -P)/" ${SLURM_SUBMIT_DIR}
rm -rf /tmp/${SLURM_JOBID}

seff ${SLURM_JOBID}
