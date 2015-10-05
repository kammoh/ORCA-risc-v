TEST_DIR=/nfs/scratch/riscv-tools/riscv-tests/isa
FILES=$(ls $TEST_DIR/rv32ui-p-* | grep -v hex | grep -v dump)


#echo \$# = $#
if [ $# -eq 1 ]
then
	 ln -sf $1_init_0.imem.mem init_0.imem.mem
	 ln -sf $1_init_1.imem.mem init_1.imem.mem
	 ln -sf $1_init_2.imem.mem init_2.imem.mem
	 ln -sf $1_init_3.imem.mem init_3.imem.mem
	 ln -sf $1.mem test.mem
	 ln -sf $1.gex test.hex
	 exit 0
fi

mkdir -p test
if which mif2hex >/dev/null
then
:
else
	 echo "cant find command mif2hex, exiting." >&2
	 exit -1;
fi

for i in $FILES
do
	 echo "$i > test/$(basename $i).gex"
	 BIN_FILE=test/$(basename $i).bin
	 GEX_FILE=test/$(basename $i).gex
	 MEM_FILE=test/$(basename $i).mem
	 MIF_FILE=test/$(basename $i).mif
	 SPLIT_FILE=test/$(basename $i).split
	 cp $i test/
	 riscv64-unknown-elf-objcopy  -O binary $i $BIN_FILE
	 riscv64-unknown-elf-objdump --disassemble-all -Mnumeric,no-aliases $i > test/$(basename $i).dump
    python ../tools/bin2mif.py $BIN_FILE 0x100 > $MIF_FILE || exit -1
    mif2hex $MIF_FILE $GEX_FILE >/dev/null 2>&1 || exit -1
	 sed -e 's/://' -e 's/\(..\)/\1 /g'  $GEX_FILE >$SPLIT_FILE

	 awk '{if (NF == 9) print $5$6$7$8}' $SPLIT_FILE > $MEM_FILE

	 awk '{if (NF == 9) printf "%04x:%s\n",NR-1,$5}'  $SPLIT_FILE  >test/$(basename $i)_init_0.imem.mem
	 awk '{if (NF == 9) printf "%04x:%s\n",NR-1,$6}'  $SPLIT_FILE  >test/$(basename $i)_init_1.imem.mem
	 awk '{if (NF == 9) printf "%04x:%s\n",NR-1,$7}'  $SPLIT_FILE  >test/$(basename $i)_init_2.imem.mem
	 awk '{if (NF == 9) printf "%04x:%s\n",NR-1,$8}'  $SPLIT_FILE  >test/$(basename $i)_init_3.imem.mem
	 rm -f $MIF_FILE $SPLIT_FILE

done
