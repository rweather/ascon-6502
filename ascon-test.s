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
; Subroutines in ROM for printing characters.  The defaults are entry
; points for Apple II and compatible ROM's.  Modify as necessary
; for other platforms.
;
            .org    $4000
CROUT       .equ    $fd8e       ; Output a CRLF, or 0 to use COUT.
COUT        .equ    $fded       ; Output a single character in A.
HIGH_ASCII  .equ    $80         ; $80 to convert to high ASCII on output.

;
; Output data is placed here for inspection.
;
outbuf      .equ    $300

;
; Test the permutation.
;
ascon_test_permutation:
    ; Test 12 rounds of the permutation.
    ldx     #msg_12_rounds-messages
    jsr     print_string
;
    lda     #<ascon_permutation_input
    sta     ascon_ptr
    lda     #>ascon_permutation_input
    sta     ascon_ptr+1
;
    ldx     #msg_input-messages
    jsr     print_string
    ldx     #40
    jsr     print_hex
;
    jsr     ascon_copy_in
    ldy     #0
    jsr     ascon_permute
;
    lda     #<outbuf
    sta     ascon_ptr
    lda     #>outbuf
    sta     ascon_ptr+1
    jsr     ascon_copy_out
;
    ldx     #msg_output-messages
    jsr     print_string
    ldx     #40
    jsr     print_hex
;
    lda     #<ascon_permutation_output_12
    sta     ascon_ptr
    lda     #>ascon_permutation_output_12
    sta     ascon_ptr+1
    ldx     #msg_expected-messages
    jsr     print_string
    ldx     #40
    jsr     print_hex

    ; Test 8 rounds of the permutation.
    ldx     #msg_8_rounds-messages
    jsr     print_string
;
    lda     #<ascon_permutation_input
    sta     ascon_ptr
    lda     #>ascon_permutation_input
    sta     ascon_ptr+1
;
    ldx     #msg_input-messages
    jsr     print_string
    ldx     #40
    jsr     print_hex
;
    jsr     ascon_copy_in
    ldy     #4
    jsr     ascon_permute
;
    lda     #<(outbuf+64)
    sta     ascon_ptr
    lda     #>(outbuf+64)
    sta     ascon_ptr+1
    jsr     ascon_copy_out
;
    ldx     #msg_output-messages
    jsr     print_string
    ldx     #40
    jsr     print_hex
;
    lda     #<ascon_permutation_output_8
    sta     ascon_ptr
    lda     #>ascon_permutation_output_8
    sta     ascon_ptr+1
    ldx     #msg_expected-messages
    jsr     print_string
    ldx     #40
    jsr     print_hex
    rts

;
; Data for the permutation test.
;
ascon_permutation_input:
    .db     $00, $01, $02, $03, $04, $05, $06, $07
    .db     $08, $09, $0a, $0b, $0c, $0d, $0e, $0f
    .db     $10, $11, $12, $13, $14, $15, $16, $17
    .db     $18, $19, $1a, $1b, $1c, $1d, $1e, $1f
    .db     $20, $21, $22, $23, $24, $25, $26, $27
ascon_permutation_output_12:
    .db     $06, $05, $87, $e2, $d4, $89, $dd, $43
    .db     $1c, $c2, $b1, $7b, $0e, $3c, $17, $64
    .db     $95, $73, $42, $53, $18, $44, $a6, $74
    .db     $96, $b1, $71, $75, $b4, $cb, $68, $63
    .db     $29, $b5, $12, $d6, $27, $d9, $06, $e5
ascon_permutation_output_8:
    .db     $83, $0d, $26, $0d, $33, $5f, $3b, $ed
    .db     $da, $0b, $ba, $91, $7b, $cf, $ca, $d7
    .db     $dd, $0d, $88, $e7, $dc, $b5, $ec, $d0
    .db     $89, $2a, $02, $15, $1f, $95, $94, $6e
    .db     $3a, $69, $cb, $3c, $f9, $82, $f6, $f7

;
; Print a string.  Offset of the string in "messages" is in X.
;
print_string:
    lda     messages,x
    beq     print_done
    cmp     #$0d
    bne     print_char
    .if (CROUT <> 0)
    jsr     CROUT
    .else
    lda     #($0d + HIGH_ASCII)
    jsr     COUT
    lda     #($0a + HIGH_ASCII)
    jsr     COUT
    .endif
    inx
    jmp     print_string
print_char:
    .if (HIGH_ASCII <> 0)
    ora     #HIGH_ASCII
    .endif
    jsr     COUT
    inx
    jmp     print_string
print_done:
    rts

;
; Print a buffer of hexadecimal bytes.  Pointer is in "ascon_ptr".
;
print_hex:
    ldy     #0
print_next_byte:
    lda     #($20 + HIGH_ASCII)
    jsr     COUT
    lda     (ascon_ptr),y
    jsr     print_hex_byte
    iny
    dex
    bne     print_next_byte
    .if (CROUT <> 0)
    jsr     CROUT
    .else
    lda     #($0d + HIGH_ASCII)
    jsr     COUT
    lda     #($0a + HIGH_ASCII)
    jsr     COUT
    .endif
    rts
print_hex_byte:
    pha
    lsr
    lsr
    lsr
    lsr
    jsr     print_hex_nibble
    pla
    and     #$0f
print_hex_nibble:
    cmp     #10
    blt     print_hex_1
    clc
    adc     #7
print_hex_1:
    adc     #($30 + HIGH_ASCII)
    jmp     COUT

messages:
msg_12_rounds:
    .db     $0d
    .asc    "12 permutation rounds:"
    .db     $0d, 0
msg_8_rounds:
    .db     $0d
    .asc    "8 permutation rounds:"
    .db     $0d, 0
msg_input:
    .asc    "input    ="
    .db     0
msg_output:
    .asc    "output   ="
    .db     0
msg_expected:
    .asc    "expected ="
    .db     0

;
; Include the implementation of ASCON.
;
    .include "ascon-6502.s"
