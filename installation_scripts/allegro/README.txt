NOTES: 

1. CLONE THE "INSTALLATION_SCRIPTS" FOLDER TO YOUR SOFTWARE FOLDER AND JUST RUN THE INSTALLATION SCRIPT, THERE IS NO NEED TO MOVE THE SCRIPT 
   AROUND, IT WILL NAVIGATE OUT OF THIS FOLDER TO INSTALL IN THE SOFTWARE FOLDER. DIRECTORY TREE:

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
	 └── nequip
	     ├── nequip/
	     ├── pair_nequip/
	     └── lammps_nequip/
	         └── build/
	             └── lmp
	

2. THE INSTALLATION SCRIPT PROVIDED ALREADY HAS THE VERSIONS THAT WORK SET, FEEL FREE TO TRY OTHER VERSIONS IF YOU WISH, HOWEVER, THEY MAY NOT 
   WORK.
      
3. THE LAMMPS INSTALLATION PATH VARIABLE HAS TO BE CHANGED TO WORK FOR YOU.

4. IF RUNNING THIS SCRIPT ON OTHER HPC CLUSTERS, YOU HAVE TO REPLACE THE LOADED MODULES BASED ON WHAT IS AVAILABLE TO YOU.
