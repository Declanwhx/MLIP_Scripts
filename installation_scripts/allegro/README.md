### NOTES:

1. Clone the `installation_scripts` folder to your `software` directory and run the installation script directly. There is no need to move the script around, as it will automatically navigate out of its folder to install in the `software` directory.

### Directory Structure:

```
	 software/
	 ├── installation_scripts/
	 │   ├── allegro/
	 │       └── installation_allegro_lammps.sh
	 │   ├── deepmd/
	 │       └── installation_deepmd_lammps.sh
	 │   └── nequip/
	 │       └── installation_nequip_lammps.sh
	 ├── allegro
	 │   ├── allegro/
	 │   ├── pair_allegro/
	 │   └── lammps_allegro/
	 │       └── build/
	 │           └── lmp
	 ├── deepmd
	 │   ├── deepmd_source/
	 │   ├── deepmd_venv/
	 │   	 └── bin/
	 │           └── build/
	 │               └── lmp
	 │   └── lammps/
	 └── nequip
	     ├── nequip/
	     ├── pair_nequip/
	     └── lammps_nequip/
	         └── build/
	             └── lmp
```

2. The installation script provided already includes **pre-set versions** that are known to work. You may try different versions if desired, but compatibility is not guaranteed.

3. If running this script on another HPC cluster, ensure that you replace the loaded modules based on the available software and dependencies on your system.

