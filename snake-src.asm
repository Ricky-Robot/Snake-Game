title "Juego Snake"
	.model small	;64KB para memoria de programa y 64KB para memoria de datos
	.386			;Version del procesador
	.stack 64		;64 bytes para el segmento stack

	.data 			;Comienza la definicion de datos


	.code
principal:			;Inicia la parte principal del programa
	mov ax, @data 	;Movemos la dirección del segmento de datos al registro AX
	mov ds, ax 		;A partir del registro AX, asignamos la dirección del segmento de datos al registro DS



salir:				;Etiqueta donde se finaliza el programa
	mov ah, 4Ch 	;Ponemos en el registro AX los valores necesarios para terminar 
	mov al, 0 		;el programa con la interrupción 21h
	
	int 21h			;Llamamos a la interrupción 21h
	end inicio		;Indicamos que finaliza la etiqueta principal