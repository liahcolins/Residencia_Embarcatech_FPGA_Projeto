@echo off
set OSSCAD=C:\OSS-CAD-SUITE
set TOP=teste_display_top
set LPF=teste_display.lpf

call "%OSSCAD%\environment.bat"
cd %~dp0

echo [1/4] Synth
yosys -p "read_verilog -sv teste_display_top.sv display_7seg.sv; synth_ecp5 -top teste_display_top -json teste_display_top.json"

echo [2/4] 
nextpnr-ecp5 --json "%TOP%.json" --textcfg "%TOP%.config" --lpf "%LPF%" --45k --package CABGA381 --speed 6

echo [3/4] Pack
ecppack --compress "%TOP%.config" "%TOP%.bit"

echo [4/4] Program (RAM)
openFPGALoader -b colorlight-i9 "%TOP%.bit"
echo === DONE ===