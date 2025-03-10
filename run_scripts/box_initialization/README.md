## Box Initialization Script

This Python script generates the **initial box domain** for a molecular system based on the specified **temperature** and **number of molecules**.

### **Usage**
Run the script with the required arguments:
```bash
python3 box_initialization.py <temperature> <num_molecules>
```
Example:
```bash
python3 box_initialization.py 300 700
```
which creates a box of 700 molecules at 300K. Additional flags are available when running this script:
```
--num_configs
--fluid
--pressure
```
These are by default, 3 , "Water" and 101325 Pa respectively. To change them, the user can simply run the script with the flags, eg.:
```bash
python3 box_initialization 300 700 --num_configs 5
```
which will generate 5 different configurations instead of the default 3. 
For a summary of available options, you can run:
```bash
python3 box_initialization.py --help
```
