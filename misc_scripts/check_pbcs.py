#!/usr/bin/env python3
# Created by: CHATGPT

import sys
from ase.io import read

def main():
    if len(sys.argv) != 2:
        print(f"Usage: {sys.argv[0]} <structure_file>")
        sys.exit(1)

    filename = sys.argv[1]

    try:
        all_atoms = read(filename, index=':')
    except Exception as e:
        print(f"❌ Error reading file '{filename}': {e}")
        sys.exit(1)

    all_pbc_correct = True

    for i, atoms in enumerate(all_atoms):
        if not all(atoms.pbc):
            print(f"⚠️  Frame {i}: PBCs are {atoms.pbc} — not all True.")
            all_pbc_correct = False

    if all_pbc_correct:
        print("✅ All frames have PBCs set to [True, True, True].")
    else:
        print("⚠️  Some frames have incorrect PBC settings.")

if __name__ == "__main__":
    main()

