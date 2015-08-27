TEST_DIR=/nfs/scratch/riscv-tools/riscv-tests/isa
FILES=$(ls $TEST_DIR/rv32ui-p-* | grep -v hex | grep -v dump)
for i in $FILES
do
	 echo "$i > test/$(basename $i).gex"
    riscv64-unknown-elf-objcopy  -O binary $i temp.bin
    python ../tools/bin2mif.py temp.bin 0x100 > temp.mif
    mif2hex temp.mif test/$(basename $i).gex >/dev/null 2>&1
done
rm temp.bin temp.mif
