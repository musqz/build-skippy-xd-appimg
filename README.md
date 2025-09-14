# Skippy-XD AppImage Version.

[Official Git Repository](https://github.com/felixfung/skippy-xd)

---

This repository contains a portable **Skippy-XD AppImage**, an Exposé-style window switcher for X11.  
The AppImage works on most modern Linux distributions (Debian/Ubuntu, Fedora, Arch, etc.) without installation.

---

## Table of Contents
- [Prerequisites](#prerequisites)
- [Building the AppImage](#building-the-appimage)
- [Running the AppImage](#running-the-appimage)
- [Updating the Binary](#updating-the-binary)
- [First-Time Run and Configuration](#first-time-run-and-configuration)
- [License](#license)

---

## Prerequisites

### Debian / Ubuntu
```bash
sudo apt update
sudo apt install -y git build-essential wget xz-utils squashfs-tools libfuse2
````

### Fedora

```bash
sudo dnf install -y git make gcc wget xz squashfs-tools fuse-libs
```

### Arch / Manjaro

```bash
sudo pacman -S --needed git base-devel wget squashfs-tools fuse2
```

---

## Building the AppImage

1. **Clone this repository**

```bash
git clone https://github.com/yourusername/skippy-xd-appimg.git
cd skippy-xd-appimg
```

2. **Download the latest upstream Skippy-XD**

```bash
git clone https://github.com/felixfung/skippy-xd.git temp_build
cd temp_build
make
cd ..
```

3. **Copy the new binary into the AppDir**

```bash
cp temp_build/skippy-xd skippy-xd.AppDir/usr/bin/
chmod +x skippy-xd.AppDir/usr/bin/skippy-xd
```

4. **Ensure AppRun is executable**

```bash
chmod +x skippy-xd.AppDir/AppRun
# If on Windows subsystem or downloaded with CRLF endings
dos2unix skippy-xd.AppDir/AppRun
```

5. **Build the AppImage**

```bash
./appimagetool-x86_64.AppImage skippy-xd.AppDir build/Skippy-XD.AppImage
```

6. **Clean up**

```bash
rm -rf temp_build
```

Now you have `build/Skippy-XD.AppImage` ready to use.

---

## Running the AppImage

```bash
chmod +x build/Skippy-XD.AppImage
./build/Skippy-XD.AppImage
```

* No root or installation required.
* The AppImage is portable and can be copied anywhere.

---

## Updating the Binary

To get the latest Skippy-XD version from upstream:

1. Re-run steps under **Building the AppImage**.
2. Replace the old binary in `skippy-xd.AppDir/usr/bin/`.
3. Rebuild the AppImage.

---

## First-Time Run and Configuration

* Skippy-XD uses `skippy-xd.rc` for settings.
* First-time run reads the configuration from:

```
/etc/xdg/skippy-xd.rc
```

* Users can override settings by copying it to:

```
~/.config/skippy-xd/skippy-xd.rc
```

* The AppImage will automatically pick up user-specific configuration if it exists.

---

## License

MIT License. See [LICENSE](LICENSE) file.

