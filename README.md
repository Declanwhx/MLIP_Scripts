The scripts provided in this repository enable the installation and execution of MLIPs. These scripts work by default; however, users are expected to review certain parameters carefully and modify them if necessary. Key aspects that may require adjustments include the number of GPUs/CPUs used, input hyperparameters, and other configurations.

1. Users of these scripts should have the following software and simulation directories in their home ($HOME) or scratch ($SCRATCH) directory:
   
```
	 $HOME/
	 ├── software
	 └── simulation
	 $SCRATCH/
	 ├── software
	 └── simulation
```
  
```bash
mkdir -p $HOME/software
mkdir -p $HOME/simulation
mkdir -p /scratch/$USER/software
mkdir -p /scratch/$USER/simulation
```

2. By default, the installation scripts use the scratch directory ($SCRATCH) for all installations due to storage constraints. However, it should be possible to modify the scripts to place 	 
   different LAMMPS builds within the same source directory (excluding DeepMD) to save some space.

3. Additionally, users may explore the possibility of running NequIP using Allegro, as Allegro is simply an extension of NequIP. This can be achieved by specifying the NequIP builders in the 
   input.yaml script instead.
