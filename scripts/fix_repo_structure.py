import os
import shutil
from pathlib import Path

def main():
    base_dir = Path.cwd()
    docs_dir = base_dir / "docs"
    specs_file_wrong = docs_dir / "specs"
    specs_dir = docs_dir / "specs_temp" # Temp dir to avoid conflict

    # 1. Fix docs/specs being a file
    if specs_file_wrong.exists() and specs_file_wrong.is_file():
        print("Found docs/specs as a file. Fixing...")
        specs_dir.mkdir(parents=True, exist_ok=True)
        shutil.move(str(specs_file_wrong), str(specs_dir / "Issue #1 Devspec"))
        
        # Now rename temp dir to specs
        # But wait, we can't rename if 'specs' file still exists (it was moved though)
        # Verify it's gone
        if not specs_file_wrong.exists():
            specs_dir.rename(docs_dir / "specs")
            print("Fixed: docs/specs is now a directory containing Issue #1")
        else:
            print("Error: specs file still exists?")
    elif not (docs_dir / "specs").exists():
         (docs_dir / "specs").mkdir(parents=True, exist_ok=True)

    # Re-define specs dir
    final_specs_dir = docs_dir / "specs"

    # 2. Move other Devspecs
    for i in [2, 3]:
        src = base_dir / f"Issue #{i} Devspec"
        if src.exists():
            shutil.move(str(src), str(final_specs_dir / f"Issue #{i} Devspec"))
            print(f"Moved Issue #{i}")

    # 3. Move Figma_Generated_UI
    figma_src = base_dir / "Figma_Generated_UI"
    proto_dir = base_dir / "prototypes"
    figma_dest = proto_dir / "figma_generated_ui"

    if figma_src.exists():
        if not proto_dir.exists():
            proto_dir.mkdir()
        
        if figma_dest.exists():
            print("Figma destination exists, merging/skipping")
            # If it exists, maybe we just move the contents? Or rename source?
            # Let's just try move and catch error
        else:
            try:
                shutil.move(str(figma_src), str(figma_dest))
                print("Moved Figma_Generated_UI")
            except Exception as e:
                print(f"Error moving figma: {e}")

if __name__ == "__main__":
    main()
