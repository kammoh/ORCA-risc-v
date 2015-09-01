TEST_DIR=/nfs/scratch/riscv-tools/riscv-tests/isa
FILES=$(ls $TEST_DIR/rv32ui-p-* | grep -v hex | grep -v dump)

mkdir -p test
for i in $FILES
do
	 echo "$i > test/$(basename $i).gex"
	 riscv64-unknown-elf-objcopy  -O binary $i temp.bin &
	 riscv64-unknown-elf-objdump --disassemble-all -Mnumeric,no-aliases $i > test/$(basename $i).dump &
	 wait
    python ../tools/bin2mif.py temp.bin 0x100 > temp.mif || exit -1
    mif2hex temp.mif test/$(basename $i).gex >/dev/null 2>&1 || exit -1
done
rm temp.bin temp.mif
