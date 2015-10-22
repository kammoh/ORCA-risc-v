
#ICECUBE2=/nfs/opt/lattice/iCEcube2/2015.14

PROJECT=ice40ultra
SBT_PROJECT=$(PROJECT)_sbt.project
SYN_PRJ=$(PROJECT)_syn.prj
LSE_PRJ=$(PROJECT)_lse.prj
OUTPUT_DIR=$(PROJECT)_Implmnt
TOP_LEVEL_ENTITY=top

TIMING_REPORT=$(OUTPUT_DIR)/sbt/outputs/router/top_timing.rpt
EDF=$(OUTPUT_DIR)/$(PROJECT).edf
BITFILE=$(OUTPUT_DIR)/sbt/outputs/bitmap/$(TOP_LEVEL_ENTITY)_bitmap.hex

MEM_LIST=imem.list
MEM_FILE=test.mem
HDL_FILES=$(wildcard hdl/*.vhd) $(wildcard hdl/*.v) $(wildcard ../*.vhd)
all: $(BITFILE)

$(BITFILE): $(TIMING_REPORT) $(MEM_FILE) $(MEM_LIST)
	tclsh iCEcube2_flow.tcl $(MEM_FILE) $(MEM_LIST)
	LD_LIBRARY_PATH=$(ICECUBE2)/sbt_backend/lib/linux/opt:$${LD_LIBRARY_PATH} $(ICECUBE2)/sbt_backend/bin/linux/opt/meminitializer --des-lib $(OUTPUT_DIR)/sbt/netlist/oadb-top --mem-list-file $(MEM_LIST)
	tclsh iCEcube2_flow.tcl $(MEM_LIST)


$(TIMING_REPORT): $(EDF)
	tclsh iCEcube2_flow.tcl
$(EDF): $(HDL_FILES)
	SYNPLIFY_PATH=$${ICECUBE2}/synpbase \
	SBT_DIR=$${ICECUBE2}/sbt_backend/ \
	LD_LIBRARY_PATH=$${ICECUBE2}/sbt_backend/bin/linux/opt/synpwrap:$${LD_LIBRARY_PATH} \
	$${ICECUBE2}/sbt_backend/bin/linux/opt/synpwrap/synpwrap -prj $(SYN_PRJ)


syn: $(EDF)


.phony: syn all clean

clean:
	rm -rf $(OUTPUT_DIR) *.imem
