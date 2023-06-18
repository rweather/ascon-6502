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
; Addresses of the words of the state, plus temporary scratch registers.
; These should be in zero page locations but can be elsewhere.  There will
; be a performance cost to put them elsewhere.  The eight bytes of each word
; must be contiguous but the separate words can go anywhere.
;
ascon_x0        .equ    $D8
ascon_x1        .equ    $E0
ascon_x2        .equ    $E8
ascon_x3        .equ    $F0
ascon_x4        .equ    $F8
ascon_temp      .equ    $10
ascon_temp2     .equ    $18
ascon_t0        .equ    ascon_temp
ascon_t1        .equ    ascon_temp+1
ascon_t2        .equ    ascon_temp+2
ascon_t3        .equ    ascon_temp+3
ascon_t4        .equ    ascon_temp+4

;
; Parameters to higher-level functions.  Must be in the zero page.
;
ascon_ptr       .equ    $08     ; 2 bytes for a pointer.

;
; Helper macros for rotating 64-bit words.
;
    .macro  ascon_rol_1
    lda     \2+7
    asl
    sta     \1+7
    lda     \2+6
    rol
    sta     \1+6
    lda     \2+5
    rol
    sta     \1+5
    lda     \2+4
    rol
    sta     \1+4
    lda     \2+3
    rol
    sta     \1+3
    lda     \2+2
    rol
    sta     \1+2
    lda     \2+1
    rol
    sta     \1+1
    lda     \2
    rol
    sta     \1
    lda     \1+7
    adc     #0
    sta     \1+7
    .endm
    .macro  ascon_rol_1_inplace
    asl     \1+7
    rol     \1+6
    rol     \1+5
    rol     \1+4
    rol     \1+3
    rol     \1+2
    rol     \1+1
    rol     \1
    lda     \1+7
    adc     #0
    sta     \1+7
    .endm
    .macro  ascon_rol_2
    ascon_rol_1 \1, \2
    ascon_rol_1_inplace \1
    .endm
    .macro  ascon_rol_4
    ascon_rol_1 \1, \2
    ascon_rol_1_inplace \1
    ascon_rol_1_inplace \1
    ascon_rol_1_inplace \1
    .endm
    .macro  ascon_ror_1
    lda     \2
    lsr
    sta     \1
    lda     \2+1
    ror
    sta     \1+1
    lda     \2+2
    ror
    sta     \1+2
    lda     \2+3
    ror
    sta     \1+3
    lda     \2+4
    ror
    sta     \1+4
    lda     \2+5
    ror
    sta     \1+5
    lda     \2+6
    ror
    sta     \1+6
    lda     \2+7
    ror
    sta     \1+7
    lda     #0
    ror
    eor     \1
    sta     \1
    .endm

;
; Helper macro for XOR'ing rotated 64-bit words in the diffusion layer.
;
    .macro  ascon_rol_xor
    lda     \1+7
    eor     ascon_temp+(((56+\2)/8)%8)
    eor     ascon_temp2+(((56+\3)/8)%8)
    sta     \1+7
    lda     \1+6
    eor     ascon_temp+(((48+\2)/8)%8)
    eor     ascon_temp2+(((48+\3)/8)%8)
    sta     \1+6
    lda     \1+5
    eor     ascon_temp+(((40+\2)/8)%8)
    eor     ascon_temp2+(((40+\3)/8)%8)
    sta     \1+5
    lda     \1+4
    eor     ascon_temp+(((32+\2)/8)%8)
    eor     ascon_temp2+(((32+\3)/8)%8)
    sta     \1+4
    lda     \1+3
    eor     ascon_temp+(((24+\2)/8)%8)
    eor     ascon_temp2+(((24+\3)/8)%8)
    sta     \1+3
    lda     \1+2
    eor     ascon_temp+(((16+\2)/8)%8)
    eor     ascon_temp2+(((16+\3)/8)%8)
    sta     \1+2
    lda     \1+1
    eor     ascon_temp+(((8+\2)/8)%8)
    eor     ascon_temp2+(((8+\3)/8)%8)
    sta     \1+1
    lda     \1
    eor     ascon_temp+(\2/8)
    eor     ascon_temp2+(\3/8)
    sta     \1
    .endm

;
; ascon_permute - Permutes the ASCON state.
;
; On entry, the state should be in "ascon_x0", "ascon_x1", etc in RAM and
; Y should be the number of the first round (0-11).
;
; On exit, X will be 0 and Y will be 12.  A will be destroyed.
; The C, V, Z, and N flags in the status register will also be destroyed.
;
ascon_permute_done:
    rts
ascon_permute:
    cpy     #12
    bge     ascon_permute_done

    ; Add the round constant to the state in the low byte of x2.
    lda     ascon_rc,y
    eor     ascon_x2+7
    sta     ascon_x2+7

    ; Substitution layer, done byte by byte starting with the low byte.
    ; X is offset by 1 to make the end check for this loop easier.
    ldx     #8
ascon_substitute:
    ; x0 ^= x4; x4 ^= x3; x2 ^= x1;
    lda     ascon_x0-1,x
    eor     ascon_x4-1,x
    sta     ascon_x0-1,x
    lda     ascon_x4-1,x
    eor     ascon_x3-1,x
    sta     ascon_x4-1,x
    lda     ascon_x2-1,x
    eor     ascon_x1-1,x
    sta     ascon_x2-1,x
    ; x2 is left in A for the next step.

    ; t0 = ~x0; t1 = ~x1; t2 = ~x2; t3 = ~x3; t4 = ~x4;
    ; t0 &= x1; t1 &= x2; t2 &= x3; t3 &= x4; t4 &= x0;
    eor     #$ff
    and     ascon_x3-1,x
    sta     ascon_t2
    lda     ascon_x0-1,x
    eor     #$ff
    and     ascon_x1-1,x
    sta     ascon_t0
    lda     ascon_x1-1,x
    eor     #$ff
    and     ascon_x2-1,x
    sta     ascon_t1
    lda     ascon_x3-1,x
    eor     #$ff
    and     ascon_x4-1,x
    sta     ascon_t3
    lda     ascon_x4-1,x
    eor     #$ff
    and     ascon_x0-1,x
    ; t4 is left in A for the next step.

    ; x0 ^= t1; x1 ^= t2; x2 ^= t3; x3 ^= t4; x4 ^= t0;
    eor     ascon_x3-1,x
    sta     ascon_x3-1,x
    lda     ascon_x0-1,x
    eor     ascon_t1
    sta     ascon_x0-1,x
    lda     ascon_x1-1,x
    eor     ascon_t2
    sta     ascon_x1-1,x
    lda     ascon_x2-1,x
    eor     ascon_t3
    sta     ascon_x2-1,x
    lda     ascon_x4-1,x
    eor     ascon_t0
    sta     ascon_x4-1,x

    ; x1 ^= x0; x0 ^= x4; x3 ^= x2; x2 = ~x2;
    lda     ascon_x1-1,x
    eor     ascon_x0-1,x
    sta     ascon_x1-1,x
    lda     ascon_x0-1,x
    eor     ascon_x4-1,x
    sta     ascon_x0-1,x
    lda     ascon_x3-1,x
    eor     ascon_x2-1,x
    sta     ascon_x3-1,x
    lda     ascon_x2-1,x
    eor     #$ff
    sta     ascon_x2-1,x

    ; Go back for the next byte of the substitution layer.
    ; If some of the state is outside the zero page, then we
    ; need to use a long jump back to the start of the loop.
    dex
    .if     (ascon_x0 > $FF || ascon_x1 > $FF || ascon_x2 > $FF || ascon_x3 > $FF || ascon_x4 > $FF || ascon_temp > $FF)
    beq     ascon_diffuse
    jmp     ascon_substitute
    .else
    bne     ascon_substitute
    .endif

    ; Linear diffusion layer.  The traditional formulation uses
    ; right rotations of the words.  It is actually quicker to do
    ; left rotations in the 6502 microprocessor in most cases.
ascon_diffuse:
    ; x0 ^= ror(x0, 19) ^ ror(x0, 28)
    ; =>
    ; x0 ^= rol(x0, 45) ^ rol(x0, 36)
    ; =>
    ; x0 ^= rol(rol(x0, 5), 40) ^ rol(rol(x0, 4), 32)
    ascon_rol_4 ascon_temp2, ascon_x0
    ascon_rol_1 ascon_temp, ascon_temp2
    ascon_rol_xor ascon_x0, 40, 32

    ; x1 ^= ror(x1, 61) ^ ror(x1, 39)
    ; =>
    ; x1 ^= rol(x1, 3) ^ rol(x1, 25)
    ; =>
    ; x1 ^= rol(x1, 3) ^ rol(rol(x1, 1), 24)
    ascon_rol_1 ascon_temp2, ascon_x1
    ascon_rol_2 ascon_temp, ascon_temp2
    ascon_rol_xor ascon_x1, 0, 24

    ; x2 ^= ror(x2, 1) ^ ror(x2, 6)
    ; =>
    ; x2 ^= ror(x2, 1) ^ rol(x2, 58)
    ; =>
    ; x2 ^= ror(x2, 1) ^ rol(rol(x2, 2), 56)
    ascon_ror_1 ascon_temp, ascon_x2
    ascon_rol_2 ascon_temp2, ascon_x2
    ascon_rol_xor ascon_x2, 0, 56

    ; x3 ^= ror(x3, 10) ^ ror(x3, 17)
    ; =>
    ; x3 ^= ror(ror(x3, 2), 8) ^ ror(ror(x3, 1), 16)
    ascon_ror_1 ascon_temp2, ascon_x3
    ascon_ror_1 ascon_temp, ascon_temp2
    ascon_rol_xor ascon_x3, 56, 48

    ; x4 ^= ror(x4, 7) ^ ror(x4, 41)
    ; =>
    ; x4 ^= rol(x4, 57) ^ rol(x4, 23)
    ; =>
    ; x4 ^= rol(rol(x4, 1), 56) ^ rol(ror(x4, 1), 24)
    ascon_rol_1 ascon_temp, ascon_x4
    ascon_ror_1 ascon_temp2, ascon_x4
    ascon_rol_xor ascon_x4, 56, 24

    ; Go back for the next round.
    iny
    jmp     ascon_permute

;
; Round constants for the ASCON permutation.
;
ascon_rc:
    .db     $f0
    .db     $e1
    .db     $d2
    .db     $c3
    .db     $b4
    .db     $a5
    .db     $96
    .db     $87
    .db     $78
    .db     $69
    .db     $5a
    .db     $4b

;
; Copies 40 contiguous bytes into the ASCON permutation state.
; The pointer is stored in ascon_ptr and ascon_ptr+1 in the zero page.
;
; A and Y are destroyed.  X is preserved.  N and Z in the status register
; are destroyed.
;
ascon_copy_in:
    .macro ascon_copy_word_in
    lda     (ascon_ptr),y
    sta     \1
    iny
    lda     (ascon_ptr),y
    sta     \1+1
    iny
    lda     (ascon_ptr),y
    sta     \1+2
    iny
    lda     (ascon_ptr),y
    sta     \1+3
    iny
    lda     (ascon_ptr),y
    sta     \1+4
    iny
    lda     (ascon_ptr),y
    sta     \1+5
    iny
    lda     (ascon_ptr),y
    sta     \1+6
    iny
    lda     (ascon_ptr),y
    sta     \1+7
    .endm
    ldy     #0
    ascon_copy_word_in ascon_x0
    iny
    ascon_copy_word_in ascon_x1
    iny
    ascon_copy_word_in ascon_x2
    iny
    ascon_copy_word_in ascon_x3
    iny
    ascon_copy_word_in ascon_x4
    rts

;
; Copies 40 contiguous bytes out of the ASCON permutation state.
; The pointer is stored in ascon_ptr and ascon_ptr+1 in the zero page.
;
; A and Y are destroyed.  X is preserved.  N and Z in the status register
; are destroyed.
;
ascon_copy_out:
    .macro ascon_copy_word_out
    lda     \1
    sta     (ascon_ptr),y
    iny
    lda     \1+1
    sta     (ascon_ptr),y
    iny
    lda     \1+2
    sta     (ascon_ptr),y
    iny
    lda     \1+3
    sta     (ascon_ptr),y
    iny
    lda     \1+4
    sta     (ascon_ptr),y
    iny
    lda     \1+5
    sta     (ascon_ptr),y
    iny
    lda     \1+6
    sta     (ascon_ptr),y
    iny
    lda     \1+7
    sta     (ascon_ptr),y
    .endm
    ldy     #0
    ascon_copy_word_out ascon_x0
    iny
    ascon_copy_word_out ascon_x1
    iny
    ascon_copy_word_out ascon_x2
    iny
    ascon_copy_word_out ascon_x3
    iny
    ascon_copy_word_out ascon_x4
    rts
