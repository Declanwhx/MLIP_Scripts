## NOTES:

1. **(IMPORTANT)** When installing PyTorch via Spack, the installation will complete without errors. However, attempting to load the newly installed module may result in an error related to 
   missing `openblas/0.3.24`. This occurs due to the unusual appending of `_threads_openmp` to the HPC's module name.  

   Thanks to ChatGPT, this issue is automatically handled if you simply run the installation script for PyTorch. Should this fail, or for those interested in manually resolving it, follow 
   these steps:

   1. Open the PyTorch module file:
      ```bash
      vim ~/software/spack/share/spack/lmod/linux-rhel8-x86_64/openmpi/4.1.6-h2uag4k/Core/py-torch/2.1.0.lua
      ```
   2. Locate the line containing:
      ```lua
      depends_on("openblas/0.3.24")
      ```
   3. Modify it to:
      ```lua
      depends_on("openblas/0.3.24_threads_openmp")
      ```

2. **(IMPORTANT)** The `lmp` executable for DeepMD is located in bin/build/ and **not** inside the `lammps/` directory. Refer to the directory tree below.

3. Clone the `installation_scripts` folder to your `software/` directory and run the installation script directly. There is no need to move the script around, as it will automatically navigate to the correct directories.

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

4. The installation script provided **already includes pre-set versions that are known to work**. You are free to try other versions, but compatibility is not guaranteed.

5. If running this script on other HPC clusters, ensure that you replace the loaded modules based on the available software and dependencies on your system.

