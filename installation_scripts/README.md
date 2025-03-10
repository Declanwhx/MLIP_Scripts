1. cleaner.sh has been attached so that you can easily clean you pip and conda caches by attaching the script to an alias in your .bashrc file
   ```bash
   vim ~/.bashrc
   ```
   and then add the following line to the file:
   ```bash
   alias cleanenv='/scratch/dwee/software/cleaner.sh'
   ```
3. installation_spack.sh allows for the installation of spack as well as a patch that ensures packages already available in the HPC are used and built upon.
