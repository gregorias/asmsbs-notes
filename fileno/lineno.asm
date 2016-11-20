;  Copyright 2016 Grzegorz Milka
;  asmsyntax=nasm
;  Created date    : 2016-11-13
;  Author          : Grzegorz Milka
;  License         : GPLv3
;  Description     : This program reads a file and prepends a line number to
;                    each line. Read HelpMsg below for usage instructions.
;                    This program is a modification of textfile.asm from Jeff
;                    Duntemann's book.

[SECTION .data] ; Section containing initialized data

IntFormat   dd '%d ',0
StrFormat   dd '%s',0
WriteBase   db '%d ',0
DiskHelpNm  db 'helptextfile.txt',0
WriteCode   db 'w',0
ReadCode    db 'r',0
IsNewLine   db 1 ; 0 (false) or 1 (true) if next line printed should
                 ; be prepended with a line count.
LineCount   dd 1 ; Current line number
Bufflen     dw 0 ; Number of valid characters without \0 in Buff
HelpMsg     db 'lineno [INPUT_FILE] [OUTPUT_FILE] - Prepends a line number  ',10,0
HELPSIZE    EQU $-HelpMsg
            db 'to INPUT_FILE and outputs to STDOUT and OUTPUT_FILE if      ',10,0
            db 'provided. If no argument is provided then this help message ',10,0
            db 'is shown or helptextfile.txt content is shown if present.   ',10,0
HelpEnd     dd 0
OutputFile  dd 0 ; Output file handle

[SECTION .bss] ; Section containing uninitialized data

HELPLEN     EQU 72         ; Define length of a line of help text data
HelpLine    resb HELPLEN   ; Reserve space for disk-based help text line
BUFSIZE     EQU 1024       ; Define length of text line buffer buff
Buff        resb BUFSIZE   ; Reserve space for a line of text

[SECTION .text]     ; Section containing code

;; These externals are all from the glibc standard C library:
extern fopen
extern fclose
extern fgets
extern fprintf
extern printf
extern sscanf
extern strlen
extern stdout

;; These externals are from the associated library linlib.asm:

extern dfopen
extern newline
extern tee_printf

global main     ; Required so linker can find entry point

main:
  ; [ebp-16] - return code
  ; [ebp-20] - FILE* input
  push ebp    ; Set up stack frame for debugger
  mov ebp,esp
  push ebx    ; Program must preserve EBP, EBX, ESI, & EDI
  push esi
  push edi
  sub esp,8

  ;; First test is to see if there are command line arguments at all.
  ;; If there are none, we show the help info as several lines.  Don't
  ;; forget that the first arg is always the program name, so there's
  ;; always at least 1 command-line argument!
  mov eax,[ebp+8]    ; Load argument count from stack into EAX
  cmp eax,1          ; If count is 1, there are no args
  ja .chkarg1        ; Continue if arg count is > 1
  call diskhelp      ; If only 1 arg, show help info...
  jmp .gohome         ; ...and exit the program

  ;; Next we check for a numeric command line argument 1:
.chkarg1:
  ; open input file
  push ReadCode
  mov ebx,[ebp+12]  ; Put pointer to 'argv' argument table into ebx
  push dword[ebx+4]  ; Push pointer to argv[1]
  call dfopen
  add esp,8
  test eax,eax
  jnz .dfopen_input_success
  ; Early exit on dfopen error
  mov dword[ebp-16],1
  jmp .gohome
.dfopen_input_success:
  mov dword[ebp-20],eax

  ; Check for a second command line argument and open output file if it is
  ; present.
.dfopen_output_check:
  mov eax,[ebp+8]   ; Load argument count from stack into EAX
  cmp eax,2         ; If count is 2, there is no output file
  jle .read_line    ; Continue if arg count is > 2

  ; open output file
  push WriteCode
  mov ebx,[ebp+12]  ; Put pointer to 'argv' argument table into ebx
  push dword[ebx+8] ; Push pointer to argv[2]
  call dfopen
  add esp,8
  test eax,eax
  jnz .dfopen_output_success
  ; Early exit on dfopen error
  mov dword[ebp-16],1
  jmp .close_input
.dfopen_output_success:
  mov dword[OutputFile],eax

.read_line:
  push dword[ebp-20]
  push BUFSIZE
  push Buff
  call fgets
  add esp,12
  cmp eax,0
  ja .read_success
  ; TODO return error if happened
  mov dword[ebp-16],1
  jmp .close_output
.read_success:
  push Buff
  call strlen
  add esp,4
  mov dword[Bufflen],eax
  call scan_input_and_write
  jmp .read_line

.close_output:
  mov eax,dword[OutputFile]
  test eax,eax
  jz .close_input
  push dword[OutputFile]
  call fclose   ; Closes the file whose handle is on the stack
  add esp,4

.close_input:
  push dword[ebp-20]
  call fclose   ; Closes the file whose handle is on the stack
  add esp,4

  ;;; Everything after this is boilerplate; use it for all ordinary apps!
.gohome:
  add esp,4
  pop eax
  pop edi     ; Restore saved registers
  pop esi
  pop ebx
  mov esp,ebp ; Destroy stack frame before returning
  pop ebp
  ret         ; Return control to to the C shutdown code


;;; SUBROUTINES================================================================

;------------------------------------------------------------------------------
;  Disk-based mini-help subroutine  --  Last update 12/5/1999
;
;  This routine reads text from a text file. The routine opens the text file,
;  reads the text from it, and displays it to standard output.  If the file
;  cannot be opened, a very short memory-based message is displayed instead.
;------------------------------------------------------------------------------
diskhelp:
  push ReadCode   ; Push pointer to open-for-read code "r"
  push DiskHelpNm ; Pointer to the name of the help file
  call fopen    ; Attempt to open the file for reading
  add esp,8   ; Clean up the stack
  cmp eax,0   ; fopen returns null if attempted open failed
  jne .disk   ; Read help info from disk, else from memory
  call memhelp
  ret
.disk:  mov ebx,eax   ; Save handle of opened file in ebx
.rdln:  push ebx    ; Push file handle on the stack
  push dword HELPLEN  ; Limit line length of text read
  push HelpLine   ; Push address of help text line buffer
  call fgets    ; Read a line of text from the file
  add esp,12    ; Clean up the stack
  cmp eax,0   ; A returned null indicates error or EOF
  jle .done   ; If we get 0 in eax, close up & return
  push HelpLine   ; Push address of help line on the stack
  call printf   ; Call printf to display help line
  add esp,4   ; Clean up the stack
  jmp .rdln

.done:  push ebx    ; Push the handle of the file to be closed
  call fclose   ; Closes the file whose handle is on the stack
  add esp,4   ; Clean up the stack
  ret     ; Go home

memhelp:
  mov eax,1
  call newline
  mov ebx,HelpMsg   ; Load address of help text into eax
.chkln: cmp dword [ebx],0 ; Does help msg pointer point to a null?
  jne .show   ; If not, show the help lines
  mov eax,1   ; Load eax with number of newslines to output
  call newline    ; Output the newlines
  ret     ; If yes, go home
.show:  push ebx    ; Push address of help line on the stack
  call printf   ; Display the line
  add esp,4   ; Clean up the stack
  add ebx,HELPSIZE  ; Increment address by length of help line
  jmp .chkln    ; Loop back and check to see if we done yet

;-------------------------------------------------------------------------------
; A helper function that processes input in Buff. It scans each line in Buff
; and prints the line number before printing a new line.
; Modifies: Uses standard libc convention for registers.
;-------------------------------------------------------------------------------
scan_input_and_write:
  push ebp
  mov ebp,esp
  push ebx
  push esi
  push edi

  xor ecx,ecx
  mov cx,word[Bufflen]
  mov edi,Buff

  ; Print newline if IsNewLine is set.
  mov al,byte[IsNewLine]
  test al,al
  jz .scan_newline
.newline:
  push ecx
  push dword[LineCount]
  push IntFormat
  push dword[OutputFile]
  call tee_printf
  add esp,12
  pop ecx
  mov byte[IsNewLine],0

.scan_newline:
  test ecx,ecx ; Do not do anything if input line is empty
  jz .return
  mov eax,10
  mov ebx,edi  ; Save beginning of current fragment
  cld          ; Make sure the direction is increasing
  repne scasb

  mov al,byte[edi]
  mov byte[edi],0 ; Note that ecx will always be smaller than size of Buff
  push ecx
  push ebx
  push StrFormat
  push dword[OutputFile]
  call tee_printf
  add esp,12
  pop ecx
  mov byte[edi],al

  mov al,byte[edi-1]
  cmp al,10
  jnz .return
  mov byte[IsNewLine],1
  mov eax,dword[LineCount]
  inc eax
  mov dword[LineCount],eax
  jmp .newline

.return:
  pop edi
  pop esi
  pop ebx
  leave
  ret
