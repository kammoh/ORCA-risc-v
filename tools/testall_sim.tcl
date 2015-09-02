cd vblox1/simulation/mentor
do msim_setup.tcl
ld
add wave -position insertpoint  sim:/vblox1/riscv_0/coe_to_host

set files [lsort [glob ../../../test/*.gex]]

foreach f $files {
	 file copy -force $f ../../../test.hex
	 restart -f
	 run 100 ns
	 while { [examine -decimal sim:/vblox1/riscv_0/coe_to_host] == 0 } {
		  if { $now > 5000000 } { break }
		  run 100 ns;
	 }

	 set v [examine -decimal sim:/vblox1/riscv_0/coe_to_host]
	 puts "$f = $v"
}

exit -f;
