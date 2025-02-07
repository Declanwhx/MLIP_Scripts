#!/bin/sh
# THIS SCRIPT INSTALLS THE ALLEGRO MLIP

# Change versions accordingly (Note: the developers of Allegro and NequIP have adopted the naming convention "main" and "develop" instead of the usualy "stable")
allegro_vers=main
nequip_vers=0.6.1

# Loading modules
module load 2023r1-gcc11
module load openmpi/4.1.4
module load miniconda3
module load cuda/11.6
module load cmake/3.24.3
module load fftw/3.3.10

# Conda environment initialization
conda remove -n allegro_$allegro_vers --all -y
conda create -n allegro_$allegro_vers python=3.10 -y
conda activate allegro_$allegro_vers

################################################################## ALLEGRO INSTALLATION ##################################################################
# Navigate out of script file first
cd ..

rm -rf allegro
mkdir allegro
cd allegro

# Install NumPY and Pytorch mainly, do not mess with these versions, 2.x does not work with NequIP/Allegro and likewise, Pytorch should ideally be 1.11.0
conda install numpy=1.26.4 scipy=1.11.3 -c conda-forge -y
conda install pytorch==1.11.0 torchvision==0.12.0 torchaudio==0.11.0 cudatoolkit=11.3 -c pytorch -y

# Install weights&biases, this is primarily for visual tracking of validation and training errors
pip install wandb

# Install NequIP
pip install nequip==$nequip_vers

# Install Allegro (Note: Allegro was built as an extension of NequIP)
rm -rf allegro
git clone https://github.com/mir-group/allegro.git
cd allegro
git checkout $allegro_vers
pip install .

# Navigate back to main folder
cd ..


