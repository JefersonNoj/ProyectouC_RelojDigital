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

  BMODO	    EQU 0
  UP	    EQU 1
  DOWN	    EQU 2
  EDITAR    EQU 3
  INICIO    EQU 4

PSECT udata_bank0	    ; Memoria común
  selector:	DS 1
  segundos:	DS 1
  minutos:	DS 1
  horas:	DS 1
  dias:		DS 1
  meses:	DS 1
  temp1:	DS 1
  temp2:	DS 1
  decenasS:	DS 1
  unidadesS:	DS 1
  decenasM:	DS 1
  unidadesM:	DS 1
  decenasH:	DS 1
  unidadesH:	DS 1
  decenasD:	DS 1
  unidadesD:	DS 1
  decenasMes:	DS 1
  unidadesMes:	DS 1
  displayM:	DS 2
  displayH:	DS 2
  estados:	DS 1
  conf:		DS 1
  set_valor:	DS 1
  segundosT:	DS 1
  minutosT:	DS 1
  decenasMT:	DS 1
  unidadesMT:	DS 1
  decenasST:	DS 1
  unidadesST:	DS 1
  minutosA:	DS 1
  horasA:	DS 1
  decenasMA:	DS 1
  unidadesMA:	DS 1
  decenasHA:	DS 1
  unidadesHA:	DS 1
  segundosC:	DS 1
  minutosC:	DS 1
  decenasMC:	DS 1
  unidadesMC:	DS 1
  decenasSC:	DS 1
  unidadesSC:	DS 1
  dismD:	DS 1
  alertaT:	DS 1
  alertaA:	DS 1
  off_temp:	DS 1
  off_alarma:	DS 1

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
    ;BTFSS   conf, 0
    INCF    segundos
    BTFSC   alertaT, 1
    DECF    segundosT
    BTFSC   PORTE, 1
    INCF    off_temp
    BTFSC   alertaA, 2
    INCF    off_alarma
    BTFSC   conf, 6
    INCF    segundosC
    RETURN

int_tmr2:
    BCF	    TMR2IF  
    BTFSC   conf, 5
    GOTO    $+4
    BSF	    conf, 5
    BSF	    PORTE, 2
    GOTO    $+3
    BCF	    conf, 5
    BCF	    PORTE, 2
    RETURN

int_portB:
    BTFSC   PORTB, BMODO
    GOTO    $+6
    INCF    estados
    MOVF    estados, 0
    SUBLW   5
    BTFSC   STATUS, 2
    CLRF    estados

    BTFSC   PORTB, EDITAR
    GOTO    $+9
    BSF	    conf, 0
    INCF    set_valor
    MOVF    set_valor, 0
    SUBLW   3
    BTFSS   STATUS, 2
    GOTO    $+3
    CLRF    set_valor
    BCF	    conf, 0

    BTFSS   PORTE, 0
    GOTO    $+3
    BTFSS   PORTB, INICIO
    BCF	    PORTE, 0

    MOVF    estados, 0
    SUBLW   2
    BTFSS   STATUS, 2
    GOTO    $+10
    BTFSC   PORTB, INICIO   
    GOTO    $+8
    BTFSC   alertaT, 0
    GOTO    $+4
    BSF	    alertaT, 1
    BSF	    alertaT, 0
    GOTO    $+3
    BCF	    alertaT, 1
    BCF	    alertaT, 0

    MOVF    estados, 0
    SUBLW   3
    BTFSS   STATUS, 2
    GOTO    $+10
    BTFSC   PORTB, INICIO   
    GOTO    $+8
    BTFSC   alertaA, 0
    GOTO    $+4
    BSF	    alertaA, 0
    BSF	    alertaA, 1		   	    
    GOTO    $+3
    BCF	    alertaA, 0
    BCF	    alertaA, 1

    MOVF    estados, 0
    SUBLW   4
    BTFSS   STATUS, 2
    GOTO    $+8
    BTFSC   PORTB, INICIO   
    GOTO    $+6
    BTFSC   conf, 6
    GOTO    $+3
    BSF	    conf, 6	   	    
    GOTO    $+2
    BCF	    conf, 6

    BTFSS   PORTB, UP
    BSF	    conf, 2
    BTFSS   PORTB, DOWN
    BSF	    conf, 3
    BCF	    RBIF		; Limpiamos bandera de interrupción
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
    CALL    limpiar_variables
    BANKSEL PORTA

;-------- LOOP RRINCIPAL --------
loop:
    MOVF    alertaA, 0
    MOVWF   PORTC
    CALL    selector_disp
    CALL    evaluar_estados
    CALL    contador_reloj
    BTFSS   conf, 0		; Saltar contador fecha si se está configurando
    CALL    contador_fecha
    BTFSC   alertaA, 1
    CALL    alarma
    CALL    off_alarma_indicador
    BTFSC   conf, 6
    CALL    cronometro
    GOTO    loop		; Saltar al loop principal

;----- SUBRUTINAS DE FUNCIÓN -----
evaluar_estados:
    CLRF    PCLATH	    ; Limpiar registro PCLATH
    BSF	    PCLATH, 0	    ; Posicionar PC en 0x01xxh
    MOVF    estados, 0
    ANDLW   0x07	    ; AND entre W y literal 0x04
    ADDWF   PCL		    ; ADD entre W y PCL
    GOTO    S0_reloj
    GOTO    S1_fecha
    GOTO    S2_timer
    GOTO    S3_alarma
    GOTO    S4_cronometro
    S0_reloj:
	CALL    obtenerDU_M
	CALL    obtenerDU_H
    	CALL    config_display_reloj
	BTFSS	conf, 0
	GOTO	salirR
	BTFSS	set_valor, 0
	GOTO	setH
	setM:	
	    BTFSC	conf, 2
	    CALL	aumentarM
	    BTFSC	conf, 3
	    CALL	disminuirM
	RETURN
	setH:	
	    BTFSC	conf, 2
	    CALL	aumentarH
	    BTFSC	conf, 3
	    CALL	disminuirH
	RETURN
	salirR:
	RETURN

    S1_fecha:
	CALL    obtenerDU_Mes
	CALL    obtenerDU_D
	CALL    config_display_fecha
	BTFSS	conf, 0
	GOTO	salirF
	BTFSS	set_valor, 0
	GOTO	setD
	setMes:	
	    BTFSC	conf, 2
	    CALL	aumentarMes
	    BTFSC	conf, 3
	    CALL	disminuirMes
	RETURN
	setD:	
	    BTFSC	conf, 2
	    CALL	aumentarD
	    BTFSC	conf, 3
	    CALL	disminuirD
	RETURN
	salirF:
	RETURN
    RETURN

    S2_timer:
	BTFSC   alertaT, 1
	CALL    temporizador
	CALL    obtenerDU_ST
	CALL    obtenerDU_MT
    	CALL    config_display_timer
	CALL	off_temp_indicador
	BTFSS	conf, 0
	GOTO	salirT
	BTFSS	set_valor, 0
	GOTO	setMT
	setST:	
	    BTFSC	conf, 2
	    CALL	aumentarST
	    BTFSC	conf, 3
	    CALL	disminuirST
	RETURN
	setMT:	
	    BTFSC	conf, 2
	    CALL	aumentarMT
	    BTFSC	conf, 3
	    CALL	disminuirMT
	RETURN
	salirT:
	RETURN

    S3_alarma:
	CALL    obtenerDU_MA
	CALL    obtenerDU_HA
    	CALL    config_display_alarma
	BTFSS	conf, 0
	GOTO	salirA
	BTFSS	set_valor, 0
	GOTO	setHA
	setMA:	
	    BTFSC	conf, 2
	    CALL	aumentarMA
	    BTFSC	conf, 3
	    CALL	disminuirMA
	RETURN
	setHA:	
	    BTFSC	conf, 2
	    CALL	aumentarHA
	    BTFSC	conf, 3
	    CALL	disminuirHA
	RETURN
	salirA:
	RETURN

    S4_cronometro:
	CALL    obtenerDU_SC
	CALL    obtenerDU_MC
    	CALL    config_display_cron
	RETURN

contador_reloj:
    MOVF    segundos, 0
    SUBLW   60		    ; 60
    BTFSS   STATUS, 2
    GOTO    $+3
    CLRF    segundos
    INCF    minutos
    MOVF    minutos, 0
    SUBLW   60		    ; 60
    BTFSS   STATUS, 2
    GOTO    $+3
    CLRF    minutos
    INCF    horas
    MOVF    horas, 0
    SUBLW   24		    ; 24
    BTFSS   STATUS, 2
    GOTO    $+3
    CLRF    horas
    INCF    dias
    RETURN

contador_fecha:
    MOVF    meses, 0
    CALL    tabla_meses
    SUBWF   dias, 0	    ; 
    BTFSS   STATUS, 2
    GOTO    $+4
    MOVLW   1
    MOVWF   dias
    INCF    meses
    MOVF    meses, 0
    SUBLW   13		    ; 24
    BTFSS   STATUS, 2
    GOTO    $+3
    MOVLW   1
    MOVWF   meses
    RETURN

temporizador:
    MOVF    segundosT, 0
    SUBLW   0xFF
    BTFSS   STATUS, 2
    GOTO    $+9
    MOVLW   59		    ;60
    MOVWF   segundosT
    MOVF    minutosT, 0
    ANDLW   0x7F
    BTFSS   STATUS, 2
    GOTO    $+2
    GOTO    temp_indicador
    DECF    minutosT
    RETURN
    temp_indicador:
	BSF	PORTE, 1
	BCF	alertaT, 1
	CLRF	segundosT
	RETURN

off_temp_indicador:
    BTFSC   alertaT, 0
    GOTO    $+3
    BCF	    PORTE, 1
    CLRF    off_temp
    MOVF    off_temp, 0
    SUBLW   60
    BTFSS   STATUS, 2
    GOTO    $+3
    BCF	    PORTE, 1
    CLRF    off_temp
    RETURN

alarma:
    MOVF    minutos, 0
    SUBWF   minutosA, 0
    BTFSS   STATUS, 2
    GOTO    $+8
    MOVF    horas, 0
    SUBWF   horasA, 0
    BTFSS   STATUS, 2
    GOTO    $+4
    BSF	    PORTE, 0
    BCF	    alertaA, 1
    BSF	    alertaA, 2
    RETURN

off_alarma_indicador:
    MOVF    off_alarma, 0
    SUBLW   60
    BTFSS   STATUS, 2
    GOTO    $+5
    BCF	    PORTE, 0
    BCF	    alertaA, 2
    CLRF    off_alarma
    BSF	    alertaA, 1
    RETURN

cronometro:
    MOVF    segundosC, 0
    SUBLW   60		    ; 60
    BTFSS   STATUS, 2
    GOTO    $+3
    CLRF    segundosC
    INCF    minutosC
    MOVF    minutosC, 0
    SUBLW   100		    ; 60
    BTFSS   STATUS, 2
    GOTO    $+3
    CLRF    minutosC
    BCF	    conf, 6
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
	MOVWF	PORTA
	BTFSS	conf, 0
	GOTO	$+7
	BTFSS	set_valor, 0
	GOTO	$+5
	BTFSC	conf, 5
	GOTO	$+3
	BCF	PORTD, 0
	GOTO	$+2
	BSF	PORTD, 0
    RETURN
    display1:
	MOVF	displayM+1, 0
	MOVWF	PORTA
	BTFSS	conf, 0
	GOTO	$+7
	BTFSS	set_valor, 0
	GOTO	$+5
	BTFSC	conf, 5
	GOTO	$+3
	BCF	PORTD, 0
	GOTO	$+2
	BSF	PORTD, 1
    RETURN
    display2:
	MOVF	displayH, 0
	MOVWF	PORTA
	BTFSS	conf, 0
	GOTO	$+7
	BTFSS	set_valor, 1
	GOTO	$+5
	BTFSC	conf, 5
	GOTO	$+3
	BCF	PORTD, 0
	GOTO	$+2
	BSF	PORTD, 2
    RETURN
    display3:
	MOVF	displayH+1, 0
	MOVWF	PORTA
	BTFSS	conf, 0
	GOTO	$+7
	BTFSS	set_valor, 1
	GOTO	$+5
	BTFSC	conf, 5
	GOTO	$+3
	BCF	PORTD, 0
	GOTO	$+2
	BSF	PORTD, 3
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

aumentarM:
    INCF    minutos
    MOVF    minutos, 0
    SUBLW   60		    ; 60
    BTFSC   STATUS, 2
    CLRF    minutos
    BCF	    conf, 2
    RETURN

disminuirM:
    MOVF    minutos, 0
    XORLW   0x00
    BTFSC   STATUS, 2
    GOTO    $+3
    DECF    minutos
    GOTO    $+3
    MOVLW   59
    MOVWF   minutos
    BCF	    conf, 3
    RETURN

aumentarH:
    INCF    horas
    MOVF    horas, 0
    SUBLW   24		    ; 60
    BTFSC   STATUS, 2
    CLRF    horas
    BCF	    conf, 2
    RETURN

disminuirH:
    MOVF    horas, 0
    XORLW   0x00
    BTFSC   STATUS, 2
    GOTO    $+3
    DECF    horas
    GOTO    $+3
    MOVLW   23
    MOVWF   horas
    BCF	    conf, 3
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

obtenerDU_ST:
    CLRF    decenasST		; Limpiar registro de la decenas
    MOVF    segundosT, 0	; Guardar valor de registro dec_temp1 en dec_temp2
    MOVWF   temp1
    MOVF    temp1, 0
    MOVWF   temp2
    MOVLW   10			; Mover literal 10 a W
    SUBWF   temp1, 1		; Restar 10 al registro dec_temp1 y guardar en este mismo registro
    BTFSS   STATUS, 0		; Evaluar bit de CARRY del registro STATUS
    GOTO    obtenerU_ST		; Saltar a la instrucción indicada si ocurrió overflow en el rango
    MOVF    temp1, 0		; Guardar valor de registro dec_temp1 en dec_temp2 
    MOVWF   temp2
    INCF    decenasST		; Incrementear el registro de las decenas   
    GOTO    $-7			; Saltar a la séptima instrucción anterior 
    obtenerU_ST:
	MOVF    temp2, 0
	MOVWF   unidadesST
	RETURN

obtenerDU_MT:
    CLRF    decenasMT		; Limpiar registro de la decenas
    MOVF    minutosT, 0		; Guardar valor de registro dec_temp1 en dec_temp2
    MOVWF   temp1
    MOVF    temp1, 0
    MOVWF   temp2
    MOVLW   10			; Mover literal 10 a W
    SUBWF   temp1, 1		; Restar 10 al registro dec_temp1 y guardar en este mismo registro
    BTFSS   STATUS, 0		; Evaluar bit de CARRY del registro STATUS
    GOTO    obtenerU_MT		; Saltar a la instrucción indicada si ocurrió overflow en el rango
    MOVF    temp1, 0		; Guardar valor de registro dec_temp1 en dec_temp2 
    MOVWF   temp2
    INCF    decenasMT		; Incrementear el registro de las decenas   
    GOTO    $-7			; Saltar a la séptima instrucción anterior 
    obtenerU_MT:
	MOVF    temp2, 0
	MOVWF   unidadesMT
	RETURN

aumentarST:
    INCF    segundosT
    MOVF    segundosT, 0
    SUBLW   60		    ; 60
    BTFSC   STATUS, 2
    CLRF    segundosT
    BCF	    conf, 2
    RETURN

disminuirST:
    MOVF    segundosT, 0
    XORLW   0x00
    BTFSC   STATUS, 2
    GOTO    $+3
    DECF    segundosT
    GOTO    $+3
    MOVLW   59
    MOVWF   segundosT
    BCF	    conf, 3
    RETURN

aumentarMT:
    INCF    minutosT
    MOVF    minutosT, 0
    SUBLW   100		    ; 60
    BTFSC   STATUS, 2
    CLRF    minutosT
    BCF	    conf, 2
    RETURN

disminuirMT:
    MOVF    minutosT, 0
    XORLW   0x00
    BTFSC   STATUS, 2
    GOTO    $+3
    DECF    minutosT
    GOTO    $+3
    MOVLW   99
    MOVWF   minutosT
    BCF	    conf, 3
    RETURN

config_display_timer:
    MOVF    unidadesST, 0
    CALL    tabla
    MOVWF   displayM
    MOVF    decenasST, 0
    CALL    tabla
    MOVWF   displayM+1
    MOVF    unidadesMT, 0
    CALL    tabla
    MOVWF   displayH
    MOVF    decenasMT, 0
    CALL    tabla
    MOVWF   displayH+1
    RETURN

obtenerDU_MA:
    CLRF    decenasMA		; Limpiar registro de la decenas
    MOVF    minutosA, 0		; Guardar valor de registro dec_temp1 en dec_temp2
    MOVWF   temp1
    MOVF    temp1, 0
    MOVWF   temp2
    MOVLW   10			; Mover literal 10 a W
    SUBWF   temp1, 1		; Restar 10 al registro dec_temp1 y guardar en este mismo registro
    BTFSS   STATUS, 0		; Evaluar bit de CARRY del registro STATUS
    GOTO    obtenerU_MA		; Saltar a la instrucción indicada si ocurrió overflow en el rango
    MOVF    temp1, 0		; Guardar valor de registro dec_temp1 en dec_temp2 
    MOVWF   temp2
    INCF    decenasMA		; Incrementear el registro de las decenas   
    GOTO    $-7			; Saltar a la séptima instrucción anterior 
    obtenerU_MA:
	MOVF    temp2, 0
	MOVWF   unidadesMA
	RETURN

obtenerDU_HA:
    CLRF    decenasHA		; Limpiar registro de la decenas
    MOVF    horasA, 0		; Guardar valor de registro dec_temp1 en dec_temp2
    MOVWF   temp1
    MOVF    temp1, 0
    MOVWF   temp2
    MOVLW   10			; Mover literal 10 a W
    SUBWF   temp1, 1		; Restar 10 al registro dec_temp1 y guardar en este mismo registro
    BTFSS   STATUS, 0		; Evaluar bit de CARRY del registro STATUS
    GOTO    obtenerU_HA		; Saltar a la instrucción indicada si ocurrió overflow en el rango
    MOVF    temp1, 0		; Guardar valor de registro dec_temp1 en dec_temp2 
    MOVWF   temp2
    INCF    decenasHA		; Incrementear el registro de las decenas   
    GOTO    $-7			; Saltar a la séptima instrucción anterior 
    obtenerU_HA:
	MOVF    temp2, 0
	MOVWF   unidadesHA
	RETURN

aumentarMA:
    INCF    minutosA
    MOVF    minutosA, 0
    SUBLW   60		    ; 60
    BTFSC   STATUS, 2
    CLRF    minutosA
    BCF	    conf, 2
    RETURN

disminuirMA:
    MOVF    minutosA, 0
    XORLW   0x00
    BTFSC   STATUS, 2
    GOTO    $+3
    DECF    minutosA
    GOTO    $+3
    MOVLW   59
    MOVWF   minutosA
    BCF	    conf, 3
    RETURN

aumentarHA:
    INCF    horasA
    MOVF    horasA, 0
    SUBLW   24		    ; 60
    BTFSC   STATUS, 2
    CLRF    horasA
    BCF	    conf, 2
    RETURN

disminuirHA:
    MOVF    horasA, 0
    XORLW   0x00
    BTFSC   STATUS, 2
    GOTO    $+3
    DECF    horasA
    GOTO    $+3
    MOVLW   23
    MOVWF   horasA
    BCF	    conf, 3
    RETURN

config_display_alarma:
    MOVF    unidadesMA, 0
    CALL    tabla
    MOVWF   displayM
    MOVF    decenasMA, 0
    CALL    tabla
    MOVWF   displayM+1
    MOVF    unidadesHA, 0
    CALL    tabla
    MOVWF   displayH
    MOVF    decenasHA, 0
    CALL    tabla
    MOVWF   displayH+1
    RETURN

obtenerDU_Mes:
    CLRF    decenasMes		; Limpiar registro de la decenas
    MOVF    meses, 0		; Guardar valor de registro dec_temp1 en dec_temp2
    MOVWF   temp1
    MOVF    temp1, 0
    MOVWF   temp2
    MOVLW   10			; Mover literal 10 a W
    SUBWF   temp1, 1		; Restar 10 al registro dec_temp1 y guardar en este mismo registro
    BTFSS   STATUS, 0		; Evaluar bit de CARRY del registro STATUS
    GOTO    obtenerU_Mes	; Saltar a la instrucción indicada si ocurrió overflow en el rango
    MOVF    temp1, 0		; Guardar valor de registro dec_temp1 en dec_temp2 
    MOVWF   temp2
    INCF    decenasMes		; Incrementear el registro de las decenas   
    GOTO    $-7			; Saltar a la séptima instrucción anterior 
    obtenerU_Mes:
	MOVF	temp2, 0
	MOVWF   unidadesMes
	RETURN

obtenerDU_D:
    CLRF    decenasD		; Limpiar registro de la decenas
    MOVF    dias, 0		; Guardar valor de registro dec_temp1 en dec_temp2
    MOVWF   temp1
    MOVF    temp1, 0
    MOVWF   temp2
    MOVLW   10			; Mover literal 10 a W
    SUBWF   temp1, 1		; Restar 10 al registro dec_temp1 y guardar en este mismo registro
    BTFSS   STATUS, 0		; Evaluar bit de CARRY del registro STATUS
    GOTO    obtenerU_D		; Saltar a la instrucción indicada si ocurrió overflow en el rango
    MOVF    temp1, 0		; Guardar valor de registro dec_temp1 en dec_temp2 
    MOVWF   temp2
    INCF    decenasD		; Incrementear el registro de las decenas   
    GOTO    $-7			; Saltar a la séptima instrucción anterior 
    obtenerU_D:
	MOVF    temp2, 0
	MOVWF   unidadesD
	RETURN

aumentarMes:
    INCF    meses
    MOVF    meses, 0
    SUBLW   13		    ; 12
    BTFSS   STATUS, 2
    GOTO    $+3
    MOVLW   1
    MOVWF   meses
    BCF	    conf, 2
    RETURN

disminuirMes:
    MOVF    meses, 0
    SUBLW   0x01
    BTFSC   STATUS, 2
    GOTO    $+3
    DECF    meses
    GOTO    $+3
    MOVLW   12
    MOVWF   meses
    BCF	    conf, 3
    RETURN

aumentarD:
    INCF    dias
    MOVF    meses, 0
    CALL    tabla_meses
    SUBWF   dias, 0	    ; PENDIENTE
    BTFSS   STATUS, 2
    GOTO    $+3
    MOVLW   1
    MOVWF   dias
    BCF	    conf, 2
    RETURN

disminuirD:
    MOVF    dias, 0
    SUBLW   0x01	    ; PENDIENTE
    BTFSC   STATUS, 2
    GOTO    $+3
    DECF    dias
    GOTO    $+7
    MOVF    meses, 0
    CALL    tabla_meses
    MOVWF   dismD
    MOVLW   1
    SUBWF   dismD, 0
    MOVWF   dias
    BCF	    conf, 3
    RETURN

config_display_fecha:
    MOVF    unidadesMes, 0
    CALL    tabla
    MOVWF   displayM
    MOVF    decenasMes, 0
    CALL    tabla
    MOVWF   displayM+1
    MOVF    unidadesD, 0
    CALL    tabla
    MOVWF   displayH
    MOVF    decenasD, 0
    CALL    tabla
    MOVWF   displayH+1
    RETURN

obtenerDU_SC:
    CLRF    decenasSC		; Limpiar registro de la decenas
    MOVF    segundosC, 0	; Guardar valor de registro dec_temp1 en dec_temp2
    MOVWF   temp1
    MOVF    temp1, 0
    MOVWF   temp2
    MOVLW   10			; Mover literal 10 a W
    SUBWF   temp1, 1		; Restar 10 al registro dec_temp1 y guardar en este mismo registro
    BTFSS   STATUS, 0		; Evaluar bit de CARRY del registro STATUS
    GOTO    obtenerU_SC		; Saltar a la instrucción indicada si ocurrió overflow en el rango
    MOVF    temp1, 0		; Guardar valor de registro dec_temp1 en dec_temp2 
    MOVWF   temp2
    INCF    decenasSC		; Incrementear el registro de las decenas   
    GOTO    $-7			; Saltar a la séptima instrucción anterior 
    obtenerU_SC:
	MOVF    temp2, 0
	MOVWF   unidadesSC
	RETURN

obtenerDU_MC:
    CLRF    decenasMC		; Limpiar registro de la decenas
    MOVF    minutosC, 0		; Guardar valor de registro dec_temp1 en dec_temp2
    MOVWF   temp1
    MOVF    temp1, 0
    MOVWF   temp2
    MOVLW   10			; Mover literal 10 a W
    SUBWF   temp1, 1		; Restar 10 al registro dec_temp1 y guardar en este mismo registro
    BTFSS   STATUS, 0		; Evaluar bit de CARRY del registro STATUS
    GOTO    obtenerU_MC		; Saltar a la instrucción indicada si ocurrió overflow en el rango
    MOVF    temp1, 0		; Guardar valor de registro dec_temp1 en dec_temp2 
    MOVWF   temp2
    INCF    decenasMC		; Incrementear el registro de las decenas   
    GOTO    $-7			; Saltar a la séptima instrucción anterior 
    obtenerU_MC:
	MOVF    temp2, 0
	MOVWF   unidadesMC
	RETURN

aumentarSC:
    INCF    segundosC
    MOVF    segundosC, 0
    SUBLW   60		    ; 60
    BTFSC   STATUS, 2
    CLRF    segundosC
    BCF	    conf, 2
    RETURN

disminuirSC:
    MOVF    segundosC, 0
    XORLW   0x00
    BTFSC   STATUS, 2
    GOTO    $+3
    DECF    segundosC
    GOTO    $+3
    MOVLW   59
    MOVWF   segundosC
    BCF	    conf, 3
    RETURN

aumentarMC:
    INCF    minutosC
    MOVF    minutosC, 0
    SUBLW   100		    ; 60
    BTFSC   STATUS, 2
    CLRF    minutosC
    BCF	    conf, 2
    RETURN

disminuirMC:
    MOVF    minutosC, 0
    XORLW   0x00
    BTFSC   STATUS, 2
    GOTO    $+3
    DECF    minutosC
    GOTO    $+3
    MOVLW   99
    MOVWF   minutosC
    BCF	    conf, 3
    RETURN

config_display_cron:
    MOVF    unidadesSC, 0
    CALL    tabla
    MOVWF   displayM
    MOVF    decenasSC, 0
    CALL    tabla
    MOVWF   displayM+1
    MOVF    unidadesMC, 0
    CALL    tabla
    MOVWF   displayH
    MOVF    decenasMC, 0
    CALL    tabla
    MOVWF   displayH+1
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
    BSF	    TRISB, UP
    BSF	    TRISB, DOWN
    BSF	    TRISB, EDITAR
    BSF	    TRISB, INICIO
    CLRF    TRISC
    CLRF    TRISD
    CLRF    TRISE
    BCF	    OPTION_REG, 7
    BSF	    WPUB, BMODO
    BSF	    WPUB, UP
    BSF	    WPUB, DOWN
    BSF	    WPUB, EDITAR
    BSF	    WPUB, INICIO
    BANKSEL PORTA
    CLRF    PORTA
    CLRF    PORTC
    CLRF    PORTD
    CLRF    PORTE
    RETURN

config_tmr0:
    BANKSEL OPTION_REG
    BCF	    T0CS
    BCF	    PSA
    BSF	    PS2		    ; Prescaler/110/1:128
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
    BSF	    IOCB, 0
    BSF	    IOCB, 1
    BSF	    IOCB, 2
    BSF	    IOCB, 3
    BSF	    IOCB, 4
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

limpiar_variables:
    CLRF    selector
    CLRF    temp1
    CLRF    temp2
    CLRF    segundos
    CLRF    minutos
    CLRF    horas
    CLRF    decenasS
    CLRF    unidadesS
    CLRF    decenasM
    CLRF    unidadesM
    CLRF    decenasH
    CLRF    unidadesH
    CLRF    dias
    BSF	    dias, 0
    CLRF    meses
    BSF	    meses, 0
    CLRF    decenasD
    CLRF    unidadesD
    CLRF    decenasMes
    CLRF    unidadesMes
    CLRF    displayM
    CLRF    displayH
    CLRF    estados
    CLRF    conf
    CLRF    set_valor
    CLRF    dismD
    CLRF    segundosT
    CLRF    minutosT
    CLRF    decenasMT
    CLRF    unidadesMT
    CLRF    decenasST
    CLRF    unidadesST
    CLRF    minutosA
    CLRF    horasA
    CLRF    decenasMA
    CLRF    unidadesMA
    CLRF    decenasHA
    CLRF    unidadesHA
    CLRF    segundosC
    CLRF    minutosC
    CLRF    decenasMC
    CLRF    unidadesMC
    CLRF    decenasSC
    CLRF    unidadesSC
    CLRF    alertaT
    CLRF    alertaA
    CLRF    off_temp
    CLRF    off_alarma
    RETURN

ORG 600h		    ; Establecer posición para la tabla
tabla:
    CLRF    PCLATH	    ; Limpiar registro PCLATH
    BSF	    PCLATH, 1	    ; Posicionar PC en 0x06xxh
    BSF	    PCLATH, 2
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

tabla_meses:
    CLRF    PCLATH	    ; Limpiar registro PCLATH
    BSF	    PCLATH, 1	    ; Posicionar PC en 0x06xxh
    BSF	    PCLATH, 2
    ANDLW   0x0F	    ; AND entre W y literal 0x0F
    ADDWF   PCL		    ; ADD entre W y PCL 
    RETLW   31	    ; 0	en 7 seg
    RETLW   32	    ; 1 en 7 seg
    RETLW   29	    ; 2 en 7 seg
    RETLW   32	    ; 3 en 7 seg
    RETLW   31	    ; 4 en 7 seg
    RETLW   32	    ; 5 en 7 seg
    RETLW   31	    ; 6 en 7 seg
    RETLW   32	    ; 7 en 7 seg
    RETLW   32	    ; 8 en 7 seg
    RETLW   31	    ; 9 en 7 seg
    RETLW   32	    ; 10 en 7 seg
    RETLW   31	    ; 11 en 7 seg
    RETLW   32	    ; 12 en 7 seg

END