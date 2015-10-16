all: vblox1.sof

QSYS_FILE=vblox1.qsys
QPF_FILE=vblox1.qpf
QIP_FILE=vblox1/synthesis/vblox1.qip
OUTPUT_DIR=output_files/
MAP_RPT_FILE=$(OUTPUT_DIR)vblox1.map.rpt
FIT_RPT_FILE=$(OUTPUT_DIR)vblox1.fit.rpt
ASM_RPT_FILE=$(OUTPUT_DIR)vblox1.asm.rpt
MIF_RPT_FILE=$(OUTPUT_DIR)vblox1.mif_update.rpt
STA_RPT_FILE=$(OUTPUT_DIR)vblox1.sta.rpt


DEVICE_FAMILY=$(shell grep deviceFamily $(QSYS_FILE) | head -1 | sed 's/.*value="\(.*\)".*/\1/')
VHDL_FILES=$(wildcard ../*.vhd)

$(QIP_FILE):$(QSYS_FILE)
	 ip-generate --project-directory=./ --output-directory=vblox1/synthesis/\
	 --file-set=QUARTUS_SYNTH --report-file=bsf:./vblox1.bsf\
	 --report-file=sopcinfo:./vblox1.sopcinfo --report-file=html:./vblox1.html \
	 --report-file=qip:vblox1/synthesis/vblox1.qip --system-info=DEVICE_FAMILY=$(DEVICE_FILE)\
	 --component-file=vblox1.qsys 2>&1 | tee ./vblox1.qsys.log
	for i in $(VHDL_FILES); do ln -sf $(readlink -f $i) vblox1/synthesis/submodules/$(basename $i); done

HEX_FILE=$(wildcard test.hex)

$(MAP_RPT_FILE) : $(QIP_FILE)
	quartus_map $(QPF_FILE)
$(FIT_RPT_FILE) : $(MAP_RPT_FILE)
	quartus_fit $(QPF_FILE)
$(STA_RPT_FILE) : $(FIT_RPT_FILE)
	quartus_sta $(QPF_FILE)
$(MIF_RPT_FILE) : $(STA_RPT_FILE) $(HEX_FILE)
	quartus_cdb --update_mif $(QPF_FILE)
$(ASM_RPT_FILE) : $(MIF_RPT_FILE)
	quartus_asm $(QPF_FILE)

vblox1.sof: $(ASM_RPT_FILE)
	cp $(OUTPUT_DIR)/$@ $@

qip: $(QIP_FILE)
map: $(MAP_RPT_FILE)
fit: $(FIT_RPT_FILE)
mif: $(MIF_RPT_FILE)
asm: $(ASM_RPT_FILE)
sta: $(STA_RPT_FILE)
.phony: all clean qip map fit mif asm sta
clean:
	rm -rf vblox1/ $(OUTPUT_DIR)
