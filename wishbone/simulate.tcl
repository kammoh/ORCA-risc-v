
proc com {} {
	 set fileset [list \
							../utils.vhd  \
							../components.vhd 	  \
							wb_ebr_ctrl/wb_ebr_ctrl.v 		  \
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
							top.vhd				  \
							../wishbone_wrapper.vhd \
							cae_library/simulation/verilog/pmi/pmi_ram_dp.v \
							top_tb.vhd]



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
set DefaultRadix hex
