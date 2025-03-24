#!/bin/sh

# Change versions accordingly
NEQUIP_VERS=0.6.1
NEQUIP_PAIR_VERS=main
LAMMPS_VERS=stable

SOURCE_NAME=nequip

LAMMPS_PATH=~/software/lammps
SOFTWARE_PATH=~/software/

# ===========================
# ?~_~T? Create Conda Environment 
# ===========================
conda remove -n ${SOURCE_NAME} --all -y
conda create -n ${SOURCE_NAME} python=3.10 -y
conda activate ${SOURCE_NAME}

cd ../../
rm -rf ${SOURCE_NAME}

# =======================
# ?~_~T? Install Dependencies
# =======================
conda install mkl-include -y
pip install nequip==${NEQUIP_VERS}

# ===================
# ?~_~T? Git Clone LAMMPS
# ===================
if [ ! -d "lammps" ]; then
  echo "Cloning LAMMPS..."
  git clone https://github.com/lammps/lammps.git
  cd ${LAMMPS_PATH}
  git checkout ${LAMMPS_VERS}
else
  echo "LAMMPS folder already exists. Skipping clone."
fi

cd ${SOFTWARE_PATH}

# =====================================
# ?~_~T? Clone Pair_Nequip and Patch LAMMPS
# =====================================
git clone https://github.com/mir-group/pair_nequip
cd pair_nequip
git checkout ${NEQUIP_PAIR_VERS}
./patch_lammps.sh ${LAMMPS_PATH}
cd ${SOFTWARE_PATH}

# ================================
# ?~_~T? Install OCTP and Patch Lammps
# ================================
git clone https://github.com/omoultosEthTuDelft/OCTP.git
cp OCTP/*.h OCTP/*.cpp ${LAMMPS_PATH}/src

rm -rf pair_nequip
rm -rf OCTP

