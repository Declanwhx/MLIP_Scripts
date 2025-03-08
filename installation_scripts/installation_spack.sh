module load 2024r1 python
git clone -b v0.21.3 https://github.com/spack/spack

source ${HOME}/software/spack/share/spack/setup-env.sh

cp /projects/unsupported/spack2024/etc/spack/*.yaml ${SPACK_ROOT}/etc/spack/

spack compiler find
