#!/bin/bash
# TABWEE T20 Bootloader Unlock
# CVE-2022-38694 / Unisoc UMS9230 / eMMC

set -e
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$DIR"

SPD="$DIR/spd_dump_linux"
EXEC_ADDR="0x65015f08"
FDL1_ADDR="0x65000800"
FDL2_ADDR="0x9efffe00"

echo ""
echo "============================================"
echo " TABWEE T20 Bootloader Unlock"
echo " CVE-2022-38694 / Unisoc UMS9230"
echo "============================================"
echo ""
echo " WARNING: This will wipe all data on your tablet!"
echo " Make sure you have backed up everything."
echo ""
read -p " Press Enter to continue..."

# Check dependencies
if ! command -v wine &>/dev/null; then
    echo "[!] wine not found. Install with: sudo apt install wine"
    exit 1
fi

# Set up udev rules if needed
if [ ! -f /etc/udev/rules.d/99-unisoc.rules ]; then
    echo ""
    echo "[*] Setting up USB permissions (needs sudo)..."
    echo 'SUBSYSTEM=="usb", ATTRS{idVendor}=="1782", MODE="0666", GROUP="plugdev"
SUBSYSTEM=="usb", ATTRS{idVendor}=="0525", MODE="0666", GROUP="plugdev"' | sudo tee /etc/udev/rules.d/99-unisoc.rules
    sudo udevadm control --reload-rules && sudo udevadm trigger
    echo "[+] udev rules set"
fi

brom_prompt() {
    echo ""
    echo " --- PUT TABLET IN BROM MODE ---"
    echo " 1. Power off tablet completely"
    echo " 2. Hold Volume Down"
    echo " 3. Plug in USB while holding Volume Down"
    echo " 4. Screen stays black - that is correct"
    echo ""
    read -p " Press Enter when ready..."
}

# ── STEP 1 ──────────────────────────────────────────
echo ""
echo "[STEP 1/4] Dump SPL + uboot, erase splloader slots"
brom_prompt

"$SPD" --wait 300 exec_addr $EXEC_ADDR \
    fdl fdl1-dl.bin $FDL1_ADDR \
    fdl fdl2-dl.bin $FDL2_ADDR \
    exec r splloader r uboot e splloader e splloader_bak reset

if [ ! -f splloader.bin ]; then
    echo "[!] ERROR: splloader.bin not found. Device not detected properly."
    exit 1
fi

echo ""
echo "[*] Patching SPL..."
wine "$DIR/gen_spl-unlock.exe" splloader.bin 2>/dev/null
mv splloader.bin u-boot-spl-16k-sign.bin
wine "$DIR/chsize.exe" uboot.bin 2>/dev/null
mv uboot.bin uboot_bak.bin
echo "[+] spl-unlock.bin created, originals backed up"

# ── STEP 2 ──────────────────────────────────────────
echo ""
echo "[STEP 2/4] Flash unlock payload to uboot"
brom_prompt

"$SPD" --wait 300 exec_addr $EXEC_ADDR \
    fdl fdl1-dl.bin $FDL1_ADDR \
    fdl fdl2-dl.bin $FDL2_ADDR \
    exec w uboot fdl2-cboot.bin reset

sleep 5

# ── STEP 3 ──────────────────────────────────────────
echo ""
echo "[STEP 3/4] Run unlock exploit"
brom_prompt

"$SPD" --wait 300 exec_addr $EXEC_ADDR \
    fdl spl-unlock.bin $FDL1_ADDR || true

echo ""
echo "[*] Tablet rebooting - that is normal. Waiting 8 seconds..."
sleep 8

# ── STEP 4 ──────────────────────────────────────────
echo ""
echo "[STEP 4/4] Verify unlock + restore original partitions"
brom_prompt

"$SPD" --wait 300 exec_addr $EXEC_ADDR \
    fdl fdl1-dl.bin $FDL1_ADDR \
    fdl fdl2-dl.bin $FDL2_ADDR \
    exec verbose 2 read_part miscdata 8192 64 m.bin \
    r boot \
    w splloader u-boot-spl-16k-sign.bin \
    w uboot uboot_bak.bin \
    w misc misc-wipe.bin reset

echo ""
echo "[*] miscdata content (should NOT be all zeros if unlocked):"
xxd m.bin

echo ""
echo "============================================"
echo " DONE!"
echo " Reboot tablet to Android."
echo " Check Developer Options — OEM Unlocking"
echo " should now be permanently enabled."
echo "============================================"
echo ""
