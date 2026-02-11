# TABWEE T20 Bootloader Unlock Guide

**Confirmed working** on TABWEE T20 (Unisoc UMS9230 / T606, Android 15, eMMC storage)

Uses the [CVE-2022-38694](https://github.com/TomKing062/CVE-2022-38694_unlock_bootloader) exploit by TomKing062.

> **⚠️ WARNING:** This will wipe all data on your tablet. Back up everything first.
> You are doing this at your own risk. Nobody is responsible for a bricked device except you.

---

## Requirements

- USB cable
- ADB + Fastboot installed
- OEM Unlock enabled in Developer Options (Settings → About → tap Build Number 7x → Developer Options → OEM Unlocking ON)

---

## Step 0 — Download the tools

From [TomKing062's releases (v1.72)](https://github.com/TomKing062/CVE-2022-38694_unlock_bootloader/releases/tag/1.72), download:

```
ums9230_universal_unlock_EMMC.zip
```

Extract it to a folder, e.g. `C:\tabwee-unlock\` (Windows) or `~/tabwee-unlock/` (Linux).

---

## How to enter BROM Download Mode

This is required for every step below.

1. **Power off** the tablet completely
2. Hold **Volume Down**
3. Plug in USB while still holding Volume Down
4. The tablet screen stays off — that's correct
5. On Windows: Device Manager should show a `Spreadtrum` device
   On Linux: `lsusb` should show `ID 1782:xxxx`

---

## WINDOWS Guide

### Install USB driver

Download the official Spreadtrum USB driver from the link in the TomKing062 release notes and install it.
Alternatively: use [Zadig](https://zadig.akeo.ie/) to install a WinUSB driver for the Spreadtrum device.

### Run the unlock

1. Extract `ums9230_universal_unlock_EMMC.zip` to `C:\tabwee-unlock\`
2. Put tablet in BROM Download Mode (see above)
3. Open Command Prompt in `C:\tabwee-unlock\`
4. Run:
   ```
   unlock_autopatch_9230.bat
   ```
5. Follow the prompts — the script will:
   - Dump your `splloader` and `uboot`
   - Patch the SPL
   - Flash the unlock payload
   - Ask you to reconnect in BROM mode a few times (just unplug, power off, Vol Down + plug)
   - Verify unlock via `miscdata`
   - Restore your original SPL and uboot

6. When done, reboot to Android and verify in **Developer Options** — OEM Unlocking should now be greyed out / permanently enabled

---

## LINUX Guide

### Install dependencies

```bash
sudo apt install git gcc libusb-1.0-0-dev wine xxd
```

### Set up USB permissions

```bash
echo 'SUBSYSTEM=="usb", ATTRS{idVendor}=="1782", MODE="0666", GROUP="plugdev"
SUBSYSTEM=="usb", ATTRS{idVendor}=="0525", MODE="0666", GROUP="plugdev"' | sudo tee /etc/udev/rules.d/99-unisoc.rules

sudo udevadm control --reload-rules && sudo udevadm trigger
```

### Build spd_dump with exec_addr support (TomKing062 fork)

```bash
git clone --depth=1 https://github.com/TomKing062/spreadtrum_flash.git
cd spreadtrum_flash
make
cp spd_dump ../tabwee-unlock/
cd ..
```

### Prepare the unlock files

```bash
mkdir ~/tabwee-unlock
cd ~/tabwee-unlock
# Copy ums9230_universal_unlock_EMMC.zip here, then:
unzip ums9230_universal_unlock_EMMC.zip
```

### Run the unlock — Step by step

All steps require the tablet in **BROM Download Mode** (Vol Down + plug USB).

#### Step 1 — Dump SPL and uboot, erase splloader slots

```bash
cd ~/tabwee-unlock

./spd_dump --wait 300 exec_addr 0x65015f08 \
  fdl fdl1-dl.bin 0x65000800 \
  fdl fdl2-dl.bin 0x9efffe00 \
  exec r splloader r uboot e splloader e splloader_bak reset
```

When done, patch the dumped SPL and rename files:

```bash
wine ./gen_spl-unlock.exe splloader.bin
mv splloader.bin u-boot-spl-16k-sign.bin
wine ./chsize.exe uboot.bin
mv uboot.bin uboot_bak.bin
```

You should now have `spl-unlock.bin`, `u-boot-spl-16k-sign.bin`, and `uboot_bak.bin`.

#### Step 2 — Flash unlock cboot (put device back in BROM mode)

```bash
./spd_dump --wait 300 exec_addr 0x65015f08 \
  fdl fdl1-dl.bin 0x65000800 \
  fdl fdl2-dl.bin 0x9efffe00 \
  exec w uboot fdl2-cboot.bin reset
```

#### Step 3 — Run the unlock exploit (put device back in BROM mode)

```bash
./spd_dump --wait 300 exec_addr 0x65015f08 \
  fdl spl-unlock.bin 0x65000800
```

Device will disconnect/reboot — that's normal.

#### Step 4 — Verify unlock (put device back in BROM mode)

```bash
./spd_dump --wait 300 exec_addr 0x65015f08 \
  fdl fdl1-dl.bin 0x65000800 \
  fdl fdl2-dl.bin 0x9efffe00 \
  exec verbose 2 read_part miscdata 8192 64 m.bin reset

xxd m.bin
```

- **All zeros** = still locked (run Step 3 again)
- **Non-zero data (32 char string + hashes)** = **UNLOCKED ✓**

#### Step 5 — Restore original SPL, uboot, wipe misc (put device back in BROM mode)

```bash
./spd_dump --wait 300 exec_addr 0x65015f08 \
  fdl fdl1-dl.bin 0x65000800 \
  fdl fdl2-dl.bin 0x9efffe00 \
  exec r boot \
  w splloader u-boot-spl-16k-sign.bin \
  w uboot uboot_bak.bin \
  w misc misc-wipe.bin reset
```

---

## After unlock — what next?

The bootloader is unlocked. You can now flash a GSI.

### Recommended GSIs for TABWEE T20 (arm64-ab, VNDK 33)

| GSI | Best for |
|---|---|
| **LineageOS 22.1 (arm64-ab)** | Lightest, fastest, best battery |
| **Evolution X (arm64-ab)** | Pixel UI + customization |
| **Project Elixir (arm64-ab)** | Minimal Pixel-like |

Download from their respective official sites, flash with:

```bash
adb reboot bootloader
fastboot flash --disable-verity --disable-verification vbmeta vbmeta.img
fastboot flash system lineage-22.1-*-arm64-ab.img
fastboot -w
# Reboot to recovery, sideload GApps (MindTheGapps Android 15 arm64)
adb sideload MindTheGapps-15.0.0-arm64-*.zip
```

---

## Credits

- **[TomKing062](https://github.com/TomKing062)** — CVE-2022-38694 exploit, spd_dump fork, unlock zips
- **[ilyakurdyukov](https://github.com/ilyakurdyukov)** — original spreadtrum_flash / spd_dump
- Tested and documented on TABWEE T20 running Android 15 (UMS9230, eMMC)
