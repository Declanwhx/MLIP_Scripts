from ase.io import read
import sys

def count_frames(filename):
    """Count the number of frames (snapshots) in an .extxyz file."""
    try:
        frames = read(filename, index=":")
        num_frames = len(frames)
        print(f"Total frames in '{filename}': {num_frames}")
        return num_frames
    except Exception as e:
        print(f"Error reading '{filename}': {e}")
        return None

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python count_frames.py <input.extxyz>")
    else:
        count_frames(sys.argv[1])

