module load 2023r1-gcc11
module load miniconda3
module load py-pip

conda clean --all -y
pip cache purge
rm -rf ~/.cache/pip/http-v2

module unload 2023r1-gcc11
module unload miniconda3
module unload py-pip