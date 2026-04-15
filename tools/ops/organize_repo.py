import os
import shutil
from pathlib import Path

# Config
MOVES = [
    ("ARCHITECTURE.md", "docs/ARCHITECTURE.md"),
    ("openapi.yaml", "docs/openapi.yaml"),
    ("Issue #1 Devspec", "docs/specs/Issue #1 Devspec"),
    ("Issue #2 Devspec", "docs/specs/Issue #2 Devspec"),
    ("Issue #3 Devspec", "docs/specs/Issue #3 Devspec"),
    ("Figma_Generated_UI", "prototypes/figma_generated_ui"),
]

DIRS = [
    "backend",
    "frontend",
    "docs/specs",
    "prototypes",
    "scripts"
]

def main():
    base_dir = Path.cwd()
    print(f"Base Dir: {base_dir}")

    # Create directories
    for d in DIRS:
        dir_path = base_dir / d
        if not dir_path.exists():
            print(f"Creating directory: {d}")
            dir_path.mkdir(parents=True, exist_ok=True)
        else:
            print(f"Directory exists: {d}")

    # Move files
    for src_name, dest_name in MOVES:
        src = base_dir / src_name
        dest = base_dir / dest_name
        
        if src.exists():
            if dest.exists():
                print(f"Destination exists, skipping: {dest_name}")
            else:
                print(f"Moving {src_name} -> {dest_name}")
                shutil.move(str(src), str(dest))
        else:
            print(f"Source not found (maybe already moved): {src_name}")

if __name__ == "__main__":
    main()
