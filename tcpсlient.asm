;nasm -f elf64 tcp.asm -o tcp.o
;ld -o tcp tcp.o

global _start
section .data
	err_msg: db 'Error ', 10
	err_msg_len equ $-err_msg
	sin_port dw 0x901F; port = 8080 
	sin_family dw 0x2; /usr/include/bits/socket.h
	sin_addr  dd 0x0100007F  ;Адрес 127.0.0.1 (в сетевом порядке байтов) sin_addr = 127.0.0.1, reversed for little endian
	msg db 'GET / HTTP/1.1', 0x0D, 0x0A, 'Host: 127.0.0.1:80', 0x0D, 0x0A, 0x0D, 0x0A, 0
 	;server_response
	msg_len equ $-msg
	;sr_len equ $-server_response
	
	
section .bss
	socket: resd 1 
	server_response: resb 255
section .text	
_start:
	
	
	mov rax,41 		; номер системного вызова socket
	mov rdi,2 		; AF_INET (IPv4)
	mov rsi,1		; SOCK_STREAM (TCP) 
	mov rdx,0		; IP-протокол (по умолчанию)
	syscall
	
	
	
	
	
; Сохраняем дескриптор файла в rbx
    	mov [socket], rax
; Заполняем структуру sockaddr_in для подключения
        xor rax,rax		; обнуляем
        push rdx		; pad 8 null bytes to align with sockaddr
	push qword[sin_addr]   ;
	push word[sin_port]	; sin_port = 80
	push word[sin_family] 		; sin_family = AF_INET
	mov rsi, rsp		; sockaddr = structure in the stack
        mov rax, 42		; syscall = connect
	mov rdi,[socket]		;sockaddr = structure in the stack
	mov dl, 16		;addrlen = 16 bytes
	syscall
	;cmp rax, 0
	;jl error ; Если произошла ошибка, переходим к выводу сообщения об ошибке
    	cmp rax, 0
  	jne error 
	; Отправляем запрос 
     	;mov rax, 1           ; sys_write
    	;lea rsi, [msg]       ; Адрес строки запроса серверу
    	;mov rdx, msg_len     ; Длина строки
    	;syscall              ; Вызов системного вызова
    	mov rax, 1 ; syscall ID
  	mov edi, [socket] ; FD of the place we want to write to
  	mov esi, msg ; Message
  	mov edx, msg_len;
  	syscall	
	; Read server response via "read" syscall 
 	mov rax, 0 ; syscall ID
 	mov edi, [socket] ; FD of socket
 	mov esi, server_response ; Buffer we will read into
 	mov edx, 640 ; count
 	syscall
	mov rax, 1          ; 1 - номер системного вызова функции write
    	mov rdi, 1          ; 1 - дескриптор файла стандартного вызова stdout
    	mov rsi, server_response    ; адрес строки для вывод
    	mov rdx, 700         ; количество байтов
    	syscall             ; выполняем системный вызов write
  
  	mov rax, 60          ; sys_exit
	syscall              ; Вызов системного вызова 
   
error:	
;Выводим сообщение об ошибке и завершаем программу
   	mov rax, 1           ; sys_write
   	mov rdi, 2           ; Стандартный поток ошибок (stderr)
    	mov rsi, err_msg   ; Адрес строки ошибки
    	mov rdx, err_msg_len ; Длина строки ошибки
   	syscall              ; Вызов системного вызова
	mov rax, 60          ; sys_exit
	syscall              ; Вызов системного вызова 
   
 


