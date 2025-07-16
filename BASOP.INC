;-----------------------------------------------
; basop.inc  --  January 7, 1991  --  Iota Systems, Inc.
;
; Basic-52 op-bytes
;
; This is an include file that contains all the op-bytes
; for using routines built into BASIC-52. These routines
; are accessed by putting the op-byte in the accumulator
; (and often setting other registers as necessary for the
; function) and making a lcall to 30H. BASIC-52 will perform
; the function and then return to the caller.
; This file is typically included at the start of an
; assembly language file that need to call these BASIC-52 routines.
;
; page numbers reference the 'BASIC-52 Programming'
; written by Systronix, Inc. and available from
; Iota Systems, Inc. (The Intel book MCS BASIC-52 User's
; Manual also contains this information)
;------------------------------------------------
;
;
;arithmetic operators p.146
;
OP_ADD  EQU     0BH     ;add Basic handles the errors
OP_ADDY EQU     82H     ;add, you handle the error
OP_DIV  EQU     0CH     ;divide, basic handles errors
OP_DIVY EQU     8AH     ;divide, you handle error
OP_MULT EQU     0AH     ;multiply, basic handles error
OP_MULTY EQU    88H     ;multiply, you handle errors
OP_SUB  EQU     0DH     ;divide, basic handles error
OP_SUBY EQU     84H     ;divide, you handle errors
OP_EXP  EQU     09H     ;arg1 raised to power of arg2
                        ;arg2 must be less than 255
OP_SQR  EQU     1FH     ;square root
;
;
;logarithmic operators p.148
;
OP_LEXP EQU     21H     ;e raised to power of arg
OP_LOG  EQU     23H     ;natural log
;
;
;value operators p.152
;
OP_ABS  EQU     18H     ;absolute value
                        ;returns flag in acc
                        ; 00H if sign wasn't changed
                        ; 01H if sign was changed
OP_INT  EQU     19H     ;returns int portion of arg
OP_PI   EQU     26H     ;pushes pi(3.1415926 on stk
OP_RND  EQU     27H     ;pushes pseudo rnd num on arg stk
OP_SIGN EQU     1AH     ;pops arf off stk and pushes
                        ;result on stack
                        ; 0.0 E 0  if num was zero
                        ;-1.0 E 1  if num was negative
                        ; 1.0 E 1  if num was positive
;
;
;logical operators p.150
;
OP_AND  EQU     0FH     ;result pushed on arg stk
OP_OR   EQU     10H     ;result pushed on arg stk
OP_XOR  EQU     0EH     ;result pushed on arg stk
OP_NOT1 EQU     1BH     ;pops arg off stk, converts to int,
                        ;xor's with 0FFFFH, pushes on stk
;
;
;trignometric operators p.148
;
OP_ATN  EQU     22H     ;arc tangent
OP_COS  EQU     1CH     ;cosine
OP_SIN  EQU     1EH     ;sine
OP_TAN  EQU     1DH     ;tangent
;
;
;system control values p.139
;
OP_FREE EQU     29H     ;pushes free onto arg stack
OP_LEN  EQU     2AH     ;length of current basic prgm
OP_MTOP EQU     2CH     ;mtop pushed onto stk
OP_XTAL EQU     2BH     ;xtal pushed onto stk
;
;data conversion p.139
OP_FPINT EQU    01H     ;fp to 16 bit binary int, returns in
                        ;reg pair r3:r1 (hi:lo)
OP_INTFP EQU    9AH     ;16 bit in to fp, r2:r0 converted
                        ;pushed onto stack
;
;
;basic and assembly language data transfer p.140
;
OP_PUSHFP       EQU     02H     ;r2:r0 fp num pushed on stk
OP_POPFP        EQU     03H     ;pop stk fp num to r3:r1
;
;
;relational operators p.149
;
OP_EQUAL        EQU     12H     ;equality
OP_GEQUAL       EQU     13H     ;>=
OP_LEQUAL       EQU     14H     ;<=
OP_NEQUAL       EQU     15H     ;<>, not equal
OP_LESS         EQU     16H     ;<, less than
OP_GREAT        EQU     17H     ;>, greater than
;
;
;console i/o p.141
;
OP_INSTR        EQU     05H     ;get line of text from console
OP_OUTSTR       EQU     06H     ;output string to cnsole
OP_CR_LFD       EQU     07H     ;carriage return line feed
OP_OUTCHAR      EQU     80H     ;char in r5 output
OP_FP           EQU     90H     ;pops fp and outputs
OP_INTHEX       EQU     98H     ;r3:r1 output in hex
OP_GETASCI      EQU     41H     ;get char in accumulator
OP_GETCHAR      EQU     28H     ;get char if ready onto stack
;
;
;special operators p.143
;
;the following opbytes push their result/reg onto the arg stack
;
OP_CBY          EQU     20H     ;get byte from program/code mem
OP_DBY          EQU     24H     ;get byte data mem
OP_XBY          EQU     25H     ;get byte from extern data mem
OP_IE           EQU     2EH     ;processor's interrupt enable
OP_IP           EQU     2FH     ;interrupt priority
OP_PCON         EQU     38H     ;power control reg
OP_1PORT        EQU     37H     ;port1 pins
OP_2RCAP        EQU     36H     ;rcap2h:rcap2l
OP_T2CON        EQU     33H     ;t2con reg
OP_TCON         EQU     34H     ;tcon reg
OP_TIME         EQU     2DH     ;sfr time
OP_OTIMER       EQU     30H     ;16 bit timer0 reg
OP_1TIMER       EQU     31H     ;16 bit timer1 reg
OP_2TIMER       EQU     32H     ;16 bit timer2 reg
OP_TMOD         EQU     35H     ;tmod reg
;
;
;text string operators p.150
OP_EVAL         EQU     39H     ;evaluate expression
OP_GTXTCHAR     EQU     3FH     ;get char don't increase ptr
OP_ADVGCHAR     EQU     40H     ;get char and increase ptr
