all: run_tokenizer comp_run run_histogram_maker
	

comp_deb:
	@arm-none-eabi-as word_counter.s -g -o word_counter.o
	@arm-none-eabi-ld word_counter.o -o word_counter
	qemu-arm -g 1233 word_counter
comp_run:
	@echo "Running word counter module (arm asm)"
	@arm-none-eabi-as word_counter.s -o word_counter.o
	@arm-none-eabi-ld word_counter.o -o word_counter
	@echo "start execution time: "
	@date
	@qemu-arm ./word_counter; echo "Exit status: $$?"
	@echo "finish execution time: "
	@date

run_tokenizer:
	@echo "Executing tokenizer module (c) with input.txt"
	@./tokenizer input.txt

run_histogram_maker:
	@echo "Executing histogram maker (python)"
	@python histogram_maker.py