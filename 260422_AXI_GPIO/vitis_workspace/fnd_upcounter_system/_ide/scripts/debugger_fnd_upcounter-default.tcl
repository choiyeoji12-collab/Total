# Usage with Vitis IDE:
# In Vitis IDE create a Single Application Debug launch configuration,
# change the debug type to 'Attach to running target' and provide this 
# tcl script in 'Execute Script' option.
# Path of this script: D:\choiyeoji\260422_AXI_GPIO\vitis_workspace\fnd_upcounter_system\_ide\scripts\debugger_fnd_upcounter-default.tcl
# 
# 
# Usage with xsct:
# To debug using xsct, launch xsct and run below command
# source D:\choiyeoji\260422_AXI_GPIO\vitis_workspace\fnd_upcounter_system\_ide\scripts\debugger_fnd_upcounter-default.tcl
# 
connect -url tcp:127.0.0.1:3121
targets -set -filter {jtag_cable_name =~ "Digilent Basys3 210183B81A37A" && level==0 && jtag_device_ctx=="jsn-Basys3-210183B81A37A-0362d093-0"}
fpga -file D:/choiyeoji/260422_AXI_GPIO/vitis_workspace/fnd_upcounter/_ide/bitstream/microblaze_gpio8.bit
targets -set -nocase -filter {name =~ "*microblaze*#0" && bscan=="USER2" }
loadhw -hw D:/choiyeoji/260422_AXI_GPIO/vitis_workspace/microblaze_gpio8/export/microblaze_gpio8/hw/microblaze_gpio8.xsa -regs
configparams mdm-detect-bscan-mask 2
targets -set -nocase -filter {name =~ "*microblaze*#0" && bscan=="USER2" }
rst -system
after 3000
targets -set -nocase -filter {name =~ "*microblaze*#0" && bscan=="USER2" }
dow D:/choiyeoji/260422_AXI_GPIO/vitis_workspace/fnd_upcounter/Debug/fnd_upcounter.elf
targets -set -nocase -filter {name =~ "*microblaze*#0" && bscan=="USER2" }
con
