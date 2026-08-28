@echo off
echo ========================================
echo  Starting FPGA Simulation (ModelSim)
echo ========================================

:: 编译所有 RTL 文件和 Testbench
vlog ../rtl/*.v ./tb_top.v -work work

:: 启动仿真并运行 500us（或者用 -all 无限运行）
vsim -c -do "run 500us; quit" tb_top

:: 如果安装了 GTKWave，可自动打开波形
:: gtkwave wave.vcd

echo ========================================
echo  Simulation Complete. Check wave.vcd
pause
