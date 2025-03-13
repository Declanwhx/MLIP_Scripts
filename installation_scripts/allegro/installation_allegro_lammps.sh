#!/bin/sh
#SBATCH --job-name="install_allegro"
#SBATCH --partition=gpu-a100-small
#SBATCH --time=01:00:00
#SBATCH --ntasks=1
#SBATCH --gpus-per-task=1
#SBATCH --cpus-per-task=8
#SBATCH --mem-per-cpu=5G
#SBATCH --account=research-me-pe

# THIS FILE INSTALLS BOTH THE ALLEGRO MLIP AND PAIR_ALLEGRO LAMMPS

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
# │   ├── deepmd_source/
# │   ├── deepmd_venv/
# │   ├── lammps/
# │   └── bin/
# │       └── build/
# │           └── lmp
# └── nequip
#     ├── nequip/
#     ├── pair_nequip/
#     └── lammps_nequip/
#         └── build/
#             └── lmp

# Change versions accordingly
NEQUIP_VERS=0.6.1
ALLEGRO_VERS=main
ALLEGRO_PAIR_VERS=main
LAMMPS_VERS=stable

SOURCE_NAME=allegro_lammps

LAMMPS_PATH=~/software/${SOURCE_NAME}/lammps_allegro
SOURCE_PATH=~/software/${SOURCE_NAME}
LIBTORCH_CMAKE_PATH=~/software/spack/opt/spack/linux-rhel8-x86_64_v3/gcc-11.3.0/py-torch-1.11.0-ik5hgzdvps4pu6ydmud466bnjflqic6u/lib/python3.10/site-packages/torch

# ======================
# 🔧 Load System Modules
# ======================
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

# ===========================
# 🔧 Create Conda Environment 
# ===========================
conda remove -n ${SOURCE_NAME} --all -y
conda create -n ${SOURCE_NAME} python=3.10 -y
conda activate ${SOURCE_NAME}

cd ../../
rm -rf ${SOURCE_NAME}
mkdir ${SOURCE_NAME}
cd ${SOURCE_NAME}

# =======================
# 🔧 Install Dependencies
# =======================
conda install mkl-include -y
pip install nequip==${NEQUIP_VERS}

# ==================
# 🔧 Install Allegro
# ==================
git clone https://github.com/mir-group/allegro.git
cd allegro
git checkout ${ALLEGRO_VERS}
pip install .
cd ${SOURCE_PATH}

# ===================
# 🔧 Git Clone LAMMPS
# ===================
git clone https://github.com/lammps/lammps.git lammps_allegro
cd lammps_allegro
git checkout ${LAMMPS_VERS}
cd ${SOURCE_PATH}

# ========================================
# 🔧 Install Pair_Allegro and Patch LAMMPS
# ========================================
git clone https://github.com/mir-group/pair_allegro
cd pair_allegro
git checkout ${ALLEGRO_PAIR_VERS}
./patch_lammps.sh ${LAMMPS_PATH}
cd ${LAMMPS_PATH}

# ================================
# 🔧 Install OCTP and Patch Lammps
# ================================
git clone https://github.com/omoultosEthTuDelft/OCTP.git
cp OCTP/*.h OCTP/*.cpp ${LAMMPS_PATH}/src

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

# Kokkos Configuration
KOKKOS_SETTINGS="-D Kokkos_ENABLE_CUDA=ON"
KOKKOS_SETTINGS+=" -D Kokkos_ENABLE_OPENMP=ON"
KOKKOS_SETTINGS+=" -D Kokkos_ENABLE_SERIAL=ON"
KOKKOS_SETTINGS+=" -D Kokkos_ARCH_AMPERE80=ON"  
KOKKOS_SETTINGS+=" -D FFT_KOKKOS=cuFFT"

# Allegro Settings
ALLEGRO_SETTINGS="-DCMAKE_PREFIX_PATH=${LIBTORCH_CMAKE_PATH}"
ALLEGRO_SETTINGS+=" -DMKL_INCLUDE_DIR=${CONDA_PREFIX}/include"

# Build LAMMPS
CMAKE_PREP="cmake ${ADD_PACKAGES} ${KOKKOS_SETTINGS} ${ALLEGRO_SETTINGS} ../cmake"
$CMAKE_PREP
CMAKE_BUILD="cmake --build . -j ${SLURM_CPUS_PER_TASK}"
$CMAKE_BUILD

cd ..
conda deactivate
