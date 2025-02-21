#!/bin/sh
#SBATCH --job-name="install_deepmd"
#SBATCH --partition=gpu-a100
#SBATCH --time=03:00:00
#SBATCH --ntasks=1
#SBATCH --gpus-per-task=1
#SBATCH --cpus-per-task=6
#SBATCH --mem-per-cpu=8G
#SBATCH --account=research-me-pe
#!/bin/sh
# THIS FILE INSTALLS BOTH THE DEEPMD MLIP AND PLUGIN LAMMPS

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
deepmd_source_path=/scratch/dwee/software/deepmd/deepmd_source
deepmd_precompiled_c_path=/scratch/dwee/software/deepmd/libdeepmd_c
lammps_path=/scratch/dwee/software/deepmd/lammps-stable_29Aug2024_update1

# ======================
# 🔧 Load System Modules
# ======================
module load 2024r1
module load python/3.10.13
module load cuda/12.5
module load cudnn/8.7.0.84-11.8
module load nccl/2.19.3-1
module load py-tensorflow/2.16.1
module load openmpi/4.1.6
module load py-keras/3.3.3
module load cmake/3.27.7

# Set CUDA module paths
export CUDA_HOME=/beegfs/apps/generic/cuda-12.5-nuybbdj

# Set TensorFlow paths based on module-loaded location
export TENSORFLOW_HOME=/apps/arch/2024r1/extra/software/linux-rhel8-x86_64_v3/gcc-11.3.0/py-tensorflow-2.16.1-a7swnqgpllwxgtzpo3j5pdhegbklgay3

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

wget https://github.com/deepmodeling/deepmd-kit/releases/latest/download/libdeepmd_c.tar.gz
tar xzf libdeepmd_c.tar.gz

git clone https://github.com/deepmodeling/deepmd-kit.git deepmd_source
mkdir -p $deepmd_source_path/source/build/

# ============================
# 🔧 Create Python Environment
# ============================
python -m venv deepmd_venv
source deepmd_venv/bin/activate 

# =====================
# 🔧 TENSORFLOW TESTING
# =====================
echo "Checking TensorFlow GPU detection..."
python -c "import tensorflow as tf; print(tf.config.list_physical_devices('GPU'))"
python -c "import tensorflow as tf; print(tf.sysconfig.get_build_info())"

# ========================================
# 🔧 Install DeePMD-Kit's Python interface
# ========================================
cd $deepmd_source_path
pip install --no-cache-dir tensorflow-io-gcs-filesystem
DP_VARIANT=cuda CUDAToolkit_ROOT=${CUDA_HOME} TENSORFLOW_ROOT=${TENSORFLOW_HOME} pip install .

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

DEEPMD_CPP_SETTINGS="-DLAMMPS_SOURCE_ROOT=${lammps_path}"
DEEPMD_CPP_SETTINGS+=" -DDEEPMD_C_ROOT=${deepmd_precompiled_c_path}"
DEEPMD_CPP_SETTINGS+=" -DCMAKE_INSTALL_PREFIX=${deepmd_root}"

CMAKE_PREP="cmake $DEEPMD_CPP_SETTINGS .."
$CMAKE_PREP
CMAKE_BUILD="cmake --build . -j 6"
$CMAKE_BUILD

echo "Root directory: $(deepmd_root)"

# =====================================================================================================================#
# =================================================LAMMPS INSTALL======================================================#
# =====================================================================================================================#

cd $lammps_path/build/

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

DEEPMD_SETTINGS="-D PKG_PLUGIN=ON"
DEEPMD_SETTINGS+=" -D LAMMPS_INSTALL_RPATH=ON"
DEEPMD_SETTINGS+=" -D BUILD_SHARED_LIBS=yes"
DEEPMD_SETTINGS+=" -D CMAKE_INSTALL_PREFIX=${deepmd_root}"
DEEPMD_SETTINGS+=" -D CMAKE_INSTALL_LIBDIR=lib"
DEEPMD_SETTINGS+=" -D CMAKE_INSTALL_FULL_LIBDIR=${deepmd_root}/lib"

# Build LAMMPS
CMAKE_PREP="cmake $ADD_PACKAGES ../cmake"
$CMAKE_PREP
CMAKE_BUILD="cmake --build . -j 6"
$CMAKE_BUILD

deactivate
