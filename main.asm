.include "ATxmega128A1Udef.inc"

.def temp    = r16
.def pat     = r17
.def steps   = r18
.def delayid = r19

.cseg
.org 0x0000
    rjmp RESET


RESET:
    ; Stack pointer
    ldi temp, low(RAMEND)
    sts CPU_SPL, temp
    ldi temp, high(RAMEND)
    sts CPU_SPH, temp

    ; Enable 32 MHz internal oscillator
    ldi temp, 0x02
    sts OSC_CTRL, temp

WAIT_RC32M:
    lds temp, OSC_STATUS
    sbrs temp, 1
    rjmp WAIT_RC32M

    ; Switch system clock to 32 MHz oscillator
    ldi temp, 0xD8
    sts CPU_CCP, temp
    ldi temp, 0x01
    sts CLK_CTRL, temp

    ; PC0-PC3 as outputs
    ldi temp, 0x0F
    sts PORTC_DIRSET, temp

    ; Clear outputs
    clr temp
    sts PORTC_OUT, temp

MAIN:
    ; -----------------------------
    ; 10 ms delay section
    ; -----------------------------
    ldi delayid, 10

    ldi r24, low(250)
    ldi r25, high(250)
    rcall FULL_CW

    ldi r24, low(250)
    ldi r25, high(250)
    rcall FULL_CCW

    ldi r24, low(125)
    ldi r25, high(125)
    rcall HALF_CW

    ldi r24, low(125)
    ldi r25, high(125)
    rcall HALF_CCW

    ; -----------------------------
    ; 5 ms delay section
    ; -----------------------------
    ldi delayid, 5

    ldi r24, low(500)
    ldi r25, high(500)
    rcall FULL_CW

    ldi r24, low(500)
    ldi r25, high(500)
    rcall FULL_CCW

    ldi r24, low(250)
    ldi r25, high(250)
    rcall HALF_CW

    ldi r24, low(250)
    ldi r25, high(250)
    rcall HALF_CCW

    ; -----------------------------
    ; 7.5 ms delay section
    ; approx 10 s per motion routine
    ; -----------------------------
    ldi delayid, 7

    ldi r24, low(333)
    ldi r25, high(333)
    rcall FULL_CW

    ldi r24, low(333)
    ldi r25, high(333)
    rcall FULL_CCW

    ldi r24, low(167)
    ldi r25, high(167)
    rcall HALF_CW

    ldi r24, low(167)
    ldi r25, high(167)
    rcall HALF_CCW

    rjmp MAIN


; =========================================
; FULL STEP CLOCKWISE
; sequence: 0011, 0110, 1100, 1001
; =========================================
FULL_CW:
FULL_CW_LOOP:
    ldi pat, 0x03
    sts PORTC_OUT, pat
    rcall DO_DELAY

    ldi pat, 0x06
    sts PORTC_OUT, pat
    rcall DO_DELAY

    ldi pat, 0x0C
    sts PORTC_OUT, pat
    rcall DO_DELAY

    ldi pat, 0x09
    sts PORTC_OUT, pat
    rcall DO_DELAY

    sbiw r24, 1
    brne FULL_CW_LOOP
    ret


; =========================================
; FULL STEP COUNTERCLOCKWISE
; =========================================
FULL_CCW:
FULL_CCW_LOOP:
    ldi pat, 0x09
    sts PORTC_OUT, pat
    rcall DO_DELAY

    ldi pat, 0x0C
    sts PORTC_OUT, pat
    rcall DO_DELAY

    ldi pat, 0x06
    sts PORTC_OUT, pat
    rcall DO_DELAY

    ldi pat, 0x03
    sts PORTC_OUT, pat
    rcall DO_DELAY

    sbiw r24, 1
    brne FULL_CCW_LOOP
    ret


; =========================================
; HALF STEP CLOCKWISE
; sequence: 0001,0011,0010,0110,0100,1100,1000,1001
; =========================================
HALF_CW:
HALF_CW_LOOP:
    ldi pat, 0x01
    sts PORTC_OUT, pat
    rcall DO_DELAY

    ldi pat, 0x03
    sts PORTC_OUT, pat
    rcall DO_DELAY

    ldi pat, 0x02
    sts PORTC_OUT, pat
    rcall DO_DELAY

    ldi pat, 0x06
    sts PORTC_OUT, pat
    rcall DO_DELAY

    ldi pat, 0x04
    sts PORTC_OUT, pat
    rcall DO_DELAY

    ldi pat, 0x0C
    sts PORTC_OUT, pat
    rcall DO_DELAY

    ldi pat, 0x08
    sts PORTC_OUT, pat
    rcall DO_DELAY

    ldi pat, 0x09
    sts PORTC_OUT, pat
    rcall DO_DELAY

    sbiw r24, 1
    brne HALF_CW_LOOP
    ret


; =========================================
; HALF STEP COUNTERCLOCKWISE
; =========================================
HALF_CCW:
HALF_CCW_LOOP:
    ldi pat, 0x09
    sts PORTC_OUT, pat
    rcall DO_DELAY

    ldi pat, 0x08
    sts PORTC_OUT, pat
    rcall DO_DELAY

    ldi pat, 0x0C
    sts PORTC_OUT, pat
    rcall DO_DELAY

    ldi pat, 0x04
    sts PORTC_OUT, pat
    rcall DO_DELAY

    ldi pat, 0x06
    sts PORTC_OUT, pat
    rcall DO_DELAY

    ldi pat, 0x02
    sts PORTC_OUT, pat
    rcall DO_DELAY

    ldi pat, 0x03
    sts PORTC_OUT, pat
    rcall DO_DELAY

    ldi pat, 0x01
    sts PORTC_OUT, pat
    rcall DO_DELAY

    sbiw r24, 1
    brne HALF_CCW_LOOP
    ret


; =========================================
; Delay selector
; delayid = 10, 5, or 7
; =========================================
DO_DELAY:
    cpi delayid, 10
    breq DELAY_10MS

    cpi delayid, 5
    breq DELAY_5MS

    rjmp DELAY_7P5MS


; =========================================
; TCC0 timer delays
; 32 MHz system clock
; TCC0 prescaler = /8
; timer clock = 4 MHz
; =========================================

DELAY_10MS:
    ; 10 ms -> 40000 counts -> PER = 39999 = 0x9C3F
    clr temp
    sts TCC0_CTRLA, temp
    sts TCC0_CTRLB, temp
    sts TCC0_CTRLD, temp

    clr temp
    sts TCC0_CNT, temp
    sts TCC0_CNT+1, temp

    ldi temp, low(39999)
    sts TCC0_PER, temp
    ldi temp, high(39999)
    sts TCC0_PER+1, temp

    ldi temp, 0x01
    sts TCC0_INTFLAGS, temp

    ldi temp, 0x04
    sts TCC0_CTRLA, temp

D10_WAIT:
    lds temp, TCC0_INTFLAGS
    sbrs temp, 0
    rjmp D10_WAIT

    ldi temp, 0x01
    sts TCC0_INTFLAGS, temp
    clr temp
    sts TCC0_CTRLA, temp
    ret


DELAY_5MS:
    ; 5 ms -> 20000 counts -> PER = 19999 = 0x4E1F
    clr temp
    sts TCC0_CTRLA, temp
    sts TCC0_CTRLB, temp
    sts TCC0_CTRLD, temp

    clr temp
    sts TCC0_CNT, temp
    sts TCC0_CNT+1, temp

    ldi temp, low(19999)
    sts TCC0_PER, temp
    ldi temp, high(19999)
    sts TCC0_PER+1, temp

    ldi temp, 0x01
    sts TCC0_INTFLAGS, temp

    ldi temp, 0x04
    sts TCC0_CTRLA, temp

D5_WAIT:
    lds temp, TCC0_INTFLAGS
    sbrs temp, 0
    rjmp D5_WAIT

    ldi temp, 0x01
    sts TCC0_INTFLAGS, temp
    clr temp
    sts TCC0_CTRLA, temp
    ret


DELAY_7P5MS:
    ; 7.5 ms -> 30000 counts -> PER = 29999 = 0x752F
    clr temp
    sts TCC0_CTRLA, temp
    sts TCC0_CTRLB, temp
    sts TCC0_CTRLD, temp

    clr temp
    sts TCC0_CNT, temp
    sts TCC0_CNT+1, temp

    ldi temp, low(29999)
    sts TCC0_PER, temp
    ldi temp, high(29999)
    sts TCC0_PER+1, temp

    ldi temp, 0x01
    sts TCC0_INTFLAGS, temp

    ldi temp, 0x04
    sts TCC0_CTRLA, temp

D75_WAIT:
    lds temp, TCC0_INTFLAGS
    sbrs temp, 0
    rjmp D75_WAIT

    ldi temp, 0x01
    sts TCC0_INTFLAGS, temp
    clr temp
    sts TCC0_CTRLA, temp
    ret