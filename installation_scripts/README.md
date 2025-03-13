### NOTES:
1. If you followed the instructions in the main folder, you should have the `installation_scripts` folder in your `software` directory, run the installation scripts from their respective folders. There is no need to move the script anywhere else, as it will automatically navigate out of its folders to install in the `software` directory, this is shown in the directory structure.

### Directory Structure:
```
	 software/
	 ├── installation_scripts/
	 │   ├── allegro/
	 │   │   └── installation_allegro_lammps.sh
	 │   ├── deepmd/
	 │   │   └── installation_deepmd_lammps.sh
	 │   ├── nequip/
	 │   │   └── installation_nequip_lammps.sh
         │   └── installation_spack.sh
	 ├── allegro
	 │   ├── allegro/
	 │   ├── pair_allegro/
	 │   └── lammps_allegro/
	 │       └── build/
	 │           └── lmp
	 ├── deepmd
	 │   ├── deepmd_source/
	 │   ├── deepmd_venv/
	 │   │	 └── bin/
	 │   │       └── build/
	 │   │           └── lmp
	 │   └── lammps/
	 ├── nequip
	 │   ├── nequip/
	 │   ├── pair_nequip/
	 │   └── lammps_nequip/
	 │       └── build/
	 │           └── lmp
	 └── spack
```
2. cleaner.sh has been attached so that you can easily clean you pip and conda caches by attaching the script to an alias in your .bashrc file
   ```bash
   vim ~/.bashrc
   ```
   and then add the following line to the file:
   ```bash
   alias cleanenv='~/software/cleaner.sh'
   ```
3. installation_spack.sh allows for the installation of Spack. The script will install the recommended version in the DelftsBlue documentation, Spack v0.21.3 .
   
5. If you already have Spack installed, please make sure that you have copied the configuration files provided by the DelftsBlue Admins, this ensures that for any packages you install with Spack, they build upon the modules already available 
   on DelftsBlue. If you haven't done so, you can do so with:
   ```bash
   cp /projects/unsupported/spack2024/etc/spack/*.yaml ${SPACK_ROOT}/etc/spack/
   ```
