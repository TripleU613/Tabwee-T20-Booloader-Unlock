# TABWEE T20 Bootloader Unlock

Confirmed working on **TABWEE T20** — Android 15, Unisoc UMS9230 (T606), eMMC.

> ⚠️ **This will wipe all data on your tablet. Back up everything first.**

---

## Before you start

Enable OEM Unlocking:
1. Settings → About Tablet → tap **Build Number** 7 times
2. Settings → Developer Options → turn on **OEM Unlocking**

---

## BROM Download Mode

Required at each step during the unlock.

1. **Power off** the tablet completely
2. Hold **Volume Down**
3. **Plug in USB** while holding Volume Down
4. Screen stays black — that's correct

---

## Windows

1. Install the Spreadtrum USB driver — or use [Zadig](https://zadig.akeo.ie/) to install WinUSB for the Spreadtrum device
2. Put tablet in **BROM mode**
3. Double-click **`unlock.bat`** and follow the prompts

---

## Linux

1. Install dependencies:
   ```bash
   sudo apt install wine xxd
   ```
2. Put tablet in **BROM mode**
3. Run:
   ```bash
   chmod +x unlock.sh spd_dump_linux
   ./unlock.sh
   ```

The script handles USB permissions automatically (asks for sudo once).

---

## Credits

- [TomKing062](https://github.com/TomKing062) — CVE-2022-38694 exploit, spd_dump, unlock tools
- [ilyakurdyukov](https://github.com/ilyakurdyukov) — original spreadtrum_flash / spd_dump
