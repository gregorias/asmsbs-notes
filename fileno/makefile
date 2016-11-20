lineno: lineno.o linlib.o
	gcc lineno.o linlib.o -o lineno -m32
lineno.o: lineno.asm
	nasm -f elf -g -F stabs lineno.asm
linlib.o: linlib.asm
	nasm -f elf -g -F stabs linlib.asm

clean:
	rm *.o lineno
