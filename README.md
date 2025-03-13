## MLIP Installation and Execution

The scripts in this repository facilitate the **installation** and **execution** of MLIPs.  
By default, they work without modifications, but users should carefully review and adjust specific parameters as needed.  
Key settings that may require customization include:  
- **Number of GPUs/CPUs**  
- **Input hyperparameters**  
- **Other relevant configurations**  

---

### 1. Directory Setup  

Users should ensure that the following **software** and **simulation** directories exist in either their **home (`$HOME`)** or **scratch (`$SCRATCH`)** directory:
```
	 $HOME/
	 ├── software
	 └── simulation
	 $SCRATCH/
	 ├── software
	 └── simulation
```

To create these directories, run:
```bash
mkdir -p ~/software
mkdir -p ~/simulation
mkdir -p /scratch/$USER/software
mkdir -p /scratch/$USER/simulation
```
Next, clone the repository and move the necessary scripts:
```bash
git clone https://github.com/Declanwhx/MLIP_Scripts.git
mv MLIP_Scripts/installation_scripts ~/software
mv MLIP_Scripts/run_scripts ~/simulation
```

2. By default, the installation scripts use the home directory ($HOME) for all installations. However, should you run into space constraints, you could amend the paths in the installation scripts to install in the scratch folder instead. Alternatively, the LAMMPS source repo could be shared between Allegro and Nequip to save space (Pair_Allegro and Pair_Nequip are different, so different builds are required).

3. Additionally, users may explore the possibility of running NequIP using Allegro, as Allegro is simply an extension of NequIP. This can be done by specifying the NequIP builders in the input.yaml script instead of the default Allegro setup.
