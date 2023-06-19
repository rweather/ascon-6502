ASCON for 6502 Microprocessors
==============================

This repository contains an implementation of ASCON for 6502 microprocessors.
It was more of a case of "can it be done?" than "should it be done?".
But here it is!

Implemented Standard ASCON Modes
--------------------------------

* ASCON-128
* ASCON-HASH
* ASCON-XOF
* Raw access to the ASCON permutation for building other modes.

API
---

The ASCON implementation is in the "ascon-6502.s" file.  Include it into
your own program to use the functions.  The code is 2968 bytes in size.

The following subroutines are provided:

* ascon\_128\_encrypt
* ascon\_128\_decrypt
* ascon\_hash\_init
* ascon\_hash\_update
* ascon\_hash\_finalize
* ascon\_xof\_init
* ascon\_xof\_absorb
* ascon\_xof\_squeeze
* ascon\_permute

See the comments in the code for arguments and usage.  Arguments are passed
in registers and zero page locations.  The test harness in "ascon-test.s"
provides some examples.

At present the API's are limited to processing no more than 255 bytes
at a time.  This isn't a problem for ASCON-HASH and ASCON-XOF as they
support incremental hashing.  Just chop the data up into smaller pieces first.

The ASCON-128 implementation does not currently support an incremental mode
or a 16-bit size argument, so the maximum plaintext size is limited to
255 bytes and the maximum associated data size is limited to 224 bytes.

Building and Customizing
------------------------

The code and the Makefile use [vasm](http://sun.hasenbraten.de/vasm/)
so you will need that installed.  The "vasm6502\_oldstyle" binary is
assumed to be installed somewhere on your PATH.

You will probably need to modify the code: "ascon-6502.s" uses zero page
memory locations to store the permutation state and other variables.
Depending upon your system you will probably need to change the addresses
to work around the BASIC on the system which steals most of the zero page.
I used a 6502 emulator of my own design to run the code and I didn't have
BASIC loaded at the time.

The "ascon-test.s" harness assumes the presence of a character output
routine in the system ROM.  The default code uses the Apple II style
"COUT" and "CROUT" routines at $FDED and $FD8E in the Apple II kernel ROM's.
You will need to modify this for other systems.  The origin at $4000
will probably also need to be changed.

Performance
-----------

I used a 6502 emulator of my own design to collect these timings.
They should be considered indicative of the performance you can
expect but maybe not 100% accurate.  On a real 6502, extra clock
cycles may occur when memory accesses cross a 256-byte page boundary.
My emulator doesn't currently emulate that.

<table border="1">
<tr><td><b>Scenario</b></td><td><b>Cycles Per Byte</b></td><td><b>Bytes Per Second @ 1MHz</b></td></tr>
<tr><td>ASCON-HASH and ASCON-XOF absorb</td><td align="right">4594</td><td align="right">217</td></th>
<tr><td>ASCON-HASH and ASCON-XOF squeeze</td><td align="right">4591</td><td align="right">217</td></th>
<tr><td>ASCON-128 absorb associated data</td><td align="right">2446</td><td align="right">408</td></th>
<tr><td>ASCON-128 encrypt plaintext</td><td align="right">2309</td><td align="right">433</td></th>
<tr><td>ASCON-128 decrypt ciphertext</td><td align="right">2316</td><td align="right">431</td></th>
</table>

12 rounds of the permutation can be performed in 36545 clock cycles,
or a nominal time of 36.5ms per permutation call at 1MHz.

Recent versions of the 6502 can run up to 14MHz.  If you were to
overclock your Apple II or Commodore 64 you could potentially
get up to around 3000 bytes per second when hashing and 6000 bytes per
second when encrypting!  Woohoo!

Test Output
-----------

    12 permutation rounds:
    input    = 00 01 02 03 04 05 06 07 08 09 0A 0B 0C 0D 0E 0F 10 11 12 13 14 15 16 17 18 19 1A 1B 1C 1D 1E 1F 20 21 22 23 24 25 26 27
    output   = 06 05 87 E2 D4 89 DD 43 1C C2 B1 7B 0E 3C 17 64 95 73 42 53 18 44 A6 74 96 B1 71 75 B4 CB 68 63 29 B5 12 D6 27 D9 06 E5
    expected = 06 05 87 E2 D4 89 DD 43 1C C2 B1 7B 0E 3C 17 64 95 73 42 53 18 44 A6 74 96 B1 71 75 B4 CB 68 63 29 B5 12 D6 27 D9 06 E5

    8 permutation rounds:
    input    = 00 01 02 03 04 05 06 07 08 09 0A 0B 0C 0D 0E 0F 10 11 12 13 14 15 16 17 18 19 1A 1B 1C 1D 1E 1F 20 21 22 23 24 25 26 27
    output   = 83 0D 26 0D 33 5F 3B ED DA 0B BA 91 7B CF CA D7 DD 0D 88 E7 DC B5 EC D0 89 2A 02 15 1F 95 94 6E 3A 69 CB 3C F9 82 F6 F7
    expected = 83 0D 26 0D 33 5F 3B ED DA 0B BA 91 7B CF CA D7 DD 0D 88 E7 DC B5 EC D0 89 2A 02 15 1F 95 94 6E 3A 69 CB 3C F9 82 F6 F7

    ASCON-HASH:
    input    = 00 01 02 03 04 05 06 07 08 09 0A 0B 0C 0D 0E 0F 10 11 12 13 14 15 16 17 18 19 1A 1B 1C 1D 1E
    output   = 2C B1 46 AE BB B6 58 5B 11 BF 1A 37 1B AA 6E 3E 55 10 8C 69 B0 83 4F 26 9F 66 2C 59 BC AA 57 00
    expected = 2C B1 46 AE BB B6 58 5B 11 BF 1A 37 1B AA 6E 3E 55 10 8C 69 B0 83 4F 26 9F 66 2C 59 BC AA 57 00

    ASCON-XOF:
    input    = 00 01 02 03 04 05 06 07 08 09 0A 0B 0C 0D 0E 0F 10 11 12 13 14 15 16 17 18 19 1A 1B 1C 1D 1E
    output   = 9E 52 42 26 D3 8B DC DB 3E 57 6C 2A 98 21 85 D3 A0 21 1D 51 98 48 A9 38 E8 35 2A C9 74 98 58 1D
    expected = 9E 52 42 26 D3 8B DC DB 3E 57 6C 2A 98 21 85 D3 A0 21 1D 51 98 48 A9 38 E8 35 2A C9 74 98 58 1D

    ASCON-128 encryption:
    key      = 00 01 02 03 04 05 06 07 08 09 0A 0B 0C 0D 0E 0F
    nonce    = 00 01 02 03 04 05 06 07 08 09 0A 0B 0C 0D 0E 0F
    ad       = 00 01 02 03 04 05 06 07 08 09 0A
    pt       = 00 01 02 03 04 05 06 07 08 09 0A 0B 0C 0D 0E 0F 10 11 12 13 14 15 16
    output   = 76 80 7B 64 48 89 6C E5 88 42 CB 4A ED 6C 41 04 1D 6D EC 3B 3A 0D D6 99 01 F9 88 A3 37 A7 23 9C 41 1A 18 31 36 22 FC
    expected = 76 80 7B 64 48 89 6C E5 88 42 CB 4A ED 6C 41 04 1D 6D EC 3B 3A 0D D6 99 01 F9 88 A3 37 A7 23 9C 41 1A 18 31 36 22 FC

    ASCON-128 decryption:
    key      = 00 01 02 03 04 05 06 07 08 09 0A 0B 0C 0D 0E 0F
    nonce    = 00 01 02 03 04 05 06 07 08 09 0A 0B 0C 0D 0E 0F
    ad       = 00 01 02 03 04 05 06 07 08 09 0A
    ct       = 76 80 7B 64 48 89 6C E5 88 42 CB 4A ED 6C 41 04 1D 6D EC 3B 3A 0D D6 99 01 F9 88 A3 37 A7 23 9C 41 1A 18 31 36 22 FC
    output   = 00 01 02 03 04 05 06 07 08 09 0A 0B 0C 0D 0E 0F 10 11 12 13 14 15 16
    expected = 00 01 02 03 04 05 06 07 08 09 0A 0B 0C 0D 0E 0F 10 11 12 13 14 15 16

Contact
-------

For more information on this code, to report bugs, or to suggest
improvements, please contact the author Rhys Weatherley via
[email](mailto:rhys.weatherley@gmail.com).
