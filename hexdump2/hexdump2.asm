;  Copyright 2016 Grzegorz Milka
;  asmsyntax=nasm
;  Executable name : hexdump2
;  Version         : 1.0
;  Created date    : 06/11/2016
;  License         : GPLv3
;  Author          : Jeff Duntemann, Grzegorz Milka
;  Description     : A simple program in assembly for Linux, using NASM 2.05,
;    demonstrating the conversion of binary values to hexadecimal strings.
;    This version fixes hexdump1 from Jeff Duntemann book, which incorrectly
;    outputs the hexdump if input's length is not a multiple of 16.
;
;  Run it this way:
;    hexdump1 < (input file)

SECTION .bss
  BUFLEN equ 16
  buf:   resb BUFLEN
  output_line: resb LINELEN

SECTION .data
  empty_line:  db " 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00", 0x0A
  LINELEN      equ $-empty_line
  digits:      db "0123456789ABCDEF"

SECTION .text
global  _start

_start:
  nop

; READ
; After READ, 'buf' contains up to 16 bytes of input data, eax contains the
; count of valid data in line. If eax is less than 16, then this is the last
; line of the input. If eax is zero then 'Read' jumps to SuccessExit.
Read:
  mov ebp,0 ; ebp - how many bytes have been read.
  mov ebx,0 ; read from stdin
  mov edx,BUFLEN ; edx - number of bytes to fill in 'buf'

Read_loop:
  mov eax,3
  lea ecx,[buf+ebp]
  int 0x80
  cmp eax,0
  jb  ErrorExit
  je  Read_success
  add ebp,eax
  sub edx,eax
  cmp ebp,BUFLEN
  jne Read_loop

Read_success:
  mov eax,ebp
  cmp eax,0
  je  SuccessExit
; END OF READ

; PRINTF
; Assumes we have data set as if after a 'Read' call.
; After 'PRINTF', 'output_line' contains the hexdump of 'buf'. eax is copied to
; esi.
  mov esi,eax

; Initialize unused symbols of the 'output_line' with symbols from
; the 'empty_line'.
  mov ebx,LINELEN
  lea ecx,[eax*2+eax]
Clear:
  cmp ebx,ecx
  je  Printf
  mov dl,byte [empty_line+ebx-1]
  mov byte [output_line+ebx-1],dl
  dec ebx
  jmp Clear

Printf:
; eax is greater than 0 and contains the number of buf bytes to process
; ebx contains the index of character in '*_line' right after the next character
; to fill.
  xor ecx,ecx
  mov cl,byte [buf+eax-1]
  mov edx,ecx

  and cl,0x0F
  mov cl,byte [digits+ecx]
  mov byte [output_line+ebx-1],cl

  and dl,0xF0
  shr dl,4
  mov dl,byte [digits+edx]
  mov byte [output_line+ebx-2],dl

  mov byte [output_line+ebx-3],0x20

  dec eax
  jz  Write
  lea ebx,[eax*2+eax]
  jmp Printf
; END OF PRINTF

; WRITE
; Outputs 'output_line' to stdout.
; Assumes that esi contains the result of READ
Write:
  mov ebx,1       ; ebx - stdout
  mov edx,LINELEN ; edx - bytes left to output
  mov ebp,0       ; ebp - index of the next byte to output
Write_loop:
  mov eax,4
  lea ecx,[output_line+ebp]
  int 0x80
  cmp eax,0
  jb  ErrorExit
  add ebp,eax
  sub edx,eax
  cmp edx,0
  je  Write_success
  jmp Write_loop
Write_success:
  cmp esi,BUFLEN
  jb  SuccessExit
  je  Read

ErrorExit:
  mov ebx,1
  jmp Exit
SuccessExit:
  mov ebx,0
Exit:
  mov eax,1
  int 0x80
