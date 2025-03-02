#!/bin/sh
#SBATCH --job-name="allegro_run_10_r_multi_gpu"
#SBATCH --partition=gpu-a100-small
#SBATCH --time=01:00:00
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --gpus-per-task=1
#SBATCH --mem-per-cpu=30G
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
run_no=$1

lmp_path=/scratch/dwee/software/allegro_lammps/lammps_allegro/build

# Load Modules
module load 2024r1
module load miniconda3
module load cuda/11.6
module load cudnn/8.7.0.84-11.8
module load py-numpy/1.24.1
module load py-scipy/1.11.3
module load openmpi/4.1.6
module load cmake/3.27.7
module load fftw/3.3.10_openmp_True

echo "SLURM assigned GPUs: $SLURM_JOB_GPUS"
echo "CUDA_VISIBLE_DEVICES: $CUDA_VISIBLE_DEVICES"

# Activate your environment
conda activate allegro 

# Copy to temporary directory
start1=$(date +%s)
echo "Starting to copy" >> slurm-${SLURM_JOB_ID}.out 2>&1
cp -r ${SLURM_SUBMIT_DIR} /tmp/${SLURM_JOBID}
cd /tmp/${SLURM_JOBID}
stop1=$(date +%s) 
echo "Copying done, simulation starting, time elapsed is $(($stop1-$start1)) seconds" >> slurm-${SLURM_JOB_ID}.out 2>&1

############################################################# TRAINING ############################################################
srun --ntasks=1 --gpus=0 --output=training.out nequip-train ./input.yaml >> slurm-${SLURM_JOB_ID}.out 2>&1
echo "Training done" >> slurm-${SLURM_JOB_ID}.out 2>&1
####################################################################################################################################

############################################################ PRE-DEPLOY ############################################################
srun --ntasks=1 --gpus=0 --output=pre-deploy.out nequip-deploy build --train-dir results/H2O/run-H2O/ h2o-deployed.pth >> slurm-${SLURM_JOB_ID}.out 2>&1
echo "Deployment done" >> slurm-${SLURM_JOB_ID}.out 2>&1
####################################################################################################################################

# Delete old output files, comment out if you want to retain them
# rm -rf output_files*
mkdir output_files_$run_no
mv results wandb h2o.rdf log.lammps training.out pre-deploy.out *.dat output_files_$run_no

echo "Simulation done, copying back" >> slurm-${SLURM_JOB_ID}.out 2>&1
# copy back
rsync -a "$(pwd -P)/" ${SLURM_SUBMIT_DIR}
rm -rf /tmp/${SLURM_JOBID}
# rm ${SLURM_SUBMIT_DIR}/slurm-${SLURM_JOBID}.out

seff ${SLURM_JOBID}
sacct --format=JobID,JobName,AllocCPUs,ReqMem,MaxRSS,Elapsed,MaxVMSize,CPUTime,TotalCPU,State --jobs=${SLURM_JOB_ID} >> slurm-${SLURM_JOB_ID}.out
