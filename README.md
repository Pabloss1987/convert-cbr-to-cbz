## convert-cbr-to-cbz.sh

**convert-cbr-to-cbz.sh** is a simple Bash script for batch converting `.cbr` (RAR) comic archives to `.cbz` (ZIP) format, preserving folder structure and moving metadata files.

### Features

- Searches for all `.cbr` files in the `input` directory (or in a provided path).
- Extracts each `.cbr` file to a temporary directory.
- Creates a `.cbz` archive in the `output` directory, preserving subfolder structure.
- Moves metadata files (`.xml`, `.txt`, `.json`, `.nfo`) with the same base name as the `.cbr` file to the output directory.
- Asks whether to delete original `.cbr` files after conversion.
- Provides clear logs for each step.
- Checks for required dependencies (`unrar`, `7z`, `find`) and informs you if any are missing.
- Works in the current directory or in a specified path:  
  `./convert-cbr-to-cbz.sh /path/to/convert`

### Requirements

- `unrar`
- `7z` (p7zip)
- `find`
- Bash (Linux, macOS, WSL)

### Usage

1. Place your `.cbr` files in the `input` directory (or specify a path as an argument).
2. Run the script:
    ```bash
    ./convert-cbr-to-cbz.sh
    ```
    or
    ```bash
    ./convert-cbr-to-cbz.sh /path/to/your/folder
    ```
3. After conversion, decide whether to delete the original `.cbr` files.

### Example output

```
🔎 Searching for .cbr files in: /home/user/comics/input
📂 Processing: /home/user/comics/input/Batman.cbr
🗃️ Extracting to: /home/user/comics/temp/Batman
📦 Creating CBZ: /home/user/comics/output/Batman.cbz
✅ Created: /home/user/comics/output/Batman.cbz
...
Do you want to delete original .cbr files? (y/N):
```

---

**A handy tool for comic collectors and archivists!**
