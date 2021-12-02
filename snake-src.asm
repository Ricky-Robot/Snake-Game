title "Proyecto: Snake" ;codigo opcional. Descripcion breve del programa, el texto entrecomillado se imprime como cabecera en cada pagina de codigo
	.model small	;directiva de modelo de memoria, small => 64KB para memoria de programa y 64KB para memoria de datos
	.386			;directiva para indicar version del procesador
	.stack 64 		;Define el tamano del segmento de stack, se mide en bytes
	.data			;Definicion del segmento de datos
;Definición de constantes
;Valor ASCII de caracteres para el marco del programa
marcoEsqInfIzq 		equ 	200d 	;'╚'
marcoEsqInfDer 		equ 	188d	;'╝'
marcoEsqSupDer 		equ 	187d	;'╗'
marcoEsqSupIzq 		equ 	201d 	;'╔'
marcoCruceVerSup	equ		203d	;'╦'
marcoCruceHorDer	equ 	185d 	;'╣'
marcoCruceVerInf	equ		202d	;'╩'
marcoCruceHorIzq	equ 	204d 	;'╠'
marcoCruce 			equ		206d	;'╬'
marcoHor 			equ 	205d 	;'═'
marcoVer 			equ 	186d 	;'║'
;Atributos de color de BIOS
;Valores de color para carácter
cNegro 			equ		00h
cAzul 			equ		01h
cVerde 			equ 	02h
cCyan 			equ 	03h
cRojo 			equ 	04h
cMagenta 		equ		05h
cCafe 			equ 	06h
cGrisClaro		equ		07h
cGrisOscuro		equ		08h
cAzulClaro		equ		09h
cVerdeClaro		equ		0Ah
cCyanClaro		equ		0Bh
cRojoClaro		equ		0Ch
cMagentaClaro	equ		0Dh
cAmarillo 		equ		0Eh
cBlanco 		equ		0Fh
;Valores de color para fondo de carácter
bgNegro 		equ		00h
bgAzul 			equ		10h
bgVerde 		equ 	20h
bgCyan 			equ 	30h
bgRojo 			equ 	40h
bgMagenta 		equ		50h
bgCafe 			equ 	60h
bgGrisClaro		equ		70h
bgGrisOscuro	equ		80h
bgAzulClaro		equ		90h
bgVerdeClaro	equ		0A0h
bgCyanClaro		equ		0B0h
bgRojoClaro		equ		0C0h
bgMagentaClaro	equ		0D0h
bgAmarillo 		equ		0E0h
bgBlanco 		equ		0F0h

;Número de columnas para el área de controles
area_controles_ancho 		equ 	20d

;Definicion de variables
;Títulos
nameStr			db 		"SNAKE"
recordStr 		db 		"HI-SCORE"
scoreStr 		db 		"SCORE"
levelStr 		db 		"LEVEL"
speedStr 		db 		"SPEED"

;Variables auxiliares para posicionar cursor al imprimir en pantalla
col_aux  		db 		0
ren_aux 		db 		0

conta 			db 		0 		;contador auxiliar
tick_ms			dw 		55 		;55 ms por cada tick del sistema, esta variable se usa para operación de MUL convertir ticks a segundos
mil				dw		1000 	;dato de valor decimal 1000 para operación DIV entre 1000
diez 			dw 		10  	;dato de valor decimal 10 para operación DIV entre 10
sesenta			db 		60 		;dato de valor decimal 60 para operación DIV entre 60
status 			db 		0 		;0 stop-pause, 1 activo

;Variables para el juego
score 			dw 		0
hi_score	 	dw 		0
speed 			db 		1

;Variable 'head' de 16 bits. Datos de la cabeza de la serpiente
;Valor inicial: 00 00 0010111 01100b
head 			dw 		0000001011101100b
;Bits 0-4: Posición del renglón (0-24d)
;Bits 5-11: Posición de la columna (0-79d)
;Bits 12-13: Dirección del siguiente movimiento
	;00: derecha
	;01: arriba
	;10: izquierda
	;11: abajo
;Bits 14-15: No definidos
;Posición inicial: renglón 12, columna 23, dirección derecha

;Datos de la cola de la serpiente
;los primeros dos valores son fijos y se imprimen al inicio del juego
;el resto se deben calcular conforme avanza el juego
;El primer elemento del arreglo 'tail' es el extremo de la cola, el siguiente es el más cercano a la cola, y así sucesivamente.
tail 			dw 		0000001010101100b,0000001011001100b,1355 dup(0)
tail_conta 		dw 		2  	;contador para la longitud de la cola

;variables para las coordenadas del objeto actual en pantalla
item_col 		db 		50  	;columna
item_ren 		db 		16 		;renglon

;Variables que sirven de parametros para el procedimiento IMPRIME_BOTON
boton_caracter 	db 		0 		;caracter a imprimir
boton_renglon 	db 		0 		;renglon de la posicion inicial del boton
boton_columna 	db 		0 		;columna de la posicion inicial del boton
boton_color		db 		0  		;color del caracter a imprimir dentro del boton
boton_bg_color	db 		0 		;color del fondo del boton

;Auxiliar para calculo de coordenadas del mouse
ocho			db 		8
;Cuando el driver del mouse no esta disponible
no_mouse		db 	'No se encuentra driver de mouse. Presione [enter] para salir$'

;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;Macros;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;
;clear - Limpia pantalla
clear macro
	mov ax,0003h 	;ah = 00h, selecciona modo video
					;al = 03h. Modo texto, 16 colores
	int 10h		;llama interrupcion 10h con opcion 00h. 
				;Establece modo de video limpiando pantalla
endm

;posiciona_cursor - Cambia la posición del cursor a la especificada con 'renglon' y 'columna' 
posiciona_cursor macro renglon,columna
	mov dh,renglon	;dh = renglon
	mov dl,columna	;dl = columna
	mov bx,0
	mov ax,0200h 	;preparar ax para interrupcion, opcion 02h
	int 10h 		;interrupcion 10h y opcion 02h. Cambia posicion del cursor
endm 

;inicializa_ds_es - Inicializa el valor del registro DS y ES
inicializa_ds_es 	macro
	mov ax,@data
	mov ds,ax
	mov es,ax 		;Este registro se va a usar, junto con BP, para imprimir cadenas utilizando interrupción 10h
endm

;muestra_cursor_mouse - Establece la visibilidad del cursor del mouser
muestra_cursor_mouse	macro
	mov ax,1		;opcion 0001h
	int 33h			;int 33h para manejo del mouse. Opcion AX=0001h
					;Habilita la visibilidad del cursor del mouse en el programa
endm

;posiciona_cursor_mouse - Establece la posición inicial del cursor del mouse
posiciona_cursor_mouse	macro columna,renglon
	mov dx,renglon
	mov cx,columna
	mov ax,4		;opcion 0004h
	int 33h			;int 33h para manejo del mouse. Opcion AX=0001h
					;Habilita la visibilidad del cursor del mouse en el programa
endm

;oculta_cursor_teclado - Oculta la visibilidad del cursor del teclado
oculta_cursor_teclado	macro
	mov ah,01h 		;Opcion 01h
	mov cx,2607h 	;Parametro necesario para ocultar cursor
	int 10h 		;int 10, opcion 01h. Cambia la visibilidad del cursor del teclado
endm

;apaga_cursor_parpadeo - Deshabilita el parpadeo del cursor cuando se imprimen caracteres con fondo de color
;Habilita 16 colores de fondo
apaga_cursor_parpadeo	macro
	mov ax,1003h 		;Opcion 1003h
	xor bl,bl 			;BL = 0, parámetro para int 10h opción 1003h
  	int 10h 			;int 10, opcion 01h. Cambia la visibilidad del cursor del teclado
endm

;imprime_caracter_color - Imprime un caracter de cierto color en pantalla, especificado por 'caracter', 'color' y 'bg_color'. 
;Los colores disponibles están en la lista a continuacion;
; Colores:
; 0h: Negro
; 1h: Azul
; 2h: Verde
; 3h: Cyan
; 4h: Rojo
; 5h: Magenta
; 6h: Cafe
; 7h: Gris Claro
; 8h: Gris Oscuro
; 9h: Azul Claro
; Ah: Verde Claro
; Bh: Cyan Claro
; Ch: Rojo Claro
; Dh: Magenta Claro
; Eh: Amarillo
; Fh: Blanco
; utiliza int 10h opcion 09h
; 'caracter' - caracter que se va a imprimir
; 'color' - color que tomará el caracter
; 'bg_color' - color de fondo para el carácter en la celda
; Cuando se define el color del carácter, éste se hace en el registro BL:
; La parte baja de BL (los 4 bits menos significativos) define el color del carácter
; La parte alta de BL (los 4 bits más significativos) define el color de fondo "background" del carácter
imprime_caracter_color macro caracter,color,bg_color
	mov ah,09h				;preparar AH para interrupcion, opcion 09h
	mov al,caracter 		;AL = caracter a imprimir
	mov bh,0				;BH = numero de pagina
	mov bl,color 			
	or bl,bg_color 			;BL = color del caracter
							;'color' define los 4 bits menos significativos 
							;'bg_color' define los 4 bits más significativos 
	mov cx,1				;CX = numero de veces que se imprime el caracter
							;CX es un argumento necesario para opcion 09h de int 10h
	int 10h 				;int 10h, AH=09h, imprime el caracter en AL con el color BL
endm

;imprime_caracter_color - Imprime un caracter de cierto color en pantalla, especificado por 'caracter', 'color' y 'bg_color'. 
; utiliza int 10h opcion 09h
; 'cadena' - nombre de la cadena en memoria que se va a imprimir
; 'long_cadena' - longitud (en caracteres) de la cadena a imprimir
; 'color' - color que tomarán los caracteres de la cadena
; 'bg_color' - color de fondo para los caracteres en la cadena
imprime_cadena_color macro cadena,long_cadena,color,bg_color
	mov ah,13h				;preparar AH para interrupcion, opcion 13h
	lea bp,cadena 			;BP como apuntador a la cadena a imprimir
	mov bh,0				;BH = numero de pagina
	mov bl,color 			
	or bl,bg_color 			;BL = color del caracter
							;'color' define los 4 bits menos significativos 
							;'bg_color' define los 4 bits más significativos 
	mov cx,long_cadena		;CX = longitud de la cadena, se tomarán este número de localidades a partir del apuntador a la cadena
	int 10h 				;int 10h, AH=09h, imprime el caracter en AL con el color BL
endm

;lee_mouse - Revisa el estado del mouse
;Devuelve:
;;BX - estado de los botones
;;;Si BX = 0000h, ningun boton presionado
;;;Si BX = 0001h, boton izquierdo presionado
;;;Si BX = 0002h, boton derecho presionado
;;;Si BX = 0003h, boton izquierdo y derecho presionados
; (400,120) => 80x25 =>Columna: 400 x 80 / 640 = 50; Renglon: (120 x 25 / 200) = 15 => 50,15
;;CX - columna en la que se encuentra el mouse en resolucion 640x200 (columnas x renglones)
;;DX - renglon en el que se encuentra el mouse en resolucion 640x200 (columnas x renglones)
lee_mouse	macro
	mov ax,0003h
	int 33h
endm

;comprueba_mouse - Revisa si el driver del mouse existe
comprueba_mouse 	macro
	mov ax,0		;opcion 0
	int 33h			;llama interrupcion 33h para manejo del mouse, devuelve un valor en AX
					;Si AX = 0000h, no existe el driver. Si AX = FFFFh, existe driver
endm
;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;Fin Macros;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;

	.code
inicio:					;etiqueta inicio
	inicializa_ds_es 	;inicializa registros DS y ES
	comprueba_mouse		;macro para revisar driver de mouse
	xor ax,0FFFFh		;compara el valor de AX con FFFFh, si el resultado es zero, entonces existe el driver de mouse
	jz imprime_ui		;Si existe el driver del mouse, entonces salta a 'imprime_ui'
	;Si no existe el driver del mouse entonces se muestra un mensaje
	lea dx,[no_mouse]
	mov ax,0900h	;opcion 9 para interrupcion 21h
	int 21h			;interrupcion 21h. Imprime cadena.
	jmp fin			;salta a 'fin'
imprime_ui:
	clear 					;limpia pantalla
	oculta_cursor_teclado	;oculta cursor del mouse
	apaga_cursor_parpadeo 	;Deshabilita parpadeo del cursor
	call DIBUJA_UI 			;procedimiento que dibuja marco de la interfaz
	muestra_cursor_mouse 	;hace visible el cursor del mouse
	posiciona_cursor_mouse 10d,0d	;establece la posición del mouse en la posición
;Revisar que el boton izquierdo del mouse no esté presionado
;Si el botón no está suelto, no continúa
mouse_no_clic:
	lee_mouse

	test bx,0001h
	jnz mouse_no_clic
;Lee el mouse y avanza hasta que se haga clic en el boton izquierdo
mouse:
	lee_mouse
conversion_mouse:
	;Leer la posicion del mouse y hacer la conversion a resolucion
	;80x25 (columnas x renglones) en modo texto
	cmp cx,160 		;Verificamos si la posición del mouse esta fuera del area restringida
	ja restringir	;Si se cumple lo anterior, saltamos a la restricción del mouse

	mov ax,dx 			;Copia DX en AX. DX es un valor entre 0 y 199 (renglon)
	div [ocho] 			;Division de 8 bits
						;divide el valor del renglon en resolucion 640x200 en donde se encuentra el mouse
						;para obtener el valor correspondiente en resolucion 80x25
	xor ah,ah 			;Descartar el residuo de la division anterior
	mov dx,ax 			;Copia AX en DX. AX es un valor entre 0 y 24 (renglon)

	mov ax,cx 			;Copia CX en AX. CX es un valor entre 0 y 639 (columna)
	div [ocho] 			;Division de 8 bits
						;divide el valor de la columna en resolucion 640x200 en donde se encuentra el mouse
						;para obtener el valor correspondiente en resolucion 80x25
	xor ah,ah 			;Descartar el residuo de la division anterior
	mov cx,ax 			;Copia AX en CX. AX es un valor entre 0 y 79 (columna)

	test bx,0001h 		;Para revisar si el boton izquierdo del mouse fue presionado
	jz mouse 			;Si el boton izquierdo no fue presionado, vuelve a leer el estado del mouse

	;Si el mouse fue presionado en el renglon 11, 12 o 13
	;se revisara si se presiono un boton de velocidad
	cmp dx, 11
	je boton_speed
	cmp dx, 12
	je boton_speed
	cmp dx, 13
	je boton_speed

	;Si el mouse fue presionado en el renglon 19, 20 o 21
	;se revisara si se presiono un boton de control
	cmp dx, 19
	je boton_controles
	cmp dx, 20
	je boton_controles
	cmp dx, 21
	je boton_controles

	;Si el mouse fue presionado en el renglon 0
	;se va a revisar si fue dentro del boton [X]
	cmp dx,0
	je boton_x

	jmp mouse_no_clic

restringir:
	posiciona_cursor_mouse 160d, dx		;Como el mouse salio del area permitida, lo regresamos a la última columna permitida en su mismo renglon
	jmp mouse_no_clic 	;Volvemos a leer la posición del mouse

boton_speed:
	cmp cx, 12d
	je boton_speed_down
	cmp cx, 13d
	je boton_speed_down
	cmp cx, 14d
	je boton_speed_down

	cmp cx, 16d
	je boton_speed_up
	cmp cx, 17d
	je boton_speed_up
	cmp cx, 18d
	je boton_speed_up

	jmp mouse_no_clic

boton_speed_down:
	cmp [speed], 1d
	je mouse_no_clic
	mov al, [speed]
	dec ax
	mov [speed], al
	call IMPRIME_SPEED

	jmp mouse_no_clic

boton_speed_up:
	cmp [speed], 99d
	je mouse_no_clic
	mov al, [speed]
	inc ax
	mov [speed], al
	call IMPRIME_SPEED

	jmp mouse_no_clic

;Verificamos que botón fue el presionado de los 3 posibles
boton_controles:
	cmp cx, 3d
	je boton_pausa
	cmp cx, 4d
	je boton_pausa
	cmp cx, 5d
	je boton_pausa

	cmp cx, 9d
	je boton_reiniciar
	cmp cx, 10d
	je boton_reiniciar
	cmp cx, 11d
	je boton_reiniciar

	cmp cx, 15d
	je boton_play
	cmp cx, 16d
	je boton_play
	cmp cx, 17d
	je boton_play

boton_pausa:

boton_reiniciar:

boton_play:

boton_x:
	jmp boton_x1

;Lógica para revisar si el mouse fue presionado en [X]
;[X] se encuentra en renglon 0 y entre columnas 17 y 19
boton_x1:
	cmp cx,17
	jge boton_x2
	jmp mouse_no_clic
boton_x2:
	cmp cx,19
	jbe boton_x3
	jmp mouse_no_clic
boton_x3:
	;Se cumplieron todas las condiciones
	jmp salir

;Si no se encontró el driver del mouse, muestra un mensaje y el usuario debe salir tecleando [enter]
fin:
	mov ah,08h
	int 21h 		;opción 08h int 21h. Lee carácter del teclado sin eco
	cmp al,0Dh		;compara la entrada de teclado si fue [enter]
	jnz fin 		;Sale del ciclo hasta que presiona la tecla [enter]

salir:				;inicia etiqueta salir
	clear 			;limpia pantalla
	mov ax,4C00h	;AH = 4Ch, opción para terminar programa, AL = 0 Exit Code, código devuelto al finalizar el programa
	int 21h			;señal 21h de interrupción, pasa el control al sistema operativo

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;PROCEDIMIENTOS;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	DIBUJA_UI proc
		;imprimir esquina superior izquierda del marco
		posiciona_cursor 0,0
		imprime_caracter_color marcoEsqSupIzq,cMagentaClaro,bgNegro
		
		;imprimir esquina superior derecha del marco
		posiciona_cursor 0,79
		imprime_caracter_color marcoEsqSupDer,cMagentaClaro,bgNegro
		
		;imprimir esquina inferior izquierda del marco
		posiciona_cursor 24,0
		imprime_caracter_color marcoEsqInfIzq,cMagentaClaro,bgNegro
		
		;imprimir esquina inferior derecha del marco
		posiciona_cursor 24,79
		imprime_caracter_color marcoEsqInfDer,cMagentaClaro,bgNegro
		
		;imprimir marcos horizontales, superior e inferior
		mov cx,78 		;CX = 004Eh => CH = 00h, CL = 4Eh 
	marcos_horizontales:
		mov [col_aux],cl
		;Superior
		posiciona_cursor 0,[col_aux]
		imprime_caracter_color marcoHor,cMagentaClaro,bgNegro
		;Inferior
		posiciona_cursor 24,[col_aux]
		imprime_caracter_color marcoHor,cMagentaClaro,bgNegro
		mov cl,[col_aux]
		loop marcos_horizontales

		;imprimir marcos verticales, derecho e izquierdo
		mov cx,23 		;CX = 0017h => CH = 00h, CL = 17h 
	marcos_verticales:
		mov [ren_aux],cl
		;Izquierdo
		posiciona_cursor [ren_aux],0
		imprime_caracter_color marcoVer,cMagentaClaro,bgNegro
		;Inferior
		posiciona_cursor [ren_aux],79
		imprime_caracter_color marcoVer,cMagentaClaro,bgNegro
		;Interno
		posiciona_cursor [ren_aux],area_controles_ancho
		imprime_caracter_color marcoVer,cMagentaClaro,bgNegro
		
		mov cl,[ren_aux]
		loop marcos_verticales

		;imprimir marcos horizontales internos
		mov cx,area_controles_ancho 		;CX = 0014h => CH = 00h, CL = 14h 
	marcos_horizontales_internos:
		mov [col_aux],cl
		;Interno izquierdo (marcador player 1)
		posiciona_cursor 8,[col_aux]
		imprime_caracter_color marcoHor,cMagentaClaro,bgNegro

		;Interno derecho (marcador player 2)
		posiciona_cursor 16,[col_aux]
		imprime_caracter_color marcoHor,cMagentaClaro,bgNegro

		mov cl,[col_aux]
		loop marcos_horizontales_internos

		;imprime intersecciones internas	
		posiciona_cursor 0,area_controles_ancho
		imprime_caracter_color marcoCruceVerSup,cMagentaClaro,bgNegro
		posiciona_cursor 24,area_controles_ancho
		imprime_caracter_color marcoCruceVerInf,cMagentaClaro,bgNegro

		posiciona_cursor 8,0
		imprime_caracter_color marcoCruceHorIzq,cMagentaClaro,bgNegro
		posiciona_cursor 8,area_controles_ancho
		imprime_caracter_color marcoCruceHorDer,cMagentaClaro,bgNegro

		posiciona_cursor 16,0
		imprime_caracter_color marcoCruceHorIzq,cMagentaClaro,bgNegro
		posiciona_cursor 16,area_controles_ancho
		imprime_caracter_color marcoCruceHorDer,cMagentaClaro,bgNegro

		;imprimir [X] para cerrar programa
		posiciona_cursor 0,17
		imprime_caracter_color '[',cMagentaClaro,bgNegro
		posiciona_cursor 0,18
		imprime_caracter_color 'X',cRojoClaro,bgNegro
		posiciona_cursor 0,19
		imprime_caracter_color ']',cMagentaClaro,bgNegro

		;imprimir título
		posiciona_cursor 0,38
		imprime_cadena_color [nameStr],5,cMagentaClaro,bgNegro

		call IMPRIME_DATOS_INICIALES
		ret
	endp

	;Reinicia scores y speed, e imprime
	DATOS_INICIALES proc
		mov [score],0
		mov [hi_score],0
		mov [speed],1
		call IMPRIME_SCORE
		call IMPRIME_HISCORE
		call IMPRIME_SPEED
		ret
	endp

	;Imprime la información inicial del programa
	IMPRIME_DATOS_INICIALES proc
		call DATOS_INICIALES

		;imprime cadena 'HI-SCORE'
		posiciona_cursor 3,2
		imprime_cadena_color recordStr,8,cGrisClaro,bgNegro

		;imprime cadena 'SCORE'
		posiciona_cursor 5,2
		imprime_cadena_color scoreStr,5,cGrisClaro,bgNegro

		;imprime cadena 'SPEED'
		posiciona_cursor 12,2
		imprime_cadena_color speedStr,5,cGrisClaro,bgNegro
		
		;imprime viborita
		call IMPRIME_PLAYER

		;imprime ítem
		call IMPRIME_ITEM

		;Botón Speed down
		mov [boton_caracter],31 		;▼
		mov [boton_color],bgCyanClaro
		mov [boton_renglon],11
		mov [boton_columna],12
		call IMPRIME_BOTON

		;Botón Speed UP
		mov [boton_caracter],30 		;▲
		mov [boton_color],bgCyanClaro
		mov [boton_renglon],11
		mov [boton_columna],16
		call IMPRIME_BOTON

		;Botón Pause
		mov [boton_caracter],186 		;║
		mov [boton_color],bgCyanClaro
		mov [boton_renglon],19
		mov [boton_columna],3
		call IMPRIME_BOTON

		;Botón Stop
		mov [boton_caracter],254d 		;■
		mov [boton_color],bgCyanClaro
		mov [boton_renglon],19
		mov [boton_columna],9
		call IMPRIME_BOTON

		;Botón Start
		mov [boton_caracter],16d 		;►
		mov [boton_color],bgCyanClaro
		mov [boton_renglon],19
		mov [boton_columna],15
		call IMPRIME_BOTON

		ret
	endp

	;Procedimiento utilizado para imprimir el score actual
	;Establece las coordenadas en variables auxiliares en donde comienza a imprimir.
	;Pone el valor en BX que se imprime con el procedimiento IMPRIME_SCORE_BX
	IMPRIME_SCORE proc
		mov [ren_aux],5
		mov [col_aux],12
		mov bx,[score]
		call IMPRIME_SCORE_BX
		ret
	endp

	;Procedimiento utilizado para imprimir el score global HI-SCORE
	;Establece las coordenadas en variables auxiliares en donde comienza a imprimir.
	;Pone el valor en BX que se imprime con el procedimiento IMPRIME_SCORE_BX
	IMPRIME_HISCORE proc
		mov [ren_aux],3
		mov [col_aux],12
		mov bx,[hi_score]
		call IMPRIME_SCORE_BX
		ret
	endp

	;Imprime el valor contenido en BX
	;Se imprime un valor de 5 dígitos. Si el número es menor a 10000, se completan los 5 dígitos con ceros a la izquierda
	IMPRIME_SCORE_BX proc
		mov ax,bx 		;AX = BX
		mov cx,5 		;CX = 5. Se realizan 5 divisiones entre 10 para obtener los 5 dígitos
	;En el bloque div10, se obtiene los dígitos del número haciendo divisiones entre 10 y se almacenan en la pila
	div10:
		xor dx,dx
		div [diez]
		push dx
		loop div10
		mov cx,5
	;En el bloque imprime_digito, se recuperan los dígitos anteriores calculados para imprimirse en pantalla.
	imprime_digito:
		mov [conta],cl
		posiciona_cursor [ren_aux],[col_aux]
		pop dx
		or dl,30h
		imprime_caracter_color dl,cBlanco,bgNegro
		xor ch,ch
		mov cl,[conta]
		inc [col_aux]
		loop imprime_digito
		ret
	endp

	;Procedimiento para imprimir el valor de SPEED en pantalla
	;Se imprime en dos caracteres.
	;La variable speed es de tipo byte, su valor puede ser hasta 255d, pero solo se requieren dos dígitos
	;si speed es mayor a igual a 100d, se limita a establecerse en 99d
	IMPRIME_SPEED proc
		;Coordenadas en donde se imprime el valor de speed
		mov [ren_aux],12
		mov [col_aux],9
		;Si speed es mayor o igual a 100, se limita a 99
		cmp [speed],100d
		jb continua
		mov [speed],99d
	continua:
		;posiciona el cursor en la posición a imprimir
		posiciona_cursor [ren_aux],[col_aux]
		;Se convierte el valor de 'speed' a ASCII
		xor ah,ah 		;AH = 00h
		mov al,[speed] 	;AL = [speed]
		aam 			;AH: Decenas, AL: Unidades
		push ax 		;guarda AX temporalmente
		mov dl,ah 		;Decenas en DL
		or dl,30h 		;Convierte BCD a su ASCII
		imprime_caracter_color dl,cBlanco,bgNegro
		inc [col_aux] 	;Desplaza la columna a la derecha
		posiciona_cursor [ren_aux],[col_aux]
		pop dx 			;recupera valor de la pila
		or dl,30h  	 	;Convierte BCD a su ASCII, DL están las unidades
		imprime_caracter_color dl,cBlanco,bgNegro
		ret
	endp

	;Imprime viborita
	IMPRIME_PLAYER proc
		call IMPRIME_HEAD 
		call IMPRIME_TAIL
		ret
	endp

	;Imprime objeto en pantalla
	IMPRIME_ITEM proc
		posiciona_cursor [item_ren],[item_col]
		imprime_caracter_color 3,cVerdeClaro,bgNegro
		ret
	endp

	;Imprime la cabeza de la serpiente
	IMPRIME_HEAD proc
		mov ax,[head]
		mov dx,ax
		and ax,11111b
		mov [ren_aux],al
		and dx,111111100000b
		shr dx,5
		mov [col_aux],dl
		posiciona_cursor [ren_aux],[col_aux]
		imprime_caracter_color 2,cCyan,bgNegro
		ret
	endp

	;Imprime el cuerpo/cola de la serpiente
	;Cada valor del arreglo 'tail' iniciando en el primer elemento es un elemento del cuerpo/cola
	;Los valores establecidos en 0 son espacios reservados para el resto de los elementos.
	;Se imprimen todos los elementos iniciando en el primero, hasta que se encuentre un 0 
	IMPRIME_TAIL proc
		lea bx,[tail]
	loop_tail:
		push bx
		mov ax,[bx]
		mov dx,ax
		and ax,11111b
		mov [ren_aux],al
		and dx,111111100000b
		shr dx,5
		mov [col_aux],dl
		posiciona_cursor [ren_aux],[col_aux]
		imprime_caracter_color 254,cCyanClaro,bgNegro
		pop bx
		add bx,2
		cmp word ptr [bx],0
		jne loop_tail
		ret 
	endp

	;Borra la serpiente para reimprimirla en una posición actualizada
	BORRA_PLAYER proc
		;;;;;Completar =);;;;
		ret
	endp

	;procedimiento IMPRIME_BOTON
	;Dibuja un boton que abarca 3 renglones y 5 columnas
	;con un caracter centrado dentro del boton
	;en la posición que se especifique (esquina superior izquierda)
	;y de un color especificado
	;Utiliza paso de parametros por variables globales
	;Las variables utilizadas son:
	;boton_caracter: debe contener el caracter que va a mostrar el boton
	;boton_renglon: contiene la posicion del renglon en donde inicia el boton
	;boton_columna: contiene la posicion de la columna en donde inicia el boton
	;boton_color: contiene el color del boton
	IMPRIME_BOTON proc
	 	;background de botón
		mov ax,0600h 		;AH=06h (scroll up window) AL=00h (borrar)
		mov bh,cRojo	 	;Caracteres en color amarillo
		xor bh,[boton_color]
		mov ch,[boton_renglon]
		mov cl,[boton_columna]
		mov dh,ch
		add dh,2
		mov dl,cl
		add dl,2
		int 10h
		mov [col_aux],dl
		mov [ren_aux],dh
		dec [col_aux]
		dec [ren_aux]
		posiciona_cursor [ren_aux],[col_aux]
		imprime_caracter_color [boton_caracter],cRojo,[boton_color]
	 	ret 			;Regreso de llamada a procedimiento
	endp	 			;Indica fin de procedimiento UI para el ensamblador
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;FIN PROCEDIMIENTOS;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	end inicio			;fin de etiqueta inicio, fin de programa