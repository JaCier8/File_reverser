; Program: freverse
; Autor: Jan Ciecierski
; Działanie programu:
; - Program dostaje nazwę pliku jako argument przy wywołaniu i 
;   odwraca jego całą zawartość, realizowane jest to przez odwracanie
;   rejestrów bswapem i potem zamienianem lewgo z prawym, aż dojdziemy
;   do momonetu, gdzie nie ma już pełnych d ówch rejestrów, to wtedy kończymy
;   przez zamienianie bajt po bajcie


; Stałe:
; System calle
SYS_READ equ 0
SYS_WRITE equ 1
SYS_OPEN equ 2
SYS_CLOSE equ 3
SYS_LSEEK equ 8
SYS_MMAP equ 9
SYS_MUNMAP equ 11
SYS_EXIT equ 60

; SYS_OPEN, otwieranie pliku w trybie r/w.
OPEN_READ_WRITE equ 2

; SYS_LSEEK, lseek na końcu pliku, żeby zwrócił długość.
SEEK_END equ 2

;SYS_MMAP
MMAP_READ_WRITE equ 3
MMAP_SHARED equ 1 

; Ilość argumnetów, |funkcja, plik| = 2
POPR_ILOSC_ARG equ 2

section .text
global _start

_start:

	; Zaczynamy od sprawdzenia czy mamy dobrą ilość argumentów.
	cmp qword [rsp], POPR_ILOSC_ARG
	jne .zakoncz_z_bledem

	; Otwieramy plik
	mov rax, SYS_OPEN
	mov rdi, [rsp + 16]
	mov rsi, OPEN_READ_WRITE
	syscall
	
	; Sprawdzamy czy się powiodło, prznieosimy desktryptor w r12.
	test rax, rax		; czy błąd trafia do rax?
	js .zakoncz_z_bledem
	mov r12, rax

	; Sprawdzamy rozmair pliku z lseek
	mov rdi, r12		; deskryptor
	xor rsi, rsi		; offset
	mov rdx, SEEK_END	; miejsce seeku
	mov rax, SYS_LSEEK	; SYSCALL - SYS_LEEK
	syscall
	
	; Sprawdzamy czy się powiodło, zapisujemy rozmiar w r13.
	test rax, rax		; Sprawdz czy pusty
	jz .zakoncz
	js .zamknij_zakoncz
	mov r13, rax

	; Mapowanie pliku z mmap
	xor rdi, rdi			; miejsce mapowania: 0 - system wybiera
	mov rsi, r13			; rozmiar pliku
	mov rdx, MMAP_READ_WRITE	; prawa dostępu
	mov r10, MMAP_SHARED		; flaga dostępu, do mmapa
	xor r9, r9			; offset
	mov r8, r12			; deskrytpor
	mov rax, SYS_MMAP		; SYSCALL - SYS_MMAP
	syscall

	; Sprawdzamy czy się powiodło, zapisujemy adres do r14.
	cmp rax, -4095
	jae .zamknij_zakoncz
	mov r14, rax

	; Zaczynamy obracać, iterator w rdx.
	mov rdx, r13
	shr rdx, 4	; Dzielimy pętle przez ilość bajtów w qword i przez 2.

	mov r8, r14	; r8 - indeks na pocz
	mov r9, r13
	add r9, r14
	dec r9		; r9 - indeks na koniec

	test rdx, rdx
	jz .petla_po_bajtach


; r14 = wsk
; r13 = len
; Iterujemy, aż zostaną mniej niż dwa rejestry, czy rdx/16 razy
.petla_obracania:
	; Pobieramy z pliku dwa rejestry je podmieniamy
	mov rax, qword [r8]
	mov rbx, qword [r9 - 7]

	; Obracamy oba
	bswap rax
	bswap rbx

	; Zamieniamy miejscami
	mov qword [r8], rbx
	mov qword [r9 - 7], rax
	

	; Zwiększami/Zmniejszamy indeksy
	add r8, 8
	sub r9, 8
	dec rdx
	jnz .petla_obracania


; Jak już mamy mniej niż 2 qwordy, to podmieniamy bit po bicie.
.petla_po_bajtach:
	; Sprawdzamy czy już nie wyszliśmy za daleko.
	cmp r8, r9
	jae .zakoncz_z_munmapem

	; Podmieniamy bity.
	mov al, [r8]
	mov bl, [r9]
	mov [r8], bl
	mov [r9], al

	; Zmieniamy iteratory.
	inc r8
	dec r9
	jmp .petla_po_bajtach

; Jeżeli przed mmapem coś wywali błąd
.zakoncz_z_munmapem:
	; Munmapowanie
	mov rdi, r14		; adres mmapa
	mov rsi, r13		; dlugosc pliku
	mov rax, SYS_MUNMAP
	syscall
	
	; Sprawdzamy czy się powiodło
	test rax, rax
	js .zamknij_zakoncz

; Konczy program, bez błędu
.zakoncz:	
	; Zamykamy plik
	mov rdi, r12		; deskryptor
	mov rax, SYS_CLOSE
	syscall

	; Sprawdzamy czy się powiodło
	test rax, rax
	js .zakoncz_z_bledem

	; Wychodzenie przez exit
	xor rdi, rdi
	mov rax, SYS_EXIT
	syscall
	
	
; Zamyka plik i przechodzi do zakończenia
.zamknij_zakoncz:
	mov rdi, r12		; deskryptor
	mov rax, SYS_CLOSE
	syscall
	jmp .zakoncz_z_bledem


; Kończy program z kodem błędu 1
.zakoncz_z_bledem:
	mov rdi, 1
	mov rax, SYS_EXIT
	syscall

