### NOTES:
1. Given that DelftsBlue does not allow for git clones in compute nodes, we perform the git clones on the login node using the script installation_repos.sh
   ```bash
   ./installation_repos.sh
   ```
   Once this is done, one can then send the installation_allegro_lammps.sh script as an sbatch job to perform the building and installation:
   ```bash
   sbatch installation_allegro_lammps.sh
   ```
3. The installation script provided already includes **pre-set versions** that are known to work. You may try different versions if desired, but compatibility is not guaranteed.
4. If running this script on another HPC cluster, ensure that you replace the loaded modules based on the available software and dependencies on your system.

