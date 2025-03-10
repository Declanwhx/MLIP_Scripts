## NOTES:

1. **Expected directory structure**
```
project/
├── input_files/
│   ├── si.data
│   └── Si_data
│       └── /Si_data
├── input.yaml
├── inputlammps
└── run_nequip_lammps.sh
```
   - project -> e.g H2O
   - inputlammps -> LAMMPS input settings file
   - input.yaml -> Nequip input settings file
   - si.data -> Initializing snapshot of system for MD
   - Si_data -> Training and validation data for Nequip

2. **Combining Run Scripts**
   - While it is technically possible to combine both run scripts, **it is not recommended**.  
   - Training, especially for complex models, can take a significant amount of time.  
   - Users should assess the **model complexity** based on their desired outputs.  
   - The creators of the Nequip MLIP provide recommendations in their `configs.yaml` file:  
     🔗 [Nequip Full Config](https://github.com/mir-group/nequip/blob/main/configs/full.yaml)

3. **CPU Usage for Training**
   - Using **more CPU cores** is highly recommended for training due to the implementation of data parsing 
     parallelization from **version 0.5.5 onwards**
   - For more details, refer to the following discussion:  
     🔗 [mir-group/nequip#182](https://github.com/mir-group/nequip/issues/182)  
   - Alternatively, review the **0.5.5 documentation** for a deeper understanding of the update.

4. **Managing Training, Validation, and Test Sets**
   - If you plan to create test sets, ensure that in your `input.yaml` file,  
     **the sum of training and validation datasets does not reach 100%**.  
   - You must leave some data aside for **testing**.  
   - Testing is performed using the following command:
     ```bash
     nequip-evaluate
     ```
