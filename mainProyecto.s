; Archivo:	mainProyecto.s
; Dispositivo:	PIC16F887
; Autor:	Jeferson Noj
; Compilador:	pic-as (v2.30), MPLABX V5.40
;
; Programa:	Reloj Digital (Hora, fecha, timer, alarma y cron�metro)
; Hardware:	Display 7 seg 4 d�gitos en PORTA, LEDs en PORTC, 
;		pushbuttons en PORTB y transisotres en PORTD
; Creado: 01 mar, 2022
; �ltima modificaci�n:  23 mar, 2022

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

PSECT udata_bank0	    ; Memoria com�n
  selector:	DS 1	    ; Selector de display
  segundos:	DS 1	    ; Registro de segundos para modo reloj
  minutos:	DS 1	    ; Registro de minutos para modo reloj
  horas:	DS 1	    ; Registro de horas para modo reloj
  dias:		DS 1	    ; Registro de d�as para modo fecha
  meses:	DS 1	    ; Registro de meses para modo fecha
  temp1:	DS 1	    ; Registro temporal para operar divisi�n
  temp2:	DS 1	    ; Registro temporal para operar divisi�n
  decenasS:	DS 1	    ; Registro decenas de segundo (reloj)
  unidadesS:	DS 1	    ; Registro unidades de segundo (reloj)
  decenasM:	DS 1	    ; Registro decenas de minutos (reloj)
  unidadesM:	DS 1	    ; Registro unidades de minutos (reloj)
  decenasH:	DS 1	    ; Registro decenas de horas (reloj)
  unidadesH:	DS 1	    ; Registro unidades de horas (reloj)
  decenasD:	DS 1	    ; Registro decenas de d�as (fecha)
  unidadesD:	DS 1	    ; Registro unidades de dias (fecha)
  decenasMes:	DS 1	    ; Registro decenas de mes (fecha)
  unidadesMes:	DS 1	    ; Registro unidades de mes (fecha)
  displayM:	DS 2	    ; Registro para display 0 y 1
  displayH:	DS 2	    ; Registro para display 2 y 3
  estados:	DS 1	    ; Registro de estados 
  conf:		DS 1	    ; Registro de banderas para modo configuraci�n
  set_valor:	DS 1	    ; 
  segundosT:	DS 1	    ; Registro de segundos para modo temporizador
  minutosT:	DS 1	    ; Registro de minutos para modo teporizador
  decenasMT:	DS 1	    ; Registro decenas de minutos (timer)
  unidadesMT:	DS 1	    ; Registro unidades de minutos (timer)
  decenasST:	DS 1	    ; Registro decenas de segundo (timer)
  unidadesST:	DS 1	    ; Registro unidades de segundo (timer)
  minutosA:	DS 1	    ; Registro de minutos para modo alarma
  horasA:	DS 1	    ; Registro de horas para modo alarma 
  decenasMA:	DS 1	    ; Registro de decenas de minutos (alarma)
  unidadesMA:	DS 1	    ; Registro de unidades de minutos (alarma)
  decenasHA:	DS 1	    ; Registro de decenas de horas (alarma)
  unidadesHA:	DS 1	    ; Registro de unidades de horas (alarma)
  segundosC:	DS 1	    ; Registro de segundos para modo cron�metro
  minutosC:	DS 1	    ; Registro de minutos para modo cron�metro
  decenasMC:	DS 1	    ; Registro decenas de minutos (cron�metro)
  unidadesMC:	DS 1	    ; Registro unidades de minutos (cron�metro)
  decenasSC:	DS 1	    ; Registro decenas de segundos (cron�metro)
  unidadesSC:	DS 1	    ; Registro unidades de segundos (cron�metro)
  dismD:	DS 1
  alertaT:	DS 1	    ; Registro de alerta para modo temporizador
  alertaA:	DS 1	    ; Registro de alerta para modo alarma 
  off_temp:	DS 1	    ; Registro de banderas para apagar alerta de timer
  off_alarma:	DS 1	    ; Registro de banderas para apagar alerta de alarma

PSECT udata_shr		    ; Memoria compartida
  W_TEMP:	DS 1		
  STATUS_TEMP:	DS 1

PSECT resVect, class=CODE, abs, delta=2
;-------- VECTOR RESET ----------
ORG 00h			    ; Posici�n 0000h para el reset
resetVec:
    PAGESEL main
    GOTO main

PSECT intVect, class=CODE, abs, delta=2
;-------- INTERRUPT VECTOR ----------
ORG 04h			    ; Posici�n 0004h para interrupciones
push:
    MOVWF   W_TEMP	    ; Mover valor de W a W_TEMP
    SWAPF   STATUS, 0	    ; Intercambiar nibbles de registro STATUS y guardar en W
    MOVWF   STATUS_TEMP	    ; Mover valor de W a STATUS_TEMP
isr: 
    BTFSC   T0IF	    ; Evaluar bandera de interrupci�n de TMR0
    CALL    int_tmr0	    ; Si T0IF = 1, ir a subrutina de interrupci�n de TMR0
    BTFSC   TMR1IF	    ; Evaluar bandera de interrupci�n de TMR1
    CALL    int_tmr1	    ; Si TMR1IF = 1, ir a subrutina de interrupci�n de TMR1
    BTFSC   TMR2IF	    ; Evaluar bandera de interrupci�n de TMR2
    CALL    int_tmr2	    ; Si TMR2IF = 1, ir a subrutina de interrupci�n de TMR2
    BTFSC   RBIF	    ; Evaluar bandera de interrupci�n de PORTB
    CALL    int_portB	    ; Si RBIF = 1, ir a subrutina de interrupci�n de PORTB
pop:			   
    SWAPF   STATUS_TEMP,0   ; Intercambiar nibbles de STATUS_TEMP y guardar en W
    MOVWF   STATUS	    ; Mover valor de W a registro STATUS
    SWAPF   W_TEMP, 1	    ; Intercambiar nibbles de W_TEMP y guardar en este mismo registro
    SWAPF   W_TEMP, 0	    ; Intercambiar nibbles de W_TEMP y gardar en W
    RETFIE

;------ Subrutinas de Interrupci�n -----
int_tmr0:
    reset_tmr0		    ; Ejecutar macro que reinicia el TMR0
    INCF    selector	    ; Incrementar selector de display
    MOVF    selector, 0	    ; Mover registro selector a W y restar la literal 4
    SUBLW   4		    
    BTFSC   STATUS, 2	    ; Evaluar ZERO para determinar si selector es igual a 4
    CLRF    selector	    ; Si es igual, limpiar registro selector 
    RETURN

int_tmr1:
    reset_tmr1 0x85, 0xA3   ; Ejecutar macro que reinicia el TRM1
    ;BTFSS   conf, 0	    
    INCF    segundos	    ; Incrementar segundos del modo reloj
    BTFSC   alertaT, 1	    ; Evaluar bit 1 de registro "alertaT" (activar timer)
    DECF    segundosT	    ; Si es igual a 1, decrementar segundos del modo timer
    BTFSC   PORTE, 1	    ; Evaluar pin 1 del puerto E (alerta de timer)
    INCF    off_temp	    ; Si es igual a 1, incremnetar registro "off_temp"
    BTFSC   alertaA, 2	    ; Evaluar bit 2 de registro "alertaA" (alerta de alarma)
    INCF    off_alarma	    ; Si es igual a 1, incrementar registro "off_alarma" 
    BTFSC   conf, 6	    ; Evaluar bit 6 de registro "conf" (activar cron�metro)
    INCF    segundosC	    ; Si es igual a 1, incrementar segundos del modo cron�metro
    RETURN

int_tmr2:
    BCF	    TMR2IF	    ; Limpiara bandera de TMR2
    BTFSC   conf, 5	    ; Evaluar bit 5 de registro "conf"
    GOTO    $+4		    ; Si es igual a 1, saltar a la cuarta instrucci�n siguiente
    BSF	    conf, 5	    ; Encender bit 5 de registro "conf"
    BSF	    PORTE, 2	    ; Encender pin 2 del PORTE
    GOTO    $+3		    ; Saltar a la tercera instrucci�n siguiente
    BCF	    conf, 5	    ; Apagar bit 5 de registro "conf"
    BCF	    PORTE, 2	    ; Apagar pin 2 del PORTE
    RETURN

int_portB:  
    BTFSC   PORTB, BMODO    ; Evaluar boton de modo
    GOTO    $+6		    ; Si no se presion�, saltar a la sexta instrucci�n siguiente
    INCF    estados	    ; Incrementar registro "estados"
    MOVF    estados, 0	    ; Mover estados a W y restar la literal 5
    SUBLW   5
    BTFSC   STATUS, 2	    ; Evaluar ZERO para determinar si estados es igual a 5
    CLRF    estados	    ; Si es igual, limpiar registro "estados"

    BTFSC   PORTB, EDITAR   ; Evaluar boton de edici�n (configuraci�n manual)
    GOTO    $+9		    ; Si no se presion�, saltar a la novena instrucci�n siguiente
    BSF	    conf, 0	    ; Encender bit 0 de registro "conf"
    INCF    set_valor	    ; Incrementar registro "set_valor"
    MOVF    set_valor, 0    ; Mover registro "set_valor" a w y restar la literal 3
    SUBLW   3
    BTFSS   STATUS, 2	    ; Evaluar ZERO para determinar si "set_valor" es igual a 3
    GOTO    $+3		    ; Si no es igual, saltar a la tercera instrucci�n siguiente
    CLRF    set_valor	    ; Si es igual, limpiar registro "set_valor"
    BCF	    conf, 0	    ; Limpiar bit 0 de registro "conf"

    BTFSS   PORTE, 0	    ; Evaluar estado del pin 0 del PORTE (alerta de alarma)
    GOTO    $+5		    ; Saltar a la quinta instrucci�n siguiente si no esta encendido
    BTFSC   PORTB, INICIO   ; Evaluar boton de inicio (inicio/pausa)
    GOTO    $+3		    ; Si no se presion�, saltar a la tercera instrucci�n siguiente
    BCF	    PORTE, 0	    ; Si se presion�, limpiar pin 0 del PORTE
    BCF	    alertaA, 3	    ; Limpiar bit 3 del registro "alertaA"

    MOVF    estados, 0	    ; Mover registro estados a w y restar la literal 2
    SUBLW   2
    BTFSS   STATUS, 2	    ; Evaluar ZERO para determinar si est� en modo timer
    GOTO    $+10	    ; Si no, saltar a la d�cima instrucci�n siguiente
    BTFSC   PORTB, INICIO   ; Evaluar boton de inicio 
    GOTO    $+8		    ; Si no se presin�, ir a la octava instrucci�n siguiente
    BTFSC   alertaT, 0	    ; Si se presion�, evaluar bit 0 de registro "alertaT"
    GOTO    $+4		    ; Si es igual a 1, ir a la cuarta instrucci�n siguiente
    BSF	    alertaT, 1	    ; Encender bit 1 del registro "alertaT"
    BSF	    alertaT, 0	    ; Encender bit 0 del registro "alertaT"
    GOTO    $+3		    ; Ir a la tercera instrucci�n siguiente
    BCF	    alertaT, 1	    ; Apagar bit 1 del registro "alertaT"
    BCF	    alertaT, 0	    ; Apagar bit 0 del registro "alertaT"

    MOVF    estados, 0	    ; Mover registro estados a w y restar la literal 3
    SUBLW   3		     
    BTFSS   STATUS, 2	    ; Evaluar ZERO para determinar si est� en modo alarma
    GOTO    $+10	    ; Si no, ir a la decima instrucci�n siguiente
    BTFSC   PORTB, INICIO   ; Evaluar boton de inicio 
    GOTO    $+8		    ; Si no se presion�, ir a la octava instrucci�n siguiente
    BTFSC   alertaA, 0	    ; Si se presion�, evaluar bit 0 del registro "alertaA" 
    GOTO    $+4		    ; Si es igual a 1, ir a la cuarta instrucci�n siguiente
    BSF	    alertaA, 0	    ; Encender bit 0 del registro "alertaA"
    BSF	    alertaA, 1	    ; Encender bit 1 del registro "alertaA"
    GOTO    $+3		    ; Ir a la tercera instrucci�n siguiente
    BCF	    alertaA, 0	    ; Apagar bit 0 del registro "alertaA"
    BCF	    alertaA, 1	    ; Apagar bit 1 del registro "alertaA"

    MOVF    estados, 0	    ; Mover registro estados a w y restar la literal 4
    SUBLW   4		    
    BTFSS   STATUS, 2	    ; Evaluar ZERO para determinar si est� en modo cron�metro
    GOTO    $+12	    ; Si no, ir a la doceava instrucci�n siguiente
    BTFSC   PORTB, INICIO   ; Evaluar boton de inicio
    GOTO    $+6		    ; Si no se presion�, ir a la sexta instrucci�n siguiente
    BTFSC   conf, 6	    ; Si se presion�, evaluar bit 6 del registro "conf"
    GOTO    $+3		    ; Si es igual a 1, ir a la tercera instrucci�n siguiente
    BSF	    conf, 6	    ; Encender bit 6 d
    GOTO    $+2
    BCF	    conf, 6
    BTFSC   PORTB, UP	    ; Evaluar boton de incremento
    GOTO    $+3		    ; Si no se presion�, saltar a la tercera instrucci�n siguiente
    CLRF    segundosC	    ; Limpiar/reiniciar segundos de modo cron�metro
    CLRF    minutosC	    ; Limpiar/reiniciar minutos de modo cron�metro 

    BTFSS   PORTB, UP	    ; Evaluar boton de incremento
    BSF	    conf, 2	    ; Si se presion�, encender bit 2 del registro "conf"
    BTFSS   PORTB, DOWN	    ; Evaluar boton de decremento
    BSF	    conf, 3	    ; Si se presion�, encender bit 3 del registro "conf"
    BCF	    RBIF	    ; Limpiar bandera de interrupci�n
    RETURN

PSECT code, delta=2, abs
ORG 100h		    ; Posici�n 0100h para el c�digo

;-------- CONFIGURACION --------
main:
    CALL    config_clk		; Configuraci�n del reloj
    CALL    config_io		; Configuraci�n de entradas y salidas
    CALL    config_tmr0		; Configuraci�n del TMR0
    CALL    config_tmr1		; Configuraci�n del TRM1
    CALL    config_tmr2		; Configuraci�n del TRM2
    CALL    config_int		; Configuraci�n de interrupciones
    CALL    limpiar_variables	; Limpiar variables implementadas
    BANKSEL PORTA

;-------- LOOP RRINCIPAL --------
loop:
    ;MOVF    alertaA, 0
    ;MOVWF   PORTC
    CALL    selector_disp	; Subrutina que ejecuta el multiplexado de displays
    CALL    evaluar_estados	; Subrutina que contiene los distintos modos
    CALL    contador_reloj	; Subrutina del contador dereloj
    BTFSS   conf, 0		; Evaluar bit 0 del registro "conf"
    CALL    contador_fecha	; Si es igual a 1, ejecutar subrutina de fecha
    BTFSC   alertaT, 1		; Evaluar bit 1 del registro "alertaT"
    CALL    temporizador	; Si es igual a 1, ejecutar subrutina para temporizador
    CALL    off_temp_indicador	; Subrutina de apagado para la alerta del timer
    BTFSC   alertaA, 1		; Evaluar bit 1 del registro "alertaA"
    CALL    alarma		; Si es igual a 1, ejecutar subrutina de alarma 
    CALL    off_alarma_indicador    ; Subrutina de apagado para la alerta de la alarma
    BTFSC   conf, 6		; Evaluar bit 6 del registro "conf"
    CALL    cronometro		; Si es igual a 1, ejecutar subrutina de cron�metro 
    GOTO    loop		; Saltar al loop principal

;----- SUBRUTINAS DE FUNCI�N -----
evaluar_estados:
    CLRF    PCLATH		    ; Limpiar registro PCLATH
    BSF	    PCLATH, 0		    ; Posicionar PC en 0x01xxh
    MOVF    estados, 0		    ; Mover registro estados a W
    ANDLW   0x07		    ; AND entre W y literal 0x07
    ADDWF   PCL			    ; ADD entre W y PCL, para direccionar
    GOTO    S0_reloj		    ; Ir a modo reloj (estado 0)
    GOTO    S1_fecha		    ; Ir a modo fecha (estado 1)
    GOTO    S2_timer		    ; Ir a modo temporizador (estado 2)
    GOTO    S3_alarma		    ; Ir a modo alarma (estado 3)
    GOTO    S4_cronometro	    ; Ir a modo cron�metro (estado 4)
    S0_reloj:
	CLRF	PORTC		    ; Limpiar PORTC
	BSF	PORTC, 3	    ; Encender pin 3 del PORTC para indicar modo reloj
	BTFSC	alertaA, 0	    ; Evaluar bit 0 del registro alertaA
	BSF	PORTC, 2	    ; Si es igual a 1, encender pin 2 del PORTC para indicar alarma activa
	CALL    obtenerDU_M	    ; Subrutina para obtener decenas y unidades de minutos
	CALL    obtenerDU_H	    ; Subrutina para obtener decenas y unidades de horas
    	CALL    config_display_reloj	; Subrutina que obtiene los valores correspondientes para los displays
	BTFSS	conf, 0		    ; Evaluar bit 0 del registro conf (si se est� configurando)
	GOTO	salirR		    ; Si no se est� configurando, salir de la subrutina 
	BTFSS	set_valor, 0	    ; Si se est� configurando, evaluar bit 0 del registro "set valor"
	GOTO	setH		    ; Si es igual a 0, ir a las instrucciones para configurar horas
	setM:	
	    BTFSC   conf, 2	    ; Evaluar bit 2 del registro conf (boton de incremento)
	    CALL    aumentarM	    ; Si est� encendido, llamar a subrutina que incrementa el registro minutos
	    BTFSC   conf, 3	    ; Evaluar bit 3 del registro conf (boton de decremento)
	    CALL    disminuirM	    ; Si est� encendido, llamar a subrutina que decrementa el registro minutos
	RETURN
	setH:	
	    BTFSC   conf, 2	    ; Evaluar bit 2 del registro conf (boton de incremento)
	    CALL    aumentarH	    ; Si est� encendido, llamar a subrutina que incrementa el registro horas
	    BTFSC   conf, 3	    ; Evaluar bit 3 del registro conf (boton de decremento)
	    CALL    disminuirH	    ; Si est� encendido, llamar a subrutina que decrementa el registro horas
	RETURN
	salirR:
	RETURN

    S1_fecha:
	CLRF	PORTC		    ; Limpiar PORTC
	BSF	PORTC, 4	    ; Encender pin 4 del PORTC para indicar modo fecha
	BTFSC	alertaA, 0	    ; Evaluar bit 0 del registro alerta 
	BSF	PORTC, 2	    ; Si es igual a 1, encender pin 2 del PORTC para indicar alarma activa 
	CALL    obtenerDU_Mes	    ; Subrutina para obtener decenas y unidades de meses
	CALL    obtenerDU_D	    ; Subrutina para obtener decenas y unidades de dias
	CALL    config_display_fecha	;Subrutina que obtiene los valores correspondientes para los displays
	BTFSS	conf, 0		    ; Evaluar bit 0 del registro conf (si se est� configurando)
	GOTO	salirF		    ; Si no se est� configurando, salir de la subrutina 
	BTFSS	set_valor, 0	    ; Si se est� configurando, evaluar bit 0 del registro "set_valor"
	GOTO	setD		    ; Si es igual a 0, ir a las instrucciones para configurar dias
	setMes:			   
	    BTFSC   conf, 2	    ; Evaluar bit 2 del registro conf (boton de incremento)
	    CALL    aumentarMes	    ; Si est� encendido, llamar a subrutina que aumenta el registro meses
	    BTFSC   conf, 3	    ; Evaluar bit 3 del registro conf (boton de decremento)
	    CALL    disminuirMes    ; Si est� encendido, llamar a subrutina que decrementa el registro meses
	RETURN
	setD:	
	    BTFSC   conf, 2	    ; Evaluar bit 2 del registro conf (boton de incremento)
	    CALL    aumentarD	    ; Si est� encendido, llamar a subrutina que incrementa el registro dias
	    BTFSC   conf, 3	    ; Evaluar bit 3 del registro conf (boton de decremento)
	    CALL    disminuirD	    ; Si est� encendido, llamar a subrutina que decrementa el registro dias
	RETURN
	salirF:
	RETURN
    RETURN

    S2_timer:
	CLRF	PORTC		    ; Limpiar PORTC
	BSF	PORTC, 5	    ; Encender pin 5 del PORTC para indicar modo temporizador 
	BTFSC	alertaA, 0	    ;  Evaluar bit 0 del registro alertaA
	BSF	PORTC, 2	    ; Si es igual a 1, encender pin 2 del PORTC para indicar alarma activa    
	CALL    obtenerDU_ST	    ; Subrutina para obtener decenas y unidades de segundos de temporizador
	CALL    obtenerDU_MT	    ; Subrutina para obtener decenas y unidades de minutos de temporizador
    	CALL    config_display_timer	; Subtutina que obtiene los valores correspondientes para los displays 
	BTFSS	conf, 0		    ; Evaluar bit 0 del registro conf (si se est� configurando)
	GOTO	salirT		    ; Si no se est� configurando, salir de la subrutina
	BTFSS	set_valor, 0	    ; Si se est� configurando, evaluar bit 0 del registro "set_valor"
	GOTO	setMT		    ; Si es igual a 0, ir a las instrucciones para configurar minutos del temporizador
	setST:			
	    BTFSC   conf, 2	    ; Evaluar bit 2 del registro conf (boton de incremento)
	    CALL    aumentarST	    ; Si est� encendido, llamar a subrutina que incrementa el registro de segundos del timer
	    BTFSC   conf, 3	    ; Evaluar bit 3 del registro conf (boton de decremento)
	    CALL    disminuirST	    ; Si est� encendido, llamar a subrutina que decrementa el registro de segundos del timer
	RETURN
	setMT:	
	    BTFSC   conf, 2	    ; Evaluar bit 2 del registro conf (boton de incremento)
	    CALL    aumentarMT	    ; Si est� encendido, llamar a subrutina que incrementa el registro de minutos del timer
	    BTFSC   conf, 3	    ; Evaluar bit 3 del registro conf (boton de decremento)
	    CALL    disminuirMT	    ; Si est� encendido, llamar a subrutina que decrementa el registro de minutos del timer
	RETURN
	salirT:
	RETURN

    S3_alarma:
	CLRF	PORTC		    ; Limpiar PORTC
	BSF	PORTC, 6	    ; Encender pin 6 del PORTC para indicar modo alarma
	BTFSC	alertaA, 0	    ; Evaluar bit 0 del registro alertaA 
	BSF	PORTC, 2	    ; Si es igual a 1, encender pin 2 del PORTC para indicar alarma activa
	CALL    obtenerDU_MA	    ; Subrutina para obtener decenas y unidades de minutos de la alarma
	CALL    obtenerDU_HA	    ; Subrutina para obtener decenas y unidades de horas de la alarma
    	CALL    config_display_alarma	; Subrutina que obtiene los valores correspondientes para los displays
	BTFSS	conf, 0		    ; Evaluar bit 0 del registro conf (si se est� configurando)
	GOTO	salirA		    ; Si no se est� configurando, salir de la subrutina
	BTFSS	set_valor, 0	    ; Si se est� configurando, evaluar bit 0 del registro "set_valor"
	GOTO	setHA		    ; Si es igual a 0, ir a las instrucciones para configurar horas de la alarma 
	setMA:	
	    BTFSC   conf, 2	    ; Evaluar bit 2 del registro conf (boton de incremento)
	    CALL    aumentarMA	    ; Si est� encendido, llamar a subrutina que incrementa el registro de minutos de la alarma
	    BTFSC   conf, 3	    ; Evaluar bit 3 del registro conf (boton de decremento)
	    CALL    disminuirMA	    ; Si est� encendido, llamar a subrutina que decrementa el registro de minutos de la alarma
	RETURN
	setHA:	
	    BTFSC   conf, 2	    ; Evaluar bit 2 del registro conf (boton de incremento)
	    CALL    aumentarHA	    ; Si est� encendido, llamar a subrutina que incrementa el registro de horas de la alarma
	    BTFSC   conf, 3	    ; Evaluar bit 3 del registro conf (boton de decremento)
	    CALL    disminuirHA	    ; Si est� encendido, llamar a subrutina que decrementa el registro de horas de la alarma
	RETURN
	salirA:
	RETURN

    S4_cronometro:
	CLRF	PORTC		    ; Limpiar PORTC
	BSF	PORTC, 7	    ; Encender pin 7 del PORTC para indicar modo cron�metro
	BTFSC	alertaA, 0	    ; Evaluar bit 0 del registro alertaA
	BSF	PORTC, 2	    ; Si es igual a 1, encender pin 2 del PORTC para indicar alarma activa
	CALL    obtenerDU_SC	    ; Subrutina para obtener decenas y unidades de segundos del cron�metro
	CALL    obtenerDU_MC	    ; Subrutina para obtener decenas y unidades de minutos del cron�metro
    	CALL    config_display_cron	; Subrutina que obtiene los valores correspondientes para los displays
	RETURN

contador_reloj:
    MOVF    segundos, 0	    ; Mover registro de segundos a W y restar la literal 60
    SUBLW   60		    
    BTFSS   STATUS, 2	    ; Evaluar ZERO para determinar si se han contado 60 segundos
    GOTO    $+3		    ; Si no han pasado 60s, ir a la tercera instrucci�n siguiente
    CLRF    segundos	    ; Si han pasado 60s, limpiar registro de segundos
    INCF    minutos	    ; Incrementar registro de minutos 
    MOVF    minutos, 0	    ; Mover registro de minutos a W y restar la literal 60 
    SUBLW   60			
    BTFSS   STATUS, 2	    ; Evaluar ZERO para determinar si se han contado 60 minutos
    GOTO    $+3		    ; Si no han pasado 60 min, ir a la tercera instrucci�n siguiente
    CLRF    minutos	    ; Si han pasado 60 min, limpiar registro de minutos
    INCF    horas	    ; Incrementar registro de horas
    MOVF    horas, 0	    ; Mover registro de horas a W y restar la literal 24
    SUBLW   24		    
    BTFSS   STATUS, 2	    ; Evaluar ZERO para determinar si se han contado 24 horas
    GOTO    $+3		    ; Si no han pasado 24 h, ir a la tercera instrucci�n siguiente
    CLRF    horas	    ; Si han pasado 24h, limpiar registro de horas
    INCF    dias	    ; Incrementar registro de d�as
    RETURN

contador_fecha:
    MOVF    meses, 0	    ; Mover registro de meses a W 
    CALL    tabla_meses	    ; Buscar los d�as que corresponden a dicho mes en la "tabla_meses"
    SUBWF   dias, 0	    ; Restar el valor recuperado al registro de d�as
    BTFSS   STATUS, 2	    ; Evaluar ZERO para determinar si se han completado los d�as del mes
    GOTO    $+4		    ; Si no se han completado, ir a la cuarta instrucci�n siguiente
    MOVLW   1		    ; Si se han completado, mover literal 1 a W
    MOVWF   dias	    ; Mover dicha literal al registro d�as para comenzar en el d�a 1
    INCF    meses	    ; Incrementar registro de meses
    MOVF    meses, 0	    ; Mover registro de meses a W y restar la literal 13
    SUBLW   13	
    BTFSS   STATUS, 2	    ; Evaluar ZERO para determinar si ya se han contado 12 meses
    GOTO    $+3		    ; Si no se han contado 12 meses, ir a la tercera instrucci�n siguiente
    MOVLW   1		    ; Si se contaron los 12 meses, mover literal a W
    MOVWF   meses	    ; Mover dicha literal al registro de meses para comenzar en el mes 1
    RETURN

temporizador:
    MOVF    segundosT, 0    ; Mover registro de segundos del timer y restar la literal 0xFF
    SUBLW   0xFF	    
    BTFSS   STATUS, 2	    ; Evaluar ZERO para determinar si han pasado 60 segundos
    GOTO    $+9		    ; Si no han pasado 60s, ir a la novena instrucci�n siguiente
    MOVLW   59		    ; Si han pasado 60s, mover literal 59 a W
    MOVWF   segundosT	    ; Mover dicha literal al registro de segundosT para comenzar en 59 segundos
    MOVF    minutosT, 0	    ; Mover valor del registro de mintuos del timer a W
    ANDLW   0x7F	    ; AND entre dicho valor y la literal 0x7F
    BTFSS   STATUS, 2	    ; Evaluar ZERO para determinar si ha llegado al minuto 0
    GOTO    $+2		    ; Si no ha llegado al minuto 0, ir a la segunda instrucci�n siguiente
    GOTO    temp_indicador  ; Si llego al minuto 0, ir a las instrucciones para la alerta del temporizador 
    DECF    minutosT	    ; Decrementar en uno el registro de minutons del temporizador
    RETURN
    temp_indicador:
	BSF	PORTE, 1    ; Encender pin 1 del PORTE (activar alerta del temporizador)
	BCF	alertaT, 1  ; Limpiar bit 1 del registro alertaT para detener el decremento del temporizador
	CLRF	segundosT   ; Limpiar registro de segundos del temporizador
	RETURN

off_temp_indicador:
    BTFSC   alertaT, 0	    ; Evaluar bit 0 del registro alertaT (boton de inicio/pausa)
    GOTO    $+3		    ; Si es igual a 1, ir a la tercera instrucci�n siguiente (apagar luego de un minuto)
    BCF	    PORTE, 1	    ; Si no, apagar bit 1 del PORTE (apagar alerta del temporizador)
    CLRF    off_temp	    ; Limpiar registro "off_temp"
    MOVF    off_temp, 0	    ; Mover valor del registro "off_temp" a W y restar la literal 60
    SUBLW   60
    BTFSS   STATUS, 2	    ; Evaluar ZERO para determinar si ha pasado un minuto desde que se activo la alerta
    GOTO    $+3		    ; Si no ha pasado un minuto, saltar a la tercera instrucci�n siguiente
    BCF	    PORTE, 1	    ; Si pas� un minuto, apatar bit 1 del PORTE (apagar alerta del temporizador)
    CLRF    off_temp	    ; Limpiar registro "off_temp"
    RETURN

alarma:
    MOVF    minutos, 0	    ; Mover valor del registro de minutos (del modo reloj) a W
    SUBWF   minutosA, 0	    ; Restar a dicho valor el valor del registro de mintuos del modo alarma
    BTFSS   STATUS, 2	    ; Evaluar ZERO para determinar si ambos valores son iguales
    GOTO    $+9		    ; Si no son iguales, ir a la novena instrucci�n siguiente
    MOVF    horas, 0	    ; Si son iguales, determinar mover el valor del registro de horas del reloj a W
    SUBWF   horasA, 0	    ; Restar a dicho valor el valor del registro de horas de la alarma
    BTFSS   STATUS, 2	    ; Evaluar ZERO para determinar si ambos valores son iguales
    GOTO    $+5		    ; Si no son iguales, ir a la quinta instrucci�n siguiente
    BSF	    PORTE, 0	    ; Si son iguales, encender pin 0 del PORTE (activar alerta de la alarma)
    BCF	    alertaA, 1	    ; Limpiar bit 1 del registro alertaA (detener comparaci�n entre valores)
    BSF	    alertaA, 2	    ; Encender bit 2 del registro alertaA (habilitar conteo de 1 minuto)
    BSF	    alertaA, 3	    ; Encender bit 3 del registro alertaA (habilitar opci�n de apagado con boton)
    RETURN

off_alarma_indicador:
    BTFSS   alertaA, 3	    ; Evaluar bit 3 del registro alertaA (opci�n de apagado con boton)
    GOTO    $+6		    ; Si es igual a 0, ir a la sexta instrucci�n siguiente
    BTFSC   conf, 5	    ; Si no, evaluar bit 5 del registro conf (bandera de 500ms)
    GOTO    $+3		    ; Si es igual a 1, ir a la tercera instruci�n siguiente (apagar RBE0)
    BCF	    PORTE, 0	    ; Si no, apagar pin 0 del PORTE (apagar alerta de alarma) 
    GOTO    $+2		    ; Ir a la segunda instrucci�n siguiente
    BSF	    PORTE, 0	    ; Eencender pin 0 del PORTE (encender alerta de alarma) 
    MOVF    off_alarma, 0   ; Mover valor del registro "off_alarma" a W y restar la literal 60
    SUBLW   60		    
    BTFSS   STATUS, 2	    ; Evaluar ZERO para determinar si la alerta de la alarma ha estado sonando durante 1 minuto
    GOTO    $+6		    ; Si no ha pasado un minuto, ir a la sexta instrucci�n siguiente
    BCF	    PORTE, 0	    ; Si pas� un minuto, apagar bit 0 del PORTE (desactivar alerta de la alarma)
    BCF	    alertaA, 2	    ; Limpiar bit 2 del registro alertaA (desabilitar conteo de 1 minuto)
    CLRF    off_alarma	    ; Limpiar registro "off_alarma"
    BSF	    alertaA, 1	    ; Encendder bit 1 del registro alertaA (habilitar comparaci�n entre reloj y alarma)
    BCF	    alertaA, 3	    ; Limpiar bit 3 del registro alertaA (desabilitar opci�n de apagado con boton)
    RETURN

cronometro:
    MOVF    segundosC, 0    ; Mover valor del registro de segundos del modo cron�metro a W
    SUBLW   60		    ; Restar a dicho valor la literal 60
    BTFSS   STATUS, 2	    ; Evaluar ZERO para determinar si han pasado 60 segundos
    GOTO    $+3		    ; Si no han pasado 60s, ir a la tercera instrucci�n siguiente
    CLRF    segundosC	    ; Reiniciar segundos del modo cron�metro
    INCF    minutosC	    ; Incrementar registro de minutos del modo cron�metro
    MOVF    minutosC, 0	    ; Mover valor de mintuso del modo cron�metro a W
    SUBLW   100		    ; Restar a dicho valor la literal
    BTFSS   STATUS, 2	    ; Evaluar ZERO para determinar si se han contado 100 minutos
    GOTO    $+3		    ; Si no se han contado 100 min, ir a la tercera instrucci�n siguiente
    CLRF    minutosC	    ; Si se han contado 100 min, reiniciar minutos del cron�metro
    BCF	    conf, 6	    ; Limpiar bit 6 del registro conf (detener cron�metro)
    RETURN

selector_disp:
    CLRF    PORTD	    ; Limpiar PORTD (apagar todos los displays)
    CLRF    PCLATH	    ; Limpiar registro PCLATH
    BSF	    PCLATH, 0	    ; Posicionar PC en 0x01xxh
    MOVF    selector, 0	    ; Mover valor del registro selector a W
    ANDLW   0x03	    ; AND entre W y literal 0x04
    ADDWF   PCL		    ; ADD entre W y PCL para direccionar al display correspondiente
    GOTO    display0	    ; Ir a instrucciones que encienden display0
    GOTO    display1	    ; Ir a instrucciones que encienden display1
    GOTO    display2	    ; Ir a instrucciones que encienden display2
    GOTO    display3	    ; Ir a instrucciones que encienden display3
    display0:
	MOVF	displayM, 0	; Mover valor del registro displayM a W
	MOVWF	PORTA		; Mover dicho valor al PORTA
	BTFSS	conf, 0		; Evaluar bit 0 del registro conf (evaluar si se est� configurando manualmente)
	GOTO	$+7		; Si no se est� configurando, ir a la s�ptima instrucci�n siguiente (encender display)
	BTFSS	set_valor, 0	; Si se est� configurando, evaluar bit 0 del registro set_valor (si se est�n configurando los displays 0 y 1)
	GOTO	$+5		; Si no se est�n configurando dichos displays, ir a la quinta instrucci�n siguiente
	BTFSC	conf, 5		; Si se est�n configurando, evaluar bit 5 del registro conf (bandera de 500ms)
	GOTO	$+3		
	BCF	PORTD, 0	; Apagar pin 0 del PORTD (display0) si la bandera de 500ms est� apagada
	GOTO	$+2		
	BSF	PORTD, 0	; Encender pin 0 del PORTD (display0) si la bandera de 500ms est� encendida
    RETURN
    display1:
	MOVF	displayM+1, 0	; Mover valor del registro displayM+1 a W
	MOVWF	PORTA		; Mover dicho valor al PORTA
	BTFSS	conf, 0		; Evaluar bit 0 del registro conf (evaluar si se est� configurando manualmente)
	GOTO	$+7		; Si no se est� configurando, ir a la s�ptima instrucci�n siguiente (encender display)
	BTFSS	set_valor, 0	; Si se est� configurando, evaluar bit 0 del registro set_valor (si se est�n configurando los displays 0 y 1)
	GOTO	$+5		; Si no se est�n configurando dichos displays, ir a la quinta instrucci�n siguiente
	BTFSC	conf, 5		; Si se est�n configurando, evaluar bit 5 del registro conf (bandera de 500ms)
	GOTO	$+3
	BCF	PORTD, 1	; Apagar pin 1 del PORTD (display1) si la bandera de 500ms est� apagada
	GOTO	$+2
	BSF	PORTD, 1	; Encender pin 1 del PORTD (display1) si la bandera de 500ms est� encendida
    RETURN
    display2:
	MOVF	displayH, 0	; Mover valor del registro displayH a W
	MOVWF	PORTA		; Mover dicho valor al PORTA
	BTFSS	conf, 0		; Evaluar bit 0 del registro conf (evaluar si se est� configurando manualmente)
	GOTO	$+7		; Si no se est� configurando, ir a la s�ptima instrucci�n siguiente (encender display)
	BTFSS	set_valor, 1	; Si se est� configurando, evaluar bit 1 del registro set_valor (si se est�n configurando los displays 2 y 3)
	GOTO	$+5		; Si no se est�n configurando dichos displays, ir a la quinta instrucci�n siguiente
	BTFSC	conf, 5		; Si se est�n configurando, evaluar bit 5 del registro conf (bandera de 500ms)
	GOTO	$+3
	BCF	PORTD, 2	; Apagar pin 2 del PORTD (display2) si la bandera de 500ms est� apagada
	GOTO	$+2
	BSF	PORTD, 2	; Encender pin 2 del PORTD (display2) si la bandera de 500ms est� encendida
    RETURN
    display3:
	MOVF	displayH+1, 0	; Mover valor del registro displayH+1 a W
	MOVWF	PORTA		; Mover dicho valor al PORTA
	BTFSS	conf, 0		; Evaluar bit 0 del registro conf (evaluar si se est� configurando manualmente)
	GOTO	$+7		; Si no se est� configurando, ir a la s�ptima instrucci�n siguiente (encender display)
	BTFSS	set_valor, 1	; Si se est� configurando, evaluar bit 1 del registro set_valor (si se est�n configurando los displays 2 y 3)
	GOTO	$+5		; Si no se est�n configurando dichos displays, ir a la quinta instrucci�n siguiente
	BTFSC	conf, 5		; Si se est�n configurando, evaluar bit 5 del registro conf (bandera de 500ms)
	GOTO	$+3
	BCF	PORTD, 3	; Apagar pin 3 del PORTD (display3) si la bandera de 500ms est� apagada
	GOTO	$+2
	BSF	PORTD, 3	; Encender pin 3 del PORTD (display3) si la bandera de 500ms est� encendida
    RETURN

obtenerDU_M:
    CLRF    decenasM	    ; Limpiar registro de las decenas
    MOVF    minutos, 0	    ; Guardar dicho valor en los registros temp1 y temp2 
    MOVWF   temp1
    MOVF    temp1, 0
    MOVWF   temp2
    MOVLW   10		    ; Mover la literal 10 a W
    SUBWF   temp1, 1	    ; Restar 10 al registro temp1 y guardar en este mismo registro
    BTFSS   STATUS, 0	    ; Evaluar CARRY para determinar si el valor tiene o no decenas
    GOTO    obtenerU_M	    ; Si no tiene decenas, ir a las instrucciones para obtener las unidades
    MOVF    temp1, 0	    ; Si no hubo CARRY, guardar valor de registro temp1 en temp2
    MOVWF   temp2		
    INCF    decenasM	    ; Incrementear el registro de las decenas   
    GOTO    $-7		    ; Ir a la s�ptima instrucci�n anterior (repetir la resta) 
    obtenerU_M:
	MOVF    temp2, 0    ; Mover valor del registro temp2 a W y luego al registro de unidades
	MOVWF   unidadesM
	RETURN

obtenerDU_H:		    ; Ver comentarios para subrutina "obtenerDU_M"
    CLRF    decenasH		
    MOVF    horas, 0		
    MOVWF   temp1
    MOVF    temp1, 0
    MOVWF   temp2
    MOVLW   10			
    SUBWF   temp1, 1		
    BTFSS   STATUS, 0		
    GOTO    obtenerU_H		
    MOVF    temp1, 0		 
    MOVWF   temp2
    INCF    decenasH		  
    GOTO    $-7			 
    obtenerU_H:
	MOVF    temp2, 0
	MOVWF   unidadesH
	RETURN

aumentarM:
    INCF    minutos	    ; Incrementar el registro de minutos 
    MOVF    minutos, 0	    ; Mover el valor de dicho registro a W y restar la literal 60
    SUBLW   60		    
    BTFSC   STATUS, 2	    ; Evaluar ZERO para determinar si se han aumentado 60 minutos
    CLRF    minutos	    ; Si se han aumentado 60 min, limpiar el registro de minutos (overflow)
    BCF	    conf, 2	    ; Apagar bit 2 del registro conf (boton de aumento)
    RETURN

disminuirM:
    MOVF    minutos, 0	    ; Mover el valor del registro de minutos a W
    XORLW   0x00	    ; XOR entre dicho valor y la literal 0x00
    BTFSC   STATUS, 2	    ; Evaluar ZERO para determinar si el valor de "minutos" es 0
    GOTO    $+3		    ; Si es 0, ir a la tercera instrucci�n siguiente
    DECF    minutos	    ; Si no es cero, decrementar el registro minutos
    GOTO    $+3		    ; Ir a la tercera instrucci�n siguiente 
    MOVLW   59		    ; Mover literal 59 a W y luego al registro minutos (underflow) 
    MOVWF   minutos 
    BCF	    conf, 3	    ; Apagar bit 3 del registro conf (boton de decremento)
    RETURN

aumentarH:
    INCF    horas	    ; Incrementar el registro de horas
    MOVF    horas, 0	    ; Mover el valor de dicho registro a W y restar la literal 24
    SUBLW   24		    
    BTFSC   STATUS, 2	    ; Evaluar ZERO para determinar si se han aumentado 24 horas
    CLRF    horas	    ; Si se han aumentado 24 h, limpiar el registro de horas (overflow)
    BCF	    conf, 2	    ; Apagar bit 2 del registro conf (boton de aumento)
    RETURN

disminuirH:
    MOVF    horas, 0	    ; Mover el valor del registro de horas a W
    XORLW   0x00	    ; XOR entre dicho valor y la literal 0x00
    BTFSC   STATUS, 2	    ; Evaluar ZERO para determinar si el valor de "horas" es 0
    GOTO    $+3		    ; Si es 0, ir a la tercera instrucci�n siguiente
    DECF    horas	    ; Si no es cero, decrementar el registro minutos
    GOTO    $+3		    ; Ir a la tercera instrucci�n siguiente 
    MOVLW   23		    ; Mover literal 23 a W y luego al registro minutos (underflow)
    MOVWF   horas
    BCF	    conf, 3	    ; Apagar bit 3 del registro conf (boton de decremento)
    RETURN

config_display_reloj:	    
    MOVF    unidadesM, 0    ; Mover registro de unidades a W
    CALL    tabla	    ; Buscar el valor equivalente en la tabla para 7 segmentos
    MOVWF   displayM	    ; Mover dicho valor al registro displayM (display0)
    MOVF    decenasM, 0	    ; Mover registro de decenas a W
    CALL    tabla	    ; Buscar el valor equivalente en la tabla para 7 segmentos
    MOVWF   displayM+1	    ; Mover dicho valor al registro displayM+1 (display1)
    MOVF    unidadesH, 0    ; Mover registro de unidades a W
    CALL    tabla	    ; Buscar el valor equivalente en la tabla para 7 segmentos
    MOVWF   displayH	    ; Mover dicho valor al registro displayH (display2)
    MOVF    decenasH, 0	    ; Mover registro de decenas a W
    CALL    tabla	    ; Buscar el valor equivalente en la tabla para 7 segmentos
    MOVWF   displayH+1	    ; Mover dicho valor al registro displayH+1 (display3)
    RETURN

obtenerDU_ST:		    ; Ver comentarios para subrutina "obtenerDU_M"
    CLRF    decenasST		
    MOVF    segundosT, 0	
    MOVWF   temp1
    MOVF    temp1, 0
    MOVWF   temp2
    MOVLW   10			
    SUBWF   temp1, 1		
    BTFSS   STATUS, 0		
    GOTO    obtenerU_ST		
    MOVF    temp1, 0		 
    MOVWF   temp2
    INCF    decenasST		  
    GOTO    $-7			 
    obtenerU_ST:
	MOVF    temp2, 0
	MOVWF   unidadesST
	RETURN

obtenerDU_MT:		    ; Ver comentarios para subrutina "obtenerDU_M"
    CLRF    decenasMT		
    MOVF    minutosT, 0		
    MOVWF   temp1
    MOVF    temp1, 0
    MOVWF   temp2
    MOVLW   10			
    SUBWF   temp1, 1		
    BTFSS   STATUS, 0		
    GOTO    obtenerU_MT		
    MOVF    temp1, 0		
    MOVWF   temp2
    INCF    decenasMT		   
    GOTO    $-7			
    obtenerU_MT:
	MOVF    temp2, 0
	MOVWF   unidadesMT
	RETURN

aumentarST:		    
    INCF    segundosT	    ; Incrementar el registro de segundos
    MOVF    segundosT, 0    ; Mover el valor de dicho registro a W y restar la literal 60
    SUBLW   60		    
    BTFSC   STATUS, 2	    ; Evaluar ZERO para determinar si se han aumentado 60 segundos
    CLRF    segundosT	    ; Si se han aumentado los 60s, limpiar el registro de segundos (overflow)
    BCF	    conf, 2	    ; Apagar bit 2 del registro conf (boton de aumento)
    RETURN

disminuirST:		    
    MOVF    segundosT, 0    ; Mover el valor del registro de segundos a W
    XORLW   0x00	    ; XOR entre dicho valor y la literal 0x00
    BTFSC   STATUS, 2	    ; Evaluar ZERO para determinar si el valor de "segundos" es 0
    GOTO    $+3		    ; Si es 0, ir a la tercera instrucci�n siguiente
    DECF    segundosT	    ; Si no es 0, decrementar el registro segundos
    GOTO    $+3		    ; Ir a la tercera instrucci�n siguiente
    MOVLW   59		    ; Mover literal 59 a W y luego al registro de segundos (underflow)
    MOVWF   segundosT
    BCF	    conf, 3	    ; Apagar bit 3 del registro conf (boton de decremento)
    RETURN

aumentarMT:		    ; Ver comentarios para subrutina "aumentarM"
    INCF    minutosT
    MOVF    minutosT, 0
    SUBLW   100		    
    BTFSC   STATUS, 2
    CLRF    minutosT
    BCF	    conf, 2
    RETURN

disminuirMT:		    ; Ver comentarios para subrutina "disminuirM"
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

config_display_timer:	    ; Ver comentarios para subrutina "config_display_reloj"
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

obtenerDU_MA:		    ; Ver comentarios para subrutina "obtenerDU_M"
    CLRF    decenasMA		
    MOVF    minutosA, 0		
    MOVWF   temp1
    MOVF    temp1, 0
    MOVWF   temp2
    MOVLW   10			
    SUBWF   temp1, 1		
    BTFSS   STATUS, 0		
    GOTO    obtenerU_MA		
    MOVF    temp1, 0		
    MOVWF   temp2
    INCF    decenasMA		  
    GOTO    $-7			
    obtenerU_MA:
	MOVF    temp2, 0
	MOVWF   unidadesMA
	RETURN

obtenerDU_HA:		    ; Ver comentarios para subrutina "obtenerDU_M"
    CLRF    decenasHA		
    MOVF    horasA, 0		
    MOVWF   temp1
    MOVF    temp1, 0
    MOVWF   temp2
    MOVLW   10			
    SUBWF   temp1, 1		
    BTFSS   STATUS, 0		
    GOTO    obtenerU_HA		
    MOVF    temp1, 0		
    MOVWF   temp2
    INCF    decenasHA		   
    GOTO    $-7			 
    obtenerU_HA:
	MOVF    temp2, 0
	MOVWF   unidadesHA
	RETURN

aumentarMA:		    ; Ver comentarios para subrutina "aumentarM"
    INCF    minutosA
    MOVF    minutosA, 0
    SUBLW   60		    
    BTFSC   STATUS, 2
    CLRF    minutosA
    BCF	    conf, 2
    RETURN

disminuirMA:		    ; Ver comentarios para subrutina "disminuirM"
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

aumentarHA:		    ; Ver comentarios para subrutina "aumentarH"
    INCF    horasA
    MOVF    horasA, 0
    SUBLW   24		    
    BTFSC   STATUS, 2
    CLRF    horasA
    BCF	    conf, 2
    RETURN

disminuirHA:		    ; Ver comentarios para subrutina "disminuirH"
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

config_display_alarma:	    ; Ver comentarios para subrutina "config_display_reloj"
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

obtenerDU_Mes:		    ; Ver comentarios para subrutina "obtenerDU_M"
    CLRF    decenasMes		
    MOVF    meses, 0		
    MOVWF   temp1
    MOVF    temp1, 0
    MOVWF   temp2
    MOVLW   10			
    SUBWF   temp1, 1		
    BTFSS   STATUS, 0		
    GOTO    obtenerU_Mes	
    MOVF    temp1, 0		
    MOVWF   temp2
    INCF    decenasMes		  
    GOTO    $-7			
    obtenerU_Mes:
	MOVF	temp2, 0
	MOVWF   unidadesMes
	RETURN

obtenerDU_D:		    ; Ver comentarios para subrutina "obtenerDU_M"
    CLRF    decenasD		
    MOVF    dias, 0		
    MOVWF   temp1
    MOVF    temp1, 0
    MOVWF   temp2
    MOVLW   10			
    SUBWF   temp1, 1		
    BTFSS   STATUS, 0		
    GOTO    obtenerU_D		
    MOVF    temp1, 0		
    MOVWF   temp2
    INCF    decenasD		  
    GOTO    $-7			
    obtenerU_D:
	MOVF    temp2, 0
	MOVWF   unidadesD
	RETURN

aumentarMes:		    
    INCF    meses	    ; Incrementar el registro de meses
    MOVF    meses, 0	    ; Mover el valor de dicho registro a W y restar la liteal 13
    SUBLW   13			
    BTFSS   STATUS, 2	    ; Evaluar ZERO para determinar si se han aumentado 13 meses
    GOTO    $+3		    ; Si se aument� al mes 13, setear la literal 1 al registros de meses (overflow)
    MOVLW   1
    MOVWF   meses
    BCF	    conf, 2	    ; Apagar bit 2 del registro conf (boton de aumento)
    RETURN

disminuirMes:		    
    MOVF    meses, 0	    ; Mover el valor del registro de meses a W y restar la literal 1
    SUBLW   0x01	    
    BTFSC   STATUS, 2	    ; Evaluar ZERO para determinar si el valor de "meses" es 1
    GOTO    $+3		    ; Si es 1, ir a la tercera instrucci�n siguiente
    DECF    meses	    ; Si no es 1, decrementar el registro de meses
    GOTO    $+3		    ; Ir a la tercera instrucci�n siguiente
    MOVLW   12		    ; Mover literal 12 a W y luego al registro de meses (underflow)
    MOVWF   meses	    
    BCF	    conf, 3	    ; Apagar bit 3 del registro conf (boton de decremento)
    RETURN

aumentarD:
    INCF    dias	    ; Incrementar el registro de dias
    MOVF    meses, 0	    ; Mover el registro de meses a W
    CALL    tabla_meses	    ; Buscar la cantidad de d�as para dicho valor en la tabla de meses
    SUBWF   dias, 0	    ; Restar el valor obtenido al registro d�as y guardar resultado en W
    BTFSS   STATUS, 2	    ; Evaluar ZERO para determinar si "dias" es igual al valor de la tabla
    GOTO    $+3		    ; Si no es igual, ir a la tercera instrucci�n siguiente
    MOVLW   1		    ; Si es igual, mover la literal 1 a W y luego al registro de d�as (overflow)
    MOVWF   dias
    BCF	    conf, 2	    ; Apagar bit 2 del registro conf (boton de aumento)
    RETURN

disminuirD:
    MOVF    dias, 0	    ; Mover el valor del registro de dias a W y restar la literal 0x01
    SUBLW   0x01	
    BTFSC   STATUS, 2	    ; Evaluar ZERO para determinar si "dias" es igual a 1
    GOTO    $+3		    ; Si es igual, ir a la tercera instrucci�n siguiente
    DECF    dias	    ; Si no es igual, decrementar el registro de d�as
    GOTO    $+7		    ; Ir a la s�ptima instrucci�n siguiente
    MOVF    meses, 0	    ; Mover el registro de meses a W
    CALL    tabla_meses	    ; Buscar la cantidad de d�as para dicho valor en la tabla de meses
    MOVWF   dismD	    ; Guardar el valor obtenido de la tabla en el registro dismD
    MOVLW   1		    ; Mover literal 1 a W
    SUBWF   dismD, 0	    ; Restar dicha literal al registro dismD y guardar resultado en W
    MOVWF   dias	    ; Mover el resultado al registro de dias (underflow)
    BCF	    conf, 3	    ; Apagar bit 3 del registro conf (boton de decremento)
    RETURN

config_display_fecha:	    ; Ver comentarios para subrutina "config_display_reloj"
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

obtenerDU_SC:		    ; Ver comentarios para subrutina "obtenerDU_M"
    CLRF    decenasSC		
    MOVF    segundosC, 0	
    MOVWF   temp1
    MOVF    temp1, 0
    MOVWF   temp2
    MOVLW   10			
    SUBWF   temp1, 1		
    BTFSS   STATUS, 0		
    GOTO    obtenerU_SC		
    MOVF    temp1, 0		
    MOVWF   temp2
    INCF    decenasSC		   
    GOTO    $-7			
    obtenerU_SC:
	MOVF    temp2, 0
	MOVWF   unidadesSC
	RETURN

obtenerDU_MC:		    ; Ver comentarios para subrutina "obtenerDU_M"
    CLRF    decenasMC		
    MOVF    minutosC, 0		
    MOVWF   temp1
    MOVF    temp1, 0
    MOVWF   temp2
    MOVLW   10			
    SUBWF   temp1, 1		
    BTFSS   STATUS, 0		
    GOTO    obtenerU_MC		
    MOVF    temp1, 0		 
    MOVWF   temp2
    INCF    decenasMC		   
    GOTO    $-7			
    obtenerU_MC:
	MOVF    temp2, 0
	MOVWF   unidadesMC
	RETURN

config_display_cron:	    ; Ver comentarios para subrutina "config_display_reloj"
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

;----- SUBRUTINAS DE CONFIGURACI�N -----
config_clk:
    BANKSEL OSCCON
    BCF	    IRCF2	    ; IRCF/011/500 kHz (frecuencia de oscilaci�n)
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
    BSF	    TRISB, BMODO    ; RB0 como entrada (boton para cambio de modo)
    BSF	    TRISB, UP	    ; RB1 como entrada (boton para incremento)
    BSF	    TRISB, DOWN	    ; RB2 como entrada (boton decremento)
    BSF	    TRISB, EDITAR   ; RB3 como entrada (boton para activiar/desactivar configuraci�n manual)
    BSF	    TRISB, INICIO   ; RB4 como entrada (boton para iniciar/detener)
    CLRF    TRISC	    ; PORTC como salida
    CLRF    TRISD	    ; PORTD como salida
    CLRF    TRISE	    ; PORTE como salida
    BCF	    OPTION_REG, 7   ; Habilitar resistencias pull-up para PORTB
    BSF	    WPUB, BMODO	    ; Habilitar pull-up para RB0
    BSF	    WPUB, UP	    ; Habilitar pull-up para RB1
    BSF	    WPUB, DOWN	    ; Habilitar pull-up para RB2
    BSF	    WPUB, EDITAR    ; Habilitar pull-up para RB3
    BSF	    WPUB, INICIO    ; Habilitar pull-up para RB4
    BANKSEL PORTA
    CLRF    PORTA	    ; Limpiar PORTA
    CLRF    PORTC	    ; Limpiar PORTD
    CLRF    PORTD	    ; Limpiar PORTC
    CLRF    PORTE	    ; Limpiar PORTE
    RETURN

config_tmr0:
    BANKSEL OPTION_REG
    BCF	    T0CS	    ; Configurar reloj interno 
    BCF	    PSA		    ; Asignar prescaler al TMR0
    BSF	    PS2		    ; Prescaler/110/1:128
    BSF	    PS1	
    BCF	    PS0
    reset_tmr0		    ; Ejecutar macro que reinicia el TRM0
    RETURN

config_tmr1:
    BANKSEL T1CON	    ; Cambiar a banco 00
    BSF	    TMR1ON	    ; Encender TMR1
    BCF	    TMR1CS	    ; Configurar reloj interno
    BCF	    T1OSCEN	    ; Apagar oscilador LP
    BSF	    T1CKPS1	    ; Configurar prescaler 1:4
    BCF	    T1CKPS0	    
    BCF	    TMR1GE	    ; TRM1 siempre contando 
    reset_tmr1 0x85, 0xA3   ; Ejecutar macro que reinicia el TRM1    
    RETURN

config_tmr2:
    BANKSEL T2CON	    
    BSF	    T2CKPS1	    ; Prescaler/11/1:16
    BSF	    T2CKPS0
    BSF	    TMR2ON	    ; Encender TRM2
    BSF	    TOUTPS3	    ; Postscaler/1111/1:16
    BSF	    TOUTPS2
    BSF	    TOUTPS1
    BSF	    TOUTPS0
    BANKSEL PR2
    MOVLW   245		    ; Mover literal 245 a W y luego al registro PR2
    MOVWF   PR2
    RETURN

config_int:
    BANKSEL PIE1	    ; Cambiar de banco 
    BSF	    TMR1IE	    ; Habilitar interrupci�n de TMR1
    BSF	    TMR2IE	    ; Habilitar interrupci�n de TRM2
    BANKSEL IOCB	    ; Cambiar de banco
    BSF	    IOCB, 0	    ; Habilitar interrupci�n On_change del pin RB0
    BSF	    IOCB, 1	    ; Habilitar interrupci�n On_change del pin RB1
    BSF	    IOCB, 2	    ; Habilitar interrupci�n On_change del pin RB2
    BSF	    IOCB, 3	    ; Habilitar interrupci�n On_change del pin RB3
    BSF	    IOCB, 4	    ; Habilitar interrupci�n On_change del pin RB4
    BANKSEL INTCON	    ; Cambiar de banco
    BSF	    GIE		    ; Habilitar interrupciones globales
    BSF	    PEIE	    ; Habilitar interrupciones perif�ricas
    BSF	    RBIE	    ; Habilitar interrupciones del PORTB
    BSF	    T0IE	    ; Habilitar interrupci�n de TRM0
    BCF	    T0IF	    ; Limpiar bandera de interrupci�n del TRM0
    BCF	    TMR1IF	    ; Limpiar bandera de interrupci�n del TRM1
    BCF	    TMR2IF	    ; Limpiar bandera de interrupci�n del TRM2
    BCF	    RBIF	    ; Limpiar bandera de interrupci�n del PORTB
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
    BSF	    dias, 0	    ; Comenzar en el d�a 01
    CLRF    meses	    
    BSF	    meses, 0	    ; Comenzar en el mes 01
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

ORG 600h		    ; Establecer posici�n para la tabla
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
    RETLW   31	    ; default
    RETLW   32	    ; cantidad de d�as para enero	(mes 01)
    RETLW   29	    ; cantidad de d�as para febrero	(mes 02)
    RETLW   32	    ; cantidad de d�as para marzo	(mes 03)
    RETLW   31	    ; cantidad de d�as para abril	(mes 04)
    RETLW   32	    ; cantidad de d�as para mayo	(mes 05)	
    RETLW   31	    ; cantidad de d�as para junio	(mes 06)
    RETLW   32	    ; cantidad de d�as para julio	(mes 07)
    RETLW   32	    ; cantidad de d�as para agosto	(mes 08)
    RETLW   31	    ; cantidad de d�as para septiembre	(mes 09)
    RETLW   32	    ; cantidad de d�as para octubre	(mes 10)
    RETLW   31	    ; cantidad de d�as para noviembre	(mes 11)
    RETLW   32	    ; cantidad de d�as para diciembre	(mes 12)

END