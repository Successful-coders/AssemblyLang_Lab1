.386
.model flat, stdcall
.stack 4096

; после знака @ указывается общая длина передаваемых параметров, после двоеточия указывается тип внешнего объекта – процедура
EXTERN	GetStdHandle@4		: PROC
EXTERN  WriteConsoleA@20	: PROC
EXTERN  CharToOemA@8		: PROC
EXTERN  ReadConsoleA@20		: PROC
EXTERN  ExitProcess@4		: PROC	; функция выхода из программы
EXTERN  lstrlenA@4			: PROC	; функция определения длины строки
EXTERN  wsprintfA			: PROC	; т.к. число параметров функции не фиксировано, используется соглашение, согласно которому очищает стек вызывающая процедура

.data
	enterNumbersMessage db "Enter the numbers: ", 13, 10, 0	; выводимая строка, в конце добавлены управляющие символы: 13 – возврат каретки, 10 – переход на новую строку, 0 – конец строки
	resultMessage		db "Result of reduction: ", 0
	errorMessage		db "An error has ocurred: ", 0

	din		dd ?	; дескриптор ввода
	dout	dd ?	; дескриптор вывода

	number0	dd 0
	number1	dd 0

	messageLength		dd ?
	buff				db 100 dup (?)
	resultMessageLength	dd 0
	resultNumber		dq " "
	resultSign			db 0

	; local variables for ReadNumber procedure
	numberLength	dd ?
	numberSign		db 0
.code

main PROC

	; перекодируем строку
	mov		eax, offset enterNumbersMessage
	push	eax 
	push	eax
	call	CharToOemA@8

	; перекодируем строку
	mov		eax, offset resultMessage
	push	eax 
	push	eax
	call	CharToOemA@8

	; перекодируем строку
	mov		eax, offset errorMessage
	push	eax 
	push	eax
	call	CharToOemA@8

	; получим дескриптор ввода 
	push	-10
	call	GetStdHandle@4
	mov		din, eax

	; получим дескриптор вывода
	push	-11
	call	GetStdHandle@4
	mov		dout, eax 

	; определяем длину строки
	push	offset resultMessage
	call	lstrlenA@4
	add		resultMessageLength, eax

	; определяем длину строки
	push	offset enterNumbersMessage
	call	lstrlenA@4

	; Выводим приглашение для ввода на экран консоли.
	push	0							; Помещаем 5-й аргумент в стек (резерв).
	push	offset messageLength		; Помещаем 4-й аргумент в стек (адрес переменной для количиства символов).
	push	eax							; Помещаем 3-й аргумент в стек (количество символов в строке).
	push	offset enterNumbersMessage	; Помещаем 2-й аргумент в стек (адрес начала строки для вывода).
	push	dout						; Помещаем 1-й аргумент в стек (дескриптор вывода).
	call	WriteConsoleA@20

	call	ReadNumber
	add		number0, eax
	
	call	ReadNumber
	mov		number1, eax

	xor		ebx, ebx

	mov		eax, number0
	sub		eax, number1

	CMP		eax, 0	 ; Сверка с нулем.
	jge		printResult
	mov		resultSign, 1   ; Если отрицательное, поменять знак.
	neg		eax
	printResult:

	xor		ecx, ecx
	mov		di, 16			; выводим в 16 СС

	convertToString:
		xor		edx, edx
		div		di			; разделить значение AX на 10,  edx:eax - делимое. di - делитель. eax - частное, edx - остаток.

		cmp		edx, 10
		jna     numeral10
		sub		edx, 10
		add		edx, 'A'

		jmp    numeral16
		numeral10:
			add		edx, '0'
		numeral16:

		push	edx
		inc		ecx			; получаем размер числа
		cmp		eax, 0
		jne		convertToString

	mov		esi, offset resultMessage
	add		esi, resultMessageLength
	add		resultMessageLength, ecx	; увеличиваем длину результирующей строки на размер числа

	cmp		resultSign, 0
	je		printStack
	mov		bl, '-'
	mov		[esi], bl					; изменить знак
	add		esi, 1
	add		resultMessageLength, 1

	printStack:
		pop		eax
		mov		[esi], eax
   		inc		esi
	LOOP printStack

	push	0
	push	offset messageLength	; адрес переменной для количиства символов
	push	resultMessageLength		; количество символов в строке
	push	offset resultMessage	; адрес начала строки для вывода
	push	dout
	call	WriteConsoleA@20

	push	0; параметр: код выхода
	call	ExitProcess@4

main ENDP

ReadNumber PROC
	
	; Ввод первого числа.
	push	0
	push	offset numberLength
	push	20
	push	offset buff
	push	din
	call	ReadConsoleA@20

	;проверка длины введенного числа
	sub		numberLength, 2		; Определяем длину строки без управляющих символов.
    cmp		numberLength, 3		; Число должно содержать не меньше 3 знаков.
	jb		error				; если меньше 3, то прыгаем на ошибку
	cmp		numberLength, 8		; Число должно содержать не больше 8 знаков.
	ja		error				; если больше 8, то прыгаем на ошибку
	mov		ecx, numberLength 
	mov		esi, offset buff
	mov		di, 10				; основание системы счисления
	xor		ebx, ebx
	xor		eax, eax

	;Проверяем, отрицательно ли первое число.
	mov		bl, [esi]
	cmp		bl, '-'
	jne		convertToNumber		; Если не минус, то переход сразу к конвертированию.
	mov		numberSign, 1		; Установить флаг отрицательности на 1 (true).
	sub		numberLength, 1		; Уменьшаем длину строки на 1.
	mov		ecx, numberLength 
	inc		esi					; Переход на следующий символ строки (цифру).

	convertToNumber:
		mov		bl, [esi]
		sub		bl, '0'			; результат в bl (ebx)
		mul		di				; умножить значение AX на 10, результат - в AX		
		add		eax, ebx
		inc		esi
	LOOP convertToNumber

	cmp		numberSign, 1		; Если изначально число отрицательное,
	je		changeSign
	
    ret

	changeSign:
		neg		eax				; то умножаем его на -1
		ret

	error:
		push	offset errorMessage
		call	lstrlenA@4
		push	0
		push	offset messageLength
		push	eax
		push	offset errorMessage
		push	dout
		call	WriteConsoleA@20

		push	0
		call	ExitProcess@4

ReadNumber ENDP

END main