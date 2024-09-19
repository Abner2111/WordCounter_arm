comp_run:
	arm-none-eabi-as word_counter.s -g -o word_counter.o
	arm-none-eabi-ld word_counter.o -o word_counter
	qemu-arm -g 1233 word_counter
