# Skippy-XD AppImage Build Instructions

This guide explains how to build the Skippy-XD AppImage for Linux manually, including dependencies for Debian/Ubuntu, Arch, and Fedora.

---

## Prerequisites

### Debian/Ubuntu (x86_64)

```bash
sudo dpkg --add-architecture i386  # for 32-bit builds
sudo apt update
sudo apt install -y wget xz-utils squashfs-tools libfuse2:i386 libc6:i386 libstdc++6:i386
````

### Arch Linux / Manjaro

```bash
sudo pacman -Syu --needed wget squashfs-tools fuse2
```

### Fedora

```bash
sudo dnf install -y wget squashfs-tools fuse
```

---

## Get Appimagetool

Download the latest AppImageKit `appimagetool` for your architecture:

```bash
wget -q "https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-x86_64.AppImage"
chmod +x appimagetool-x86_64.AppImage
mv appimagetool-x86_64.AppImage ./appimagetool
```

For 32-bit:

```bash
wget -q "https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-i686.AppImage"
chmod +x appimagetool-i686.AppImage
mv appimagetool-i686.AppImage ./appimagetool
```

---

## Prepare AppDir

Ensure your `skippy-xd.AppDir` contains the following structure:

```
skippy-xd.AppDir/
├── AppRun
├── skippy-xd.desktop
├── skippy-xd.png
└── usr/
    ├── bin/skippy-xd
    ├── lib/  # required libraries
    └── share/
        ├── applications/skippy-xd.desktop
        ├── icons/hicolor/256x256/apps/skippy-xd.png
        └── metainfo/org.felixfung.SkippyXD.desktop.appdata.xml
```

Make binaries executable:

```bash
chmod +x skippy-xd.AppDir/AppRun
chmod +x skippy-xd.AppDir/usr/bin/skippy-xd
```

> **Note:** If the AppRun script was edited on Windows, run `dos2unix AppRun` to fix line endings.

---

## Build the AppImage

Create a build folder:

```bash
mkdir -p build
```

Build the AppImage:

### 64-bit

```bash
./appimagetool skippy-xd.AppDir build/Skippy-XD-x86_64.AppImage
```

### 32-bit

```bash
./appimagetool skippy-xd.AppDir build/Skippy-XD-i386.AppImage
```

---

## Running the AppImage

```bash
./build/Skippy-XD-x86_64.AppImage
```

* On first run, a default configuration is copied from `/etc/xdg/skippy-xd.rc` to:

```
$XDG_CONFIG_HOME/skippy-xd/skippy-xd.rc
```

* Users can edit their own configuration file to customize shortcuts and settings.

---

## Notes

* Ensure all required libraries are bundled in `usr/lib/` for maximum portability.
* The `skippy-xd.png` icon must be in the AppDir root and referenced in `.desktop` without the `.png` extension.
* This workflow produces AppImages compatible with multiple Linux distributions (Debian, Ubuntu, Arch, Fedora).
