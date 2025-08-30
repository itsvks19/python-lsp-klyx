#!/bin/bash

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Building Klyx Extension...${NC}"

echo -e "${YELLOW}Cleaning previous builds...${NC}"
# cargo clean
rm -rf output/
mkdir -p output/

echo -e "${YELLOW}Compiling to WebAssembly...${NC}"
cargo build --target wasm32-wasip1 --release

WASM_FILE_NAME=$(grep '^name = ' Cargo.toml | cut -d '"' -f 2 | sed 's/[ -]/_/g')

# check if the WASM file was created
WASM_FILE="target/wasm32-wasip1/release/${WASM_FILE_NAME}.wasm"
if [ ! -f "$WASM_FILE" ]; then
    echo -e "${RED}Error: WASM file not found at $WASM_FILE${NC}"
    exit 1
fi

mkdir -p lib
cp "$WASM_FILE" "lib/"

if command -v wasm2wat >/dev/null 2>&1; then
    if wasm2wat "$WASM_FILE" -o "$WASM_FILE_NAME.wat" 2>/dev/null; then
        echo "Generated WAT using wasm2wat."
    else
        echo "wasm2wat failed. Trying wasm-tools..."
        if command -v wasm-tools >/dev/null 2>&1; then
            wasm-tools print "$WASM_FILE" > "$WASM_FILE_NAME.wat"
            echo "Generated WAT using wasm-tools."
        else
            echo "wasm-tools not found. Cannot generate .wat"
        fi
    fi
else
    echo "wasm2wat not found. Trying wasm-tools..."
    if command -v wasm-tools >/dev/null 2>&1; then
        wasm-tools print "$WASM_FILE" > "$WASM_FILE_NAME.wat"
        echo "Generated WAT using wasm-tools."
    else
        echo "wasm-tools not found. Cannot generate .wat"
    fi
fi

# create temporary directory for packaging
TEMP_DIR="output/temp"
mkdir -p "$TEMP_DIR/src"

# copy the WASM file to src directory in temp
cp "$WASM_FILE" "$TEMP_DIR/src/"

# copy extension.toml to temp directory
cp "extension.toml" "$TEMP_DIR/"

# get extension info for naming
EXTENSION_ID=$(grep '^id = ' extension.toml | cut -d '"' -f 2)
EXTENSION_VERSION=$(grep '^version = ' extension.toml | cut -d '"' -f 2)

# create the zip file
ZIP_NAME="${EXTENSION_ID}-${EXTENSION_VERSION}.zip"
echo -e "${YELLOW}Creating package: output/$ZIP_NAME${NC}"

cd "$TEMP_DIR"
zip -r "../../output/${ZIP_NAME}" .
cd - > /dev/null

# clean up temp directory
rm -rf "$TEMP_DIR"

echo -e "${GREEN}Build complete!${NC}"
echo -e "${GREEN}Package created: output/$ZIP_NAME${NC}"
echo -e "${GREEN}Contents:${NC}"
echo -e "  - extension.toml"
echo -e "  - src/${WASM_FILE_NAME}.wasm"
