;CBBS V3.5.0 	CBBSCLKS.ASM - SCITRONICS CLOCK FUNCTIONS
;07/13/81 20:16:29
; LINKED FROM CBBSDISK ONLY IF CLOCKS=TRUE
;
;	LINKS TO CBBSSUB1
;
;	O O O	O	O   O	O O O
;	O	O	O  O	O
; CBBS	O	O	OOO	O O O	.ASM
;	O	O	O  O	    O
;	O O O	O O O	O   O	O O O
;
;MOD LOG (THRU 3.2 WRITTEN TO "HISTORY")
;
;====> HISTORICAL COMMENTS SINCE 3.3 TO "HISTORY.033"
;
;	----------------
;SCITRONICS CLOCK BOARD EQUATES
;
SCIP0	EQU	24	;SCITRONICS CLOCK READ
SCIP1	EQU	SCIP0+1
SCIP2	EQU	SCIP0+2
SCIP3	EQU	SCIP0+3
;
;'T' COMMAND: PRINTS DATE, TIME, ELAPSED TIME
;
PRDTIME	CALL	PRETIME
	JMP	FUNCT
;
;DATE/TIME PRINT SUBROUTINE
;
PRTIME	LXI	H,ANSWER ;STORE IT HERE
	PUSH	H
	CALL	RDDATE
	MVI	M,' '
	INX	H
	JC	CLKINOP
	CALL	RDTIME	;GET TIME
	MVI	M,0
	POP	H
	MOV	A,M	;GET HI
	CPI	'3'	;VALID?
	JNC	CLKINO1
	CALL	TYPEM0	;TYPE DATE
	CALL	CRLF
	ORA	A	;SHOW CLOCK IS OK
	RET
;
CLKINOP	POP	H	;FIXUP STACK
CLKINO1	CALL	ILPRT
	DB	'++Clock inop++',CR,LF,0
	STC		;SHOW ERROR
	RET
;
;PRETIME: PRINTS CURRENT AND ELAPSED TIME
;
PRETIME	CALL	PRTIME
	RC		;RET IF NO CLOCK
	LXI	H,ANSWER
	PUSH	H
	CALL	RDTIME
	POP	H
	CALL	CONVTBI	;HL=BINARY CURR TIME
	PUSH	H
	LXI	H,LGINTIM ;GET LOGGED IN TIME
	CALL	CONVTBI	;HL=LOGGED IN TIME
	POP	D	;DE=CURR TIME
;SUBTRACT TO GET ELAPSED MINUTES
	MOV	A,E
	SUB	L
	MOV	L,A
	MOV	A,D
	SBB	H
	MOV	H,A
	RAL		;CARRY IF NEG
	JNC	PRETOK
;ELAPSED TIME IS NEGATIVE - ADD 24 HOURS
	LXI	D,24*60	;1 DAY OF MINUTES
	DAD	D
PRETOK	MOV	A,H
	ORA	A	;>255 MINUTES?
	JNZ	PREBAD
	MOV	A,L	;GET TIME
	CPI	120	;>2 HRS? PROB. BAD.
	JNC	PREBAD
;E.T. IS VALID, PRINT IT
	PUSH	PSW
	CALL	ILPRT
	DB	'Connect time ',0
	POP	PSW
	CALL	PRDEC
	CALL	ILPRT
	DB	' minutes',CR,LF,0
	RET
;
PREBAD	CALL	ILPRT
	DB	'Unable to calc connect time',cr,lf,0
	RET
;
;WRITE DATE, TIME, ELAPSED TIME
;
WRETIME	CALL	PRETIME	;PRINT & CALC ELAPSED
	RC		;INVALID CLOCK
	LXI	H,WRETMSG
	JMP	WRVARC	;WRITE ELAPSED, ","
;
;WRITE DATE AND TIME TO CURRENTLY OPEN
;FILE (USUALLY LOG, BUT SOMETIMES "NOTES")
;
WRTIME	LXI	H,ANSWER ;WORK AREA
	PUSH	H
	CALL	RDDATE
	MVI	M,0DH
	POP	H
	RC
	MOV	A,M
	CPI	'2'	;VALIDATE
	CMC		;	THE
	RC		;	TIME
	PUSH	H
	CALL	WRVARC	;WRITE DATE
	POP	H
	PUSH	H
	CALL	RDTIME
	MVI	M,0DH
	POP	H
	JMP	WRVARC	;WRITE DATE
;
;RDTIME - STORES THE TIME "HH:MM:SS " INTO
;	FIELD POINTED TO BY HL.  UPON RETURN,
;	HL POINTS PAST LAST BYTE.
;
RDTIME	CALL	CLKINIT
	RC
	LXI	D,256*5+':' ;GET DIGIT SEL, DELIM
	CALL	CLKDIG2
	CALL	CLKDIG2
	CALL	CLKDIG2
	CALL	CLKCONT
	DCX	H
	ORA	A	;SHOW READ OK
	RET
;
;RDDATE - STORES THE DATE "MM/DD/YY " INTO
;	FIELD POINTED TO BY HL.  UPON RETURN,
;	HL POINTS PAST LAST BYTE.
;
RDDATE	CALL	CLKINIT
	RC
	LXI	D,256*10+'/'
	CALL	CLKDIG2
	CALL	CLKDIG2
	MVI	D,12
	CALL	CLKDIG2
	CALL	CLKCONT	;RESTART CLOCK
	DCX	H
	ORA	A
	RET
;
;STORE 2 CONSECUTIVE DATE/TIME DIGITS
;
CLKDIG2	CALL	CLKDIG
	CALL	CLKDIG
	MOV	M,E
	INX	H
	RET
;
;====>	CLKDIG:	GETS A SINGLE DIGIT FROM THE CLOCK TO MEMORY
;
CLKDIG	MOV	A,D	;GET DIGIT SELECT
	DCR	D	;SETUP FOR NEXT DIGIT
	OUT	SCIP0	;ASK FOR IT
	CPI	5	;HOURS (HAVE TO MASK)?
	IN	SCIP0	;READ IT (PRESERVES CPI 5 TEST)
	JNZ	CLKN5	;	NOT DIGIT 5, SKIP MASKING
	ANI	70H	;	KILL HI DIGIT
CLKN5	RAR!RAR!RAR!RAR	;DIVIDE BY 16
	ANI	0FH	;ISOLATE NUMERIC VALUE
	ADI	'0'	;MAKE PRINTABLE
	MOV	M,A	;STORE I
	INX	H	;BUMP TO NEXT
	RET		;	AND RETURN
;
;====>	CLKINIT	INITIALIZES THE CLOCK FOR READ
;	RETURNS CARRY IF THERE IS NO CLOCK
;
CLKINIT	IN	SCIP0	;CLOCK EXIST?
	INR	A
	STC		;RETURN CARRY
	RZ		;	IF NO CLOCK
;
;INIT PIA
;
	MVI	A,0F0H	;1
	OUT	SCIP1	;2
	MVI	A,0FH	;3
	OUT	SCIP0
	MVI	A,0FCH
	OUT	SCIP3
	MVI	A,0F4H
	OUT	SCIP1
	ORA	A	;CLOCK OK
	RET
;
;====>	CLKCONT	CONTINUE CLOCK
;
CLKCONT	MVI	A,0F8H
	OUT	SCIP1
	MVI	A,0FH
	OUT	SCIP0
	MVI	A,0F8H
	OUT	SCIP3
	MVI	A,0FCH
	OUT	SCIP1
	MVI	A,0FH
	OUT	SCIP0
	RET		;END OF CLOCK ROUTINES
;
;SUBROUTINE TO CONVERT ASCII TIME TO BINARY
;
;USED TO PRINT CALLER'S ELAPSED TIME
;
;	HL POINTS TO "HH:MM"
;
;	BINARY MINUTES RETURNED IN HL
;
CONVTBI	EQU	$
	MOV	B,H	;POINTER
	MOV	C,L	;	TO BC
	LXI	H,0	;INIT ANS
	CALL	CT10F	;GET DIGIT
	CALL	CT10	;X 10 + NEXT DIGIT
	INX	B	;SKIP COLON
	CALL	CT6	;X 6 + NEXT DIGIT
;
;FALL INTO CB10, TO MULTIPLY BY 10
;AND GET LAST DIGIT
;
;MULTIPLY HL BY 10 AND ADD IN BINARY
;VALUE OF NEXT ASCII DIGIT POINTED TO BY BC.
;
CT10	MOV	D,H	;SET UP
	MOV	E,L	;	FOR MULT
	DAD	H	;X2
	DAD	H	;X4
	DAD	D	;X5
	DAD	H	;X10
;
;ENTER HERE TO GET FIRST DIGIT
;
CT10F	LDAX	B	;GET DIGIT
	INX	B	;TO NEXT DIGIT
	SUI	'0'	;MAKE BINARY
	ADD	L	;ADD TO LOW
	MOV	L,A	;SAVE BACK
	RNC
	INR	H	;ADD IN CARRY
	RET
;
;ROUTINE TO MULTIPLY HL BY 60, AND ADD
;IN NEXT DIGIT
;
CT6	MOV	D,H	;SET UP
	MOV	E,L	;	FOR MULT
	DAD	H	;X2
	DAD	D	;X3
	DAD	H	;X6
	JMP	CT10F	;GET DIGIT
;
	ENDIF		;CLOCK
;
 	LINK	CBBSSUB1 ;TO NEXT .ASM FILE
