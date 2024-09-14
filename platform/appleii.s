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
; Subroutines in the Apple II ROM for printing characters.
;
RDKEY       .equ    $fd0c       ; Read a key.
CROUT       .equ    $fd8e       ; Output a CRLF.
COUT        .equ    $fded       ; Output a single character in A.

;
; Initialize the platform routines.
;
platform_init:
    rts

;
; Pause after a test before running the next one.
;
platform_pause:
    jsr     CROUT
    ldx     #msg_pause-messages
    jsr     print_string
    jsr     RDKEY
    jmp     CROUT

;
; Print an ASCII character to the system console.
;
print_char:
    cmp     #$0a                ; Is this '\n'?
    beq     print_crlf
    cmp     #$60                ; Older Apple II's don't have lower case.
    bcc     print_char_2
    sbc     #$20                ; Convert to upper case.
print_char_2:
    ora     #$80                ; Apple II uses "high ascii".
    jmp     COUT
print_crlf:
    jmp     CROUT

;
; Raise a pin for the beginning of a measurement.  An oscilloscope
; connected to the pin can be used to perform timings.
;
measure_start:
    rts

;
; Lower a pin for the end of a measurement.
;
measure_end:
    rts

;
; Output data is placed here for inspection.
;
outbuf:
    .ds     256
