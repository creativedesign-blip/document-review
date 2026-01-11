#!/usr/bin/env python3
"""
Convert Simplified Chinese to Traditional Chinese in all project files using OpenCC.

Usage:
    pip install opencc-python-reimplemented
    python convert_to_traditional.py [--dry-run]

Options:
    --dry-run    Preview changes without modifying files
"""

import os
import sys
from pathlib import Path

# Fix Windows console encoding
if sys.platform == "win32":
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")
    sys.stderr.reconfigure(encoding="utf-8", errors="replace")

try:
    import opencc
except ImportError:
    print("Please install opencc: pip install opencc-python-reimplemented")
    sys.exit(1)

# Directories to skip
SKIP_DIRS = {
    ".git",
    ".venv",
    "venv",
    "__pycache__",
    "node_modules",
    ".next",
    "dist",
    "build",
    ".terraform",
    ".idea",
    ".vscode",
    "coverage",
    ".pytest_cache",
    ".mypy_cache",
}

# File extensions to process
TEXT_EXTENSIONS = {
    ".py",
    ".js",
    ".jsx",
    ".ts",
    ".tsx",
    ".json",
    ".md",
    ".txt",
    ".html",
    ".css",
    ".scss",
    ".yaml",
    ".yml",
    ".toml",
    ".ini",
    ".cfg",
    ".env",
    ".jinja2",
    ".jinja",
    ".sql",
    ".sh",
    ".bat",
    ".ps1",
    ".xml",
    ".svg",
}

# Files to skip
SKIP_FILES = {
    "package-lock.json",
    "yarn.lock",
    "pnpm-lock.yaml",
    ".gitignore",
    ".gitattributes",
}


def should_process_file(file_path: Path) -> bool:
    """Check if file should be processed."""
    # Skip specific files
    if file_path.name in SKIP_FILES:
        return False

    # Check extension
    suffix = file_path.suffix.lower()
    if suffix not in TEXT_EXTENSIONS:
        return False

    return True


def should_skip_dir(dir_name: str) -> bool:
    """Check if directory should be skipped."""
    return dir_name in SKIP_DIRS or dir_name.startswith(".")


def convert_file(file_path: Path, converter: opencc.OpenCC, dry_run: bool = False) -> bool:
    """
    Convert a single file from Simplified to Traditional Chinese.
    Returns True if file was modified, False otherwise.
    """
    try:
        # Read file content
        with open(file_path, "r", encoding="utf-8") as f:
            original_content = f.read()
    except UnicodeDecodeError:
        # Skip binary files or files with encoding issues
        return False
    except Exception as e:
        print(f"  Error reading {file_path}: {e}")
        return False

    # Convert content
    converted_content = converter.convert(original_content)

    # Check if content changed
    if original_content == converted_content:
        return False

    # Show changes
    print(f"  Converting: {file_path}")

    if dry_run:
        # Show preview of changes (first few differences)
        original_lines = original_content.splitlines()
        converted_lines = converted_content.splitlines()
        diff_count = 0
        for i, (orig, conv) in enumerate(zip(original_lines, converted_lines), 1):
            if orig != conv and diff_count < 5:
                print(f"    Line {i}:")
                print(f"      - {orig[:80]}{'...' if len(orig) > 80 else ''}")
                print(f"      + {conv[:80]}{'...' if len(conv) > 80 else ''}")
                diff_count += 1
        if diff_count >= 5:
            print("    ... (more changes)")
    else:
        # Write converted content
        try:
            with open(file_path, "w", encoding="utf-8") as f:
                f.write(converted_content)
        except Exception as e:
            print(f"  Error writing {file_path}: {e}")
            return False

    return True


def main():
    dry_run = "--dry-run" in sys.argv

    if dry_run:
        print("DRY RUN MODE - No files will be modified\n")

    # Initialize OpenCC converter (s2t = Simplified to Traditional)
    converter = opencc.OpenCC("s2t")

    # Get project root (directory containing this script)
    project_root = Path(__file__).parent.resolve()

    print(f"Project root: {project_root}")
    print(f"Converting Simplified Chinese to Traditional Chinese...\n")

    files_processed = 0
    files_converted = 0

    # Walk through all files
    for root, dirs, files in os.walk(project_root):
        # Filter out directories to skip
        dirs[:] = [d for d in dirs if not should_skip_dir(d)]

        root_path = Path(root)

        for file_name in files:
            file_path = root_path / file_name

            if not should_process_file(file_path):
                continue

            files_processed += 1

            if convert_file(file_path, converter, dry_run):
                files_converted += 1

    print(f"\nSummary:")
    print(f"  Files scanned: {files_processed}")
    print(f"  Files {'would be ' if dry_run else ''}converted: {files_converted}")

    if dry_run and files_converted > 0:
        print(f"\nRun without --dry-run to apply changes.")


if __name__ == "__main__":
    main()
