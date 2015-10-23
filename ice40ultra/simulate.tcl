
proc com {} {
	 set fileset [list \
							../utils.vhd  \
							../components.vhd 	  \
							../alu.vhd 				  \
							../avalon_master.vhd	  \
							../branch_unit.vhd	  \
							../decode.vhd 			  \
							../execute.vhd			  \
							../instruction_fetch.vhd\
							../instructions.vhd	  \
							../load_store_unit.vhd \
							../lui.vhd 				  \
							../memory_system.vhd   \
							../pc_incr.vhd			  \
							../register_file.vhd   \
							../riscv.vhd 			  \
							../sys_call.vhd 		  \
							../wishbone_wrapper.vhd \
							hdl/top_util_pkg.vhd \
							hdl/top_component_pkg.vhd\
							hdl/wb_ram.vhd 		  \
							hdl/top.vhd				  \
							hdl/wb_arbiter.vhd \
							hdl/wb_splitter.vhd \
							hdl/wb_pio.vhd \
							hdl/bram.vhd \
							hdl/my_led_sim.v\
							hdl/uart_rd1042/uart_core.vhd\
							hdl/uart_rd1042/modem.vhd      \
							hdl/uart_rd1042/rxcver.vhd		 \
							hdl/uart_rd1042/txcver_fifo.vhd\
							hdl/uart_rd1042/rxcver_fifo.vhd\
							hdl/uart_rd1042/intface.vhd	 \
							hdl/uart_rd1042/txmitt.vhd     \
							hdl/top_tb.vhd]



	 vlib work

	 foreach f $fileset {
		  if { [file extension $f ] == ".v" } {
				vlog -work work -stats=none $f
		  } else {
				vcom -work work -2002 -explicit $f
		  }
	 }
}

com

vsim work.top_tb
add log -r *

add wave -noupdate /top_tb/dut/rv/rv/clk
add wave -noupdate /top_tb/dut/rv/rv/reset
add wave -noupdate -divider Execute
add wave -noupdate /top_tb/dut/rv/rv/X/valid_input
add wave -noupdate /top_tb/dut/rv/rv/X/pc_current
add wave -noupdate /top_tb/dut/rv/rv/X/instruction

set DefaultRadix hex
