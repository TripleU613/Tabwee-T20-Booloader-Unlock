@echo off
title TABWEE T20 Bootloader Unlock
color 0A
echo.
echo  ============================================
echo   TABWEE T20 Bootloader Unlock
echo   CVE-2022-38694 / Unisoc UMS9230
echo  ============================================
echo.
echo  WARNING: This will wipe all data on your tablet!
echo  Make sure you have backed up everything.
echo.
pause

:STEP1
echo.
echo  [STEP 1/4] Dump SPL + uboot, erase splloader slots
echo.
echo  --- PUT TABLET IN BROM MODE NOW ---
echo  1. Power off tablet completely
echo  2. Hold Volume Down
echo  3. Plug in USB while holding Volume Down
echo  4. Screen stays black - that is correct
echo.
pause

spd_dump.exe --wait 300 exec_addr 0x65015f08 fdl fdl1-dl.bin 0x65000800 fdl fdl2-dl.bin 0x9efffe00 exec r splloader r uboot e splloader e splloader_bak reset

if not exist splloader.bin (
    echo.
    echo  ERROR: splloader.bin not found. Device not detected.
    echo  Check USB driver and try again.
    pause
    exit /b 1
)

echo.
echo  Patching SPL...
gen_spl-unlock.exe splloader.bin
rename splloader.bin u-boot-spl-16k-sign.bin
chsize.exe uboot.bin
rename uboot.bin uboot_bak.bin
echo  Done. spl-unlock.bin created.

:STEP2
echo.
echo  [STEP 2/4] Flash unlock payload to uboot
echo.
echo  --- PUT TABLET IN BROM MODE AGAIN ---
echo  Power off, hold Volume Down, plug USB
echo.
pause

spd_dump.exe --wait 300 exec_addr 0x65015f08 fdl fdl1-dl.bin 0x65000800 fdl fdl2-dl.bin 0x9efffe00 exec w uboot fdl2-cboot.bin reset

timeout /t 5 /nobreak >nul

:STEP3
echo.
echo  [STEP 3/4] Run unlock exploit
echo.
echo  --- PUT TABLET IN BROM MODE AGAIN ---
echo  Power off, hold Volume Down, plug USB
echo.
pause

spd_dump.exe --wait 300 exec_addr 0x65015f08 fdl spl-unlock.bin 0x65000800

echo.
echo  Tablet will reboot - that is normal.
timeout /t 8 /nobreak >nul

:STEP4
echo.
echo  [STEP 4/4] Verify unlock + restore original partitions
echo.
echo  --- PUT TABLET IN BROM MODE AGAIN ---
echo  Power off, hold Volume Down, plug USB
echo.
pause

spd_dump.exe --wait 300 exec_addr 0x65015f08 fdl fdl1-dl.bin 0x65000800 fdl fdl2-dl.bin 0x9efffe00 exec verbose 2 read_part miscdata 8192 64 m.bin r boot w splloader u-boot-spl-16k-sign.bin w uboot uboot_bak.bin w misc misc-wipe.bin reset

echo.
echo  miscdata content (should NOT be all zeros if unlocked):
certutil -encodehex m.bin nul 4 2>nul || type m.bin

echo.
echo  ============================================
echo   DONE!
echo   Reboot tablet to Android.
echo   Check Developer Options - OEM Unlocking
echo   should now be permanently enabled.
echo  ============================================
echo.
pause
