#!/bin/bash
set -euo pipefail

# -----------------------------------------------------------------------------
# Skippy-XD AppImage Builder Script
# -----------------------------------------------------------------------------

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

# --- Configuration ---
TEMP_BUILD_DIR="temp_build"
APP_DIR_NAME="skippy-xd.AppDir"
BUILD_DIR="build"
GITHUB_URL="https://github.com/felixfung/skippy-xd"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_err()  { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

# --- Step 1: Install Prerequisites ---
log_info "Detecting OS and installing dependencies..."

if [ -f /etc/os-release ]; then
    . /etc/os-release
    case $ID in
        debian|ubuntu|linuxmint)
            sudo apt-get update -q
            sudo apt-get install -y \
                git build-essential wget xz-utils \
                squashfs-tools libfuse2 \
                desktop-file-utils appstream \
                libx11-dev libxft-dev libxrender-dev \
                libxcomposite-dev libxdamage-dev libxfixes-dev \
                libxext-dev libxinerama-dev \
                libpng-dev zlib1g-dev libjpeg-dev libgif-dev \
                libfreetype6-dev pkg-config
            ;;
        fedora)
            sudo dnf install -y \
                git make gcc wget xz squashfs-tools fuse-libs \
                desktop-file-utils appstream \
                libX11-devel libXft-devel libXrender-devel \
                libXcomposite-devel libXdamage-devel libXfixes-devel \
                libXext-devel libXinerama-devel \
                libpng-devel zlib-devel libjpeg-devel giflib-devel \
                freetype-devel pkg-config
            ;;
        arch|manjaro)
            sudo pacman -S --needed \
                git base-devel wget squashfs-tools fuse2 \
                desktop-file-utils appstream \
                libx11 libxft libxrender libxcomposite \
                libxdamage libxfixes libxext libxinerama \
                libpng zlib libjpeg giflib freetype2 pkgconf
            ;;
        *)
            log_warn "Unknown distro '$ID' — install build deps manually if needed"
            ;;
    esac
fi

# --- Step 2: Clone Source ---
log_info "Setting up build directories..."
[ -d "$TEMP_BUILD_DIR" ] && rm -rf "$TEMP_BUILD_DIR"

log_info "Fetching latest skippy-xd source..."
git clone --depth 1 "$GITHUB_URL".git "$TEMP_BUILD_DIR"

cd "$TEMP_BUILD_DIR"
log_info "Latest commit: $(git log -1 --oneline)"

# --- Step 3: Read Version (pure bash, no awk/sed ordering issues) ---
if [ ! -f version.txt ]; then
    log_err "version.txt not found in repo"
fi

read -r raw_version < version.txt          # read first line only
raw_version="${raw_version%% *}"           # strip everything after first space  (e.g. "(2026.1.4) - 'Brainrot 67' Edition")
VERSION="${raw_version#v}"                 # strip leading 'v'

if [ -z "$VERSION" ]; then
    log_err "Could not parse version from version.txt (got: '$raw_version')"
fi

log_info "Version: $VERSION"

cd ..

# --- Step 4: Clean & Create AppDir ---
log_info "Cleaning AppDir..."
[ -d "$APP_DIR_NAME" ] && rm -rf "$APP_DIR_NAME"

mkdir -p \
    "$APP_DIR_NAME/usr/bin" \
    "$APP_DIR_NAME/usr/lib" \
    "$APP_DIR_NAME/usr/share/skippy-xd" \
    "$APP_DIR_NAME/usr/share/man/man1" \
    "$APP_DIR_NAME/usr/share/applications" \
    "$APP_DIR_NAME/usr/share/icons/hicolor/256x256/apps" \
    "$APP_DIR_NAME/usr/share/metainfo"

# --- Step 5: AppRun ---
log_info "Setting up AppRun..."

cat > "$APP_DIR_NAME/AppRun" << 'APPRUN_EOF'
#!/bin/bash
HERE="$(dirname "$(readlink -f "${0}")")"
export PATH="${HERE}/usr/bin:${PATH}"
export LD_LIBRARY_PATH="${HERE}/usr/lib:${LD_LIBRARY_PATH}"
export XDG_CONFIG_DIRS="${HERE}/etc/xdg:${XDG_CONFIG_DIRS}"
export XDG_DATA_DIRS="${HERE}/usr/share:${XDG_DATA_DIRS}"

# Man page support
if [ "$1" = "--help-man" ]; then
    for MANPAGE in \
        "${HERE}/usr/share/man/man1/skippy-xd.1.gz" \
        "${HERE}/usr/share/man/man1/skippy-xd.1"; do
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

exec "${HERE}/usr/bin/skippy-xd" "$@"
APPRUN_EOF

chmod +x "$APP_DIR_NAME/AppRun"

# --- Step 6: Build & Install ---
log_info "Building skippy-xd..."

cd "$TEMP_BUILD_DIR"
make PREFIX=/usr VERSION_SKIPPYXD="$VERSION"
make PREFIX=/usr DESTDIR="../${APP_DIR_NAME}" install
cd ..

chmod +x "${APP_DIR_NAME}/usr/bin/skippy-xd"

# --- Step 7: Copy rc to user config ---
if [ -f "$TEMP_BUILD_DIR/skippy-xd.rc" ]; then
    mkdir -p ~/.config/skippy-xd
    cp "$TEMP_BUILD_DIR/skippy-xd.rc" ~/.config/skippy-xd/
    log_info "Copied skippy-xd.rc to ~/.config/skippy-xd/"
fi

# --- Step 8: Desktop file ---
# Required by AppImage hub even for daemons — kept minimal and valid
log_info "Creating desktop file..."

cat > "$APP_DIR_NAME/usr/share/applications/skippy-xd.desktop" << EOF
[Desktop Entry]
Type=Application
Name=Skippy-XD
GenericName=Window Switcher
Comment=Expose-style window switcher daemon for X11
Exec=skippy-xd --start-daemon
Icon=skippy-xd
Terminal=false
Categories=Utility;X-Daemon;
Keywords=expose;window;switcher;daemon;x11;
NoDisplay=true
EOF

# Symlink to AppDir root (required by appimagetool)
cp "$APP_DIR_NAME/usr/share/applications/skippy-xd.desktop" "$APP_DIR_NAME/skippy-xd.desktop"

# Validate desktop file
if command -v desktop-file-validate &>/dev/null; then
    desktop-file-validate "$APP_DIR_NAME/skippy-xd.desktop" \
        && log_info "Desktop file: OK" \
        || log_warn "Desktop file validation warnings (check above)"
fi

# --- Step 9: Icon (256x256 valid PNG — minimal but real) ---
# Skippy-XD is a daemon with no GUI window, so we create a clean
# symbolic icon using Python (available on all target systems)
log_info "Generating icon..."

python3 - << 'PYEOF'
import struct, zlib

def make_png(size, bg=(30,30,30), fg=(180,180,180)):
    """Generate a minimal valid 256x256 PNG with an X symbol."""
    def chunk(name, data):
        c = zlib.crc32(name + data) & 0xffffffff
        return struct.pack('>I', len(data)) + name + data + struct.pack('>I', c)

    pixels = []
    for y in range(size):
        row = []
        for x in range(size):
            # Draw an X pattern representing the expose switcher
            margin = size // 8
            thickness = size // 10
            dx = abs(x - y)
            dy = abs(x - (size - 1 - y))
            on_diag = (dx < thickness and margin < x < size - margin) or \
                      (dy < thickness and margin < x < size - margin)
            # Outer circle border
            cx, cy = size // 2, size // 2
            r = size // 2 - margin // 2
            dist = ((x - cx)**2 + (y - cy)**2) ** 0.5
            on_circle = abs(dist - r) < thickness // 2
            if on_diag or on_circle:
                row += list(fg) + [255]
            else:
                row += list(bg) + [255]
        pixels.append(bytes([0] + row))  # filter byte

    raw = zlib.compress(b''.join(pixels))

    png  = b'\x89PNG\r\n\x1a\n'
    png += chunk(b'IHDR', struct.pack('>IIBBBBB', size, size, 8, 2, 0, 0, 0)
                 .replace(struct.pack('>IIBBBBB', size, size, 8, 2, 0, 0, 0),
                          struct.pack('>II', size, size) + bytes([8, 2, 0, 0, 0])))
    png += chunk(b'IDAT', raw)
    png += chunk(b'IEND', b'')
    return png

# Write correct IHDR manually
import io

def write_png(filename, size=256):
    w = h = size
    raw_rows = []
    margin = size // 8
    thickness = max(size // 12, 3)
    fg = (160, 160, 160)
    bg = (30, 30, 30)
    for y in range(h):
        row = bytearray()
        row.append(0)  # filter none
        for x in range(w):
            cx, cy = w // 2, h // 2
            dx = abs(x - y)
            dy = abs(x - (h - 1 - y))
            in_margin = margin <= x <= w - margin and margin <= y <= h - margin
            on_diag = in_margin and (dx < thickness or dy < thickness)
            dist = ((x - cx)**2 + (y - cy)**2) ** 0.5
            r = w // 2 - margin // 2
            on_circle = abs(dist - r) < thickness
            if on_diag or on_circle:
                row += bytes(fg)
            else:
                row += bytes(bg)
        raw_rows.append(bytes(row))

    compressed = zlib.compress(b''.join(raw_rows), 9)

    def mk_chunk(tag, data):
        crc = zlib.crc32(tag + data) & 0xffffffff
        return struct.pack('>I', len(data)) + tag + data + struct.pack('>I', crc)

    with open(filename, 'wb') as f:
        f.write(b'\x89PNG\r\n\x1a\n')
        f.write(mk_chunk(b'IHDR',
            struct.pack('>IIBBBBB', w, h, 8, 2, 0, 0, 0)))
        f.write(mk_chunk(b'IDAT', compressed))
        f.write(mk_chunk(b'IEND', b''))

write_png('skippy-xd.AppDir/skippy-xd.png')
write_png('skippy-xd.AppDir/usr/share/icons/hicolor/256x256/apps/skippy-xd.png')
print("Icon generated OK")
PYEOF

# --- Step 10: AppStream Metainfo ---
# Email NOT required — only id, name, summary, licenses, description needed
log_info "Creating AppStream metainfo..."

cat > "$APP_DIR_NAME/usr/share/metainfo/io.github.felixfung.skippy-xd.appdata.xml" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<component type="console-application">
  <id>io.github.felixfung.skippy-xd</id>
  <name>Skippy-XD</name>
  <summary>Exposé-style window switcher daemon for X11</summary>
  <metadata_license>FSFAP</metadata_license>
  <project_license>GPL-2.0-or-later</project_license>
  <description>
    <p>
      Skippy-XD is a full-screen Exposé-like task switcher for the X Window System.
      It runs as a lightweight daemon and displays all open windows simultaneously,
      allowing fast switching between them. It is designed for use with minimal
      window managers that do not provide their own expose functionality.
    </p>
    <p>
      As a daemon, skippy-xd has no persistent graphical interface of its own —
      it activates on demand via a configurable hotkey or command.
    </p>
  </description>
  <url type="homepage">https://github.com/felixfung/skippy-xd</url>
  <url type="bugtracker">https://github.com/felixfung/skippy-xd/issues</url>
  <developer id="io.github.felixfung">
    <name>felixfung</name>
  </developer>
  <releases>
    <release version="${VERSION}" date="$(date +%Y-%m-%d)"/>
  </releases>
  <provides>
    <binary>skippy-xd</binary>
  </provides>
  <categories>
    <category>Utility</category>
  </categories>
  <content_rating type="oars-1.1"/>
</component>
EOF

# Validate metainfo if appstreamcli available
if command -v appstreamcli &>/dev/null; then
    appstreamcli validate --no-net \
        "$APP_DIR_NAME/usr/share/metainfo/io.github.felixfung.skippy-xd.appdata.xml" \
        && log_info "Metainfo: OK" \
        || log_warn "Metainfo validation warnings (check above)"
fi

# --- Step 11: Download AppImageTool ---
APPIMAGE_TOOL="appimagetool-x86_64.AppImage"

if [ ! -f "$APPIMAGE_TOOL" ]; then
    log_info "Downloading appimagetool..."
    wget -q --show-progress \
        -O "$APPIMAGE_TOOL" \
        "https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-x86_64.AppImage"
fi
chmod +x "$APPIMAGE_TOOL"

# --- Step 12: Run appdir-lint if available ---
APPDIR_LINT="appdir-lint.sh"
if [ ! -f "$APPDIR_LINT" ]; then
    wget -q -O "$APPDIR_LINT" \
        "https://raw.githubusercontent.com/AppImageCommunity/appimage-builder/master/appimagebuilder/modules/lint/appdir_lint.sh" \
        2>/dev/null || true
fi
if [ -f "$APPDIR_LINT" ] && [ -s "$APPDIR_LINT" ]; then
    chmod +x "$APPDIR_LINT"
    bash "$APPDIR_LINT" "$APP_DIR_NAME" \
        && log_info "appdir-lint: OK" \
        || log_warn "appdir-lint warnings (check above)"
fi

# --- Step 13: Build AppImage ---
log_info "Building AppImage..."
mkdir -p "$BUILD_DIR"

# Constant URL-friendly name (no version in base name) + versioned output
OUTPUT_NAME="${BUILD_DIR}/Skippy-xd-${VERSION}-x86_64.AppImage"

ARCH=x86_64 ./"$APPIMAGE_TOOL" "$APP_DIR_NAME" "$OUTPUT_NAME"

# --- Step 14: Cleanup ---
log_info "Cleaning up..."
rm -rf "$TEMP_BUILD_DIR"
rm -f "$APPIMAGE_TOOL" "$APPDIR_LINT" 2>/dev/null || true

# --- Done ---
echo ""
log_info "============================================================"
log_info "  Build complete!"
log_info "  Output: $OUTPUT_NAME"
log_info "============================================================"
ls -lh "$BUILD_DIR"
