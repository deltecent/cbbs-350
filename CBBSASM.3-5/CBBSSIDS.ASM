;CBBS V3.5.0 	CBBSIDS.ASM	- IDS MODEM
;07/11/81 12:59:16
;	LINKS TO CBBSWORK
;
;	O O O	O O	O O O
;	  O	O   O	O
; CBBS	  O	O   O	O O O	.ASM
;	  O	O   O	    O
;	O O O	O O	O O O
;
;MOD LOG (THRU 3.2 WRITTEN TO "HISTORY"):
;<< NO FURTHER MODS >>
;
;IDS MODEM BOARD EQUATES
;
IDSST	EQU	0C0H	;STATUS PORT ADDRESS
IDSDAT	EQU	IDSST+1	;DATA PORT ADDRESS
;
;	BITS IN THE STATUS INPUT PORT
IDSCTS	EQU	40H	;CLEAR TO SEND (CARRIER DET)
IDSPE	EQU	8	;PARITY ERROR
IDSTRE	EQU	1	;TX REG EMPTY
IDSRRF	EQU	2	;RCV REG FILLED
;
IDSOUT2	EQU	IDSST+2;OUTPUT PORT 2
;	BITS IN CONTROL OUTPUT PORT 2
IDS2MOD	EQU	1	;OUT 3 WILL BE MODEM CTL
IDSANSW	EQU	30H	;ANSWER MODE FILTERS
IDS2DL	EQU	2	;OUT 3 WILL BE DIALER
IDS2BR	EQU	4	;OUT 3 WILL BE BAUD RATE
;----------------------------
IDSOUT3	EQU	IDSST+3	;OUTPUT PORT 3
;	BITS IN CONTROL OUTPUT PORT 3
IDS3ELS	EQU	1	;ENABLE LONG SPACE DISCONNECT
IDSNESD	EQU	2	;NO ENABLE SPACE DISCONNECT
IDS3MOD	EQU	20H	;MODE FOR 0-600 BAUD
IDS3DTR	EQU	40H	;DATA TERMINAL READY
;
IDS81	EQU	1CH	;8 DATA BITS, 1 STOP
IDS82	EQU	5CH	;8 DATA BITS, 2 STOP
;
IDS110	EQU	142	;DIVIDER FOR 110 BAUD
IDS300	EQU	52	;.. FOR 300 BAUD
IDS450	EQU	35	;..FOR 450 BAUD
IDS600	EQU	26	;..FOR 600 BAUD
;
;ROUTINE TO CONNECT TO THE CALLER
;
CONNECT	EQU	$
;SET UP LONG DELAY REQUEST
	MVI	A,IDS2MOD+IDSANSW
	OUT	IDSOUT2	;SELECT MODEM CTL
;ENABLE LONG SPACE DISC & SET DATA TERMINAL READY
	MVI	A,IDS3ELS+IDS3DTR+IDS3MOD
	OUT	IDSOUT3
;OUTPUT MOTOR ON, AND RING DETECT
	MVI	A,CTLRDET+CTLMOTR
	OUT	CTLPORT
;HOLD THE RING DETECT SIGNAL FOR 1 SEC (CAN'T USE
;IDS RING DETECT BECAUSE IT WOULD GIVE CARRIER,
;EVEN THO THE PROGRAM IS NOT THERE)
;THEN TURN THE RING DETECT BACK OFF
	LXI	H,0
ROWAIT	DCX	H
	MOV	A,H
	ORA	L
	JNZ	ROWAIT
	MVI	A,CTLMOTR
	OUT	CTLPORT	;KEEP MOTOR ON
	CALL	SET110	;PICK UP PHONE
	MVI	B,15	;APPROX # SEC. DELAY
DELAY	LXI	H,9A00H	;1 SEC DELAY
DELLP	IN	IDSST
	ANI	IDSCTS
	JNZ	GOTCAR	;EXIT LOOP IF CARRIER FOUND
	DCX	H	;DECR. LOOP COUNT
	MOV	A,H
	ORA	L
	JNZ	DELLP
;DELAYED ANOTHER SECOND, MORE SECONDS?
	DCR	B	;DCR SECONDS
	JNZ	DELAY	;YES
	JMP	NOCAR
;PHASE 1 - LOOK FOR C/R AT EITHER SPEED
GOTCAR	MVI	A,10+1	;10 TRIES FOR C/R
	STA	TRIES
;QUIT IF NO C/R HAS BEEN READ AFTER 10 TRIES
TRY1	LXI	H,TRIES
	DCR	M
	JZ	NOCAR	;NO CARRIER
	CALL	SET110
	CALL	KEYIN	;GET A CHAR
	CPI	CR
	RZ		;OK.  GO WELCOME ABOARD
	INR	A	;LOSS OF CARRIER?
	JZ	NOCAR	;YES
	CALL	SET300
	CALL	KEYIN	;GET A CHAR
	CPI	CR
	RZ		;OK.  GO WELCOME ABOARD
	INR	A	;LOSS OF CARRIER?
	JZ	NOCAR	;YES
;
	CALL	SET450
	CALL	KEYIN	;GET A CHAR
	CPI	CR
	RZ		;OK.  GO WELCOME ABOARD
	INR	A	;LOSS OF CARRIER?
	JZ	NOCAR	;YES
	CALL	SET600
	CALL	KEYIN
	CPI	CR
	RZ		;OK. 600 BAUD
	INR	A	;LOSS OF CARRIER?
	JNZ	TRY1	;TRY AGAIN
;NO CARRIER FOUND
NOCAR	LXI	H,NOCON
	JMP	PRDIS	;PRINT MSG, EXIT TO PROM
NOCON	DB	CR,LF
	DB	'++NO C/R SEEN, OR LOSS OF CARRIER'
	DB	CR,LF,'    ',0	;%
;
;SET SPEED TO 110 BAUD - PARITY INHIBIT, 2 STOP BITS,
;ANSWER MODE
;
SET110	MVI	A,IDS82	;8 DATA, 2 STOP, NO PARITY
	OUT	IDSST
	MVI	A,IDS2BR+IDSANSW ;SELECT BAUD RATE
	OUT	IDSOUT2
	MVI	A,IDS110
	OUT	IDSOUT3
	MVI	A,'1'
	STA	SPEED
	RET
;
;SET SPEED TO 300 BAUD, PARITY INHIBIT, 1 STOP BIT,
;ANSWER MODE
;
SET300	MVI	A,IDS81	;8 DATA BITS, 1 STOP, NO PARITY
	OUT	IDSST
	MVI	A,IDS2BR+IDSANSW ;SELECT BAUD RATE
	OUT	IDSOUT2
	MVI	A,IDS300
	OUT	IDSOUT3
	MVI	A,'2'
	STA	SPEED
	RET
;
SET450	MVI	A,IDS81	;8 DATA, 1 STOP, NO PARITY
	OUT	IDSST
	MVI	A,IDS2BR+IDSANSW ;SELECT BAUD RATE
	OUT	IDSOUT2
	MVI	A,IDS450
	OUT	IDSOUT3
	MVI	A,'4'
	STA	SPEED
	RET
;
SET600	MVI	A,IDS81	;8 DATA, 1 STOP, NO PARITY
	OUT	IDSST
	MVI	A,IDS2BR+IDSANSW ;SELECT BAUD RATE
	OUT	IDSOUT2
	MVI	A,IDS600
	OUT	IDSOUT3
	MVI	A,'6'
	STA	SPEED
	RET
;
;SET BAUD RATE, BINARY VALUE IN C
;(FROM ALTBAUD COMMAND)
;
SETBAUD	MVI	A,IDS2BR+IDSANSW ;SELECT BAUD RATE
	OUT	IDSOUT2
	MOV	A,C	;GET RATE
	OUT	IDSOUT3
	CALL	KEYIN	;AWAIT A CHAR
	JMP	FUNCT
;
;ROUTINE TO HANG UP PHONE
;
HANGUP	XRA	A
	OUT	IDSOUT3
	MVI	A,IDS2MOD
	OUT	IDSOUT2
	RET
;
	LINK	CBBSWORK ;NEXT .ASM FILE
