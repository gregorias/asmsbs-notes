;  Copyright 2016 Grzegorz Milka
;  asmsyntax=nasm
;  Created date    : 2016-11-13
;  Author          : Grzegorz Milka
;  License         : GPLv3
;  Description     : A procedure library in assembly using NASM 2.03

[SECTION .data]   ; Section containing initialized data

DFopenErr db 'Could not open %s',10,0

[SECTION .bss]    ; Section containing uninitialized data

[SECTION .text]   ; Section containing code

extern fopen
extern fprintf
extern printf
extern stderr
extern stdout

global dfopen
global newline
global tee_printf

;-------------------------------------------------------------------------------
; Wraps fopen and adds error reporting.
; Modifies: Saves and restores ebp and esp registers.
;-------------------------------------------------------------------------------
dfopen:
  push ebp
  mov ebp,esp
  push dword[ebp+12]
  push dword[ebp+8]
  call fopen
  add esp,8
  test eax,eax
  jz .show_error
  leave
  ret
.show_error:
  push eax
  push dword[ebp+8]
  push DFopenErr
  push dword[stderr]
  call fprintf
  add esp,12
  pop eax
  leave
  ret

;-------------------------------------------------------------------------------
; Wraps fprintf and outputs provided printf argument to stdandard output and
; provided file if its handle is non-zero.
; Arguments: Accepts printf output file pointer, format string, and one format
;            string parameter.
; Modifies: Uses standard libc convention for registers.
;-------------------------------------------------------------------------------
tee_printf:
  push ebp
  mov ebp,esp
  push ebx
  push esi
  push edi

  push dword[ebp+16] ; push first format string parameter
  push dword[ebp+12] ; push format string
  push dword[stdout]
  call fprintf
  add esp,4

  mov eax,dword[ebp+8]
  test eax,eax
  jz .return
  push eax
  call fprintf
  add esp,4

.return:
  add esp,8
  pop edi
  pop esi
  pop ebx
  leave
  ret

;------------------------------------------------------------------------------
;  Newline outputter  --  Last update 5/29/2009
;
;  This routine allows you to output a number of newlines to stdout, given by
;  the value passed in eax.  Legal values are 1-10. All sacred registers are
;  respected. Passing a 0 value in eax will result in no newlines being issued.
;------------------------------------------------------------------------------
newline:
	mov ecx,10		; We need a skip value, which is 10 minus the
	sub ecx,eax		;  number of newlines the caller wants.
	add ecx,nl		; This skip value is added to the address of
	push ecx		;  the newline buffer nl before calling printf.
	call printf		; Display the selected number of newlines
	add esp,4		; Clean up the stack
	ret			; Go home
nl	db 10,10,10,10,10,10,10,10,10,10,0
