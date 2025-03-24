#!/bin/sh

# Change versions accordingly
NEQUIP_VERS=0.6.1
ALLEGRO_VERS=main
ALLEGRO_PAIR_VERS=main
LAMMPS_VERS=stable

SOURCE_NAME=allegro

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
conda install pytorch==1.11.0 -c pytorch -y
conda install mkl-include -y
pip install wandb
pip install nequip==${NEQUIP_VERS}

# ==================
# ?~_~T? Install Allegro
# ==================
git clone https://github.com/mir-group/allegro.git
cd allegro
git checkout ${ALLEGRO_VERS}
pip install .
cd ${SOFTWARE_PATH}

# ===================
# ?~_~T? Git Clone LAMMPS
# ===================
git clone https://github.com/lammps/lammps.git 
cd lammps
git checkout ${LAMMPS_VERS}
cd ${SOFTWARE_PATH}

# ========================================
# ?~_~T? Install Pair_Allegro and Patch LAMMPS
# ========================================
git clone https://github.com/mir-group/pair_allegro
cd pair_allegro
git checkout ${ALLEGRO_PAIR_VERS}
./patch_lammps.sh ${LAMMPS_PATH}
cd ${SOFTWARE_PATH}

# ================================
# ?~_~T? Install OCTP and Patch Lammps
# ================================
git clone https://github.com/omoultosEthTuDelft/OCTP.git
cp OCTP/*.h OCTP/*.cpp ${LAMMPS_PATH}/src
cd ${SOFTWARE_PATH}

rm -rf pair_allegro
rm -rf OCTP

