#!/bin/sh
#SBATCH --job-name="install_deepmd"
#SBATCH --partition=gpu-a100-small
#SBATCH --time=01:00:00
#SBATCH --ntasks=1
#SBATCH --gpus-per-task=1
#SBATCH --cpus-per-task=8
#SBATCH --mem-per-cpu=5G
#SBATCH --account=research-me-pe

# THIS FILE INSTALLS BOTH THE DEEPMD MLIP AND BUILTIN LAMMPS

# NOTE: CLONE THE "INSTALLATION_SCRIPTS" FOLDER TO YOUR SOFTWARE FOLDER AND JUST RUN THE INSTALLATION SCRIPT, THERE IS NO NEED TO MOVE THE SCRIPT AROUND, IT WILL NAVIGATE OUT OF THIS FOLDER TO INSTALL IN THE SOFTWARE FOLDER.

DEEPMD_VERS="v3.0.2"

SOURCE_NAME=deepmd_lammps

DEEPMD_PATH=~/software/${SOURCE_NAME}/deepmd_venv/lib/python3.10/site-packages/deepmd
DEEPMD_SOURCE_PATH=~/software/${SOURCE_NAME}/deepmd_source
LAMMPS_PATH=~/software/${SOURCE_NAME}/lammps-stable_29Aug2024_update1

# ====================================================================
# 🔧 Load System Modules (CHANGE YOUR MODULE USE PATH ACCORDINGLY)
# ====================================================================
# THESE MODULE USE LINES ARE SO THAT SPACK PACKAGES TAKE PRECEDENCE OVER HPC ONES
module use ~/software/spack/share/spack/lmod/linux-rhel8-x86_64/Core
module use ~/software/spack/share/spack/lmod/linux-rhel8-x86_64/openmpi/4.1.6-h2uag4k/Core

module purge
module load DefaultModules
module load 2024r1
module load openmpi/4.1.6
module load py-torch/2.1.0
module load gcc/11.3.0
module load cmake

cd ../../
rm -rf ${SOURCE_NAME}
mkdir ${SOURCE_NAME} 
cd ${SOURCE_NAME}

# ===================================================================
# 🔍 Use Spack PyTorch (`v6gfbmm`) Only (HPC PyTorch is non DDP) 
# ===================================================================
export SPACK_PYTORCH_PATH=$(spack location -i /v6gfbmm)
export LD_LIBRARY_PATH=${SPACK_PYTORCH_PATH}/lib/python3.10/site-packages/torch/lib:$LD_LIBRARY_PATH
python -c "import torch; print(torch.__file__)"  # Check PyTorch path
TORCH_DIR=$(python -c "import torch; print(torch.__path__[0])")/share/cmake/Torch

# ========================
# 🔧 WGET & GIT CLONES
# ========================
wget https://github.com/lammps/lammps/archive/stable_29Aug2024_update1.tar.gz
tar xf stable_29Aug2024_update1.tar.gz
mkdir -p ${LAMMPS_PATH}/build/

git clone --branch ${DEEPMD_VERS} https://github.com/deepmodeling/deepmd-kit.git deepmd_source
mkdir -p ${DEEPMD_SOURCE_PATH}/source/build/

# ================================
# 🔧 Create Python Environment
# ================================
python -m venv --system-site-packages deepmd_venv
source deepmd_venv/bin/activate 

# ========================================
# 🔧 Install DeePMD-Kit's Python interface
# ========================================
cd ${DEEPMD_SOURCE_PATH}

DP_VARIANT=cuda \
CUDAToolkit_ROOT=${CUDA_PATH} \
DP_ENABLE_TENSORFLOW=0 \
DP_ENABLE_PYTORCH=1 \
PYTORCH_ROOT=${SPACK_PYTORCH_PATH} pip install .

#==========================================
# 🔧 Install DeePMD-Kit's C++ interface
# =========================================
cd ${DEEPMD_SOURCE_PATH}/source/build

DEEPMD_CPP_SETTINGS="-DENABLE_PYTORCH=TRUE"
DEEPMD_CPP_SETTINGS+=" -DCMAKE_PREFIX_PATH=${SPACK_PYTORCH_PATH}"
DEEPMD_CPP_SETTINGS+=" -DCMAKE_INSTALL_PREFIX=${DEEPMD_PATH}"
DEEPMD_CPP_SETTINGS+=" -DUSE_CUDA_TOOLKIT=TRUE"
DEEPMD_CPP_SETTINGS+=" -DCUDAToolkit_ROOT=${CUDA_PATH}"
DEEPMD_CPP_SETTINGS+=" -DCAFFE2_USE_CUDNN=TRUE" 
DEEPMD_CPP_SETTINGS+=" -DCMAKE_CXX_FLAGS=\"-D_GLIBCXX_USE_CXX11_ABI=1\""
DEEPMD_CPP_SETTINGS+=" -DTorch_DIR=${TORCH_DIR}"

CMAKE_PREP="cmake ${DEEPMD_CPP_SETTINGS} .."
$CMAKE_PREP

make -j${SLURM_CPUS_PER_TASK}
make install

# =====================================================================================================================#
# =================================================LAMMPS INSTALL======================================================#
# =====================================================================================================================#

make lammps

cd ${LAMMPS_PATH}/build
echo "include(${DEEPMD_SOURCE_PATH}/source/lmp/builtin.cmake)" >> ../cmake/CMakeLists.txt

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

ADD_PACKAGES=""
# Append all packages as -D flags to the cmake command
for PKG in "${ALL_PACKAGES[@]}"; do
  ADD_PACKAGES+=" -D PKG_${PKG}=yes"
done

DEEPMD_SETTINGS="-D LAMMPS_INSTALL_RPATH=ON"
DEEPMD_SETTINGS+=" -D BUILD_SHARED_LIBS=yes"
DEEPMD_SETTINGS+=" -D CMAKE_INSTALL_PREFIX=${DEEPMD_PATH}"
DEEPMD_SETTINGS+=" -D CMAKE_INSTALL_FULL_LIBDIR=${DEEPMD_PATH}/lib"

CMAKE_PREP="cmake ${ADD_PACKAGES} ${DEEPMD_SETTINGS} ../cmake"
$CMAKE_PREP

make -j${SLURM_CPUS_PER_TASK}
make install

deactivate
