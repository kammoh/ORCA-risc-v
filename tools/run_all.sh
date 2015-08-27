STR=""
for i in test/*.gex
do
	 cp $i test.hex
	 quartus_cdb --update_mif vblox1.qpf
	 quartus_asm vblox1.qpf
	 quartus_pgm -m JTAG -o P\;output_files/vblox1.sof
	 echo "$i - homtohost?"
	 read -n1 k

	 echo "$i = $k" >> test_results.txt
done
echo $STR
