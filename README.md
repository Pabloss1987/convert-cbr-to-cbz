## convert-cbr-to-cbz.sh

**convert-cbr-to-cbz.sh** is a simple Bash script for batch converting and repacking comic archives. It supports `.cbr` (RAR), `.cbz` (ZIP), and `.pdf` files, preserves folder structure, and moves metadata files.

### Features

- **Recursive search** for `.cbr`, `.cbz`, and `.pdf` files in the `input` directory or a provided path.
- **CBR to CBZ conversion:** Extracts each `.cbr` file to a temporary directory and creates a `.cbz` archive in the output directory, preserving subfolder structure.
- **CBZ repacking:** Optionally repacks existing `.cbz` files (extracts and re-zips contents).
- **PDF to CBZ conversion:** Optionally converts `.pdf` files to `.cbz` by extracting each page as an image and archiving them.
- **Interactive selection:** Before processing, the script scans and asks which file types you want to process.
- **Metadata support:** Moves metadata files (`.xml`, `.txt`, `.json`, `.nfo`) with the same base name as the archive to the output directory.
- **Output directory control:** Output and temp directories are created next to the script by default, but you can specify a custom output directory with `-o`.
- **Clear logs** for each step.
- **Dependency check:** Checks for required dependencies (`unrar`, `7z`, `find`, `pdftoppm`) and informs you if any are missing.
- **Safe original removal:** Asks whether to delete original `.cbr` files after conversion.
- **Flexible input:** Works in the current directory or in a specified path with `-d` or `--dir`.

### Requirements

- `unrar`
- `7z` (p7zip)
- `find`
- `pdftoppm` (from poppler-utils)
- Bash (Linux, macOS, WSL)

### Usage

1. Place your `.cbr`, `.cbz`, or `.pdf` files in the `input` directory (or specify a path with `-d`).
2. Run the script:
    ```bash
    ./convert-cbr-to-cbz.sh
    ```
    or
    ```bash
    ./convert-cbr-to-cbz.sh -d /path/to/your/folder
    ```
    Optionally, specify output directory:
    ```bash
    ./convert-cbr-to-cbz.sh -d /path/to/your/folder -o /path/to/output
    ```
3. The script will scan for files and ask which types to process.
4. After processing, decide whether to delete the original `.cbr` files.

### Example output

```
🔎 Scanning for .cbz, .cbr and .pdf files in: /home/user/comics/input
Found: 3 CBZ, 5 CBR, 2 PDF files.
Do you want to repack all found .cbz files? (y/N): y
Do you want to convert all found .cbr files? (y/N): y
Do you want to convert all found .pdf files to CBZ? (y/N): n
...
Do you want to delete original .cbr files? (y/N):
```

---

**A handy tool for comic
