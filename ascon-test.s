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
; Set the origin for the code.
;
    .ifdef EATER6502
        .org    $8000
    .else
        .ifndef O65
            .org    $2000
        .endif
    .endif

;
; Main entry point to the test harness.
;
main:
    jsr     platform_init
    jsr     ascon_test_permutation
    jsr     ascon_test_hash
    jsr     ascon_test_xof
    jsr     ascon_test_encryption
    jsr     ascon_test_decryption
    rts

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
    jsr     measure_start
    jsr     ascon_permute
    jsr     measure_end
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
    lda     #<(outbuf+40)
    sta     ascon_ptr
    lda     #>(outbuf+40)
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

ascon_test_bytes_to_hash .equ 31

;
; Test ASCON-HASH.
;
ascon_test_hash:
    ldx     #msg_hash-messages
    jsr     print_string
;
    jsr     ascon_hash_init
;
    lda     #<ascon_hash_input
    sta     ascon_ptr
    lda     #>ascon_hash_input
    sta     ascon_ptr+1
;
    ldx     #msg_input-messages
    jsr     print_string
    ldx     #ascon_test_bytes_to_hash
    jsr     print_hex
;
; Break the input up into two blocks to test incremental updates.
;
    lda     #13
    jsr     ascon_hash_update
    lda     #<(ascon_hash_input+13)
    sta     ascon_ptr
    lda     #>(ascon_hash_input+13)
    sta     ascon_ptr+1
    lda     #(ascon_test_bytes_to_hash-13)
    jsr     ascon_hash_update
;
    lda     #<(outbuf+80)
    sta     ascon_ptr
    lda     #>(outbuf+80)
    sta     ascon_ptr+1
    jsr     ascon_hash_finalize
;
    ldx     #msg_output-messages
    jsr     print_string
    ldx     #32
    jsr     print_hex
;
    lda     #<ascon_hash_output
    sta     ascon_ptr
    lda     #>ascon_hash_output
    sta     ascon_ptr+1
    ldx     #msg_expected-messages
    jsr     print_string
    ldx     #32
    jsr     print_hex
;
    rts

;
; Test ASCON-XOF.
;
ascon_test_xof:
    ldx     #msg_xof-messages
    jsr     print_string
;
    jsr     ascon_xof_init
;
    lda     #<ascon_hash_input
    sta     ascon_ptr
    lda     #>ascon_hash_input
    sta     ascon_ptr+1
;
    ldx     #msg_input-messages
    jsr     print_string
    ldx     #ascon_test_bytes_to_hash
    jsr     print_hex
;
; Break the input up into two blocks to test incremental updates.
;
    lda     #13
    jsr     ascon_xof_absorb
    lda     #<(ascon_hash_input+13)
    sta     ascon_ptr
    lda     #>(ascon_hash_input+13)
    sta     ascon_ptr+1
    lda     #(ascon_test_bytes_to_hash-13)
    jsr     ascon_xof_absorb
;
    lda     #<(outbuf+128)
    sta     ascon_ptr
    lda     #>(outbuf+128)
    sta     ascon_ptr+1
    lda     #32
    jsr     ascon_xof_squeeze
;
    ldx     #msg_output-messages
    jsr     print_string
    ldx     #32
    jsr     print_hex
;
    lda     #<ascon_xof_output
    sta     ascon_ptr
    lda     #>ascon_xof_output
    sta     ascon_ptr+1
    ldx     #msg_expected-messages
    jsr     print_string
    ldx     #32
    jsr     print_hex
;
    rts

;
; Test ASCON-128 encryption.
;
ascon_test_encryption:
    ldx     #msg_encrypt_128-messages
    jsr     print_string
;
    ldx     #msg_key-messages
    jsr     print_string
    lda     #<ascon_128_key_input
    sta     ascon_ptr
    lda     #>ascon_128_key_input
    sta     ascon_ptr+1
    ldx     #16
    jsr     print_hex
;
    ldx     #msg_nonce-messages
    jsr     print_string
    lda     #<ascon_128_nonce_input
    sta     ascon_ptr
    lda     #>ascon_128_nonce_input
    sta     ascon_ptr+1
    ldx     #16
    jsr     print_hex
;
    ldx     #msg_ad-messages
    jsr     print_string
    lda     #<ascon_128_ad_input
    sta     ascon_ptr
    lda     #>ascon_128_ad_input
    sta     ascon_ptr+1
    ldx     #ascon_128_ad_input_end-ascon_128_ad_input
    jsr     print_hex
;
    ldx     #msg_pt-messages
    jsr     print_string
    lda     #<ascon_128_plaintext_input
    sta     ascon_ptr
    lda     #>ascon_128_plaintext_input
    sta     ascon_ptr+1
    ldx     #ascon_128_plaintext_input_end-ascon_128_plaintext_input
    jsr     print_hex
;
    lda     #<ascon_128_plaintext_input
    sta     ascon_ptr
    lda     #>ascon_128_plaintext_input
    sta     ascon_ptr+1
    ldy     #0
    ldx     #ascon_128_plaintext_input_end-ascon_128_plaintext_input
    jsr     ascon_test_copy
;
    lda     #<ascon_128_key_input
    sta     ascon_key
    lda     #>ascon_128_key_input
    sta     ascon_key+1
    lda     #<outbuf
    sta     ascon_ptr
    lda     #>outbuf
    sta     ascon_ptr+1
    lda     #ascon_128_ad_input_end-ascon_128_ad_input
    ldx     #ascon_128_plaintext_input_end-ascon_128_plaintext_input
    jsr     ascon_128_encrypt
;
    ldx     #msg_output-messages
    jsr     print_string
    lda     #<outbuf
    sta     ascon_ptr
    lda     #>outbuf
    sta     ascon_ptr+1
    ldx     #ascon_128_ciphertext_output_end-ascon_128_ciphertext_output
    jsr     print_hex
;
    ldx     #msg_expected-messages
    jsr     print_string
    lda     #<ascon_128_ciphertext_output
    sta     ascon_ptr
    lda     #>ascon_128_ciphertext_output
    sta     ascon_ptr+1
    ldx     #ascon_128_ciphertext_output_end-ascon_128_ciphertext_output
    jsr     print_hex
;
    rts

;
; Test ASCON-128 decryption.
;
ascon_test_decryption:
    ldx     #msg_decrypt_128-messages
    jsr     print_string
;
    ldx     #msg_key-messages
    jsr     print_string
    lda     #<ascon_128_key_input
    sta     ascon_ptr
    lda     #>ascon_128_key_input
    sta     ascon_ptr+1
    ldx     #16
    jsr     print_hex
;
    ldx     #msg_nonce-messages
    jsr     print_string
    lda     #<ascon_128_nonce_input
    sta     ascon_ptr
    lda     #>ascon_128_nonce_input
    sta     ascon_ptr+1
    ldx     #16
    jsr     print_hex
;
    ldx     #msg_ad-messages
    jsr     print_string
    lda     #<ascon_128_ad_input
    sta     ascon_ptr
    lda     #>ascon_128_ad_input
    sta     ascon_ptr+1
    ldx     #ascon_128_ad_input_end-ascon_128_ad_input
    jsr     print_hex
;
    ldx     #msg_ct-messages
    jsr     print_string
    lda     #<ascon_128_ciphertext_output
    sta     ascon_ptr
    lda     #>ascon_128_ciphertext_output
    sta     ascon_ptr+1
    ldx     #ascon_128_ciphertext_output_end-ascon_128_ciphertext_output
    jsr     print_hex
;
    lda     #<ascon_128_ciphertext_output
    sta     ascon_ptr
    lda     #>ascon_128_ciphertext_output
    sta     ascon_ptr+1
    ldy     #0
    ldx     #ascon_128_ciphertext_output_end-ascon_128_ciphertext_output
    jsr     ascon_test_copy
;
    lda     #<ascon_128_key_input
    sta     ascon_key
    lda     #>ascon_128_key_input
    sta     ascon_key+1
    lda     #<outbuf
    sta     ascon_ptr
    lda     #>outbuf
    sta     ascon_ptr+1
    lda     #ascon_128_ad_input_end-ascon_128_ad_input
    ldx     #ascon_128_plaintext_input_end-ascon_128_plaintext_input
    jsr     ascon_128_decrypt
;
    ldx     #msg_output-messages
    jsr     print_string
    lda     #<outbuf
    sta     ascon_ptr
    lda     #>outbuf
    sta     ascon_ptr+1
    ldx     #ascon_128_plaintext_input_end-ascon_128_plaintext_input
    jsr     print_hex
;
    ldx     #msg_expected-messages
    jsr     print_string
    lda     #<ascon_128_plaintext_input
    sta     ascon_ptr
    lda     #>ascon_128_plaintext_input
    sta     ascon_ptr+1
    ldx     #ascon_128_plaintext_input_end-ascon_128_plaintext_input
    jsr     print_hex
;
    rts

ascon_test_copy:
    lda     (ascon_ptr),y
    sta     outbuf,y
    iny
    dex
    bne     ascon_test_copy
    rts

;
; Data for the various test cases.
;
ascon_hash_input:
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
ascon_hash_output:
    .db     $2C, $B1, $46, $AE, $BB, $B6, $58, $5B
    .db     $11, $BF, $1A, $37, $1B, $AA, $6E, $3E
    .db     $55, $10, $8C, $69, $B0, $83, $4F, $26
    .db     $9F, $66, $2C, $59, $BC, $AA, $57, $00
ascon_xof_output:
    .db     $9E, $52, $42, $26, $D3, $8B, $DC, $DB
    .db     $3E, $57, $6C, $2A, $98, $21, $85, $D3
    .db     $A0, $21, $1D, $51, $98, $48, $A9, $38
    .db     $E8, $35, $2A, $C9, $74, $98, $58, $1D
ascon_128_key_input:
    .db     $00, $01, $02, $03, $04, $05, $06, $07
    .db     $08, $09, $0a, $0b, $0c, $0d, $0e, $0f
ascon_128_nonce_input:  ; Must come after the key.
    .db     $00, $01, $02, $03, $04, $05, $06, $07
    .db     $08, $09, $0a, $0b, $0c, $0d, $0e, $0f
ascon_128_ad_input:     ; Must come after the nonce.
    .db     $00, $01, $02, $03, $04, $05, $06, $07
    .db     $08, $09, $0a
ascon_128_ad_input_end:
ascon_128_plaintext_input:
    .db     $00, $01, $02, $03, $04, $05, $06, $07
    .db     $08, $09, $0a, $0b, $0c, $0d, $0e, $0f
    .db     $10, $11, $12, $13, $14, $15, $16
ascon_128_plaintext_input_end:
ascon_128_ciphertext_output: ; Must come after the plaintext.
    .db     $76, $80, $7B, $64, $48, $89, $6C, $E5
    .db     $88, $42, $CB, $4A, $ED, $6C, $41, $04
    .db     $1D, $6D, $EC, $3B, $3A, $0D, $D6, $99
    .db     $01, $F9, $88, $A3, $37, $A7, $23, $9C
    .db     $41, $1A, $18, $31, $36, $22, $FC
ascon_128_ciphertext_output_end:

;
; Print a string.  Offset of the string in "messages" is in X.
;
print_string:
    lda     messages,x
    beq     print_done
    jsr     print_char
    inx
    bne     print_string
print_done:
    rts

;
; Print a buffer of hexadecimal bytes.  Pointer is in "ascon_ptr"
; and the number of bytes to print is in X.
;
print_hex:
    ldy     #0
print_next_byte:
    lda     #$20
    jsr     print_char
    lda     (ascon_ptr),y
    jsr     print_hex_byte
    iny
    dex
    bne     print_next_byte
    jmp     print_crlf
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
    adc     #$30
    jmp     print_char

messages:
msg_12_rounds:
    .db     $0a
    .asc    "12 permutation rounds:"
    .db     $0a, 0
msg_8_rounds:
    .db     $0a
    .asc    "8 permutation rounds:"
    .db     $0a, 0
msg_hash:
    .db     $0a
    .asc    "ASCON-HASH:"
    .db     $0a, 0
msg_xof:
    .db     $0a
    .asc    "ASCON-XOF:"
    .db     $0a, 0
msg_encrypt_128:
    .db     $0a
    .asc    "ASCON-128 encryption:"
    .db     $0a, 0
msg_decrypt_128:
    .db     $0a
    .asc    "ASCON-128 decryption:"
    .db     $0a, 0
msg_input:
    .asc    "input    ="
    .db     0
msg_output:
    .asc    "output   ="
    .db     0
msg_expected:
    .asc    "expected ="
    .db     0
msg_key:
    .asc    "key      ="
    .db     0
msg_nonce:
    .asc    "nonce    ="
    .db     0
msg_ad:
    .asc    "ad       ="
    .db     0
msg_pt:
    .asc    "pt       ="
    .db     0
msg_ct:
    .asc    "ct       ="
    .db     0

;
; Include the implementation of ASCON.
;
    .include "ascon-6502.s"

;
; Include the platform-specific routines.
;
  .ifdef APPLEII
    .include "platform/appleii.s"
  .endif
  .ifdef EATER6502
    .include "platform/eater6502.s"
  .endif
