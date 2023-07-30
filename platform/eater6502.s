; Copyright (C) 2023 Southern Storm Software, Pty Ltd.
;
; Permission is hereby granted, free of charge, to any person obtaining a
; copy of this software and associated documentation files (the "Software"),
; to deal in the Software without restriction, including without limitation
; the rights to use, copy, modify, merge, publish, distribute, sublicense,
; and/or sell copies of the Software, and to permit persons to whom the
; Software is furnished to do so, subject to the following conditions:
;
; The above copyright notice and this permission notice shall be included
; in all copies or substantial portions of the Software.
;
; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
; OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
; FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
; AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
; LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
; FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
; DEALINGS IN THE SOFTWARE.

;
; Platform support for Ben Eater's 6502 Breadboard Computer.
; https://eater.net/6502
;
; Characters are written to the 6551 ACIA serial interface at 19200 bps.
;
; The entire code is placed into ROM to allow getting precise timings
; without any interrupt sources or other distractions.
;

;
; Output data is placed here for inspection.
;
outbuf          .equ    $300

;
; I/O ports.
;
PORTA           .equ    $6001
DDRA            .equ    $6003
ACIA_DATA       .equ    $5000
ACIA_STATUS     .equ    $5001
ACIA_CMD        .equ    $5002
ACIA_CTRL       .equ    $5003

;
; Initialize the platform routines.
;
platform_init:
    cld
    cli
;
    lda     #%10000000          ; Configure PA7 for output.
    sta     DDRA
    lda     #0                  ; Set it initially low.
    sta     PORTA
;
    lda     ACIA_STATUS         ; Clear any reported errors on the ACIA.
    lda     ACIA_DATA           ; Empty the receive buffer.
    lda     #0
    sta     ACIA_STATUS         ; Reset the ACIA.
    lda     #%00011111          ; Set up 19200-N-8-1 communications.
    sta     ACIA_CTRL
    lda     #%00001011          ; Enable TIC1/DTR; disable receive interrupts.
    sta     ACIA_CMD
;
    rts

;
; Print an ASCII character to the system console.
;
print_char:
    cmp     #$0a                ; Is this '\n'?
    beq     print_crlf
print_char_raw:
    pha
    phx
    sta     ACIA_DATA           ; Write the character to the serial port.
    ldx     #$70                ; Wait for the TX delay.
print_char_delay:
    dex
    bne     print_char_delay
    plx
    pla
    rts
print_crlf:
    lda     #$0d
    jsr     print_char_raw
    lda     #$0a
    jmp     print_char_raw

;
; Raise the PA7 pin for the beginning of a measurement.  An oscilloscope
; connected to the pin can be used to perform timings.
;
measure_start:
    lda     #%10000000
    sta     PORTA
    rts

;
; Lower the PA7 pin for the end of a measurement.
;
measure_end:
    lda     #0
    sta     PORTA
    rts

;
; Dummy IRQ and NMI interrupt handler.
;
irq:
    rti

;
; Set up the reset and interrupt vectors.
;
    .org    $FFFA
    .dw     irq
    .dw     main
    .dw     irq
