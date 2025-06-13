#!/bin/bash

# === Dependencies check ===
MISSING=""
command -v unrar >/dev/null 2>&1 || MISSING="${MISSING}unrar "
command -v 7z >/dev/null 2>&1 || MISSING="${MISSING}7z "
command -v find >/dev/null 2>&1 || MISSING="${MISSING}find "

if [ -n "$MISSING" ]; then
    echo "❌ Missing dependencies: $MISSING"
    echo "Please install the missing components and try again."
    exit 1
fi

# === Directories ===
BASE_DIR="$(pwd)"
INPUT_DIR="$BASE_DIR/input"
OUTPUT_DIR="$BASE_DIR/output"
TEMP_DIR="$BASE_DIR/temp"

mkdir -p "$TEMP_DIR"
mkdir -p "$OUTPUT_DIR"

echo "🔎 Searching for .cbr files in: $INPUT_DIR"
FOUND=0

find "$INPUT_DIR" -type f -iname "*.cbr" | while read -r CBR_FILE; do
    FOUND=1
    echo "📂 Processing: $CBR_FILE"

    # Relative path (for subfolders)
    REL_PATH="${CBR_FILE#$INPUT_DIR/}"
    REL_DIR=$(dirname "$REL_PATH")

    # Temporary directory for extraction
    WORK_DIR="$TEMP_DIR/$(basename "${CBR_FILE%.cbr}")"
    mkdir -p "$WORK_DIR"

    echo "🗃️ Extracting to: $WORK_DIR"
    unrar x -o+ "$CBR_FILE" "$WORK_DIR/" > /dev/null
    if [ $? -ne 0 ]; then
        echo "❌ Extraction failed: $CBR_FILE"
        rm -rf "$WORK_DIR"
        continue
    fi

    # Output directory (recreate structure)
    DEST_DIR="$OUTPUT_DIR/$REL_DIR"
    mkdir -p "$DEST_DIR"

    # Output .cbz file
    CBZ_FILE="$DEST_DIR/$(basename "${CBR_FILE%.cbr}").cbz"

    echo "📦 Creating CBZ: $CBZ_FILE"
    7z a -tzip "$CBZ_FILE" "$WORK_DIR"/* > /dev/null

    if [ $? -eq 0 ]; then
        echo "✅ Created: $CBZ_FILE"
    else
        echo "❌ Failed to create: $CBZ_FILE"
    fi

    # Clean up temporary files
    rm -rf "$WORK_DIR"
done

# Remove temp if empty
rmdir "$TEMP_DIR" 2>/dev/null

# Ask to delete original files
echo
read -p "Do you want to delete original .cbr files? (y/N): " DEL_ORIG
if [[ "$DEL_ORIG" =~ ^[Yy]$ ]]; then
    echo "🗑️ Deleting original .cbr files..."
    find "$INPUT_DIR" -type f -iname "*.cbr" -exec rm -v {} \;
    echo "✅ All original .cbr files deleted."
else
    echo "ℹ️ Original .cbr files were not deleted."
fi

echo "🎉 Conversion finished."
