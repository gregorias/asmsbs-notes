showenvs: showenvs.o
	ld -o showenvs showenvs.o -melf_i386
showenvs.o: showenvs.asm
	nasm -f elf -g -F stabs showenvs.asm -l showenvs.lst

clean:
	rm *.o *.lst showenvs
