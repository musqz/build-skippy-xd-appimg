# Skippy-XD AppImage Build It Yourself

[Official Skippy-XD Git Repository (Felix Fung)](https://github.com/felixfung/skippy-xd)

---

This repository contains files and structure needed to create a **Skippy-XD AppImage**, an Exposé-style window switcher for X11.  
The AppImage works on most modern Linux distributions (Debian/Ubuntu, Fedora, Arch, etc.) without installation.

---

## Table of Contents
- [Prerequisites](#prerequisites)
- [Building the AppImage](#building-the-appimage)
  - [64-bit Build](#64-bit-build)
  - [32-bit Build](#32-bit-build)
- [Running the AppImage](#running-the-appimage)
- [Updating the Binary / RC File](#updating-the-binary--rc-file)
- [License](#license)

## Prerequisites

### Debian / Ubuntu
```bash
sudo apt update
sudo apt install -y git build-essential wget xz-utils squashfs-tools libfuse2
sudo apt install -y gcc-multilib g++-multilib libc6-dev-i386 lib32z1 # For 32-bit build
````

### Fedora

```bash
sudo dnf install -y git make gcc wget xz squashfs-tools fuse-libs glibc-devel.i686
```

### Arch / Manjaro

```bash
sudo pacman -S --needed git base-devel wget squashfs-tools fuse2
```

---

## Building the AppImage

1. **Clone this repository**

```bash
git clone https://github.com/musqz/build-skippy-xd-appimg.git
cd build-skippy-xd-appimg
```

2. **Download the latest upstream Skippy-XD**

```bash
git clone https://github.com/felixfung/skippy-xd.git temp_build
cd temp_build
```

3. **Build and install into the AppDir for 64-bit**

```bash
make
make DESTDIR=../skippy-xd.AppDir/usr install
```

4. **Optional: Build 32-bit version**

```bash
make clean
make CFLAGS="-m32" LDFLAGS="-m32"
make DESTDIR=../skippy-xd.AppDir-i386/usr install
```

5. **Ensure AppRun and binary permissions**

[64bit]
```bash
chmod +x ../skippy-xd.AppDir/AppRun
chmod +x ../skippy-xd.AppDir/usr/bin/skippy-xd
```

[32bit]
```
chmod +x ../skippy-xd.AppDir-i386/AppRun
chmod +x ../skippy-xd.AppDir-i386/usr/bin/skippy-xd
```

6. **Build the AppImages**

Install the tool

```
wget https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-x86_64.AppImage
chmod +x appimagetool-x86_64.AppImage
./appimagetool-x86_64.AppImage --help
```


```bash
[64bit]
./appimagetool-x86_64.AppImage skippy-xd.AppDir build/Skippy-XD-x86_64.AppImage

[32bit]
./appimagetool-i686.AppImage skippy-xd.AppDir-i386 build/Skippy-XD-i386.AppImage
```

7. **Clean up**

```bash
rm -rf temp_build
```

Now you have `build/Skippy-XD-x86_64.AppImage` or `build/Skippy-XD-i386.AppImage` ready to use.

---

## Running the AppImage

```bash
chmod +x build/Skippy-XD-*.AppImage
./build/Skippy-XD-x86_64.AppImage
# or
./build/Skippy-XD-i386.AppImage
```

* No root or installation required.
* The AppImage is portable and can be copied anywhere.

---

## Updating the Binary / RC File

* The AppImage uses the RC file installed by `make install`:

  ```
  usr/share/skippy-xd/skippy-xd.rc
  ```
* For first-time users, AppImage will pick up this RC file automatically.
* Users can override settings by copying the RC file to:

  ```
  ~/.config/skippy-xd/skippy-xd.rc
  ```
* To update the binary and RC file, re-run the **Building the AppImage** steps.

---

Start Daemon first. 

```
Skippy-xd.AppImage --start-daemon
```

[Read Felix Fung github how to use skippy-xd.](https://github.com/felixfung/skippy-xd)


## License

MIT License. See [LICENSE](LICENSE) file.
