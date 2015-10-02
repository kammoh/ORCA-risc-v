
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
							wb_ram.vhd 		  \
							top.vhd				  \
							wb_arbiter.vhd \
							bram.vhd \
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
