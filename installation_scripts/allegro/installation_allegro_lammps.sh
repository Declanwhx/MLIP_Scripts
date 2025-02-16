#!/bin/sh
#SBATCH --job-name="install_allegro"
#SBATCH --partition=gpu-a100-small
#SBATCH --time=04:00:00
#SBATCH --ntasks=1
#SBATCH --gpus-per-task=1
#SBATCH --cpus-per-task=1
#SBATCH --mem-per-cpu=8G
#SBATCH --account=research-me-pe

# THIS SCRIPT INSTALLS BOTH ALLEGRO AND THE PAIR_ALLEGRO LAMMPS

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

# Change versions accordingly
allegro_vers=main
allegro_pair_vers=main
nequip_vers=0.6.1
lammps_vers=stable

# Location env variable
lammps_path=/scratch/dwee/software/allegro/lammps_allegro

# ======================
# 🔧 Load System Modules
# ======================
module load 2023r1-gcc11
module load miniconda3
module load openmpi/4.1.4
module load cuda/11.6
module load cmake/3.24.3
module load fftw/3.3.10

# ===========================
# 🔧 Create Conda Environment
# ===========================
conda remove -n allegro_$allegro_vers --all -y
conda create -n allegro_$allegro_vers python=3.10 -y
conda activate allegro_$allegro_vers 

cd ../../
rm -rf allegro
mkdir allegro
cd allegro

# =======================
# 🔧 Install Dependencies
# =======================
conda install numpy=1.26.4 scipy=1.11.3 -c conda-forge -y
conda install pytorch==1.11.0 torchvision==0.12.0 torchaudio==0.11.0 -c pytorch -y
conda install mkl-include -y
conda install -c conda-forge cudnn=8.9.2.26 -y
pip install wandb
pip install nequip==$nequip_vers

# ==================
# 🔧 Install Allegro
# ==================
git clone https://github.com/mir-group/allegro.git
cd allegro
git checkout $allegro_vers
pip install .
cd ..

# =================
# 🔧 Install LAMMPS
# =================
git clone https://github.com/lammps/lammps.git lammps_allegro
cd lammps_allegro
git checkout $lammps_vers
cd ..

# ========================================
# 🔧 Install Pair_Allegro and Patch LAMMPS
# ========================================
git clone https://github.com/mir-group/pair_allegro
cd pair_allegro
git checkout $allegro_pair_vers
./patch_lammps.sh $lammps_path
cd $lammps_path

# ===============
# 🔧 Install OCTP
# ===============
git clone https://github.com/omoultosEthTuDelft/OCTP.git
cp OCTP/*.h OCTP/*.cpp $lammps_path/src

# ===================
# 🔧 Install Libtorch
# ===================
wget https://download.pytorch.org/libtorch/cu113/libtorch-cxx11-abi-shared-with-deps-1.11.0%2Bcu113.zip
unzip -q libtorch-cxx11-abi-shared-with-deps-1.11.0+cu113.zip

# ===================================================================
# 🔧 Remove Conflicting Conda Libraries in cuDNN & Module Loaded CUDA 
# ===================================================================
rm -rf $CONDA_PREFIX/lib/libgomp*
rm -rf $CONDA_PREFIX/lib/libcuda*
rm -rf $CONDA_PREFIX/lib/libcudart*
rm -rf $CONDA_PREFIX/lib/libcufft*
rm -rf $CONDA_PREFIX/lib/libcurand*
rm -rf $CONDA_PREFIX/lib/libcublas*
rm -rf $CONDA_PREFIX/lib/libnvrtc*
rm -rf $CONDA_PREFIX/lib/libcusolver*
rm -rf $CONDA_PREFIX/lib/libcusparse*
rm -rf $CONDA_PREFIX/lib/libnvToolsExt*

# Set CUDA module paths
export CUDA_HOME=/beegfs/apps/generic/cuda-11.6
export LD_LIBRARY_PATH=$CUDA_HOME/lib64:$LD_LIBRARY_PATH

# Add cuDNN from Conda
export LD_LIBRARY_PATH=$CONDA_PREFIX/lib:$LD_LIBRARY_PATH
export CUDNN_INCLUDE_DIR=$CONDA_PREFIX/include
export CUDNN_LIBRARY=$CONDA_PREFIX/lib/libcudnn.so

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
  KOKKOS
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

rm -rf build
mkdir build
cd build

ADD_PACKAGES=""
# Append all packages as -D flags to the cmake command
for PKG in "${ALL_PACKAGES[@]}"; do
  ADD_PACKAGES+=" -D PKG_${PKG}=yes"
done

# Kokkos Configuration (NOTE: KOKKOS IS CASE-SENSITIVE!!!)
KOKKOS_SETTINGS="-D Kokkos_ENABLE_CUDA=ON"
KOKKOS_SETTINGS+=" -D Kokkos_ENABLE_OPENMP=ON"
KOKKOS_SETTINGS+=" -D Kokkos_ARCH_AMPERE80=ON"  
KOKKOS_SETTINGS+=" -D FFT_KOKKOS=cuFFT"

# Ensure cuBLAS and cuDNN are properly linked
COMPILER_SETTINGS="-D CMAKE_INCLUDE_PATH=$CONDA_PREFIX/include;/beegfs/apps/generic/cuda-11.6/include"
COMPILER_SETTINGS+=" -D CMAKE_LIBRARY_PATH=$CONDA_PREFIX/lib;/beegfs/apps/generic/cuda-11.6/targets/x86_64-linux/lib"
COMPILER_SETTINGS+=" -D CUDA_CUBLAS_LIBRARIES='/beegfs/apps/generic/cuda-11.6/targets/x86_64-linux/lib/libcublas.so;/beegfs/apps/generic/cuda-11.6/targets/x86_64-linux/lib/libcublasLt.so'"
COMPILER_SETTINGS+=" -D CUDA_CUDNN_LIBRARIES='$CONDA_PREFIX/lib/libcudnn.so'"

# Allegro Settings
ALLEGRO_SETTINGS="-DCMAKE_PREFIX_PATH=$lammps_path/libtorch"
ALLEGRO_SETTINGS+=" -DMKL_INCLUDE_DIR=$CONDA_PREFIX/include"

# Build LAMMPS
CMAKE_PREP="cmake $ADD_PACKAGES $COMPILER_SETTINGS $KOKKOS_SETTINGS $ALLEGRO_SETTINGS ../cmake"
$CMAKE_PREP
CMAKE_BUILD="cmake --build . -j 8"
$CMAKE_BUILD

cd ..
conda deactivate
