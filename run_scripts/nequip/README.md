## NOTES:

1. **Expected directory structure**
```
project/
├── input_files/
│   ├── combined_training.extxyz
│   └── temp_300.0
├── input.yaml
├── nvt_simulation.in
├── run_nequip.sh
├── training_files/
└── h2o-deployed.pth
```
- **`project/`** → Example: `H2O`
- **`combined_training.extxyz`** → Contains all DFT frames; training/validation split is managed via `input.yaml`.
- **`temp_300.0/`** → Folder with the initial system snapshot generated by `box_initializer.py`.
- **`nvt_simulation.in`** → LAMMPS input file for NVT (or NPT) simulations.
- **`input.yaml`** → Allegro input configuration file.
- **`run_nequip.sh`** → SLURM `sbatch` script for job execution.
- **`training_files/`** → Stores logs, trained models, and datasets.
- **`h2o-deployed.pth`** → Final trained model.

---

## 🛠️ Run Script Best Practices
- **Avoid combining training and simulation run scripts** unless necessary.
- Training can be time-intensive, particularly for complex models and retraining these models are unneccessary.
- The **NequIP MLIP** developers provide configuration recommendations:  
  🔗 [Nequip Full Config](https://github.com/mir-group/nequip/blob/main/configs/full.yaml)

---

## 🖥️ CPU Usage for Training
- Using **multiple CPU cores** is recommended due to improved speed from **data parsing parallelization** (from version **0.5.5+**).
- For details, see:  
  🔗 [Discussion: mir-group/nequip#182](https://github.com/mir-group/nequip/issues/182)  
  or consult the **0.5.5+ documentation**.

---

## 📊 Training, Validation & Test Sets
- Ensure that the **sum of training + validation data is < 100%** to leave datasets for testing.
- To evaluate trained models, use:
  ```bash
  nequip-evaluate
  ```
