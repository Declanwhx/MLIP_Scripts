#!/bin/sh
#SBATCH --job-name="install_nequip"
#SBATCH --partition=gpu-a100-small
#SBATCH --time=03:00:00
#SBATCH --ntasks=1
#SBATCH --gpus-per-task=1
#SBATCH --cpus-per-task=6
#SBATCH --mem-per-cpu=8G
#SBATCH --account=research-me-pe

# THIS FILE INSTALLS BOTH THE NEQUIP MLIP AND PAIR_NEQUIP LAMMPS

# NOTE: CLONE THE "INSTALLATION_SCRIPTS" FOLDER TO YOUR SOFTWARE FOLDER AND JUST RUN THE INSTALLATION SCRIPT, THERE IS NO NEED TO MOVE THE SCRIPT AROUND, IT WILL NAVIGATE OUT OF THIS FOLDER TO INSTALL IN THE SOFTWARE FOLDER.

# Expected directory structure:
#
# software/
# ├── installation_scripts/
# │   ├── allegro/
# │       └── installation_allegro_lammps.sh
# │   ├── deepmd/
# │       └── installation_deepmd.sh
# │   └── nequip/
# │       └── installation_nequip_lammps.sh
# ├── allegro
# │   ├── allegro/
# │   ├── pair_allegro/
# │   └── lammps_allegro/
# │       └── build/
# │           └── lmp
# ├── deepmd
# └── nequip
#     ├── nequip/
#     ├── pair_nequip/
#     └── lammps_nequip/
#         └── build/
#             └── lmp
 
# Change versions accordingly (Note: the developers of Allegro and NequIP have adopted the naming convention "main" and "develop" instead of the usualy "stable")
nequip_vers=0.6.1
nequip_pair_vers=main
lammps_vers=stable

# Location env variable. PLEASE CHANGE THIS TO YOUR INTENDED INSTALL LOCATION.
lammps_path=/scratch/dwee/software/nequip_lammps/lammps_nequip

# ===============================================================
# 🔧 Load System Modules (ONLY AVAILABLE ON DELFTBLUE A100 NODES)
# ===============================================================
module load 2024r1
module load miniconda3
module load openmpi/4.1.6
module load cuda/11.6
module load cudnn/8.7.0.84-11.8
module load py-numpy/1.24.1
module load py-scipy/1.11.3
module load cmake/3.27.7
module load fftw/3.3.10_openmp_True

# =========================
# 🔧 Set path env variables
# =========================
# Set CUDA module paths
export CUDA_HOME=/beegfs/apps/generic/cuda-11.6
export LD_LIBRARY_PATH=$CUDA_HOME/lib64:$LD_LIBRARY_PATH

# Add cuDNN from Conda
export CUDNN_HOME=/beegfs/apps/generic/cudnn-8.7.0.84-11.8
export PATH=$CUDNN_HOME/bin:$PATH
export LD_LIBRARY_PATH=$CUDNN_HOME/lib:$LD_LIBRARY_PATH
export CPATH=$CUDNN_HOME/include:$CPATH
export LIBRARY_PATH=$CUDNN_HOME/lib:$LIBRARY_PATH

# ===========================
# 🔧 Create Conda Environment
# ===========================
conda remove -n nequip--all -y
conda create -n nequip python=3.10 -y
conda activate nequip

cd ../../
rm -rf nequip_lammps
mkdir nequip_lammps
cd nequip_lammps

# =======================
# 🔧 Install Dependencies
# =======================
conda install pytorch==1.11.0 -c pytorch -y
conda install mkl-include -y
pip install wandb
pip install nequip==$nequip_vers

# =================
# 🔧 Clone LAMMPS
# =================
git clone https://github.com/lammps/lammps.git lammps_nequip
cd lammps_nequip
git checkout $lammps_vers
cd ..

# =====================================
# 🔧 Clone Pair_Nequip and Patch LAMMPS
# =====================================
git clone https://github.com/mir-group/pair_nequip
cd pair_nequip
git checkout $nequip_pair_vers
./patch_lammps.sh $lammps_path 
cd $lammps_path

# ==============================
# 🔧 Clone OCTP and Patch LAMMPS
# ==============================
git clone https://github.com/omoultosEthTuDelft/OCTP.git
cp OCTP/*.h OCTP/*.cpp $lammps_path/src

# ===================
# 🔧 Install Libtorch
# ===================
rm -rf libtorch*
wget https://download.pytorch.org/libtorch/cu113/libtorch-cxx11-abi-shared-with-deps-1.11.0%2Bcu113.zip && unzip -q libtorch-cxx11-abi-shared-with-deps-1.11.0+cu113.zip

# ==================================
# 🔧 Build LAMMPS with Kokkos + CUDA
# ==================================
# CMake script to enable all packages and configurations equivalent to the provided bash script
# PACKages not enabled
# 1) PYTHON -- useful (Required python-dev)
# 2) KIM -- maybe useful
# 3) LATBOLTZ -- maybe useful
# 4) VERONI -- maybe useful
# 5) GPU -- not useful
# 6) ADIOS -- useful (Required Double precision FFTW3)
# 7) VTK -- maybe useful (Would be hard to install)
# 8) PLUMED -- maybe useful (Required libgsl-dev: sudo apt-get install libgsl-dev)
# 9) SCAFACOS -- maybe useful (Required libgsl-dev: sudo apt-get install libgsl-dev)
# 10) RHEO -- maybe useful (Required libgsl-dev: sudo apt-get install libgsl-dev)
# 11) NETCDF -- maybe useful

# List of all packages to enable
ALL_PACKAGES=(
  ASPHERE
  BODY
  CLASS2
  DIPOLE
  EXTRA-COMMAND
  EXTRA-COMPUTE
  EXTRA-DUMP
  EXTRA-FIX
  EXTRA-MOLECULE
  EXTRA-PAIR
  GRANULAR
  INTERLAYER
  KSPACE
  MANYBODY
  MOLECULE
  MOLFILE
  OPENMP
  OPT
  RIGID
  SHOCK
  TALLY
)

mkdir build
cd build

ADD_PACKAGES=""
# Append all packages as -D flags to the cmake command
for PKG in "${ALL_PACKAGES[@]}"; do
  ADD_PACKAGES+=" -D PKG_${PKG}=yes"
done

# Allegro Settings
NEQUIP_SETTINGS="-DCMAKE_PREFIX_PATH=$lammps_path/libtorch"
NEQUIP_SETTINGS+=" -DMKL_INCLUDE_DIR="$CONDA_PREFIX/include""

# Build LAMMPS
CMAKE_PREP="cmake $ADD_PACKAGES $NEQUIP_SETTINGS ../cmake"
$CMAKE_PREP
CMAKE_BUILD="cmake --build . -j 6"
$CMAKE_BUILD

cd ..
conda deactivate




