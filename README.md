# TABWEE T20 Bootloader Unlock

Confirmed working on **TABWEE T20** — Android 15, Unisoc UMS9230 (T606), eMMC.

> ⚠️ **This will wipe all data on your tablet. Back up everything first.**

---

## Before you start

Enable OEM Unlocking:
1. Settings → About Tablet → tap **Build Number** 7 times
2. Settings → Developer Options → turn on **OEM Unlocking**

---

## How to enter BROM Download Mode

Required at each step during the unlock process.

1. **Power off** the tablet completely
2. Hold **Volume Down**
3. **Plug in USB** while holding Volume Down
4. Screen stays black — that's correct

---

## Windows

1. [Download this repo](https://github.com/TripleU613/Tabwee-T20-Booloader-Unlock/archive/refs/heads/main.zip) and extract it
2. Install the Spreadtrum USB driver (link in [TomKing062's release notes](https://github.com/TomKing062/CVE-2022-38694_unlock_bootloader/releases/tag/1.72)) — or use [Zadig](https://zadig.akeo.ie/) to install WinUSB for the Spreadtrum device
3. Put tablet in **BROM mode** (see above)
4. Double-click **`unlock.bat`**
5. Follow the prompts — you will be asked to reconnect in BROM mode 4 times

---

## Linux

1. Install dependencies:
   ```bash
   sudo apt install wine xxd
   ```
2. [Download this repo](https://github.com/TripleU613/Tabwee-T20-Booloader-Unlock/archive/refs/heads/main.zip) and extract it
3. Put tablet in **BROM mode** (see above)
4. Run:
   ```bash
   chmod +x unlock.sh spd_dump_linux
   ./unlock.sh
   ```
5. Follow the prompts — you will be asked to reconnect in BROM mode 4 times

The script sets up USB permissions automatically (will ask for sudo password once).

---

## After unlock

Reboot to Android. In Developer Options, **OEM Unlocking** will be permanently enabled.

You can now flash a GSI. Recommended for best performance:

| GSI | Notes |
|---|---|
| **LineageOS 22.1 arm64-ab** | Lightest, fastest |
| **Evolution X arm64-ab** | Pixel UI + customisation |

Flash with:
```bash
adb reboot bootloader
fastboot flash --disable-verity --disable-verification vbmeta vbmeta.img
fastboot flash system <gsi>.img
fastboot -w
```
Then sideload **MindTheGapps Android 15 arm64** from recovery for Google apps.

---

## Credits

- [TomKing062](https://github.com/TomKing062) — CVE-2022-38694 exploit, spd_dump, unlock tools
- [ilyakurdyukov](https://github.com/ilyakurdyukov) — original spreadtrum_flash / spd_dump
