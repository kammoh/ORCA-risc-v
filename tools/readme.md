
Altera's tools do not parse regular ihex files properly.

In order to run a program compiled for riscv using altera's sythesis tools,
use the following sequence. Assuming you have a compiled elf called in.elf,
and qsys set up the on chip rams to be initialized from out.hex

```
riscv64-unknown-elf-objcopy  -O binary in.elf temp.bin
python bin2mif.py temp.bin 0x100 > temp.mif #assuming the elf starts at 0x100
mif2hex temp.mif out.hex
```
