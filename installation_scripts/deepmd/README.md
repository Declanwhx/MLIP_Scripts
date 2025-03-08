NOTES: 

1. (IMPORTANT) NOTE THAT WHEN YOU SPACK INSTALL PYTORCH, IT WILL SHOW AN ERROR ABOUT FAILING TO LOAD/FIND OPENBLAS/0.3.24, THIS IS CAUSED BY THE UNUSUAL APPENDATION OF "_threads_openmp" TO THE
   MODULE NAME. I PROVIDE THE SOLUTION IN THE FOLLOWING STEPS:
	1. vim ~/software/spack/share/spack/lmod/linux-rhel8-x86_64/openmpi/4.1.6-h2uag4k/Core/py-torch/2.1.0.lua
	2. look for the line containing "depends_on("openblas/0.3.24")"
	3. modify the line found in (2) to "depends_on("openblas/0.3.24_threads_openmp")"

2. (IMPORTANT) TAKE NOTE THAT THE LMP EXECUTABLE FOR DEEPMD IS IN BIN/BUILD/LMP AND NOT IN LAMMPS. 

3. CLONE THE "INSTALLATION_SCRIPTS" FOLDER TO YOUR SOFTWARE FOLDER AND JUST RUN THE INSTALLATION SCRIPT, THERE IS NO NEED TO MOVE THE SCRIPT 
   AROUND, IT WILL NAVIGATE OUT OF THIS FOLDER TO INSTALL IN THE SOFTWARE FOLDER.

```
	 software/
	 ├── installation_scripts/
	 │   ├── allegro/
	 │       └── installation_allegro_lammps.sh
	 │   ├── deepmd/
	 │       └── installation_deepmd.sh
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
	 │   ├── lammps/
	 │   └── bin/
	 │       └── build/
	 │           └── lmp
	 └── nequip
	     ├── nequip/
	     ├── pair_nequip/
	     └── lammps_nequip/
	         └── build/
	             └── lmp
```

4. THE INSTALLATION SCRIPT PROVIDED ALREADY HAS THE VERSIONS THAT WORK SET, FEEL FREE TO TRY OTHER VERSIONS IF YOU WISH, HOWEVER, THEY MAY NOT 
   WORK.

5. CHANGE THE PATH VARIABLES ACCORDINGLY

6. IF RUNNING THIS SCRIPT ON OTHER HPC CLUSTERS, YOU HAVE TO REPLACE THE LOADED MODULES BASED ON WHAT IS AVAILABLE TO YOU.
