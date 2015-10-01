TEST_DIR=/nfs/scratch/riscv-tools/riscv-tests/isa
FILES=$(ls $TEST_DIR/rv32ui-p-* | grep -v hex | grep -v dump)

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
	 riscv64-unknown-elf-objcopy  -O binary $i $BIN_FILE
	 riscv64-unknown-elf-objdump --disassemble-all -Mnumeric,no-aliases $i > test/$(basename $i).dump
    python ../tools/bin2mif.py $BIN_FILE 0x100 > $MIF_FILE || exit -1
    mif2hex $MIF_FILE $GEX_FILE >/dev/null 2>&1 || exit -1
	 cat <(head -c $((0x100)) /dev/zero ) $BIN_FILE | xxd -c 4 | awk "{print \$2\$3}" > $MEM_FILE
	 rm -f $MIF_FILE
done
