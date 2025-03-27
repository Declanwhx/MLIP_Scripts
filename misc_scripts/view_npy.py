import numpy as np
import sys

# Check if a file was provided
if len(sys.argv) < 2:
    print("Usage: python load_npy.py <filename.npy>")
    sys.exit(1)

# Get the filename from the command-line argument
filename = sys.argv[1]

try:
    # Load the .npy file
    data = np.load(filename)

    # Print basic info about the array
    print(f"Loaded file: {filename}")
    print(f"Type: {type(data)}")
    print(f"Shape: {data.shape}")
    print(f"Data type: {data.dtype}")
    print("\nPreview of the data:")
    print(data)

except Exception as e:
    print(f"Error loading file: {e}")

