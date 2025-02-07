#!/bin/sh
# THIS SCRIPT INSTALLS THE PAIR_ALLEGRO LAMMPS

# Change versions accordingly (Note: the developers of Allegro and NequIP have adopted the naming convention "main" and "develop" instead of the usualy "stable")
allegro_pair_vers=main

# Loading modules
module load 2023r1-gcc11
module load openmpi/4.1.4
module load miniconda3
module load cuda/11.6
module load cmake/3.24.3
module load fftw/3.3.10

# Conda environment initialization
conda remove -n lammps_allegro --all -y
conda create -n lammps_allegro python=3.10 -y
conda activate lammps_allegro

################################################################## LAMMPS INSTALLATION ##################################################################
# Location env variables
lammps_path=/scratch/dwee/software/allegro/lammps_allegro

# Git clone stable version of LAMMPS
rm -rf lammps_allegro
git clone https://github.com/lammps/lammps.git lammps_allegro
cd lammps_allegro
git checkout stable

# Navigate back to main folder
cd ..

# Git clone stable version of pair_allegro and patch
rm -rf pair_allegro
git clone https://github.com/mir-group/pair_allegro
cd pair_allegro
git checkout $allegro_pair_vers
./patch_lammps.sh $lammps_path

# Navigate back to LAMMPS folder
cd $lammps_path

# Installing Libtorch
rm -rf libtorch*
wget https://download.pytorch.org/libtorch/cu113/libtorch-cxx11-abi-shared-with-deps-1.11.0%2Bcu113.zip && unzip -q libtorch-cxx11-abi-shared-with-deps-1.11.0+cu113.zip

# Installing cudnn, version specifically for CUDA 11.x
conda install -c conda-forge cudnn=8.9.2.26 -y

# Exporting cuDNN paths
export LD_LIBRARY_PATH=$CONDA_PREFIX/lib:$LD_LIBRARY_PATH
export CUDNN_INCLUDE_DIR=$CONDA_PREFIX/include
export CUDNN_LIBRARY=$CONDA_PREFIX/lib

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
#  ASPHERE
#  BODY
#  CLASS2
#  DIPOLE
#  EXTRA-COMMAND
#  EXTRA-COMPUTE
#  EXTRA-DUMP
#  EXTRA-FIX
#  EXTRA-MOLECULE
#  EXTRA-PAIR
#  GRANULAR
#  INTERLAYER
  KOKKOS
#  KSPACE
#  MANYBODY
#  MOLECULE
#  MOLFILE
#  OPENMP
#  OPT
#  RIGID
#  SHOCK
#  TALLY
)

rm -rf build
mkdir build
cd build

ADD_PACKAGES=""
# Append all packages as -D flags to the cmake command
for PKG in "${ALL_PACKAGES[@]}"; do
  ADD_PACKAGES+=" -D PKG_${PKG}=yes"
done
# KOKKOS_SETTINGS="-D Kokkos_ARCH_SPR=ON"
KOKKOS_SETTINGS=" -D Kokkos_ENABLE_OPENMP=ON"
KOKKOS_SETTINGS+=" -D FFT_KOKKOS=FFTW3"
KOKKOS_SETTINGS+=" -D Kokkos_ARCH_AMPERE80=ON"
KOKKOS_SETTINGS+=" -D Kokkos_ENABLE_CUDA=ON"
KOKKOS_SETTINGS+=" -D FFT_KOKKOS=cuFFT"

# set path to libtorch install
ALLEGRO_SETTINGS="-DCMAKE_PREFIX_PATH=$lammps_path/libtorch"
ALLEGRO_SETTINGS+=" -DMKL_INCLUDE_DIR="$CONDA_PREFIX/include""

CMAKE_PREP="cmake $ADD_PACKAGES $KOKKOS_SETTINGS $ALLEGRO_SETTINGS ../cmake"
$CMAKE_PREP
CMAKE_BUILD="cmake --build . -j 6"
# CMAKE_BUILD="cmake --build . -j $(($SLURM_NTASKS * $SLURM_CPUS_PER_TASK))"
$CMAKE_BUILD

cd ..

conda deactivate

