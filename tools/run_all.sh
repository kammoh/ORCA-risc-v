STR=""
DATE=$(date)
for i in test/*.gex
do
	 cp $i test.hex
	 quartus_cdb --update_mif vblox1.qpf
	 quartus_asm vblox1.qpf
	 quartus_pgm -m JTAG -o P\;output_files/vblox1.sof
	 k=$(system-console --script=system_console.tcl | grep to_host | sed 's/to_host=\(.*\)/\1/')
	 echo "$i = $k" | tee -a "test_results$DATE.txt"
done
echo $STR
