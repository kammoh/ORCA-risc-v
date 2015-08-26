
Altera's tools do not parse regular ihex files properly.

In order to run a program compiled for riscv using altera's sythesis tools,
use the following sequence. Assuming you have a compiled elf called `in.elf`,
and qsys set up the on chip rams to be initialized from `out.hex`

```
riscv64-unknown-elf-objcopy  -O binary in.elf temp.bin
python bin2mif.py temp.bin 0x100 > temp.mif #assuming the elf starts at 0x100
mif2hex temp.mif out.hex
```

Copying tests

```
cp /nfs/scratch/riscv-tools/riscv-tests/isa/rv32ui-p-* test/
for i in test/*.hex
do
   riscv64-unknown-elf-objcopy  -O binary test/$(basename $i .hex) temp.bin
   python ../tools/bin2mif.py temp.bin 0x100 > temp.mif
   mif2hex temp.mif test/$(basename $i .hex).gex
done
rm temp.bin temp.mif
```

To update memory initialization without rerunning entire compiliation run
```
quartus_cdb --update_mif <project name> quartus_asm <project name>
```
