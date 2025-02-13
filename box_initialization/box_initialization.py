# -*- coding: utf-8 -*-
"""
Created on Fri Apr 28 13:30:26 2023

@author: Declan and ChatGPT
"""

import CoolProp.CoolProp as CP
import numpy as np
import os
import glob
import shlex
import subprocess
import shutil
import argparse
from ase import Atoms
from ase.io import write

home_directory = os.path.expanduser("~")

def square_domain_from_molecules(temperature, num_water, fluid='Water', pressure=101325):
    """Compute the side length of a cubic domain given the number of molecules."""
    
    # Constants
    NA = 6.022e23  # Avogadro's number (molecules/mol)
    M_H2O = 0.018015  # Molar mass of H2O in kg/mol

    # Convert number of molecules to mass (kg)
    mass = (num_water / NA) * M_H2O

    # Get density of water at the given T and P
    try:
        density = CP.PropsSI("D", "T", temperature, "P", pressure, fluid)
    except Exception as e:
        print(f"Error retrieving properties for {fluid}: {e}")
        return None

    # Compute total volume (m³)
    total_volume = mass / density

    # Compute side length for cubic domain
    side_length_3D = total_volume ** (1/3)
    side_length_3D_Angstrom = side_length_3D * 1e10

    # Compute molar density (molecules/m³)
    molar_density = num_water / (total_volume * 1e3)

    return {
        "Cube Side Length": side_length_3D_Angstrom, # (A)
        "Total Volume": total_volume, # (m³)
        "Density": density, # (kg/m³)
        "Molar Density": molar_density # (molecules/m³)
    }

def ase_formatting(xyz_file):
    """Reformats the Packmol created xyz files into LAMMPS and PDB files."""

    with open(xyz_file, "r") as f:
        lines = f.readlines()

    # --- Parse Header ---
    # First line: number of atoms (we don't actually need it for ASE, but we check for consistency)
    n_atoms = int(lines[0].strip())

    # Second line: cell vectors (9 numbers representing a 3x3 cell matrix)
    cell_numbers = list(map(float, lines[1].split()))
    if len(cell_numbers) != 9:
        raise ValueError("Expected 9 numbers for the cell, got {}".format(len(cell_numbers)))
    cell = [cell_numbers[0:3], cell_numbers[3:6], cell_numbers[6:9]]

    # --- Parse Atomic Coordinates ---
    symbols = []
    positions = []

    # The remaining lines contain atomic symbols and coordinates.
    for line in lines[2:]:
        parts = line.split()
        if len(parts) < 4:  # Skip empty or incomplete lines
            continue
        symbol = parts[0]
        pos = [float(x) for x in parts[1:4]]
        symbols.append(symbol)
        positions.append(pos)

    # (Optional) Check if the number of atoms matches the header
    if len(symbols) != n_atoms:
        print(f"Warning: header specifies {n_atoms} atoms but found {len(symbols)} atoms in the file.")

    # --- Create ASE Atoms Object ---
    atoms = Atoms(symbols=symbols, positions=positions, cell=cell, pbc=True)

    # --- Write LAMMPS Data File ---
    write("h2o.data", atoms, format="lammps-data")
    write("h2o.pdb", atoms, format="proteindatabank")
    print("LAMMPS data file 'lammps.data' has been written.")


def prepare_config(i, temp_dir, args, result):
    """Creates a configuration directory, copies required files, runs fftool and Packmol."""

    config_dir = os.path.join(temp_dir, f"config_{i}")
    os.makedirs(config_dir, exist_ok=True)

    # Copy required files
    shutil.copy("water.xyz", config_dir)
    shutil.copy("params.ff", config_dir)

    os.chdir(config_dir)

    # Run fftool
    fftool_command = f'{home_directory}/software/fftool/fftool {args.n_water} water.xyz -b {result["Cube Side Length"]}'
    subprocess.run(shlex.split(fftool_command), capture_output=False, text=True)
    
    subprocess.run(["echo", "seed -1", ">>", "pack.inp"], capture_output=False)

    packmol_command = f"{home_directory}/software/packmol-20.15.3/packmol < pack.inp > packmol.out"


    try:
        results = subprocess.run(packmol_command, shell=True, capture_output=True, text=True, check=True)
        print(f"Packmol output for config_{i}:\n{results.stdout}")
    except subprocess.CalledProcessError as e:
        print(f"Error in Packmol execution for config_{i}:\n{e.stderr}")

    simbox_path = os.path.join(os.getcwd(), "simbox.xyz")
    
    # Read and modify the file
    with open(simbox_path, "r") as file:
        lines = file.readlines()

    lattice_line = f'{result["Cube Side Length"]} 0.0 0.0 0.0 {result["Cube Side Length"]} 0.0 0.0 0.0 {result["Cube Side Length"]}'
    lines = [lattice_line + "\n" if "Built with Packmol" in line else line for line in lines]

    if lines:
        lines[0] = lines[0].lstrip()

    # Write the modified content back
    with open(simbox_path, "w") as file:
        file.writelines(lines)

    ase_formatting(simbox_path)

    data_path = os.path.join(os.getcwd(), "h2o.data")
    pdb_path =  os.path.join(os.getcwd(), "h2o.pdb")
    os.chdir(os.path.join(os.getcwd(), "../"))
    shutil.copy(data_path, f'./h2o_{i}.data')
    shutil.copy(pdb_path, f'./h2o_{i}.pdb')
    os.chdir(os.path.join(os.getcwd(), "../"))

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Calculate box size based on molecule count.")
    parser.add_argument("temperature", type=float, help="Temperature (Kelvin)")
    parser.add_argument("n_water", type=int, help="Number of water molecules")
    parser.add_argument("--fluid", type=str, default="Water", help="Fluid name")
    parser.add_argument("--pressure", type=int, default=101325, help="Pressure (Pa)")
    parser.add_argument("--num_configs", type=int, default=3, help="Number of configurations")

    args = parser.parse_args()
    result = square_domain_from_molecules(args.temperature, args.n_water, args.fluid, args.pressure)
    
    temp_dir = f"temp_{args.temperature}"
    os.makedirs(temp_dir, exist_ok=True)

    for i in range(1, args.num_configs + 1):
        prepare_config(i, temp_dir, args, result)

    os.chdir(temp_dir)
    
    for dir_path in glob.glob("config_*"):
        if os.path.isdir(dir_path):  # Check if it is indeed a directory
            shutil.rmtree(dir_path)
            print(f"Removed directory: {dir_path}")
