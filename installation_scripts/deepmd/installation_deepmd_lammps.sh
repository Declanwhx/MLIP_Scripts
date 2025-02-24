#!/bin/sh
#SBATCH --job-name="install_deepmd"
#SBATCH --partition=gpu-a100
#SBATCH --time=03:00:00
#SBATCH --ntasks=1
#SBATCH --gpus-per-task=1
#SBATCH --cpus-per-task=6
#SBATCH --mem-per-cpu=8G
#SBATCH --account=research-me-pe

# THIS FILE INSTALLS BOTH THE DEEPMD MLIP AND BUILTIN LAMMPS

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

deepmd_vers='v3.0.1'
deepmd_root=/scratch/dwee/software/deepmd
deepmd_source_path=/scratch/dwee/software/deepmd/deepmd_source
deepmd_precompiled_c_path=/scratch/dwee/software/deepmd/libdeepmd_c
lammps_path=/scratch/dwee/software/deepmd/lammps-stable_29Aug2024_update1

# ==================================================================
# 🔧 Load System Modules (ONLY WORKS WITH DELFTBLUE'S A100 NODES!!!)
# ==================================================================
module load 2024r1
module load cuda/12.5
module load cudnn/8.7.0.84-11.8
module load nccl/2.19.3-1

# WE DO THIS SO THAT THE LOADING OF TENSORFLOW TRIGGERS THE VERSION CHANGE OF THE DEPENDENCIES
# YOU COULD JUST LOAD THE CHANGED VERSIONS IF YOU WANT A MORE ELEGANT SCRIPT
module load py-tensorflow/2.16.1 
module unload py-tensorflow

module load openmpi/4.1.6
module load cmake/3.27.7
module load fftw/3.3.10_openmp_True

unset PYTHONPATH  # Ensure the module paths are not interfering

# Set CUDA module paths
export CUDA_HOME=/beegfs/apps/generic/cuda-12.5-nuybbdj

cd ../../
rm -rf deepmd
mkdir deepmd
cd deepmd

# ====================
# 🔧 WGET & GIT CLONES
# ====================
wget https://github.com/lammps/lammps/archive/stable_29Aug2024_update1.tar.gz
tar xf stable_29Aug2024_update1.tar.gz
mkdir -p $lammps_path/build/

git clone https://github.com/deepmodeling/deepmd-kit.git deepmd_source
mkdir -p $deepmd_source_path/source/build/

# ============================
# 🔧 Create Python Environment
# ============================
python -m venv deepmd_venv
source deepmd_venv/bin/activate 

# ========================================
# 🔧 Install DeePMD-Kit's Python interface
# ========================================
cd $deepmd_source_path

pip install --no-cache-dir --force-reinstall tensorflow==2.16.1
DP_VARIANT=cuda CUDAToolkit_ROOT=${CUDA_HOME} pip install .

export TF_LIB_DIR=$(python -c "import tensorflow as tf; print(tf.sysconfig.get_lib())")
export TF_INCLUDE_DIR=$(python -c "import tensorflow as tf; print(tf.sysconfig.get_include())")
export LD_LIBRARY_PATH=$TF_LIB_DIR:$LD_LIBRARY_PATH

# =====================
# 🔧 TENSORFLOW TESTING
# =====================
echo "Checking TensorFlow GPU detection..."
python -c "import tensorflow as tf; print(tf.config.list_physical_devices('GPU'))"
python -c "import tensorflow as tf; print(tf.sysconfig.get_build_info())"

# ==================
# 🔧 Install Horovod
# ==================
HOROVOD_GPU_OPERATIONS=NCCL \
HOROVOD_NCCL_HOME=$NCCL_HOME \
HOROVOD_WITHOUT_GLOO=1 \
HOROVOD_WITH_MPI=1 \
HOROVOD_WITH_TENSORFLOW=1 \
pip install horovod mpi4py

horovodrun --check-build

# =====================================
# 🔧 Install DeePMD-Kit's C++ interface
# =====================================
cd $deepmd_source_path/source/build

DEEPMD_CPP_SETTINGS="-DUSE_TF_PYTHON_LIBS=TRUE"
DEEPMD_CPP_SETTINGS+=" -DCMAKE_INSTALL_PREFIX=${deepmd_root}"
DEEPMD_CPP_SETTINGS+=" -DUSE_CUDA_TOOLKIT=TRUE"
DEEPMD_CPP_SETTINGS+=" -DCUDAToolkit_ROOT=${CUDA_HOME}"

CMAKE_PREP="cmake $DEEPMD_CPP_SETTINGS .."
$CMAKE_PREP

make -j $SLURM_CPUS_PER_TASK
make install


# =====================================================================================================================#
# =================================================LAMMPS INSTALL======================================================#
# =====================================================================================================================#

make lammps

cd $lammps_path/build
echo "include(${deepmd_source_path}/source/lmp/builtin.cmake)" >> ../cmake/CMakeLists.txt

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
DEEPMD_SETTINGS+=" -D CMAKE_INSTALL_PREFIX=${deepmd_root}"
DEEPMD_SETTINGS+=" -D CMAKE_INSTALL_FULL_LIBDIR=${deepmd_root}/lib"

# Build LAMMPS
CMAKE_PREP="cmake $ADD_PACKAGES $DEEPMD_SETTINGS ../cmake"
$CMAKE_PREP

make -j $SLURM_CPUS_PER_TASK
make install

deactivate
