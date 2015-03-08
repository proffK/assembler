;*****************************************************************************|
;                                                                             |
;                   Program is converter bin, oct, dec, hex number            |
;                   to bin, oct, dec, hex format.                             |
;                                                                             |
;                   Developer is Klim Kireev                                  |
;                                                                             |
;*****************************************************************************|

[bits 64]

;##############################################################################
; Macro section:

;=============================================================================|
; Macro write print string in stdout                                          |
;                                                                             |
; Entry rcx -> string, rdx -> string size                                     |
;                                                                             |
; Destr rax, rbx, rcx, rdx.                                                   |
;=============================================================================|

%macro write 2
        mov rax, 1
        mov rdi, 1
        mov rsi, %1
        mov rdx, %2
        syscall
%endmacro

;=============================================================================|
; Macro read read string in stdout                                            |
;                                                                             |
; Entry rcx -> buffer, rdx -> string size                                     |
;                                                                             |
; Destr rax, rbx, rcx, rdx.                                                   |
;=============================================================================|

%macro read 2
        xor rax, rax
        xor rdi, rdi
        mov rsi, %1
        mov rdx, %2
        syscall
%endmacro

;=============================================================================|
; You can guess to do macro exit                                              |
;                                                                             |
; Entry none                                                                  |
;                                                                             |
; Destr doesn't mean                                                          |
;=============================================================================|

%macro exit 0
        mov rax, 60
        mov rdi, 0
        syscall
%endmacro

;##############################################################################

section .data

    welcome_msg1 db "Please enter type of input number "
    WEL1_SIZE equ $ - welcome_msg1

    welcome_msg2 db "Please enter input number "
    WEL2_SIZE equ $ - welcome_msg2

    welcome_msg3 db "Please enter type of output number "
    WEL3_SIZE equ $ - welcome_msg3

    err_msg db "Error numeration"
    err_msg_size equ $ - err_msg

;##############################################################################

section .bss  

    str_buf resb 31              ; input buffer
    BUFF_SIZE equ 31 

    input_char resw 2            ; input char



;##############################################################################

section .text
    global _start 

_start:

        mov rdx, str_buf
        mov rcx, BUFF_SIZE
        call erase_buf
        
        mov rax, 1               ; print first welcome message
        mov rdi, 1  
        mov rsi, welcome_msg1    ; I didn't use macro for better knowledge syscall syntax
        mov rdx, WEL1_SIZE
        syscall

        xor rax, rax             ; read input numeration
        xor rdi, rdi             ; At this moment I use all my register
        mov rsi, input_char      ; and invoke Linux Kernel Magic 
        mov rdx, 4
        syscall

        write welcome_msg2, WEL2_SIZE

        read str_buf, BUFF_SIZE
                                 ; read first number

        mov rdx, str_buf         ; prepare to call convert subroutine
        xor rcx, rcx

        mov rax, [input_char]    ; prepare to switch

;-----------------------------------------------------------------------------|
                                 ; Start first switch
        cmp al, 'b' 
        jne cmp2_sw1
        call ascii2bin
        jmp end_sw1
cmp2_sw1:
        cmp al, 'd'
        jne cmp3_sw1
        call ascii2dec
        jmp end_sw1
cmp3_sw1:
        cmp al, 'h'
        jne cmp4_sw1
        call ascii2hex
        jmp end_sw1
cmp4_sw1:
        cmp al, 'o'
        jne def_sw1
        call ascii2oct
        jmp end_sw1
def_sw1:
        mov rax, 1
        mov rdi, 1
        mov rsi, err_msg
        mov rdx, err_msg_size
    syscall
        jmp end_program

end_sw1:
                                 ; End first switch
;-----------------------------------------------------------------------------|
        
        mov rax, rbx
        push rax

        write welcome_msg3, WEL3_SIZE

        read input_char, 1       ; read output numeration

        mov bl, [input_char]

        pop rax
        mov rdx, str_buf
        mov rcx, (BUFF_SIZE - 1)

;-----------------------------------------------------------------------------|
                                 ; Start second switch
        cmp bl, 'b'
        jne cmp2_sw2
        call bin2ascii
        jmp end_sw2
cmp2_sw2:
        cmp bl, 'd'
        jne cmp3_sw2
        call dec2ascii
        jmp end_sw2
cmp3_sw2:
        cmp bl, 'h'
        jne cmp4_sw2
        call hex2ascii
        jmp end_sw2
cmp4_sw2:
        cmp bl, 'o'
        jne def_sw1              ; for optimization use first default
        call oct2ascii
        jmp end_sw2
end_sw2:
                                 ; End second switch
;-----------------------------------------------------------------------------|
        push rax
        mov al, 0Ah
        mov [input_char], al
        pop rax

        write str_buf, (BUFF_SIZE + 1)

end_program:
        mov rax, 60
        xor rdi, rdi
        syscall

;##############################################################################
;Subroutine section

;==============================================================================
;         
;        	All next 4 function convert string->number
; 
; Entry:        rdx - string, rcx - null
;
; Exit:        	rbx - number
;
; Destr:        rax, rbx, rdx, rcx
;
;==============================================================================

ascii2bin:
        
        xor rax, rax

start_ascii2bin:
        mov al, [rdx + rcx]      ; Go from begin to eng ax = ax*2 + bx         
        cmp al, 0Ah 
        je end_ascii2bin
        sub al, '0'
        shl bx, 1
        add bx, ax

loop_ascii2bin:
        inc ecx
        cmp ecx, BUFF_SIZE
        jne start_ascii2bin

end_ascii2bin:
        ret

ascii2oct:

        xor rax, rax

start_ascii2oct:
        mov al, [rdx + rcx]
        cmp al, 0Ah 
        je end_ascii2oct
        sub al, '0'
        shl bx, 3
        add bx, ax

loop_ascii2oct:
        inc ecx
        cmp ecx, BUFF_SIZE
        jne start_ascii2oct

end_ascii2oct:
        ret

ascii2dec:

        xor rax, rax
        xor rbx, rbx

start_ascii2dec:
        mov bl, [rdx + rcx]
        cmp bl, 0Ah 
        je end_ascii2dec
        sub bl, '0'
        push rbx
        push rdx
        mov bx, 10
        mul bx
        pop rdx
        pop rbx
        add ax, bx

loop_ascii2dec:
        inc ecx
        cmp ecx, BUFF_SIZE
        jne start_ascii2dec

end_ascii2dec:
        mov ebx, eax
        ret

ascii2hex:
        
        xor rax, rax

start_ascii2hex:
        mov al, [rdx + rcx]
        cmp al, 0Ah
        je end_ascii2hex
        cmp al, 'A'
        jb dec_check
        sub al, ('A' - 10)

ascii2hex_shift:
        shl bx, 4
        add bx, ax
        jmp loop_ascii2hex

dec_check:
        sub al, '0'
        jmp ascii2hex_shift

loop_ascii2hex:
        inc ecx
        cmp ecx, BUFF_SIZE
        jne start_ascii2hex

end_ascii2hex:
        ret
        
;==============================================================================
;         
;        	All next 4 function convert number->string
; 
; Entry:        rdx - string, rcx - string size, rax - number
;
; Exit none
;
; Destr:        rax, rdx, rcx , rbx
;
;==============================================================================

bin2ascii:

        push rcx                 ; Go from end to begin write ax % 2 and 
        push rdx                 ; check quotient
        xor rdx, rdx
        xor rcx, rcx
        mov rcx, 2
        div cx
        mov bx, dx
        add bl, '0'
        pop rdx
        pop rcx
        mov [rdx + rcx], bl
        test ax, ax
        je end_bin2ascii
        loop bin2ascii

end_bin2ascii:
        ret
        
oct2ascii:
        
        push rcx
        push rdx
        xor rdx, rdx
        xor rcx, rcx
        mov rcx, 8
        div cx
        mov bx, dx
        add bl, '0'
        pop rdx
        pop rcx
        mov [rdx + rcx], bl
        test ax, ax
        je end_oct2ascii
        loop oct2ascii

end_oct2ascii:
        ret

dec2ascii:

        push rcx
        push rdx
        xor rdx, rdx
        xor rcx, rcx
        mov rcx, 10
        div cx
        mov bx, dx
        add bl, '0'
        pop rdx
        pop rcx
        mov [rdx + rcx], bl
        test ax, ax
        je end_dec2ascii
        loop dec2ascii

end_dec2ascii:
        ret

hex2ascii:

        push rcx
        push rdx
        xor rdx, rdx
        xor rcx, rcx
        mov rcx, 16
        div cx
        mov bx, dx
        cmp bl, 10
        jb else_hex2ascii

        add bl, ('A' - 10)
        jmp endif_hex2ascii

else_hex2ascii:
        add bl, '0'

endif_hex2ascii:
        pop rdx
        pop rcx
        mov [rdx + rcx], bl
        test ax, ax
        je end_hex2ascii
        loop hex2ascii

end_hex2ascii:
        ret

;==============================================================================
;
;               Erase buffer
;
; Entry:        rdx - buffer, rcx - buffer size
;
; Exit none
;
; Destr:        rdx, rcx, rax
;
;==============================================================================

erase_buf:
        xor rax, rax
erase:
        mov [rdx + rcx], ax
        loop erase
        ret

;##############################################################################


