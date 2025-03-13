#!/bin/sh
#SBATCH --job-name="nequip lammps run"
#SBATCH --partition=gpu-a100
#SBATCH --time=00:25:00
#SBATCH --nodes=1
#SBATCH --ntasks=2
#SBATCH --cpus-per-task=2
#SBATCH --gpus-per-task=1
#SBATCH --mem-per-cpu=12G
#SBATCH --account=research-me-pe
#SBATCH --mail-type=FAIL
#SBATCH --output=mpi-out.%j
#SBATCH --error=mpi-err.%j

lmp_path=~/software/nequip_lammps/lammps_nequip/build

# ------------------------------ Load Modules ------------------------------ #
module use ~/software/spack/share/spack/lmod/linux-rhel8-x86_64/Core
module use ~/software/spack/share/spack/lmod/linux-rhel8-x86_64/openmpi/4.1.6-h2uag4k/Core

module load 2024r1
module load miniconda3
module load openmpi/4.1.6
module load py-torch/1.11.0
module load py-scipy/1.11.3
module load py-kiwisolver/1.4.5
module load py-sympy/1.11.1
module load py-mpmath/1.2.1
module load py-pillow/10.0.0
module load py-packaging/23.0
module load py-matplotlib/3.7.1
module load py-cycler/0.11.0
module load py-contourpy/1.0.7
module load py-fonttools/4.39.4
module load py-wandb/0.13.9
module load cmake/3.27.7
module load fftw/3.3.10_openmp_True

# ------------------------------ Export MPI & CUDA Settings ------------------------------ #
export CUDA_VISIBLE_DEVICES=$(echo $SLURM_JOB_GPUS | tr ',' '\n' | paste -sd ',')
export OMPI_MCA_pml=ob1
export OMPI_MCA_btl_smcuda_use_cuda_ipc=1
export OMPI_MCA_btl=self,vader,smcuda
export OMP_NUM_THREADS=$SLURM_CPUS_PER_TASK
export OMP_PROC_BIND=spread
export OMP_PLACES=threads

echo "SLURM assigned GPUs: $SLURM_JOB_GPUS"
echo "CUDA_VISIBLE_DEVICES: $CUDA_VISIBLE_DEVICES"

# ------------------------------ Activate Conda Environment ------------------------------ #
conda activate nequip_lammps

# ------------------------------ Copy to Temporary Directory ------------------------------ #
start1=$(date +%s)
echo "Starting to copy"
cp -r ${SLURM_SUBMIT_DIR} /tmp/${SLURM_JOBID}
cd /tmp/${SLURM_JOBID}
stop1=$(date +%s)
echo "Copying done, simulation starting, time elapsed is $(($stop1-$start1)) seconds"

# ------------------------------ Run LAMMPS Simulation ------------------------------ #
srun --mpi=pmix \
     --ntasks=${SLURM_NTASKS} \
     --gpus-per-task=${SLURM_GPUS_PER_TASK} \
     --cpus-per-task=${SLURM_CPUS_PER_TASK} \
     --gpu-bind=none \
     "$lmp_path/lmp" \
     -in ./nvt_simulation.in \
     -k on g ${SLURM_NTASKS} t ${SLURM_CPUS_PER_TASK} \
     -sf kk \
     -pk kokkos neigh full comm device cuda/aware on

# ------------------------------ Move Output Files ------------------------------ #
mkdir ${SLURM_JOB_PARTITION}_${SLURM_NTASKS}G_${SLURM_CPUS_PER_TASK}T
mv cuda.h mpi-* slurm* sys* volume.dat ${SLURM_JOB_PARTITION}_${SLURM_NTASKS}G_${SLURM_CPUS_PER_TASK}T

# ------------------------------ Copy Back and Cleanup ------------------------------ #
echo "Simulation done, copying back" 
rsync -a "$(pwd -P)/" ${SLURM_SUBMIT_DIR}
rm -rf /tmp/${SLURM_JOBID}
rm ${SLURM_SUBMIT_DIR}/slurm-${SLURM_JOBID}.out

seff ${SLURM_JOBID}

