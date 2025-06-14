#!/bin/bash

# === Dependencies check ===
MISSING=""
command -v unrar >/dev/null 2>&1 || MISSING="${MISSING}unrar "
command -v 7z >/dev/null 2>&1 || MISSING="${MISSING}7z "
command -v find >/dev/null 2>&1 || MISSING="${MISSING}find "
command -v pdftoppm >/dev/null 2>&1 || MISSING="${MISSING}pdftoppm "

if [ -n "$MISSING" ]; then
    echo "❌ Missing dependencies: $MISSING"
    echo "Please install the missing components and try again."
    exit 1
fi

# === Script directory logic ===
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
OUTPUT_DIR=""
SEARCH_DIR=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        -d|--dir)
            shift
            if [ -n "$1" ]; then
                SEARCH_DIR="$(realpath "$1")"
                if [ ! -d "$SEARCH_DIR" ]; then
                    echo "❌ Provided path does not exist: $SEARCH_DIR"
                    exit 1
                fi
            else
                echo "❌ No directory specified after -d"
                exit 1
            fi
            ;;
        -o|--output)
            shift
            if [ -n "$1" ]; then
                OUTPUT_DIR="$(realpath "$1")"
                mkdir -p "$OUTPUT_DIR"
            else
                echo "❌ No output directory specified after -o"
                exit 1
            fi
            ;;
        *)
            echo "Usage: $0 [-d|--dir /input/path] [-o|--output /output/path]"
            exit 1
            ;;
    esac
    shift
done

if [ -z "$SEARCH_DIR" ]; then
    SEARCH_DIR="$SCRIPT_DIR/input"
fi

if [ -z "$OUTPUT_DIR" ]; then
    OUTPUT_DIR="$SCRIPT_DIR/output"
fi
TEMP_DIR="$SCRIPT_DIR/temp"

mkdir -p "$TEMP_DIR"
mkdir -p "$OUTPUT_DIR"

echo "🔎 Scanning for .cbz, .cbr and .pdf files in: $SEARCH_DIR"

# === Scan files ===
CBZ_LIST=()
CBR_LIST=()
PDF_LIST=()

while IFS= read -r -d '' file; do
    CBZ_LIST+=("$file")
done < <(find "$SEARCH_DIR" -type f -iname "*.cbz" -print0)

while IFS= read -r -d '' file; do
    CBR_LIST+=("$file")
done < <(find "$SEARCH_DIR" -type f -iname "*.cbr" -print0)

while IFS= read -r -d '' file; do
    PDF_LIST+=("$file")
done < <(find "$SEARCH_DIR" -type f -iname "*.pdf" -print0)

echo "Found: ${#CBZ_LIST[@]} CBZ, ${#CBR_LIST[@]} CBR, ${#PDF_LIST[@]} PDF files."

# === Ask what to process ===
REPACK_CBZ=1
CONVERT_CBR=1
CONVERT_PDF=1

if [ "${#CBZ_LIST[@]}" -gt 0 ]; then
    read -p "Do you want to repack all found .cbz files? (y/N): " ANS
    [[ ! "$ANS" =~ ^[Yy]$ ]] && REPACK_CBZ=0
fi

if [ "${#CBR_LIST[@]}" -gt 0 ]; then
    read -p "Do you want to convert all found .cbr files? (y/N): " ANS
    [[ ! "$ANS" =~ ^[Yy]$ ]] && CONVERT_CBR=0
fi

if [ "${#PDF_LIST[@]}" -gt 0 ]; then
    read -p "Do you want to convert all found .pdf files to CBZ? (y/N): " ANS
    [[ ! "$ANS" =~ ^[Yy]$ ]] && CONVERT_PDF=0
fi

# === Repack CBZ files ===
if [ "$REPACK_CBZ" -eq 1 ]; then
    for CBZ_FILE in "${CBZ_LIST[@]}"; do
        echo "🔄 Found CBZ: $CBZ_FILE"
        DEST_DIR="$OUTPUT_DIR/$(dirname "${CBZ_FILE#$SEARCH_DIR/}")"
        mkdir -p "$DEST_DIR"
        NEW_CBZ="$DEST_DIR/$(basename "$CBZ_FILE")"

        if [ -f "$NEW_CBZ" ]; then
            read -p "⚠️  $NEW_CBZ already exists. Repack again? (y/N): " OVERWRITE_CBZ
            if [[ ! "$OVERWRITE_CBZ" =~ ^[Yy]$ ]]; then
                echo "⏩ Skipping $CBZ_FILE"
                continue
            fi
        fi

        TEMP_REPACK="$TEMP_DIR/repack_$(basename "${CBZ_FILE%.cbz}")"
        mkdir -p "$TEMP_REPACK"
        echo "🗃️ Extracting CBZ to: $TEMP_REPACK"
        7z x "$CBZ_FILE" -o"$TEMP_REPACK" > /dev/null

        echo "📦 Repacking CBZ: $NEW_CBZ"
        7z a -tzip "$NEW_CBZ" "$TEMP_REPACK"/* > /dev/null

        if [ $? -eq 0 ]; then
            echo "✅ Repacked: $NEW_CBZ"
        else
            echo "❌ Failed to repack: $NEW_CBZ"
        fi

        rm -rf "$TEMP_REPACK"
    done
fi

# === Convert CBR files ===
if [ "$CONVERT_CBR" -eq 1 ]; then
    for CBR_FILE in "${CBR_LIST[@]}"; do
        echo "📂 Processing: $CBR_FILE"

        REL_PATH="${CBR_FILE#$SEARCH_DIR/}"
        REL_DIR=$(dirname "$REL_PATH")
        DEST_DIR="$OUTPUT_DIR/$REL_DIR"
        mkdir -p "$DEST_DIR"
        CBZ_FILE="$DEST_DIR/$(basename "${CBR_FILE%.cbr}").cbz"

        if [ -f "$CBZ_FILE" ]; then
            read -p "⚠️  $CBZ_FILE already exists. Convert again? (y/N): " OVERWRITE
            if [[ ! "$OVERWRITE" =~ ^[Yy]$ ]]; then
                echo "⏩ Skipping $CBR_FILE"
                continue
            fi
        fi

        WORK_DIR="$TEMP_DIR/$(basename "${CBR_FILE%.cbr}")"
        mkdir -p "$WORK_DIR"

        echo "🗃️ Extracting to: $WORK_DIR"
        unrar x -o+ "$CBR_FILE" "$WORK_DIR/" > /dev/null
        if [ $? -ne 0 ]; then
            echo "❌ Extraction failed: $CBR_FILE"
            rm -rf "$WORK_DIR"
            continue
        fi

        echo "📦 Creating CBZ: $CBZ_FILE"
        7z a -tzip "$CBZ_FILE" "$WORK_DIR"/* > /dev/null

        if [ $? -eq 0 ]; then
            echo "✅ Created: $CBZ_FILE"
        else
            echo "❌ Failed to create: $CBZ_FILE"
        fi

        rm -rf "$WORK_DIR"
    done
fi

# === Convert PDF files ===
if [ "$CONVERT_PDF" -eq 1 ]; then
    for PDF_FILE in "${PDF_LIST[@]}"; do
        echo "📄 Processing PDF: $PDF_FILE"

        REL_PATH="${PDF_FILE#$SEARCH_DIR/}"
        REL_DIR=$(dirname "$REL_PATH")
        DEST_DIR="$OUTPUT_DIR/$REL_DIR"
        mkdir -p "$DEST_DIR"
        CBZ_FILE="$DEST_DIR/$(basename "${PDF_FILE%.pdf}").cbz"

        if [ -f "$CBZ_FILE" ]; then
            read -p "⚠️  $CBZ_FILE already exists. Convert PDF again? (y/N): " OVERWRITE_PDF
            if [[ ! "$OVERWRITE_PDF" =~ ^[Yy]$ ]]; then
                echo "⏩ Skipping $PDF_FILE"
                continue
            fi
        fi

        TEMP_PDF="$TEMP_DIR/pdf_$(basename "${PDF_FILE%.pdf}")"
        mkdir -p "$TEMP_PDF"

        echo "🖼️ Extracting images from PDF to: $TEMP_PDF"
        pdftoppm -png "$PDF_FILE" "$TEMP_PDF/page" > /dev/null

        echo "📦 Creating CBZ: $CBZ_FILE"
        7z a -tzip "$CBZ_FILE" "$TEMP_PDF"/*.png > /dev/null

        if [ $? -eq 0 ]; then
            echo "✅ Created: $CBZ_FILE"
        else
            echo "❌ Failed to create: $CBZ_FILE"
        fi

        rm -rf "$TEMP_PDF"
    done
fi

# Remove temp if empty
rmdir "$TEMP_DIR" 2>/dev/null

# Ask to delete original files
echo
read -p "Do you want to delete original .cbr files? (y/N): " DEL_ORIG
if [[ "$DEL_ORIG" =~ ^[Yy]$ ]]; then
    echo "🗑️ Deleting original .cbr files..."
    find "$SEARCH_DIR" -type f -iname "*.cbr" -exec rm -v {} \;
    echo "✅ All original .cbr files deleted."
else
    echo "ℹ️ Original .cbr files were not deleted."
fi

echo "🎉 Conversion finished."
