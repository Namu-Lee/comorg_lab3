all: simple_cpu

MODULES = src/modules/control/alu_control.v 						\
					src/modules/control/branch_control.v					\
					src/modules/control/control.v									\
					src/modules/control/forwarding.v							\
					src/modules/control/hazard.v									\
					src/modules/branch/branch_hardware.v					\
					src/modules/branch/branch_target_buffer.v			\
					src/modules/branch/gshare.v										\
					src/modules/memory/data_memory.v							\
					src/modules/memory/exmem_reg.v								\
					src/modules/memory/idex_reg.v									\
					src/modules/memory/ifid_reg.v									\
					src/modules/memory/instruction_memory.v				\
					src/modules/memory/memwb_reg.v								\
					src/modules/memory/register_file.v						\
					src/modules/operation/adder.v									\
					src/modules/operation/alu.v										\
					src/modules/operation/immediate_generator.v		\
					src/modules/utils/defines.v										\
					src/modules/utils/mux_2x1.v										\
					src/modules/utils/mux_3x1.v										\
					src/modules/utils/mux_4x1.v										\
					src/modules/utils/hardware_counter.v										

SOURCES = ./src/riscv_tb.v ./src/simple_cpu.v 

simple_cpu: $(MODULES) $(SOURCES)
	iverilog -I src/modules/ -s riscv_tb -o $@ $^

clean:
	rm -f simple_cpu *.vcd
