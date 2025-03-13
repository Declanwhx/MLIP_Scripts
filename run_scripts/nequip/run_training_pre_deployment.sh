#!/bin/sh
#SBATCH --job-name="nequip train"
#SBATCH --partition=gpu-a100
#SBATCH --time=04:00:00
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=6
#SBATCH --gpus-per-task=1
#SBATCH --mem-per-cpu=25G
#SBATCH --account=research-me-pe
#SBATCH --mail-type=FAIL

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
module load py-packaging/23.1
module load py-matplotlib/3.7.1
module load py-cycler/0.11.0
module load py-contourpy/1.0.7
module load py-fonttools/4.39.4
module load py-wandb/0.13.9
module load cmake/3.27.7
module load fftw/3.3.10_openmp_True

# ------------------------------ Activate Environment ------------------------------ #
conda activate nequip_lammps

# ------------------------------ Copy to Temporary Directory ------------------------------ #
start1=$(date +%s)
echo "📂 Starting to copy files..."
cp -r ${SLURM_SUBMIT_DIR} /tmp/${SLURM_JOBID}
cd /tmp/${SLURM_JOBID}
stop1=$(date +%s)
echo "✅ Copying complete. Time elapsed: $(($stop1 - $start1)) seconds."

# ------------------------------ TRAINING ------------------------------ #
echo "🚀 Starting training..."
srun --output=training.out nequip-train ./input.yaml
echo "✅ Training complete."

# ------------------------------ EVALUATION (Optional) ------------------------------ #
# echo "🔍 Starting evaluation..."
# srun nequip-evaluate --train-dir results/H2O/run-H2O --batch-size 1 --output ./predicted.extxyz
# echo "✅ Evaluation complete."

# ------------------------------ PRE-DEPLOYMENT ------------------------------ #
echo "⚙️  Starting model deployment..."
srun --output=pre-deploy.out nequip-deploy build --train-dir results/H2O/run-H2O/ h2o-deployed.pth
echo "✅ Deployment complete."

# ------------------------------ Organize Output Files ------------------------------ #
echo "📁 Organizing output files..."
rm -rf output_files*
mkdir output_files
mv results wandb h2o.rdf log.lammps training.out pre-deploy.out *.dat output_files

# ------------------------------ Copy Back and Clean Up ------------------------------ #
echo "🔄 Copying results back..."
rsync -a "$(pwd -P)/" ${SLURM_SUBMIT_DIR}
rm -rf /tmp/${SLURM_JOBID}

# Uncomment if you want to remove the SLURM output file
# rm ${SLURM_SUBMIT_DIR}/slurm-${SLURM_JOBID}.out

seff ${SLURM_JOBID}

