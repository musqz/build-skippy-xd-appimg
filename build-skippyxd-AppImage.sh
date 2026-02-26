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
echo "    4. Copy latest skippy-xd.rc to ~/.config/skippy-xd/"
echo ""
echo "  Press ENTER to continue or Ctrl+C to cancel..."
echo "============================================================"
read -r

set -e

# --- Configuration ---
TEMP_BUILD_DIR="temp_build"
APP_DIR_NAME="skippy-xd.AppDir"
BUILD_DIR="build"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }

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

if [ -d "$TEMP_BUILD_DIR" ]; then
    rm -rf "$TEMP_BUILD_DIR"
fi

# Clone source
log_info "Fetching latest skippy-xd source..."
git clone --depth 1 https://github.com/felixfung/skippy-xd.git "$TEMP_BUILD_DIR"

cd "$TEMP_BUILD_DIR"
log_info "Latest commit: $(git log -1 --oneline)"

# Version
if [ -f version.txt ]; then
    VERSION=$(head -n1 version.txt | sed 's/^v//' | awk '{print $1}')
    log_info "Version: $VERSION"
else
    log_warn "version.txt not found"
    VERSION="unknown"
fi

cd ..

# --- Step 3: Clean AppDir ---
log_info "Cleaning AppDir..."

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

if [ "$1" = "--appimage-extract" ]; then
    echo "Extracting..."
    exit 0
fi

exec "${HERE}/usr/bin/skippy-xd" "$@"
APPRUN_EOF

# --- Step 5: Build & Install ---
log_info "Building skippy-xd..."

cd "$TEMP_BUILD_DIR"
make
make DESTDIR=../${APP_DIR_NAME} install
cd ..

# --- Step 6: Copy rc file to user config ---
if [ -f "$TEMP_BUILD_DIR/skippy-xd.rc" ]; then
    mkdir -p ~/.config/skippy-xd
    cp "$TEMP_BUILD_DIR/skippy-xd.rc" ~/.config/skippy-xd/
    log_info "Copied skippy-xd.rc to ~/.config/skippy-xd/"
fi

# --- Step 7: Create .desktop file ---
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
printf '\x89PNG\r\n\x1a\n\x00\x00\x00\rIHDR\x00\x00\x00\x01\x00\x00\x00\x01\x08\x06\x00\x00\x00\x1f\x15\xc4\x89\x00\x00\x00\nIDATx\x9cc\x00\x01\x00\x00\x05\x00\x01\r\n-\xb4\x00\x00\x00\x00IEND\xaeB`\x82' > "$APP_DIR_NAME/skippy-xd.png"
cp "$APP_DIR_NAME/skippy-xd.png" "$APP_DIR_NAME/usr/share/icons/hicolor/256x256/apps/skippy-xd.png"

# --- Step 9: Permissions ---
chmod +x "${APP_DIR_NAME}/AppRun"
chmod +x "${APP_DIR_NAME}/usr/bin/skippy-xd"

# --- Step 10: Download AppImageTool ---
APPIMAGE_TOOL="appimagetool-x86_64.AppImage"

if [ -f "$APPIMAGE_TOOL" ]; then
    chmod +x "$APPIMAGE_TOOL"
else
    wget -q --show-progress -O "$APPIMAGE_TOOL" "https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-x86_64.AppImage"
    chmod +x "$APPIMAGE_TOOL"
fi

# --- Step 11: Build AppImage ---
mkdir -p build

OUTPUT_NAME="build/Skippy-xd-${VERSION}-x86_64.AppImage"

./"$APPIMAGE_TOOL" "$APP_DIR_NAME" "$OUTPUT_NAME"

# --- Step 12: Cleanup ---
rm -rf "$TEMP_BUILD_DIR"
rm -f "$APPIMAGE_TOOL"

cd build

# --- Done ---
log_info "============================================================"
log_info "  Build complete!"
log_info "  Output: $OUTPUT_NAME"
log_info "============================================================"
ls -lh
