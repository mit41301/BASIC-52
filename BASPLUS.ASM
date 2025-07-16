;******************************************************************
;
; basplus.asm --  Version 1.1 -- last change 5/24/92
;
;******************************************************************
; changes from version 1.0
; 1. The DC (display program code memory) was changed to DP. Since the letters
; DC are hex numbers, it caused a problem with hex downloads where BASIC
; would try to intrepret the DC hex values as a command. Since DP are not
; hex letters the problem is solved
; 2. The version command now displays version 1.1
;******************************************************************
;
; Copyright 1991
; This code may only be used or modified by the purchaser.
; It may be used in purchaser's products (in executable form only)
; only if that product is not competitive with products of Iota Systems, Inc.
;
; Iota Systems, Inc.
; P.O. Box 8987
; Incline Village, NV 89450
; 702-831-6302
; fax: 702-831-4629
;
; This program extends BASIC-52 with some additional features.
; Additional BASIC commands are added to the BASIC language to
; extend its features. The additional commands added are:
;     RX    -- which Receives an intel hex file from the serial port
;           and puts it into eXternal data memory.
;           The user types RX from Command mode, and the program
;           reads in a line of data. When it is ready for another line
;           of data, the program outputs  '#>' characters.  This is the
;           handshaking method that is used.  The RX command is
;           terminated when a hex line containing 0 bytes is received,
;           namely a line like ":0000000000". All recieved data is
;           is saved into external data ram.
;           This command does miminal error checking.  If the incoming
;           hex data contains garbage, unpredictable results will occur.
;           Checksum errors are flagged, but data is stored anyway.
;     SC    start_address, end_address  -- which sends in intel hex
;           format the data from the start_address to the end_address
;           of code memory
;     SX    start_address, end_address  -- which sends in intel hex
;           format the data from the start_address to the end_address
;           of external data memory
;     DX    start_address, end_address -- which displays external ram memory
;           to the console
;     DI    start_address, end_address -- which displays internal ram memory
;           to the console
;     DP    start_address, end_address -- which displays program memory
;           to the console
;     CX    address -- which displays one byte of eXternal data and allows
;           you to Change it. A period terminates the command.
;     CI    address -- which displays one byte of indirect Data and allows
;           you to Change it. A period terminates the command.
;     FX    beg_addr,end_addr,data -- which fills external memory with data
;     FI    beg_addr,end_addr,data -- which fills internal memory with data
;     VER   displays the current version
;
;     NOTE: a Control-C will abort any of the above commands (except FX and FI)
;******************************************************************
;
; include the basic op-byte definition file
$include (basop.inc)
;
;
            NAME  BASPLUS
;
EXTRN       CODE  (BCK)                 ;this is a direct call address
                                        ;in BASIC-52 for checking to see
                                        ;if control-s or -q has been pressed
                                        ;and if it has our calls to output
                                        ;characters will be stopped and
                                        ;started
;
; CODE space equates
BASIC       CODE  30H                   ;address to call BASIC routines
;
; internal DATA equates
; register bank 3 is used and accessed directly via the register's
; address
LBEG_ADDR   DATA  18H                   ; low byte of beginning address
HBEG_ADDR   DATA  19H                   ; high byte of beginning address
LEND_ADDR   DATA  1AH                   ; low byte of ending address
HEND_ADDR   DATA  1BH                   ; high byte of ending address
TEMP        DATA  1CH                   ; temporary storage location
CHECKSUM    DATA  1DH                   ; used for keeping track of check sum
BYTE_COUNT  DATA  1EH                   ; keep track of number of bytes output
                                        ; in a line
; XDATA space equates
IN_STRING   XDATA 07H                   ; location of the string basic reads in
;
;**********************************************************************
; the following is required by basic so it knows of new tokens
;**********************************************************************
;
; CSEG means CODE SEGMENT. Similiar to an ORG statement.
;
            CSEG  AT 2002H              ;tell basic the expansion option exists
            db    5AH

            CSEG  AT 2048H              ; flag to tell preprocessor custom table
            setb  45                    ; exists
            ret

            CSEG  AT 2070H              ; basic comes here to get vector table
            mov   dptr,#vector_table    ; address
            ret

            CSEG  AT 2078H              ; basic comes here for token table addr
            mov   dptr,#token_table
            ret

            CSEG  AT 2100H              ; start of user routines,
                                        ;out of basic's space

vector_table:
            dw    do_savec              ; address of send code routine (SC)
            dw    do_savex              ; address of send external routine (SX)
            dw    do_load               ; address of load routine (RX)
            dw    do_dispx              ; address of display x memory (DX)
            dw    do_dispi              ; address of display i memory (DI)
            dw    do_dispc              ; address of display code memory (DP)
            dw    do_chngx              ; address of change x memory (CX)
            dw    do_chngi              ; address of change idata memory (CI)
            dw    do_fillx              ; address of the fill x memory (FX)
            dw    do_filli              ; address of the fill i memory (FI)
            dw    do_ver                ; address of the display version (VER)
token_table:
            db    10H                   ; custom routine 'SC', send code mem.
            db    'SC'                  ; keyword
            db    0

            db    11H                   ; custom routine 'SX', send eX. mem.
            db    'SX'                  ; keyword
            db    0

            db    12H                   ; custom routine 'RX', rcve x memory
            db    'RX'
            db    0

            db    13H                   ; custom routine 'DX', display x mem
            db    'DX'
            db    0

            db    14H                   ; custom routine 'DI', display i mem
            db    'DI'
            db    0

            db    15H                   ; custom routine 'DP', display program
            db    'DP'
            db    0

            db    16H                   ; custom routine 'CX', change x mem
            db    'CX'
            db    0

            db    17H                   ; custom routine 'CI', change idata mem
            db    'CI'
            db    0

            db    18H                   ; custom routine 'FX', fill x memory
            db    'FX'
            db    0

            db    19H                   ; custom routine 'FI', fill i memory
            db    'FI'
            db    0

            db    1AH                   ; custom routine 'VER', show version
            db    'VER'
            db    0FFH                  ; end of token table marker
;
; define some string constants in code space
;
; strings stored in CODE memory, basic wants a CR for termination
last_line:  db    ':0000000000"'
cmd_msg:    db    'ERROR: MUST BE USED IN COMMAND MODE"'
syntax_msg: db    'ERROR: BAD SYNTAX OR BAD DATA VALUE"'
cksum_msg:  db    'ERROR: INVALID DATA RECEIVED"'
version:    db    'BASIC-52 PLUS Version 1.1 - (c) 1991 Iota Systems, Inc."'
;
; Start of the code
;
; (RX) this is the routine to receive an INTEL hex file and put it in
; external data ram.
do_load:
            jb    47,load0              ; see if basic is in command mode
            ljmp  cmd_error             ; load only works in command mode
                                        ; if bit 47 is set ok, else return

load0:
            mov   r5,#'#'               ; output the prompt characters
            mov   a,#OP_OUTCHAR
            lcall BASIC
            mov   r5,#'>'               ; output the prompt characters
            mov   a,#OP_OUTCHAR
            lcall BASIC
            mov   a,#OP_INSTR           ; get a line of text from the console
            lcall BASIC
load1:
; read input string for the first colon character
            mov   dptr,#IN_STRING       ; set up data pointer to get 1st char
            movx  a,@dptr               ; get 1st character, should be colon
            cjne  a,#':',load_cmd_err   ; jmp if not a colon
            inc   dptr
; read input string for the byte count
            acall read_byte
            mov   BYTE_COUNT,a
            mov   CHECKSUM,a            ; save checksum
; now get the starting address
            acall read_byte
            mov   HBEG_ADDR,a
            add   a,CHECKSUM
            mov   CHECKSUM,a
            acall read_byte
            mov   LBEG_ADDR,a
            add   a,CHECKSUM
            mov   CHECKSUM,a
; now get the dummy 00 data from the input string, discard the data
            acall read_byte
; now check if last line of data.  if BYTE_COUNT is 0 we are done.
            mov   a,BYTE_COUNT
            jz    load_done
; get data and save it to ram
load2:
            acall read_byte
            push  acc                   ; save a while we calc checksum
            add   a,CHECKSUM
            mov   CHECKSUM,a
            pop   acc
            push  dph                   ; save data pointer to string
            push  dpl
            mov   dph,HBEG_ADDR         ; get location of data
            mov   dpl,LBEG_ADDR
            movx  @dptr,a               ; save the data
            inc   dptr                  ; inc and save the data location
            mov   HBEG_ADDR,dph
            mov   LBEG_ADDR,dpl
            pop   dpl
            pop   dph
            djnz  BYTE_COUNT,load2      ; go back for more data if bytes left
; check the checksum for valid checksum
            acall read_byte
            add   a,CHECKSUM
            jz    load0                 ; jump if no cksum error, next line
            lcall cksum_error           ; call if we have a ckecksum error
            ljmp  load0                 ; get next line
;
load_done:
            clr   a
            ljmp  BASIC

load_cmd_err:
            lcall cksum_error           ; invalid 1st character, disp msg
            ljmp  load0                 ; go get next line

; routine to get a byte of data from ascii string (reads 2 ascii chars and
; converts it to one byte.  No error checking performed. characters better
; be 0-9 or A-F upper or lower case
; uses ram location TEMP, a, dptr must point to the character to be read.
; byte returned in a.
read_byte:
            movx  a,@dptr               ; get 1st character from input string
            jnb   acc.6,rb1             ; jump if not a letter a-f or A-F
            clr   acc.5                 ; convert to upper case
rb1:        clr   c                     ; convert from ascii to number 0-15
            subb  a,#30H
            jnb   acc.4,rb2             ; if an a-f number then sub 7
            subb  a,#7                  ; convert an a-f number
rb2:
            rl    a                     ; this is high nibble, rotate it left
            rl    a
            rl    a
            rl    a
            mov   TEMP,a                ; save it
            inc   dptr                  ; now get low nibble from input string
            movx  a,@dptr
            jnb   acc.6,rb3             ; jump if not a letter
            clr   acc.5                 ; convert to upper case
rb3:        clr   c                     ; convert from ascii to number 0-15
            subb  a,#30H
            jnb   acc.4,rb4             ; if an a-f number then sub a 7
            subb  a,#7                  ; convert an a-f number
rb4:        add   a,TEMP                ; add in the high nibble and
            inc   dptr                  ; get ready for next character
            ret


; (SC) this routine sends an intel hex file for the given addresses
; using code memory
savec_err:   ljmp  syntax_error         ; error jump table
do_savec:
            jb    47,savec1             ; see if basic is in command mode
            ljmp  cmd_error             ; save only works in command mode
                                        ; if bit 47 is set ok, else return

savec1:     mov   a,#OP_EVAL            ; evaluate 1st expression (begin addr)
            lcall BASIC                 ; value is put on arg stack

            mov   a,#OP_ADVGCHAR        ; get char after expr and advance
            lcall BASIC                 ; text pointer

            cjne  a,#',',savec_err      ; if not a comma, an error and return

savec2:     mov   a,#OP_EVAL            ; evaluate 2nd expr (end addr)
            lcall BASIC

            mov   a,#OP_FPINT           ; convert end addr to int, returned
            lcall BASIC                 ; in r3,r1

            mov   LEND_ADDR,r1          ; save low ending address
            mov   HEND_ADDR,r3          ; save high ending address

            mov   a,#OP_FPINT           ; convert beg addr to int
            lcall BASIC

            mov   LBEG_ADDR,r1          ; save low beg address
            mov   HBEG_ADDR,r3          ; save high beg address

; check address to see if done
savec3:
            clr   c
            mov   a,LEND_ADDR
            subb  a,LBEG_ADDR
            mov   BYTE_COUNT,a          ; save low subtraction here
            mov   a,HEND_ADDR
            subb  A,HBEG_ADDR
            jnc   savec4                ; if within address range go do it
            ljmp  done_savec            ; else we are done

; check to see how many bytes are left to output
savec4:
            cjne  a,#00H,savec5         ; a contains the result from subing
                                        ; high beg byte from the high end addr
                                        ; if they are not equal can assume at
                                        ; least 256 bytes to output
; BYTE_COUNT contains the result of the lower byte subtracts.  if the
; number is >= 15, then we set BYTE_COUNT = 16 and continue.  IF
; BYTE_COUNT < 15 then we need to increment BYTE_COUNT and use this as
; the remaining bytes to output.
            clr   c
            mov   a,BYTE_COUNT
            subb  a,#0FH

            jnc   savec5                ; if a >= 15 then byte count becomes 16
            inc   BYTE_COUNT            ; need to add 1 to get num of bytes
            sjmp  savec6

savec5:
            mov   BYTE_COUNT,#10H       ; count must be 16
savec6:
            mov   CHECKSUM,#00H         ; init check sum to zero

; output standard line header
            mov   r5,#':'               ; get ready to output colon
            mov   a,#OP_OUTCHAR
            lcall BASIC

            mov   a,BYTE_COUNT
            swap  a                     ; get high nibble of byte counter
            lcall ascii_out
            mov   a,BYTE_COUNT          ; get low nibble to output
            lcall ascii_out

            mov   a,BYTE_COUNT          ; add byte counter value to checksum
            add   a,CHECKSUM
            mov   CHECKSUM,a

; output address
savec7:
            mov   a,HBEG_ADDR           ; get beginning address
            add   a,CHECKSUM            ; update checksum
            mov   CHECKSUM,a            ; get addr value back

            mov   a,HBEG_ADDR
            swap  a                     ; send high nibble to be output
            lcall ascii_out             ; output value
            mov   a,HBEG_ADDR           ; get original address back
            lcall ascii_out             ; output low nibble

            mov   a,LBEG_ADDR           ; get low byte of begging address
            add   a,CHECKSUM            ; update checksum
            mov   CHECKSUM,a            ; get address value back

            mov   a,LBEG_ADDR
            swap  a                     ; send high nibble to output
            lcall ascii_out             ; output value
            mov   a,LBEG_ADDR           ; get original address back
            lcall ascii_out             ; output low nibble

; need to output 2 zeros, check sum doesn't increase
            mov   r5,#'0'
            mov   a,#OP_OUTCHAR         ; output 1st zero
            lcall BASIC
            mov   r5,#'0'
            mov   A,#OP_OUTCHAR         ;can't assume r5 and a don't get changed
            lcall BASIC

; finally ready to output data!!!!
savec8:
            mov   dpl,LBEG_ADDR         ; set up data pointer
            mov   dph,HBEG_ADDR
            clr   a
            movc  a,@a+dptr             ; get data
            inc   dptr                  ; increment data ptr to next byte
            mov   TEMP,a                ; save data value
            mov   LBEG_ADDR,dpl         ; save new address
            mov   HBEG_ADDR,dph

            add   a,CHECKSUM            ; update checksum
            mov   CHECKSUM,a

            mov   a,TEMP
            swap  a                     ; get high nibble to output first
            lcall ascii_out             ; output
            mov   a,TEMP                ; get original value
            lcall ascii_out             ; output low nibble

; have we output all of the bytes? (i.e. are we at end of line?)
            djnz  BYTE_COUNT,savec8


savec9:
            mov   a,CHECKSUM            ; output checksum
            cpl   a                     ; complement checksum in a
            add   a,#01H                ; add 1 before outputtin
            mov   CHECKSUM,a            ; save checksum value
            swap  a
            lcall ascii_out             ; output high nibble
            mov   a,CHECKSUM
            lcall ascii_out             ; output low nibble

            mov   a,#OP_CR_LFD          ; output carriage return line feed
            lcall BASIC

            call  BCK                   ; check for xon and xoff characters

            mov   CHECKSUM,#00H         ; initialize check sum
            clr   a                     ; see if BEG_ADDR = 0, if so we're done
            cjne  a,LBEG_ADDR,savec10
            cjne  a,HBEG_ADDR,savec10
            sjmp  done_savec

savec10:    ljmp  savec3

; done with savec, need to output 10 zeros in last line
done_savec:
            mov   r3,#HIGH last_line
            mov   r1,#LOW last_line
            setb  52                    ; so basic knows from program mem
            mov   a,#OP_OUTSTR
            lcall BASIC
            mov   a,#OP_CR_LFD          ; output carriage return line feed
            lcall BASIC
            clr   a
            ljmp  BASIC

; (SX) this routine sends an intel hex file for the given addresses
; using code memory
savex_err:  ljmp  syntax_error          ; error jump table
do_savex:
            jb    47,savex1             ; see if basic is in command mode
            ljmp  cmd_error             ; save only works in command mode
                                        ; if bit 47 is set ok, else return

savex1:     mov   a,#OP_EVAL            ; evaluate 1st expression (begin addr)
            lcall BASIC                 ; value is put on arg stack

            mov   a,#OP_ADVGCHAR        ; get char after expr and advance
            lcall BASIC                 ; text pointer

            cjne  a,#',',savex_err      ; if not a comma, an error and return

savex2:     mov   a,#OP_EVAL            ; evaluate 2nd expr (end addr)
            lcall BASIC

            mov   a,#OP_FPINT           ; convert end addr to int, returned
            lcall BASIC                 ; in r3,r1

            mov   LEND_ADDR,r1          ; save low ending address
            mov   HEND_ADDR,r3          ; save high ending address

            mov   a,#OP_FPINT           ; convert beg addr to int
            lcall BASIC

            mov   LBEG_ADDR,r1          ; save low beg address
            mov   HBEG_ADDR,r3          ; save high beg address

; check address to see if done
savex3:
            clr   c
            mov   a,LEND_ADDR
            subb  a,LBEG_ADDR
            mov   BYTE_COUNT,a          ; save low subtraction here
            mov   a,HEND_ADDR
            subb  A,HBEG_ADDR
            jnc   savex4                ; if within address range go do it
            ljmp  done_savex            ; else we are done

; check to see how many bytes are left to output
savex4:
            cjne  a,#00H,savex5         ; a contains the result from subing
                                        ; high beg byte from the high end addr
                                        ; if they are not equal can assume at
                                        ; least 256 bytes to output
; BYTE_COUNT contains the result of the lower byte subtracts.  if the
; number is >= 15, then we set BYTE_COUNT = 16 and continue.  IF
; BYTE_COUNT < 15 then we need to increment BYTE_COUNT and use this as
; the remaining bytes to output.
            clr   c
            mov   a,BYTE_COUNT
            subb  a,#0FH

            jnc   savex5                ; if a >= 15 then byte count becomes 16
            inc   BYTE_COUNT            ; need to add 1 to get num of bytes
            sjmp  savex6

savex5:
            mov   BYTE_COUNT,#10H       ; count must be 16
savex6:
            mov   CHECKSUM,#00H         ; init check sum to zero

; output standard line header
            mov   r5,#':'               ; get ready to output colon
            mov   a,#OP_OUTCHAR
            lcall BASIC

            mov   a,BYTE_COUNT
            swap  a                     ; get high nibble of byte counter
            lcall ascii_out
            mov   a,BYTE_COUNT          ; get low nibble to output
            lcall ascii_out

            mov   a,BYTE_COUNT          ; add byte counter value to checksum
            add   a,CHECKSUM
            mov   CHECKSUM,a

; output address
savex7:
            mov   a,HBEG_ADDR           ; get beginning address
            add   a,CHECKSUM            ; update checksum
            mov   CHECKSUM,a            ; get addr value back

            mov   a,HBEG_ADDR
            swap  a                     ; send high nibble to be output
            lcall ascii_out             ; output value
            mov   a,HBEG_ADDR           ; get original address back
            lcall ascii_out             ; output low nibble

            mov   a,LBEG_ADDR           ; get low byte of begging address
            add   a,CHECKSUM            ; update checksum
            mov   CHECKSUM,a            ; get address value back

            mov   a,LBEG_ADDR
            swap  a                     ; send high nibble to output
            lcall ascii_out             ; output value
            mov   a,LBEG_ADDR           ; get original address back
            lcall ascii_out             ; output low nibble

; need to output 2 zeros, check sum doesn't increase
            mov   r5,#'0'
            mov   a,#OP_OUTCHAR         ; output 1st zero
            lcall BASIC
            mov   r5,#'0'
            mov   A,#OP_OUTCHAR         ;can't assume r5 and a don't get changed
            lcall BASIC

; finally ready to output data!!!!
savex8:
            mov   dpl,LBEG_ADDR         ; set up data pointer
            mov   dph,HBEG_ADDR
            movx  a,@dptr               ; get data
            inc   dptr                  ; increment data ptr to next byte
            mov   TEMP,a                ; save data value
            mov   LBEG_ADDR,dpl         ; save new address
            mov   HBEG_ADDR,dph

            add   a,CHECKSUM            ; update checksum
            mov   CHECKSUM,a

            mov   a,TEMP
            swap  a                     ; get high nibble to output first
            lcall ascii_out             ; output
            mov   a,TEMP                ; get original value
            lcall ascii_out             ; output low nibble

; have we output all of the bytes? (i.e. are we at end of line?)
            djnz  BYTE_COUNT,savex8


savex9:
            mov   a,CHECKSUM            ; output checksum
            cpl   a                     ; complement checksum in a
            add   a,#01H                ; add 1 before outputtin
            mov   CHECKSUM,a            ; save checksum value
            swap  a
            lcall ascii_out             ; output high nibble
            mov   a,CHECKSUM
            lcall ascii_out             ; output low nibble

            mov   a,#OP_CR_LFD          ; output carriage return line feed
            lcall BASIC

            call  BCK                   ; check for xon and xoff characters

            mov   CHECKSUM,#00H         ; initialize check sum

            clr   a                     ; see if BEG_ADDR = 0, if so we're done
            cjne  a,LBEG_ADDR,savex10
            cjne  a,HBEG_ADDR,savex10
            sjmp  done_savex

savex10:    ljmp  savex3

; done with savex, need to output 10 zeros in last line
done_savex:
            mov   r3,#HIGH last_line
            mov   r1,#LOW last_line
            setb  52                    ; so basic knows from program mem
            mov   a,#OP_OUTSTR
            lcall BASIC
            mov   a,#OP_CR_LFD          ; output carriage return line feed
            lcall BASIC
            clr   a
            ljmp  BASIC

;
; (DX)
; display eXternal data ram locations
do_dispx:
            jb    47,dispx1             ; see if basic is in command mode
            ljmp  cmd_error             ; disp only works in command mode
                                        ; if bit 47 is set ok, else return

dispx1:     mov   a,#OP_EVAL            ; evaluate 1st expression (begin addr)
            lcall BASIC                 ; value is put on arg stack

            mov   a,#OP_ADVGCHAR        ; get char after expr and advance
            lcall BASIC                 ; text pointer

            cjne  a,#',',dispx_err      ; if not a comma, an error and return

dispx2:     mov   a,#OP_EVAL            ; evaluate 2nd expr (end addr)
            lcall BASIC

            mov   a,#OP_FPINT           ; convert end addr to int, returned
            lcall BASIC                 ; in r3,r1

            mov   LEND_ADDR,r1          ; save low ending address
            mov   HEND_ADDR,r3          ; save high ending address

            mov   a,#OP_FPINT           ; convert beg addr to int
            lcall BASIC

            mov   LBEG_ADDR,r1          ; save low beg address
            anl   LBEG_ADDR,#0f0h       ; round off the starting address
            mov   HBEG_ADDR,r3          ; save high beg address

; check address to see if done
dispx3:
            clr   c
            mov   a,LEND_ADDR
            subb  a,LBEG_ADDR
            mov   BYTE_COUNT,a          ;save low subtraction here in BYTE_COUNT
            mov   a,HEND_ADDR
            subb  A,HBEG_ADDR
            jnc   dispx4                ; if within address range go do it
            ljmp  done_dispx            ; else we are done

; set BYTE_COUNT to 16
dispx4:
            mov   BYTE_COUNT,#16


; output address
dispx7:
            mov   r1,LBEG_ADDR          ;output address in hex
            mov   r3,HBEG_ADDR
            clr   36H                   ;don't supress leading 0's
            mov   a,#OP_INTHEX
            call  BASIC


; need to output a colon and space
            mov   r5,#':'
            mov   a,#OP_OUTCHAR         ; output 1st zero
            lcall BASIC
            mov   r5,#' '
            mov   A,#OP_OUTCHAR         ;can't assume r5 and a don't get changed
            lcall BASIC

; finally ready to output data!!!!
dispx8:
            mov   dpl,LBEG_ADDR         ; set up data pointer
            mov   dph,HBEG_ADDR
            movx  a,@dptr               ; get data
            inc   dptr                  ; increment data ptr to next byte
            mov   LBEG_ADDR,dpl         ; save new address
            mov   HBEG_ADDR,dph

            mov   r1,a                  ;output the data
            mov   r3,#0
            setb  36H                   ;suppress leading 0's
            mov   a,#OP_INTHEX
            call  BASIC

; have we output all of the bytes? (i.e. are we at end of line?)
            djnz  BYTE_COUNT,dispx8


            mov   a,#OP_CR_LFD          ; output carriage return line feed
            lcall BASIC

            call  BCK                   ; check for xon or xoff

            clr   a                     ; see if BEG_ADDR = 0, if so we're done
            cjne  a,LBEG_ADDR,dispx10
            cjne  a,HBEG_ADDR,dispx10
            sjmp  done_dispx

dispx10:    ljmp  dispx3

; done with dispx
done_dispx:
            clr   a
            ljmp  BASIC

dispx_err:  ljmp  syntax_error

;
; (DI)
; display internal data ram locations
do_dispi:
            jb    47,dispi1             ; see if basic is in command mode
            ljmp  cmd_error             ; disp only works in command mode
                                        ; if bit 47 is set ok, else return

dispi1:     mov   a,#OP_EVAL            ; evaluate 1st expression (begin addr)
            lcall BASIC                 ; value is put on arg stack

            mov   a,#OP_ADVGCHAR        ; get char after expr and advance
            lcall BASIC                 ; text pointer

            cjne  a,#',',dispi_err      ; if not a comma, an error and return

dispi2:     mov   a,#OP_EVAL            ; evaluate 2nd expr (end addr)
            lcall BASIC

            mov   a,#OP_FPINT           ; convert end addr to int, returned
            lcall BASIC                 ; in r3,r1

            mov   LEND_ADDR,r1          ; save low ending address
            mov   HEND_ADDR,r3          ; save high ending address
            cjne  r3,#0,dispi_err       ; call for error if top byte <> 0


            mov   a,#OP_FPINT           ; convert beg addr to int
            lcall BASIC

            mov   LBEG_ADDR,r1          ; save low beg address
            anl   LBEG_ADDR,#0f0h       ; round off the starting address
            mov   HBEG_ADDR,r3          ; save high beg address
            cjne  r3,#0,dispi_err       ; call for error if top byte <> 0

; check address to see if done
dispi3:
            clr   c
            mov   a,LEND_ADDR
            subb  a,LBEG_ADDR
            mov   BYTE_COUNT,a          ;save low subtraction here in BYTE_COUNT
            mov   a,HEND_ADDR
            subb  A,HBEG_ADDR
            jnc   dispi4                ; if within address range go do it
            ljmp  done_dispi            ; else we are done

; set BYTE_COUNT to 16
dispi4:
            mov   BYTE_COUNT,#16


; output address
dispi7:
            mov   r1,LBEG_ADDR          ;output address in hex
            mov   r3,HBEG_ADDR
            setb  36H                   ;do supress leading 0's
            mov   a,#OP_INTHEX
            call  BASIC


; need to output a colon and space
            mov   r5,#':'
            mov   a,#OP_OUTCHAR         ; output 1st zero
            lcall BASIC
            mov   r5,#' '
            mov   A,#OP_OUTCHAR         ;can't assume r5 and a don't get changed
            lcall BASIC

; finally ready to output data!!!!
dispi8:
            mov   r1,LBEG_ADDR          ; set up pointer to data
            mov   a,@r1                 ; get data
            inc   LBEG_ADDR             ; increment to next byte

            mov   r1,a                  ;output the data
            mov   r3,#0
            setb  36H                   ;suppress leading 0's
            mov   a,#OP_INTHEX
            call  BASIC

; have we output all of the bytes? (i.e. are we at end of line?)
            djnz  BYTE_COUNT,dispi8


            mov   a,#OP_CR_LFD          ; output carriage return line feed
            lcall BASIC

            call  BCK                   ; check for xon or xoff

            clr   a                     ; see if BEG_ADDR = 0, if so we're done
            cjne  a,LBEG_ADDR,dispi10
            sjmp  done_dispi

dispi10:    ljmp  dispi3

; done with dispi
done_dispi:
            clr   a
            ljmp  BASIC

dispi_err:  ljmp  syntax_error

;
; (DP)
; display code memory locations
do_dispc:
            jb    47,dispc1             ; see if basic is in command mode
            ljmp  cmd_error             ; disp only works in command mode
                                        ; if bit 47 is set ok, else return

dispc1:     mov   a,#OP_EVAL            ; evaluate 1st expression (begin addr)
            lcall BASIC                 ; value is put on arg stack

            mov   a,#OP_ADVGCHAR        ; get char after expr and advance
            lcall BASIC                 ; text pointer

            cjne  a,#',',dispc_err      ; if not a comma, an error and return

dispc2:     mov   a,#OP_EVAL            ; evaluate 2nd expr (end addr)
            lcall BASIC

            mov   a,#OP_FPINT           ; convert end addr to int, returned
            lcall BASIC                 ; in r3,r1

            mov   LEND_ADDR,r1          ; save low ending address
            mov   HEND_ADDR,r3          ; save high ending address

            mov   a,#OP_FPINT           ; convert beg addr to int
            lcall BASIC

            mov   LBEG_ADDR,r1          ; save low beg address
            anl   LBEG_ADDR,#0f0h       ; round off the starting address
            mov   HBEG_ADDR,r3          ; save high beg address

; check address to see if done
dispc3:
            clr   c
            mov   a,LEND_ADDR
            subb  a,LBEG_ADDR
            mov   BYTE_COUNT,a          ; save low subtraction in BYTE_COUNT
            mov   a,HEND_ADDR
            subb  A,HBEG_ADDR
            jnc   dispc4                ; if within address range go do it
            ljmp  done_dispc            ; else we are done

; set BYTE_COUNT to 16
dispc4:
            mov   BYTE_COUNT,#16


; output address
dispc7:
            mov   r1,LBEG_ADDR          ;output address in hex
            mov   r3,HBEG_ADDR
            clr   36H                   ;don't supress leading 0's
            mov   a,#OP_INTHEX
            call  BASIC


; need to output a colon and space
            mov   r5,#':'
            mov   a,#OP_OUTCHAR         ; output 1st zero
            lcall BASIC
            mov   r5,#' '
            mov   A,#OP_OUTCHAR         ;can't assume r5 and a don't get changed
            lcall BASIC

; finally ready to output data!!!!
dispc8:
            mov   dpl,LBEG_ADDR         ; set up data pointer
            mov   dph,HBEG_ADDR
            clr   a
            movc  a,@a+dptr             ; get data
            inc   dptr                  ; increment data ptr to next byte
            mov   LBEG_ADDR,dpl         ; save new address
            mov   HBEG_ADDR,dph

            mov   r1,a                          ;output the data
            mov   r3,#0
            setb  36H                           ;suppress leading 0's
            mov   a,#OP_INTHEX
            call  BASIC

; have we output all of the bytes? (i.e. are we at end of line?)
            djnz  BYTE_COUNT,dispc8


            mov   a,#OP_CR_LFD          ; output carriage return line feed
            lcall BASIC

            call  BCK                   ; check for xon-xoff characters

            clr   a                     ; see if BEG_ADDR = 0, if so we're done
            cjne  a,LBEG_ADDR,dispc10
            cjne  a,HBEG_ADDR,dispc10
            sjmp  done_dispc

dispc10:    ljmp  dispc3

; done with dispc
done_dispc:
            clr   a
            ljmp  BASIC

dispc_err:  ljmp  syntax_error
;
; (CX)
; change eXternal data ram locations
do_chngx:
            jb    47,chngx1             ; see if basic is in command mode
            ljmp  cmd_error             ; disp only works in command mode
                                        ; if bit 47 is set ok, else return

chngx1:     mov   a,#OP_EVAL            ; evaluate expression (addr)
            lcall BASIC                 ; value is put on arg stack


            mov   a,#OP_FPINT           ; convert addr to int, returned
            lcall BASIC                 ; in r3,r1

            mov   LBEG_ADDR,r1          ; save low address
            mov   HBEG_ADDR,r3          ; save high address



; output address
chngx7:
            mov   r1,LBEG_ADDR          ;output address in hex
            mov   r3,HBEG_ADDR
            clr   36H                   ;don't supress leading 0's
            mov   a,#OP_INTHEX
            call  BASIC


; need to output a colon and space
            mov   r5,#':'
            mov   a,#OP_OUTCHAR
            lcall BASIC
            mov   r5,#' '
            mov   A,#OP_OUTCHAR
            lcall BASIC

; finally ready to output data!!!!
chngx8:
            mov   dpl,LBEG_ADDR         ; set up data pointer
            mov   dph,HBEG_ADDR
            movx  a,@dptr               ; get data

            mov   r1,a                  ;output the data
            mov   r3,#0
            setb  36H                   ;suppress leading 0's
            mov   a,#OP_INTHEX
            call  BASIC

            mov   r5,#' '               ;output 2 spaces
            mov   a,#OP_OUTCHAR
            lcall BASIC
            mov   r5,#' '
            mov   A,#OP_OUTCHAR
            lcall BASIC

                                        ;input a string of the new data
            mov   A,#OP_INSTR
            lcall BASIC

;check the first character of string, if it a CR, then go on to next address
            mov   dptr,#IN_STRING
            movx  a,@dptr
            cjne  a,#0DH,chngx2
            sjmp  chngx6                ; jmp to get next address

;if it is a '.' then abort this command
chngx2:     cjne  a,#'.',chngx3
            sjmp  done_chngx
;set up basic pointer to the address of the string we inputted
chngx3:     mov   8,#LOW(IN_STRING)
            mov   0ah,#HIGH(IN_STRING)
                                        ;get the number from the string
            mov   a,#OP_EVAL            ; evaluate expression
            lcall BASIC                 ; value is put on arg stack

            mov   a,#OP_FPINT           ; convert number to int
            lcall BASIC                 ; in r3,r1

            mov   a,r1                  ; save low byte in acc, discard high
                                        ; get the address back and save number
                                        ; in memory
            cjne  r3,#0,chngx_err       ; if data > 255 then command error
            mov   dpl,LBEG_ADDR         ; set up data pointer
            mov   dph,HBEG_ADDR
            movx  @dptr,a               ; save data
chngx6:     mov   dpl,LBEG_ADDR         ; set up data pointer, again so if we
                                        ; jmp here from above without getting
                                        ; new data we can increment the addr
            mov   dph,HBEG_ADDR
            inc   dptr
            mov   LBEG_ADDR,dpl         ; save new address
            mov   HBEG_ADDR,dph


chngx9:
            ljmp  chngx7

; done with chngx
done_chngx:
            clr   a
            ljmp  BASIC
;
chngx_err:  ljmp  syntax_error          ; have a syntax error
;
; (CI)
; Change internal indirect Data ram locations
do_chngi:
            jb    47,chngi1             ; see if basic is in command mode
            ljmp  cmd_error             ; disp only works in command mode
                                        ; if bit 47 is set ok, else return

chngi1:     mov   a,#OP_EVAL            ; evaluate expression (addr)
            lcall BASIC                 ; value is put on arg stack


            mov   a,#OP_FPINT           ; convert addr to int, returned
            lcall BASIC                 ; in r3,r1

            mov   LBEG_ADDR,r1          ; save low address
            mov   HBEG_ADDR,r3          ; save high address
            cjne  r3,#0,chngi_err       ; call for error if top byte <> 0



; output address
chngi7:
            mov   r1,LBEG_ADDR          ;output address in hex
            mov   r3,#0
            setb  36H                   ;do supress leading 0's
            mov   a,#OP_INTHEX
            call  BASIC


; need to output a colon and space
            mov   r5,#':'
            mov   a,#OP_OUTCHAR
            lcall BASIC
            mov   r5,#' '
            mov   A,#OP_OUTCHAR
            lcall BASIC

; finally ready to output data!!!!
chngi8:
            mov   r1,LBEG_ADDR          ; set up data pointer
            mov   a,@r1                 ; get data

            mov   r1,a                  ;output the data
            mov   r3,#0
            setb  36H                   ;suppress leading 0's
            mov   a,#OP_INTHEX
            call  BASIC

            mov   r5,#' '               ;output 2 spaces
            mov   a,#OP_OUTCHAR
            lcall BASIC
            mov   r5,#' '
            mov   A,#OP_OUTCHAR
            lcall BASIC

                                        ;input a string of the new data
            mov   A,#OP_INSTR
            lcall BASIC
;check the first character of string, if it a CR, then go on to next address
            mov   dptr,#IN_STRING
            movx  a,@dptr
            cjne  a,#0DH,chngi2
            sjmp  chngi6                ; jmp to get next address

;if it is a '.' then abort this command
chngi2:     cjne  a,#'.',chngi3
            sjmp  done_chngi
;set up basic pointer to the address of the string we inputted
chngi3:     mov   8,#LOW(IN_STRING)
            mov   0ah,#HIGH(IN_STRING)
                                        ;get the number from the string
            mov   a,#OP_EVAL            ; evaluate expression
            lcall BASIC                 ; value is put on arg stack


            mov   a,#OP_FPINT           ; convert number to int
            lcall BASIC                 ; in r3,r1

            mov   a,r1                  ; save low byte in acc, discard high
                                        ; get the address back and save number
                                        ; in memory
            cjne  r3,#0,chngi_err       ; if data > 255 then command error
            mov   r1,LBEG_ADDR          ; set up data pointer
            mov   @r1,a                 ; save data
chngi6:     inc   LBEG_ADDR             ; increment the address


chngi9:
            ljmp  chngi7                ; go get next data byte

; done with chngi
done_chngi:
            clr   a
            ljmp  BASIC
;
chngi_err:  ljmp  syntax_error          ; have a syntax error
;
; (FX)
; fill external memory with data from beg to end address
do_fillx:
            jb    47,fillx1             ; see if basic is in command mode
            ljmp  cmd_error             ; disp only works in command mode
                                        ; if bit 47 is set ok, else return

fillx1:     mov   a,#OP_EVAL            ; evaluate 1st expression (begin addr)
            lcall BASIC                 ; value is put on arg stack

            mov   a,#OP_ADVGCHAR        ; get char after expr and advance
            lcall BASIC                 ; text pointer

            cjne  a,#',',fillx_err      ; if not a comma, an error and return

            mov   a,#OP_EVAL            ; evaluate 2nd expr (end addr)
            lcall BASIC

            mov   a,#OP_ADVGCHAR        ; get char after expr and advance
            lcall BASIC                 ; text pointer

            cjne  a,#',',fillx_err      ; if not a comma, an error and return

            mov   a,#OP_EVAL            ; evaluate 3nd expr (data)
            lcall BASIC

            mov   a,#OP_FPINT           ; convert data to int, returned
            lcall BASIC                 ; in r3,r1

            mov   TEMP,r1               ; save data in TEMP, discard high byte
            cjne  r3,#0,fillx_err       ; if data > 255 then command error

            mov   a,#OP_FPINT           ; convert end addr to int, returned
            lcall BASIC                 ; in r3,r1

            mov   LEND_ADDR,r1          ; save low ending address
            mov   HEND_ADDR,r3          ; save high ending address

            mov   a,#OP_FPINT           ; convert beg addr to int
            lcall BASIC

            mov   LBEG_ADDR,r1          ; save low beg address
            mov   HBEG_ADDR,r3          ; save high beg address

; check address to see if done
fillx3:
            clr   c
            mov   a,LEND_ADDR
            subb  a,LBEG_ADDR
            mov   BYTE_COUNT,a          ;save low subtraction here in BYTE_COUNT
            mov   a,HEND_ADDR
            subb  A,HBEG_ADDR
            jnc   fillx4                ; if within address range go do it
            ljmp  done_fillx            ; else we are done

fillx4:
            mov   dpl,LBEG_ADDR         ; set up data pointer
            mov   dph,HBEG_ADDR
            mov   a,TEMP                ; get the data and save it to memory
            movx  @dptr,a
            inc   dptr                  ; increment data ptr to next byte
            mov   LBEG_ADDR,dpl         ; save new address
            mov   HBEG_ADDR,dph

            clr   a                     ; see if BEG_ADDR = 0, if so we're done
            cjne  a,LBEG_ADDR,fillx10
            cjne  a,HBEG_ADDR,fillx10
            sjmp  done_fillx

fillx10:    ljmp  fillx3

; done with fillx
done_fillx:
            clr   a
            ljmp  BASIC

fillx_err:  ljmp  syntax_error

;
; (FI)
; fill internal memory with data from beg to end address
do_filli:
            jb    47,filli1             ; see if basic is in command mode
            ljmp  cmd_error             ; disp only works in command mode
                                        ; if bit 47 is set ok, else return

filli1:     mov   a,#OP_EVAL            ; evaluate 1st expression (begin addr)
            lcall BASIC                 ; value is put on arg stack

            mov   a,#OP_ADVGCHAR        ; get char after expr and advance
            lcall BASIC                 ; text pointer

            cjne  a,#',',filli_err      ; if not a comma, an error and return

            mov   a,#OP_EVAL            ; evaluate 2nd expr (end addr)
            lcall BASIC

            mov   a,#OP_ADVGCHAR        ; get char after expr and advance
            lcall BASIC                 ; text pointer

            cjne  a,#',',filli_err      ; if not a comma, an error and return

            mov   a,#OP_EVAL            ; evaluate 3nd expr (data)
            lcall BASIC

            mov   a,#OP_FPINT           ; convert data to int, returned
            lcall BASIC                 ; in r3,r1

            mov   TEMP,r1               ; save data in TEMP, discard high byte
            cjne  r3,#0,filli_err       ; if data > 255 then command error

            mov   a,#OP_FPINT           ; convert end addr to int, returned
            lcall BASIC                 ; in r3,r1

            mov   LEND_ADDR,r1          ; save low ending address
            mov   HEND_ADDR,r3          ; save high ending address
            cjne  r3,#0,filli_err       ; if addr > 255 then command error

            mov   a,#OP_FPINT           ; convert beg addr to int
            lcall BASIC

            mov   LBEG_ADDR,r1          ; save low beg address
            mov   HBEG_ADDR,r3          ; save high beg address
            cjne  r3,#0,filli_err       ; if addr > 255 then command error

; check address to see if done
filli3:
            clr   c
            mov   a,LEND_ADDR
            subb  a,LBEG_ADDR
            mov   BYTE_COUNT,a          ;save low subtraction here in BYTE_COUNT
            mov   a,HEND_ADDR
            subb  A,HBEG_ADDR
            jnc   filli4                ; if within address range go do it
            ljmp  done_filli            ; else we are done

filli4:
            mov   r1,LBEG_ADDR          ; set up pointer
            mov   a,TEMP                ; get the data and save it to memory
            mov   @r1,a
            inc   LBEG_ADDR             ; increment ptr to next byte

            clr   a                     ; see if BEG_ADDR = 0, if so we're done
            cjne  a,LBEG_ADDR,filli10
            sjmp  done_filli

filli10:    ljmp  filli3

; done with filli
done_filli:
            clr   a
            ljmp  BASIC

filli_err:  ljmp  syntax_error


; (VER)
; display version of this code
do_ver:
            jb    47,ver1               ; see if basic is in command mode
            ljmp  cmd_error             ; disp only works in command mode
                                        ; if bit 47 is set ok, else return
ver1:
            mov   a,#OP_CR_LFD          ; output carriage return line feed
            lcall BASIC
            setb  52                    ; so basic knows message in pgm mem
            mov   r3,#HIGH version      ; missing comma error
            mov   r1,#LOW version
            mov   a,#OP_OUTSTR
            lcall BASIC                 ; output message
            mov   a,#OP_CR_LFD          ; output carriage return line feed
            lcall BASIC
            clr   a
            ljmp  BASIC                 ; exit, done


;convert the lower nibble of acc to ascii and output it
ascii_out:
            anl   a,#0FH                ; mask out top bits
            add   a,#30H                ; convert to ascii
            mov   r5,a                  ; save ascii value
            subb  a,#3AH                ; is it greater than '9'?
            jc    ascii2                ; no don't need to add 7
            mov   a,r5                  ; value is A to F
            add   a,#07H                ; add 7
            mov   r5,a
ascii2:
            mov   a,#OP_OUTCHAR
            lcall BASIC                 ; output ascii value
            ret                         ; return


; error and handling stuff
cmd_error:
            mov   r3,#HIGH cmd_msg      ; command message error
            mov   r1,#LOW cmd_msg
            sjmp  error_handle
syntax_error:
            mov   r3,#HIGH syntax_msg   ; bad syntax error
            mov   r1,#LOW syntax_msg
            sjmp  error_handle

error_handle:
            mov   a,#OP_CR_LFD          ; output carriage return line feed
            lcall BASIC
            setb  52                    ; so basic knows message in pgm mem
            mov   a,#OP_OUTSTR
            lcall BASIC                 ; output message
            clr   a
            ljmp  BASIC                 ; exit, done

;cksum_error, print message and return
cksum_error:
            setb  52
            mov   r3,#HIGH cksum_msg    ; checksum message error
            mov   r1,#LOW cksum_msg
            mov   a,#OP_OUTSTR
            lcall BASIC
            mov   a,#OP_CR_LFD          ; output carriage return line feed
            lcall BASIC
            ret


            end
