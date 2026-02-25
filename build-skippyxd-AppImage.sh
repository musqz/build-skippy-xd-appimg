#!/bin/bash

# -----------------------------------------------------------------------------
# Skippy-XD AppImage Builder Script
# -----------------------------------------------------------------------------

# --- Banner ---
echo ""
echo "============================================================"
echo "  Skippy-XD AppImage Builder"
echo "============================================================"
echo ""
echo "  This script will:"
echo "    1. Install required build dependencies"
echo "    2. Clone latest Skippy-XD from GitHub"
echo "    3. Build and package it as an AppImage"
echo "    4. Output: build/Skippy-XD-x86_64.AppImage"
echo "    5. Copy latest skippy-xd.rc to ~/.config/skippy-xd/"
echo ""
echo "  Press ENTER to continue or Ctrl+C to cancel..."
echo "============================================================"
read -r

set -e

# --- Configuration ---
BUILD_DIR="build-skippy-xd-appimg"
APP_DIR_NAME="skippy-xd.AppDir"
TEMP_BUILD_DIR="temp_build"
ARCH="x86_64"

# Colors
GREEN='\033[0;32m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }

# --- Step 1: Install Prerequisites ---
log_info "Detecting OS and installing dependencies..."

if [ -f /etc/os-release ]; then
    . /etc/os-release
    case $ID in
        debian|ubuntu|linuxmint)
            sudo apt update
            sudo apt install -y git build-essential wget xz-utils squashfs-tools libfuse2
            ;;
        fedora)
            sudo dnf install -y git make gcc wget xz squashfs-tools fuse-libs
            ;;
        arch|manjaro)
            sudo pacman -S --needed git base-devel wget squashfs-tools fuse2
            ;;
    esac
fi

# --- Step 2: Prepare Dirs ---
log_info "Setting up build directories..."

# Check if temp_build exists from previous run, remove if so
[ -d "$TEMP_BUILD_DIR" ] && rm -rf "$TEMP_BUILD_DIR"

# Get latest skippy-xd source
log_info "Fetching latest skippy-xd source..."

git clone --depth 1 https://github.com/felixfung/skippy-xd.git "$TEMP_BUILD_DIR"

log_info "Latest skippy-xd commit:"
cd "$TEMP_BUILD_DIR"
git log -1 --oneline
cd ..


# --- Step 3: Clean AppDir ---
log_info "Cleaning AppDir for fresh build..."

[ -d "$APP_DIR_NAME" ] && rm -rf "$APP_DIR_NAME"

mkdir -p "$APP_DIR_NAME/usr/bin"
mkdir -p "$APP_DIR_NAME/usr/lib"
mkdir -p "$APP_DIR_NAME/usr/share/skippy-xd"
mkdir -p "$APP_DIR_NAME/usr/share/man/man1"
mkdir -p "$APP_DIR_NAME/usr/share/applications"
mkdir -p "$APP_DIR_NAME/usr/share/icons/hicolor/256x256/apps"

# --- Step 4: AppRun ---
log_info "Setting up AppRun..."

cat > "$APP_DIR_NAME/AppRun" << 'APPRUN_EOF'
#!/bin/bash
# AppRun wrapper for Skippy-XD

HERE="$(dirname "$(readlink -f "${0}")")"
export PATH="${HERE}/usr/bin:${PATH}"
export LD_LIBRARY_PATH="${HERE}/usr/lib:${LD_LIBRARY_PATH}"
export XDG_CONFIG_DIRS="${HERE}/etc/xdg:${XDG_CONFIG_DIRS}"
export XDG_DATA_DIRS="${HERE}/usr/share:${XDG_DATA_DIRS}"

# Handle --help-man to display the manpage
if [ "$1" = "--help-man" ]; then
    for MANPAGE in "${HERE}/usr/share/man/man1/skippy-xd.1.gz" "${HERE}/usr/share/man/man1/skippy-xd.1"; do
        if [ -f "$MANPAGE" ]; then
            if [[ "$MANPAGE" == *.gz ]]; then
                zcat "$MANPAGE" | man -l -
            else
                man -l "$MANPAGE"
            fi
            exit $?
        fi
    done
    echo "Error: Manpage not found"
    exit 1
fi

# Handle --appimage-extract
if [ "$1" = "--appimage-extract" ]; then
    echo "Extracting..."
    exit 0
fi

# Run skippy-xd
exec "${HERE}/usr/bin/skippy-xd" "$@"
APPRUN_EOF

# --- Step 5: Build & Install ---
log_info "Building skippy-xd..."

cd "$TEMP_BUILD_DIR"
make
make DESTDIR=../${APP_DIR_NAME} install
cd ..

# --- Step 6: Copy latest rc file to user config ---
log_info "Copying latest config to user config..."

if [ -f "$TEMP_BUILD_DIR/skippy-xd.rc" ]; then
    mkdir -p ~/.config/skippy-xd
    cp "$TEMP_BUILD_DIR/skippy-xd.rc" ~/.config/skippy-xd/
    log_info "Copied skippy-xd.rc to ~/.config/skippy-xd/"
else
    log_info "No skippy-xd.rc found in source"
fi

# --- Step 7: Create .desktop file ---
log_info "Creating .desktop file..."

cat > "$APP_DIR_NAME/skippy-xd.desktop" << 'EOF'
[Desktop Entry]
Name=Skippy-XD
Comment=Expose-style window switcher for X11
Exec=skippy-xd --start-daemon
Icon=skippy-xd
Terminal=false
Type=Application
Categories=Utility;
EOF

# --- Step 8: Create placeholder icon ---
log_info "Creating placeholder icon..."

printf '\x89PNG\r\n\x1a\n\x00\x00\x00\rIHDR\x00\x00\x00\x01\x00\x00\x00\x01\x08\x06\x00\x00\x00\x1f\x15\xc4\x89\x00\x00\x00\nIDATx\x9cc\x00\x01\x00\x00\x05\x00\x01\r\n-\xb4\x00\x00\x00\x00IEND\xaeB`\x82' > "$APP_DIR_NAME/skippy-xd.png"
cp "$APP_DIR_NAME/skippy-xd.png" "$APP_DIR_NAME/usr/share/icons/hicolor/256x256/apps/skippy-xd.png"

# --- Step 9: Permissions ---
log_info "Setting permissions..."

chmod +x "${APP_DIR_NAME}/AppRun"
chmod +x "${APP_DIR_NAME}/usr/bin/skippy-xd"

# --- Step 10: Download AppImageTool ---
log_info "Downloading appimagetool..."

APPIMAGE_TOOL="appimagetool-x86_64.AppImage"

if [ -f "$APPIMAGE_TOOL" ]; then
    log_info "Using existing appimagetool..."
    chmod +x "$APPIMAGE_TOOL"
else
    wget -q --show-progress -O "$APPIMAGE_TOOL" "https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-x86_64.AppImage"
    chmod +x "$APPIMAGE_TOOL"
fi

# --- Step 11: Build AppImage ---
log_info "Building AppImage..."

mkdir -p build
./"$APPIMAGE_TOOL" "$APP_DIR_NAME" "build/Skippy-XD-x86_64.AppImage"

# --- Step 12: Cleanup ---
rm -rf "$TEMP_BUILD_DIR"
rm -f "$APPIMAGE_TOOL"

# --- Step 13: Go to build folder ---
cd build

# --- Done ---
log_info "============================================================"
log_info "  Build complete!"
log_info "  Output: build/Skippy-XD-x86_64.AppImage"
log_info "  Man page: use ./Skippy-XD-x86_64.AppImage --help-man"
log_info "  Start daemon: ./Skippy-XD-x86_64.AppImage --start-daemon"
log_info "============================================================"
ls -lh
