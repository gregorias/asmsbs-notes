;  Copyright 2016 Grzegorz Milka
;  asmsyntax=nasm
;  Created date    : 2016-11-13
;  Author          : Grzegorz Milka
;  License         : GPLv3
;  Description     : Prints out environment strings to standard output.
;                    This program demonstrates usage of program's initial stack
;                    in x86 Linux.

section .bss

section .data

	ErrMsg db "Terminated with error.",10
	ERRLEN equ $-ErrMsg

section .text

global _start

_start:
  mov ebp,[esp]         ; ebp = argc
  lea ebp,[esp+4*ebp+8] ; We need to skip argc, the argv table, and the 0 dword.
  ; ebp now will always point to the next env address entry

; while(*ebp != 0) {
;   size_t len = strnlen(*ebp, 0xffff);
;   // jmp to Error if string is longer than 0xffff, otherwise:
;   syswrite(1, *ebp, len)
;   ebp += 4;
; }
ScanEnvpEntry:
  mov edi,dword[ebp]
  test edi, edi
  jz Exit

  ; ebx will contain the address of the environment string
  mov ebx,edi
  ; Count the length
	mov ecx,0x0000ffff ; Limit search to 65535 bytes max
  xor eax,eax
  cld
  repne scasb
  jnz Error

  ; NULL terminator has been found, calculate length and output
  mov byte[edi-1],10 ; Put newline in place of NULL
  mov ecx,ebx
  sub edi,ebx        ; Get the length into edi (edi = edi - ebx)
  mov edx,edi
  mov eax,4
  mov ebx,1
  int 80H

  add ebp,4
  jmp ScanEnvpEntry

Error:
  mov eax,4      ; Specify sys_write call
	mov ebx,2      ; Specify File Descriptor 2: Standard Error
	mov ecx,ErrMsg ; Pass offset of the error message
	mov edx,ERRLEN ; Pass the length of the message
	int 80H        ; Make kernel call

Exit:
  mov eax,1
  mov ebx,0
  int 80H
