
; Name:	Mordechai kemelman & David Shchori
; Date:	
; File:	 Mini-Project -  A Simple Signal Generator
;
; Hardware      : ADuC841
;
;
; Description: The first character will be an S ,A or Q.
; where 'S' stands for Sine wave,
; 'A' stands for sawtooth wave, 
; and 'Q' stands for square wave. 
; The next three characters will be a three digit numbers, that will determine the frequency of the signal
;
;
;Flags:
;
;
;
;
;The registers we used:
;
;
;


;____________________________________________________________________
														; MAIN PROGRAM:
#include<aduc841.h>
CSEG	AT		0000H
JMP 	MAIN

;____________________________________________________________________
														; TIMER 0 ISR:
CSEG		AT		000BH		; Timer 0 ISR.
JMP		T0_I

T0_I:                 

PUSH	ACC					
PUSH	PSW	

; COUNT = COUNT + DELTA
MOV		A,	CNTRL
ADD 	A,	DLTL
MOV		CNTRL,	A
MOV		A, CNTRH
ADDC	A,	DLTH
MOV		CNTRH,	A

; if COUNTH bigger then 200
IfBig:     MOV 		A,		CNTRH
		   CJNE		A,		#200, 	EX_TIMER		   ; jump if not equal 
		   MOV 		CNTRH,  #0				   ; If is more then 200 reset
		   JMP      EX_TIMER1
		   
TooMuch:   MOV 		A,		CNTRH   
		   SUBB 	A, #200
		   MOV 		CNTRH,		A
		   JMP EX_TIMER1
EX_TIMER:
JNC TooMuch ; more then 200 Jump  CARY =0
EX_TIMER1:
SETB	TIME_IS_OVER
POP		PSW
POP		ACC
RETI
;____________________________________________________________________
														; UART ISR:
CSEG	 	AT	 	0023H 		; UART ISR
JMP		U_I

U_I:                                                 ;The UART ISR

PUSH	ACC					
PUSH	PSW	

JBC		TI,		EX_UART		; Check to see if there was a transmit interrupt 
							; Jump if direct bit is set and clear bit
MOV 	A,		SBUF	    ; Move the data to A
CLR		RI
;____________________________________________________________________
														; draw the waves:
CJNE A, #'S', IF_NOT_S		; jump if not equal
;We get Sine wave 
MOV DPTR, #SINE
SETB HUNDREDS_B
SETB OPTION_B         ; 
JMP EX_UART

IF_NOT_S:
CJNE A, #'A', IF_NOT_A	
;We get sAwtooth wave 
SETB OPTION_B 
SETB HUNDREDS_B
JMP EX_UART

IF_NOT_A:
CJNE A, #'Q', IF_NOT_ANY
;We get sQuare wave 
MOV DPTR, #sQuare
SETB HUNDREDS_B
SETB OPTION_A                                ;
JMP EX_UART


IF_NOT_ANY:	; the frequancy 

JNB HUNDREDS_B, CHEK_TENS ;if HUNDREDS=1 contin , if not jump
CLR HUNDREDS_B 
MOV HUNDREDS,	SBUF
SETB TENS_B
JMP EX_UART

CHEK_TENS:
JNB 		TENS_B, CHEK_UNITS
CLR TENS_B
MOV 		TENS,	SBUF
SETB UNITS_B
JMP EX_UART

CHEK_UNITS:
JNB 		UNITS_B, EX_UART
CLR UNITS_B
MOV 		UNITS,	SBUF

; The DELTA 
ANL HUNDREDS, 	#00001111B
ANL TENS, 	  	#00001111B
ANL UNITS, 		#00001111B
;the units
MOV DLTL , UNITS
; The tens
MOV A, TENS
MOV B, #10
MUL  AB
ADD	A,	DLTL
MOV DLTL, A
MOV DLTH,B
 ;the hundreds
MOV A, HUNDREDS
MOV B, #100
MUL  AB
ADD A, DLTL
MOV DLTL,A
MOV A, B
ADDC A, DLTH
MOV DLTH,A

EX_UART:

POP		PSW
POP		ACC
RETI

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
MAIN:
; UART setup 
CLR 	SM0 ; 8-bit variable baud rate mode
SETB	SM1
SETB 	REN 	; Enable reception.

; Timer 3 is used as the clock for the UART. Baud rate = 115,200.
ANL	 	T3CON, #01111000B
ORL 	T3CON, #10000010B ; Make Timer3 the UART’s clock,
						  ; and set DIV to 2.
MOV		 T3FD, #32

SETB	ES
SETB	EA

;	DAC setup
MOV			DACCON,		#10011111B				; Sets Register of DAC ports

ANL 		ADCCON1,		#00111111B
ORL			ADCCON1,		#10000000B

; Timer 0
ANL			TMOD,		#11110000B				;
ORL			TMOD,		#00000010B				;  Set Timer 0 to run in mode 2 in autoreload mode

SETB	TR0 									; Turn on Timer 0.
SETB 	ET0 									; Enable the Timer 0 interrupt.
MOV TH0, #028H									; 11059200/(256*200)=216 , 256-216=40 => 028H 


; Reset with sin 1 Hz
MOV DLTL,   #00000001B 
MOV	DLTH,	#00000000B
MOV DPTR,  #SINE

;____________________________________________________________________
														; The LOOPS:

LOOP_A:
CLR OPTION_B;
JNB TIME_IS_OVER ,$
JB OPTION_A , LOOP_B ; IF IT 1 JUMP 
CLR TIME_IS_OVER 
MOV			A,			CNTRH
MOVC		A,			@A+DPTR					; the comolator A got a new value in a new address
MOV		DAC1L,	A						;The wave - To DAC1L as requested
JMP LOOP_A

LOOP_B:
CLR OPTION_A 
JNB TIME_IS_OVER ,$
JB OPTION_B , LOOP_A ; IF IT 1 JUMP   ;
CLR TIME_IS_OVER 
MOV		DAC1L,	CNTRH
JMP LOOP_B

;____________________________________________________________________
														; strings:
DSEG	AT		0030H
DLTH:	   	 DS		1
DLTL:		 DS		1
CNTRH:	     DS 	1
CNTRL:   	 DS 	1
UNITS:		 DS 	1
TENS:		 DS 	1
HUNDREDS:	 DS 	1
 	
;____________________________________________________________________
														; Flags:	
BSEG
HUNDREDS_B      : DBIT 1
TENS_B          : DBIT 1
UNITS_B		    : DBIT 1
TIME_IS_OVER    : DBIT 1
OPTION_A	    : DBIT 1
OPTION_B    	: DBIT 1	

;____________________________________________________________________
														; waves:
CSEG	 AT		0300H
sQuare:
        DB             228 
        DB             228 
        DB             228 
        DB             228 
        DB             228 
        DB             228 
        DB             228 
        DB             228 
        DB             228 
        DB             228 
        DB             228 
        DB             228 
        DB             228 
        DB             228 
        DB             228 
        DB             228 
        DB             228 
        DB             228 
        DB             228 
        DB             228 
        DB             228 
        DB             228 
        DB             228 
        DB             228 
        DB             228 
        DB             228 
        DB             228 
        DB             228 
        DB             228 
        DB             228 
        DB             228 
        DB             228 
        DB             228 
        DB             228 
        DB             228 
        DB             228 
        DB             228 
        DB             228 
        DB             228 
        DB             228 
        DB             228 
        DB             228 
        DB             228 
        DB             228 
        DB             228 
        DB             228 
        DB             228 
        DB             228 
        DB             228 
        DB             228 
        DB             228 
        DB             228 
        DB             228 
        DB             228 
        DB             228 
        DB             228 
        DB             228 
        DB             228 
        DB             228 
        DB             228 
        DB             228 
        DB             228 
        DB             228 
        DB             228 
        DB             228 
        DB             228 
        DB             228 
        DB             228 
        DB             228 
        DB             228 
        DB             228 
        DB             228 
        DB             228 
        DB             228 
        DB             228 
        DB             228 
        DB             228 
        DB             228 
        DB             228 
        DB             228 
        DB             228 
        DB             228 
        DB             228 
        DB             228 
        DB             228 
        DB             228 
        DB             228 
        DB             228 
        DB             228 
        DB             228 
        DB             228 
        DB             228 
        DB             228 
        DB             228 
        DB             228 
        DB             228 
        DB             228 
        DB             228 
        DB             228 
        DB             228 
        DB             228 
        DB             228 
        DB             228 
        DB             228 
        DB             228 
        DB             228 
        DB             228 
        DB             228 
        DB             228 
        DB             228 
        DB             228 
        DB             228 
        DB             228 
        DB             228 
        DB             228 
        DB             228 
        DB             228 
        DB             228 
        DB             228 
        DB             228 
        DB             228 
        DB             228 
        DB             228 
        DB             228 
        DB             228 
        DB             228 
        DB             228 
        DB             228 
        DB             28 
        DB             28 
        DB             28 
        DB             28 
        DB             28 
        DB             28 
        DB             28 
        DB             28 
        DB             28 
        DB             28 
        DB             28 
        DB             28 
        DB             28 
        DB             28 
        DB             28 
        DB             28 
        DB             28 
        DB             28 
        DB             28 
        DB             28 
        DB             28 
        DB             28 
        DB             28 
        DB             28 
        DB             28 
        DB             28 
        DB             28 
        DB             28 
        DB             28 
        DB             28 
        DB             28 
        DB             28 
        DB             28 
        DB             28 
        DB             28 
        DB             28 
        DB             28 
        DB             28 
        DB             28 
        DB             28 
        DB             28 
        DB             28 
        DB             28 
        DB             28 
        DB             28 
        DB             28 
        DB             28 
        DB             28 
        DB             28 
        DB             28 
        DB             28 
        DB             28 
        DB             28 
        DB             28 
        DB             28 
        DB             28 
        DB             28 
        DB             28 
        DB             28 
        DB             28 
        DB             28 
        DB             28 
        DB             28 
        DB             28 
        DB             28 
        DB             28 
        DB             28 
        DB             28 
        DB             28 
        DB             28 
        DB             28 
        DB             28 
        DB             28 
        DB             28 
        DB             28 
        DB             28 
        DB             28 
        DB             28 
        DB             28 
        DB             28 
        DB             28 
        DB             28 
        DB             28 
        DB             28 
        DB             28 
        DB             28 
        DB             28 
        DB             28 
        DB             28 
        DB             28 
        DB             28 
        DB             28 
        DB             28 
        DB             28 
        DB             28 
        DB             28 
        DB             28 
        DB             28 
        DB             28 
        DB             28 
        DB             28 
        DB             28 
        DB             28 
        DB             28 
        DB             28 
        DB             28 
        DB             28 
        DB             28 
        DB             28 
        DB             28 
        DB             28 
        DB             28 
        DB             28 
        DB             28 
        DB             28 
        DB             28 
        DB             28 
        DB             28 
        DB             28 
        DB             28 
        DB             28 
        DB             28 
        DB             28 
        DB             28 
        DB             28 
        DB             28 
        DB             28 
        DB             28 
SINE:
        DB             128 
        DB             130 
        DB             133 
        DB             135 
        DB             138 
        DB             140 
        DB             143 
        DB             145 
        DB             148 
        DB             150 
        DB             152 
        DB             155 
        DB             157 
        DB             159 
        DB             162 
        DB             164 
        DB             166 
        DB             169 
        DB             171 
        DB             173 
        DB             175 
        DB             177 
        DB             179 
        DB             181 
        DB             184 
        DB             186 
        DB             188 
        DB             190 
        DB             191 
        DB             193 
        DB             195 
        DB             197 
        DB             199 
        DB             200 
        DB             202 
        DB             204 
        DB             205 
        DB             207 
        DB             208 
        DB             210 
        DB             211 
        DB             212 
        DB             214 
        DB             215 
        DB             216 
        DB             217 
        DB             218 
        DB             219 
        DB             220 
        DB             221 
        DB             222 
        DB             223 
        DB             224 
        DB             224 
        DB             225 
        DB             226 
        DB             226 
        DB             227 
        DB             227 
        DB             227 
        DB             228 
        DB             228 
        DB             228 
        DB             228 
        DB             228 
        DB             228 
        DB             228 
        DB             228 
        DB             228 
        DB             227 
        DB             227 
        DB             227 
        DB             226 
        DB             226 
        DB             225 
        DB             224 
        DB             224 
        DB             223 
        DB             222 
        DB             221 
        DB             220 
        DB             219 
        DB             218 
        DB             217 
        DB             216 
        DB             215 
        DB             214 
        DB             212 
        DB             211 
        DB             210 
        DB             208 
        DB             207 
        DB             205 
        DB             204 
        DB             202 
        DB             200 
        DB             199 
        DB             197 
        DB             195 
        DB             193 
        DB             191 
        DB             190 
        DB             188 
        DB             186 
        DB             184 
        DB             181 
        DB             179 
        DB             177 
        DB             175 
        DB             173 
        DB             171 
        DB             169 
        DB             166 
        DB             164 
        DB             162 
        DB             159 
        DB             157 
        DB             155 
        DB             152 
        DB             150 
        DB             148 
        DB             145 
        DB             143 
        DB             140 
        DB             138 
        DB             135 
        DB             133 
        DB             130 
        DB             128 
        DB             126 
        DB             123 
        DB             121 
        DB             118 
        DB             116 
        DB             113 
        DB             111 
        DB             108 
        DB             106 
        DB             104 
        DB             101 
        DB             99 
        DB             97 
        DB             94 
        DB             92 
        DB             90 
        DB             87 
        DB             85 
        DB             83 
        DB             81 
        DB             79 
        DB             77 
        DB             75 
        DB             72 
        DB             70 
        DB             68 
        DB             66 
        DB             65 
        DB             63 
        DB             61 
        DB             59 
        DB             57 
        DB             56 
        DB             54 
        DB             52 
        DB             51 
        DB             49 
        DB             48 
        DB             46 
        DB             45 
        DB             44 
        DB             42 
        DB             41 
        DB             40 
        DB             39 
        DB             38 
        DB             37 
        DB             36 
        DB             35 
        DB             34 
        DB             33 
        DB             32 
        DB             32 
        DB             31 
        DB             30 
        DB             30 
        DB             29 
        DB             29 
        DB             29 
        DB             28 
        DB             28 
        DB             28 
        DB             28 
        DB             28 
        DB             28 
        DB             28 
        DB             28 
        DB             28 
        DB             29 
        DB             29 
        DB             29 
        DB             30 
        DB             30 
        DB             31 
        DB             32 
        DB             32 
        DB             33 
        DB             34 
        DB             35 
        DB             36 
        DB             37 
        DB             38 
        DB             39 
        DB             40 
        DB             41 
        DB             42 
        DB             44 
        DB             45 
        DB             46 
        DB             48 
        DB             49 
        DB             51 
        DB             52 
        DB             54 
        DB             56 
        DB             57 
        DB             59 
        DB             61 
        DB             63 
        DB             65 
        DB             66 
        DB             68 
        DB             70 
        DB             72 
        DB             75 
        DB             77 
        DB             79 
        DB             81 
        DB             83 
        DB             85 
        DB             87 
        DB             90 
        DB             92 
        DB             94 
        DB             97 
        DB             99 
        DB             101 
        DB             104 
        DB             106 
        DB             108 
        DB             111 
        DB             113 
        DB             116 
        DB             118 
        DB             121 
        DB             123 
        DB             126