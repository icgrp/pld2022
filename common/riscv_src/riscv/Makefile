
all:
	./qsub_run.sh
	/opt/riscv32i/bin/riscv32-unknown-elf-objdump -S firmware.elf > out.S

clean:
	rm -rf ./*.o ./*.elf ./*.hex ./*.bin
