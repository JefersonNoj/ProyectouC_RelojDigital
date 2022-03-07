; Archivo:	mainProyecto.s
; Dispositivo:	PIC16F887
; Autor:	Jeferson Noj
; Compilador:	pic-as (v2.30), MPLABX V5.40
;
; Programa:	
; Hardware:	
;
; Creado: 01 mar, 2022
; Última modificación:  mar, 2022

PROCESSOR 16F887
#include <xc.inc>
#include "macros_config.s"

; CONFIG1
  CONFIG  FOSC = INTRC_NOCLKOUT ; Oscillator Selection bits (INTOSCIO oscillator: I/O function on RA6/OSC2/CLKOUT pin, I/O function on RA7/OSC1/CLKIN)
  CONFIG  WDTE = OFF            ; Watchdog Timer Enable bit (WDT disabled and can be enabled by SWDTEN bit of the WDTCON register)
  CONFIG  PWRTE = ON            ; Power-up Timer Enable bit (PWRT enabled)
  CONFIG  MCLRE = OFF           ; RE3/MCLR pin function select bit (RE3/MCLR pin function is digital input, MCLR internally tied to VDD)
  CONFIG  CP = OFF              ; Code Protection bit (Program memory code protection is disabled)
  CONFIG  CPD = OFF             ; Data Code Protection bit (Data memory code protection is disabled)
  CONFIG  BOREN = OFF           ; Brown Out Reset Selection bits (BOR disabled)
  CONFIG  IESO = OFF            ; Internal External Switchover bit (Internal/External Switchover mode is disabled)
  CONFIG  FCMEN = OFF           ; Fail-Safe Clock Monitor Enabled bit (Fail-Safe Clock Monitor is disabled)
  CONFIG  LVP = OFF             ; Low Voltage Programming Enable bit (RB3/PGM pin has PGM function, low voltage programming enabled)

; CONFIG2
  CONFIG  BOR4V = BOR40V        ; Brown-out Reset Selection bit (Brown-out Reset set to 4.0V)
  CONFIG  WRT = OFF             ; Flash Program Memory Self Write Enable bits (Write protection off)

  BMODO EQU 0

PSECT udata_bank0	    ; Memoria común
  selector:	DS 1
  segundos:	DS 1
  minutos:	DS 1
  horas:	DS 1
  dias:		DS 1
  meses:	DS 1
  temp1:	DS 1
  temp2:	DS 1
  decenasM:	DS 1
  unidadesM:	DS 1
  decenasH:	DS 1
  unidadesH:	DS 1
  displayM:	DS 2
  displayH:	DS 2
  estados:	DS 1

PSECT udata_shr		    ; Memoria compartida
  W_TEMP:	DS 1		
  STATUS_TEMP:	DS 1

PSECT resVect, class=CODE, abs, delta=2
;-------- VECTOR RESET ----------
ORG 00h			    ; Posición 0000h para el reset
resetVec:
    PAGESEL main
    GOTO main

PSECT intVect, class=CODE, abs, delta=2
;-------- INTERRUPT VECTOR ----------
ORG 04h			    ; Posición 0004h para interrupciones
push:
    MOVWF   W_TEMP	    ; Mover valor de W a W_TEMP
    SWAPF   STATUS, 0	    ; Intercambiar nibbles de registro STATUS y guardar en W
    MOVWF   STATUS_TEMP	    ; Mover valor de W a STATUS_TEMP
isr: 
    BTFSC   T0IF	    ; Evaluar bandera de interrupción de TMR0
    CALL    int_tmr0
    BTFSC   TMR1IF
    CALL    int_tmr1
    BTFSC   TMR2IF
    CALL    int_tmr2
    BTFSC   RBIF
    CALL    int_portB
pop:			   
    SWAPF   STATUS_TEMP,0   ; Intercambiar nibbles de STATUS_TEMP y guardar en W
    MOVWF   STATUS	    ; Mover valor de W a registro STATUS
    SWAPF   W_TEMP, 1	    ; Intercambiar nibbles de W_TEMP y guardar en este mismo registro
    SWAPF   W_TEMP, 0	    ; Intercambiar nibbles de W_TEMP y gardar en W
    RETFIE

;------ Subrutinas de Interrupción -----
int_tmr0:
    reset_tmr0
    INCF    selector
    MOVF    selector, 0
    SUBLW   4
    BTFSC   STATUS, 2
    CLRF    selector
    RETURN

int_tmr1:
    reset_tmr1 0x85, 0xA3  ; Reiniciamos TMR1 
    INCF    segundos
    RETURN

int_tmr2:
    BCF	    TMR2IF  
    BTFSC   PORTB, 5
    GOTO    $+3
    BSF	    PORTB, 5
    GOTO    $+2
    BCF	    PORTB, 5
    RETURN

int_portB:
    BCF	    RBIF
    BTFSC   PORTB, BMODO
    GOTO    $+6
    INCF    estados
    MOVF    estados, 0
    SUBLW   4
    BTFSC   STATUS, 2
    CLRF    estados
    RETURN

PSECT code, delta=2, abs
ORG 100h		    ; Posición 0100h para el código

;-------- CONFIGURACION --------
main:
    CALL    config_clk	    ; Configuración del reloj
    CALL    config_io
    CALL    config_tmr0
    CALL    config_tmr1
    CALL    config_tmr2
    CALL    config_int
    CLRF    segundos
    CLRF    minutos
    CLRF    horas
    CLRF    estados
    BANKSEL PORTA

;-------- LOOP RRINCIPAL --------
loop:
    CALL    evaluar_estados
    ;CALL    contador_reloj
    CALL    obtenerDU_M
    CALL    obtenerDU_H
    ;CALL    config_display
    CALL    selector_disp
    GOTO    loop		; Saltar al loop principal

;----- SUBRUTINAS DE FUNCIÓN -----
evaluar_estados:
    CLRF    PCLATH	    ; Limpiar registro PCLATH
    BSF	    PCLATH, 0	    ; Posicionar PC en 0x01xxh
    MOVF    estados, 0
    ANDLW   0x03	    ; AND entre W y literal 0x04
    ADDWF   PCL		    ; ADD entre W y PCL
    GOTO    S0_reloj
    GOTO    S1_fecha
    GOTO    S2_timer
    GOTO    S3_alarma
    S0_reloj:
	CALL	contador_reloj
	CALL    config_display_reloj
	RETURN
    S1_fecha:

	RETURN
    S2_timer:

	RETURN
    S3_alarma:

	RETURN

contador_reloj:
    MOVF    segundos, 0
    SUBLW   60		    ; 60
    BTFSS   STATUS, 2
    GOTO    $+13
    INCF    minutos
    CLRF    segundos
    MOVF    minutos, 0
    SUBLW   60		    ; 60
    BTFSS   STATUS, 2
    GOTO    $+7
    INCF    horas
    CLRF    minutos
    MOVF    horas, 0
    SUBLW   24		    ; 24
    BTFSC   STATUS, 2
    CLRF    horas
    RETURN

obtenerDU_M:
    CLRF    decenasM		; Limpiar registro de la decenas
    MOVF    minutos, 0		; Guardar valor de registro dec_temp1 en dec_temp2
    MOVWF   temp1
    MOVF    temp1, 0
    MOVWF   temp2
    MOVLW   10			; Mover literal 10 a W
    SUBWF   temp1, 1		; Restar 10 al registro dec_temp1 y guardar en este mismo registro
    BTFSS   STATUS, 0		; Evaluar bit de CARRY del registro STATUS
    GOTO    obtenerU_M		; Saltar a la instrucción indicada si ocurrió overflow en el rango
    MOVF    temp1, 0		; Guardar valor de registro dec_temp1 en dec_temp2 
    MOVWF   temp2
    INCF    decenasM		; Incrementear el registro de las decenas   
    GOTO    $-7			; Saltar a la séptima instrucción anterior 
    obtenerU_M:
	MOVF    temp2, 0
	MOVWF   unidadesM
	RETURN

obtenerDU_H:
    CLRF    decenasH		; Limpiar registro de la decenas
    MOVF    horas, 0		; Guardar valor de registro dec_temp1 en dec_temp2
    MOVWF   temp1
    MOVF    temp1, 0
    MOVWF   temp2
    MOVLW   10			; Mover literal 10 a W
    SUBWF   temp1, 1		; Restar 10 al registro dec_temp1 y guardar en este mismo registro
    BTFSS   STATUS, 0		; Evaluar bit de CARRY del registro STATUS
    GOTO    obtenerU_H		; Saltar a la instrucción indicada si ocurrió overflow en el rango
    MOVF    temp1, 0		; Guardar valor de registro dec_temp1 en dec_temp2 
    MOVWF   temp2
    INCF    decenasH		; Incrementear el registro de las decenas   
    GOTO    $-7			; Saltar a la séptima instrucción anterior 
    obtenerU_H:
	MOVF    temp2, 0
	MOVWF   unidadesH
	RETURN

config_display_reloj:
    MOVF    unidadesM, 0
    CALL    tabla
    MOVWF   displayM
    MOVF    decenasM, 0
    CALL    tabla
    MOVWF   displayM+1
    MOVF    unidadesH, 0
    CALL    tabla
    MOVWF   displayH
    MOVF    decenasH, 0
    CALL    tabla
    MOVWF   displayH+1
    RETURN

selector_disp:
    CLRF    PORTD
    CLRF    PCLATH	    ; Limpiar registro PCLATH
    BSF	    PCLATH, 0	    ; Posicionar PC en 0x01xxh
    MOVF    selector, 0
    ANDLW   0x03	    ; AND entre W y literal 0x04
    ADDWF   PCL		    ; ADD entre W y PCL
    GOTO    display0
    GOTO    display1
    GOTO    display2
    GOTO    display3
    display0:
	MOVF	displayM, 0
	MOVWF	PORTC
	BSF	PORTD, 0
	RETURN
    display1:
	MOVF	displayM+1, 0
	MOVWF	PORTC
	BSF	PORTD, 1
	RETURN
    display2:
	MOVF	displayH, 0
	MOVWF	PORTC
	BSF	PORTD, 2
	RETURN
    display3:
	MOVF	displayH+1, 0
	MOVWF	PORTC
	BSF	PORTD, 3
	RETURN

;----- SUBRUTINAS DE CONFIGURACIÓN -----
config_clk:
    BANKSEL OSCCON
    BCF	    IRCF2	    ; IRCF/011/500 kHz (frecuencia de oscilación)
    BSF	    IRCF1
    BSF	    IRCF0
    BSF	    SCS		    ; Reloj interno
    RETURN

config_io:
    BANKSEL ANSEL	
    CLRF    ANSEL	    ; I/O digitales
    CLRF    ANSELH
    BANKSEL TRISA
    CLRF    TRISA	    ; PORTA como salida
    BSF	    TRISB, BMODO
    BSF	    TRISB, 1
    BSF	    TRISB, 2
    BSF	    TRISB, 3
    BSF	    TRISB, 4
    BCF	    TRISB, 5
    CLRF    TRISC
    CLRF    TRISD
    BCF	    OPTION_REG, 7
    BSF	    WPUB, BMODO
    BSF	    WPUB, 1
    BSF	    WPUB, 2
    BSF	    WPUB, 3
    BSF	    WPUB, 4
    BANKSEL PORTA
    CLRF    PORTA
    BCF	    PORTB, 5
    CLRF    PORTC
    CLRF    PORTD
    RETURN

config_tmr0:
    BANKSEL OPTION_REG
    BCF	    T0CS
    BCF	    PSA
    BCF	    PS2		    ; Prescaler/010/1:8
    BSF	    PS1
    BCF	    PS0
    reset_tmr0
    RETURN

config_tmr1:
    BANKSEL T1CON	    ; Cambiar a banco 00
    BSF	    TMR1ON	    ; Encender TMR1
    BCF	    TMR1CS	    ; Configurar con reloj interno
    BCF	    T1OSCEN	    ; Apagar oscilador LP
    BSF	    T1CKPS1	    ; Configurar prescaler 1:4
    BCF	    T1CKPS0	    
    BCF	    TMR1GE	    ; TRM1 siempre contando 
    reset_tmr1 0x85, 0xA3		    
    RETURN

config_tmr2:
    BANKSEL T2CON
    BSF	    T2CKPS1	    ; Prescaler/11/1:16
    BSF	    T2CKPS0
    BSF	    TMR2ON
    BSF	    TOUTPS3	    ; Postscaler/1111/1:16
    BSF	    TOUTPS2
    BSF	    TOUTPS1
    BSF	    TOUTPS0
    BANKSEL PR2
    MOVLW   245
    MOVWF   PR2
    RETURN

config_int:
    BANKSEL PIE1
    BSF	    TMR1IE
    BSF	    TMR2IE
    BANKSEL IOCB
    BSF	    IOCB0
    BSF	    IOCB1
    BSF	    IOCB2
    BSF	    IOCB3
    BSF	    IOCB4
    BANKSEL INTCON  
    BSF	    GIE
    BSF	    PEIE
    BSF	    RBIE
    BSF	    T0IE
    BCF	    T0IF
    BCF	    TMR1IF
    BCF	    TMR2IF
    BCF	    RBIF
    RETURN

ORG 200h		    ; Establecer posición para la tabla
tabla:
    CLRF    PCLATH	    ; Limpiar registro PCLATH
    BSF	    PCLATH, 1	    ; Posicionar PC en 0x02xxh
    ANDLW   0x0F	    ; AND entre W y literal 0x0F
    ADDWF   PCL		    ; ADD entre W y PCL 
    RETLW   00111111B	    ; 0	en 7 seg
    RETLW   00000110B	    ; 1 en 7 seg
    RETLW   01011011B	    ; 2 en 7 seg
    RETLW   01001111B	    ; 3 en 7 seg
    RETLW   01100110B	    ; 4 en 7 seg
    RETLW   01101101B	    ; 5 en 7 seg
    RETLW   01111101B	    ; 6 en 7 seg
    RETLW   00000111B	    ; 7 en 7 seg
    RETLW   01111111B	    ; 8 en 7 seg
    RETLW   01101111B	    ; 9 en 7 seg
    RETLW   01110111B	    ; 10 en 7 seg
    RETLW   01111100B	    ; 11 en 7 seg
    RETLW   00111001B	    ; 12 en 7 seg
    RETLW   01011110B	    ; 13 en 7 seg
    RETLW   01111001B	    ; 14 en 7 seg
    RETLW   01110001B	    ; 15 en 7 seg

END