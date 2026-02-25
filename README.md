
# Automatic skippy-xd AppImage Builder 
(64 bit only)

Build the latest Skippy-XD as a portable AppImage.

[Skippy-XD by Felix Fung](https://github.com/felixfung/skippy-xd)

---

## What is this?

This script automates building the latest Skippy-XD from source and packaging it as an AppImage. 

No manual steps required—just run it and get your AppImage.

## Prerequisites 


### Debian/Ubuntu
```bash
sudo apt update && sudo apt install -y git build-essential wget xz-utils squashfs-tools libfuse2
```

### Fedora
```bash
sudo dnf install -y git make gcc wget xz squashfs-tools fuse-libs
```

### Arch/Manjaro
```bash
sudo pacman -S --needed git base-devel wget squashfs-tools fuse2
```

# Building Skippy-XD-x86_64.AppImage

```
git clone https://github.com/musqz/build-skippy-xd-appimg.git
cd build-skippy-xd-appimg
chmod +x build-skippy-xd-appimg.sh
./build-skippy-xd-appimg.sh
```

Script will ask for confirmation, then build. Output: build/Skippy-XD-x86_64.AppImage

## Usage
Make Executable

```
chmod +x Skippy-XD-x86_64.AppImage
```

#### View Manpage

```
./Skippy-XD-x86_64.AppImage --help-man

```

#### Extract (for debugging)

```
./Skippy-XD-x86_64.AppImage --appimage-extract
```

How It Works

    Detects your OS and installs build dependencies
    Clones the latest Skippy-XD from felixfung/skippy-xd
    Builds from source
    Creates AppDir structure (AppRun, .desktop, icon, manpage)
    Packages everything into a single AppImage

Features

    Always up-to-date: Builds from latest GitHub commit
    Portable: No installation needed
    Manpage included: Use --help-man to view man page
    Auto-cleanup: Removes temporary build files

License

MIT License. See LICENSE file.
