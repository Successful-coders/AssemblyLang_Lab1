.386
.model flat, stdcall
.stack 4096

; после знака @ указывается общая длина передаваемых параметров,
; после двоеточия указывается тип внешнего объекта – процедура
EXTERN  GetStdHandle@4: PROC
EXTERN  WriteConsoleA@20: PROC
EXTERN  CharToOemA@8: PROC
EXTERN  ReadConsoleA@20: PROC
EXTERN  ExitProcess@4: PROC; функция выхода из программы
EXTERN  lstrlenA@4: PROC; функция определения длины строки
EXTERN  wsprintfA: PROC; т.к. число параметров функции не фиксировано,
			; используется соглашение, согласно которому очищает стек 
			; вызывающая процедура

.data
	enterNumbersMessage db "Enter the numbers: ",13,10,0; выводимая строка, в конце добавлены управляющие символы: 13 – возврат каретки, 10 – переход на новую строку, 0 – конец строки
	resultMessage db "Result of reduction: ",13,10,0;
	errorMessage db "An error has ocurred: ",0;

	din dd ?; дескриптор ввода
	dout dd ?; дескриптор вывода

	number0	dd 0
	number1	dd 0

	number0Sign db 0
	number1Sign db 0

	messageLength dd ?;
	buff dd ?;

.code

main PROC

	; перекодируем строку
	mov  eax, offset enterNumbersMessage
	push eax 
	push eax
	call CharToOemA@8

	; перекодируем строку
	mov  eax, offset resultMessage
	push eax 
	push eax
	call CharToOemA@8

	; перекодируем строку
	mov  eax, offset errorMessage
	push eax 
	push eax
	call CharToOemA@8

	; получим дескриптор ввода 
	push -10
	call GetStdHandle@4
	mov din, eax

	; получим дескриптор вывода
	push -11
	call GetStdHandle@4
	mov dout, eax 

	; определяем длину строки
	push offset enterNumbersMessage
	call lstrlenA@4

	; Выводим приглашение для ввода на экран консоли.
	push 0; Помещаем 5-й аргумент в стек (резерв).
	push offset messageLength; Помещаем 4-й аргумент в стек (адрес переменной для количиства символов).
	push eax; Помещаем 3-й аргумент в стек (количество символов в строке).
	push offset enterNumbersMessage; Помещаем 2-й аргумент в стек (адрес начала строки для вывода).
	push dout; Помещаем 1-й аргумент в стек (дескриптор вывода).
	call WriteConsoleA@20

	; Ввод первого числа.
	push 0; Помещаем 5-й аргумент в стек (резерв).
	push offset messageLength; Помещаем 4-й аргумент в стек (адрес переменной для количества символов). 
	push 20; Помещаем 3-й аргумент в стек (максимальное количество символов).
	push offset buff; Помещаем 2-й аргумент в стек (адрес начала строки для ввода).
	push din; Помещаем 1-й аргумент в стек (дескриптор ввода).
	call ReadConsoleA@20	

	;проверка длины введенного числа
	sub messageLength, 2; Определяем длину строки без управляющих символов.
    cmp messageLength, 3; Число должно содержать не меньше 3 знаков.
	jb error; если меньше 3, то прыгаем на ошибку
	cmp messageLength, 8; Число должно содержать не больше 8 знаков.
	ja error; если больше 8, то прыгаем на ошибку
	mov ecx, messageLength 
	mov esi, offset buff
	mov di, 10; основание системы счисления
	xor ebx, ebx
	xor eax, eax

	;Проверяем, отрицательно ли первое число.
	mov bl, [esi]						
	cmp bl, '-'
	jne convertToNumber; Если не минус, то переход сразу к конвертированию.
	sub messageLength, 1; Если минус, то уменьшить длину строки на 1.
	mov ecx, messageLength 
	mov number0Sign, 1; Установить флаг отрицательности на 1 (true).
	inc esi; Переход на следующий символ строки (цифру).

	convertToNumber:
		mov bl, [esi]
		sub bl, '0'
		mul di; умножить значение AX на 10, результат - в AX		
		add eax, ebx
		inc esi
	LOOP convertToNumber

	add number0, eax
	jc error

	cmp number0Sign, 1; Если изначально число отрицательное,
	je changeSign
	
	changeSign:
		neg number0; то умножаем его на -1.

	push 0; параметр: код выхода
	call ExitProcess@4

	error:
		push offset errorMessage
		call lstrlenA@4
		push 0
		push offset messageLength
		push eax
		push offset errorMessage
		push dout
		call WriteConsoleA@20

		push 0
		call ExitProcess@4

main ENDP	

END main