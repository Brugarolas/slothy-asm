///
/// Copyright (c) 2022 Arm Limited
/// Copyright (c) 2022 Hanno Becker
/// Copyright (c) 2023 Amin Abdulrahman, Matthias Kannwischer
/// SPDX-License-Identifier: MIT
///
/// Permission is hereby granted, free of charge, to any person obtaining a copy
/// of this software and associated documentation files (the "Software"), to deal
/// in the Software without restriction, including without limitation the rights
/// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
/// copies of the Software, and to permit persons to whom the Software is
/// furnished to do so, subject to the following conditions:
///
/// The above copyright notice and this permission notice shall be included in all
/// copies or substantial portions of the Software.
///
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
/// SOFTWARE.
///

.data
roots:
#include "ntt_dilithium_12_34_56_78_twiddles.s"
.text

// Barrett multiplication
.macro mulmod dst, src, const, const_twisted
        vmul.s32       \dst,  \src, \const
        vqrdmulh.s32   \src,  \src, \const_twisted
        vmla.s32       \dst,  \src, modulus
.endm

.macro ct_butterfly a, b, root, root_twisted
        mulmod tmp, \b, \root, \root_twisted
        vsub.u32       \b,    \a, tmp
        vadd.u32       \a,    \a, tmp
.endm

.align 4
roots_addr: .word roots
.syntax unified
.type ntt_dilithium_12_34_56_78_no_trans_vld4_opt_m85, %function
.global ntt_dilithium_12_34_56_78_no_trans_vld4_opt_m85
ntt_dilithium_12_34_56_78_no_trans_vld4_opt_m85:

        push {r4-r11,lr}
        // Save MVE vector registers
        vpush {d8-d15}

        modulus  .req r12
        root_ptr .req r11

        .equ modulus_const, -8380417
        movw modulus, #:lower16:modulus_const
        movt modulus, #:upper16:modulus_const
        ldr  root_ptr, roots_addr

        in_low       .req r0
        in_high      .req r1

        add in_high, in_low, #(4*128)

        root0         .req r2
        root0_twisted .req r3
        root1         .req r4
        root1_twisted .req r5
        root2         .req r6
        root2_twisted .req r7

        data0 .req q0
        data1 .req q1
        data2 .req q2
        data3 .req q3

        tmp .req q4

        // Layers 1-2
        ldrd root0, root0_twisted, [root_ptr], #+8
        ldrd root1, root1_twisted, [root_ptr], #+8
        ldrd root2, root2_twisted, [root_ptr], #+8

        mov lr, #16
        vldrw.u32 q7, [r1]              // *.
        vqrdmulh.s32 q5, q7, r3         // .*
        
        // original source code
        // vldrw.u32 q7, [r1]           // *. 
        // vqrdmulh.s32 q5, q7, r3      // .* 
        
        sub lr, lr, #1
.p2align 2
layer12_loop:
        vmul.s32 q6, q7, r2               // ....*.......................
        vldrw.u32 q4, [r1, #256]          // ...*........................
        vqrdmulh.s32 q0, q4, r3           // ..........*.................
        vldrw.u32 q2, [r0, #256]          // .*..........................
        vmul.s32 q1, q4, r2               // .........*..................
        vldrw.u32 q7, [r1, #16]           // ..e.........................
        vmla.s32 q1, q0, r12              // ...........*................
        vldrw.u32 q3, [r0]                // *...........................
        vmla.s32 q6, q5, r12              // ......*.....................
        vadd.u32 q0, q2, q1               // .............*..............
        vmul.s32 q5, q0, r4               // ..............*.............
        vsub.u32 q4, q2, q1               // ............*...............
        vqrdmulh.s32 q2, q0, r5           // ...............*............
        vsub.u32 q0, q3, q6               // .......*....................
        vmla.s32 q5, q2, r12              // ................*...........
        vadd.u32 q3, q3, q6               // ........*...................
        vmul.s32 q1, q4, r6               // ...................*........
        vadd.u32 q6, q3, q5               // ..................*.........
        vqrdmulh.s32 q2, q4, r7           // ....................*.......
        vsub.u32 q3, q3, q5               // .................*..........
        vmla.s32 q1, q2, r12              // .....................*......
        vstrw.u32 q3, [r0, #256]          // .........................*..
        vsub.u32 q3, q0, q1               // ......................*.....
        vstrw.u32 q3, [r1, #256]          // ...........................*
        vadd.u32 q3, q0, q1               // .......................*....
        vstrw.u32 q6, [r0] , #16          // ........................*...
        vqrdmulh.s32 q5, q7, r3           // .....e......................
        vstrw.u32 q3, [r1] , #16          // ..........................*.
        
        // original source code
        // vldrw.u32 q0, [r0]             // ..............................*.................... 
        // vldrw.u32 q1, [r0, #256]       // ..........................*........................ 
        // vldrw.u32 q2, [r1]             // e.................................................. 
        // vldrw.u32 q3, [r1, #256]       // ........................*.......................... 
        // vmul.s32 q4, q2, r2            // .......................*........................... 
        // vqrdmulh.s32 q2, q2, r3        // .....................e............................. 
        // vmla.s32 q4, q2, r12           // ...............................*................... 
        // vsub.u32 q2, q0, q4            // ....................................*.............. 
        // vadd.u32 q0, q0, q4            // ......................................*............ 
        // vmul.s32 q4, q3, r2            // ...........................*....................... 
        // vqrdmulh.s32 q3, q3, r3        // .........................*......................... 
        // vmla.s32 q4, q3, r12           // .............................*..................... 
        // vsub.u32 q3, q1, q4            // ..................................*................ 
        // vadd.u32 q1, q1, q4            // ................................*.................. 
        // vmul.s32 q4, q1, r4            // .................................*................. 
        // vqrdmulh.s32 q1, q1, r5        // ...................................*............... 
        // vmla.s32 q4, q1, r12           // .....................................*............. 
        // vsub.u32 q1, q0, q4            // ..........................................*........ 
        // vadd.u32 q0, q0, q4            // ........................................*.......... 
        // vmul.s32 q4, q3, r6            // .......................................*........... 
        // vqrdmulh.s32 q3, q3, r7        // .........................................*......... 
        // vmla.s32 q4, q3, r12           // ...........................................*....... 
        // vsub.u32 q3, q2, q4            // .............................................*..... 
        // vadd.u32 q2, q2, q4            // ...............................................*... 
        // vstrw.u32 q0, [r0] , #16       // ................................................*.. 
        // vstrw.u32 q1, [r0, #240]       // ............................................*...... 
        // vstrw.u32 q2, [r1] , #16       // ..................................................* 
        // vstrw.u32 q3, [r1, #240]       // ..............................................*.... 
        
        le lr, layer12_loop
        vmul.s32 q4, q7, r2               // *.........................
        vldrw.u32 q7, [r1, #256]          // .*........................
        vmul.s32 q2, q7, r2               // ....*.....................
        vldrw.u32 q3, [r0]                // ......*...................
        vqrdmulh.s32 q1, q7, r3           // ..*.......................
        vldrw.u32 q6, [r0, #256]          // ...*......................
        vmla.s32 q2, q1, r12              // .....*....................
        // gap                            // ..........................
        vmla.s32 q4, q5, r12              // .......*..................
        vadd.u32 q5, q6, q2               // ........*.................
        vmul.s32 q7, q5, r4               // .........*................
        vadd.u32 q1, q3, q4               // ..............*...........
        vqrdmulh.s32 q0, q5, r5           // ...........*..............
        vsub.u32 q4, q3, q4               // ............*.............
        vmla.s32 q7, q0, r12              // .............*............
        vsub.u32 q6, q6, q2               // ..........*...............
        vmul.s32 q3, q6, r6               // ...............*..........
        vadd.u32 q2, q1, q7               // ................*.........
        vqrdmulh.s32 q5, q6, r7           // .................*........
        vsub.u32 q1, q1, q7               // ..................*.......
        vstrw.u32 q2, [r0] , #16          // ........................*.
        vmla.s32 q3, q5, r12              // ...................*......
        vstrw.u32 q1, [r0, #240]          // ....................*.....
        vsub.u32 q0, q4, q3               // .....................*....
        vstrw.u32 q0, [r1, #256]          // ......................*...
        vadd.u32 q0, q4, q3               // .......................*..
        vstrw.u32 q0, [r1] , #16          // .........................*
        
        // original source code
        // vmul.s32 q6, q7, r2            // *......................... 
        // vldrw.u32 q4, [r1, #256]       // .*........................ 
        // vqrdmulh.s32 q0, q4, r3        // ....*..................... 
        // vldrw.u32 q2, [r0, #256]       // .....*.................... 
        // vmul.s32 q1, q4, r2            // ..*....................... 
        // vmla.s32 q1, q0, r12           // ......*................... 
        // vldrw.u32 q3, [r0]             // ...*...................... 
        // vmla.s32 q6, q5, r12           // .......*.................. 
        // vadd.u32 q0, q2, q1            // ........*................. 
        // vmul.s32 q5, q0, r4            // .........*................ 
        // vsub.u32 q4, q2, q1            // ..............*........... 
        // vqrdmulh.s32 q2, q0, r5        // ...........*.............. 
        // vsub.u32 q0, q3, q6            // ............*............. 
        // vmla.s32 q5, q2, r12           // .............*............ 
        // vadd.u32 q3, q3, q6            // ..........*............... 
        // vmul.s32 q1, q4, r6            // ...............*.......... 
        // vadd.u32 q6, q3, q5            // ................*......... 
        // vqrdmulh.s32 q2, q4, r7        // .................*........ 
        // vsub.u32 q3, q3, q5            // ..................*....... 
        // vmla.s32 q1, q2, r12           // ....................*..... 
        // vstrw.u32 q3, [r0, #256]       // .....................*.... 
        // vsub.u32 q3, q0, q1            // ......................*... 
        // vstrw.u32 q3, [r1, #256]       // .......................*.. 
        // vadd.u32 q3, q0, q1            // ........................*. 
        // vstrw.u32 q6, [r0] , #16       // ...................*...... 
        // vstrw.u32 q3, [r1] , #16       // .........................* 
        

        .unreq in_high
        .unreq in_low
        in .req r0

        // Layers 3,4
        sub in, in, #(64*4)

        // 4 butterfly blocks per root config, 4 root configs
        // loop over root configs

        count .req r1
        mov count, #4

out_start:
        ldrd root0, root0_twisted, [root_ptr], #+8
        ldrd root1, root1_twisted, [root_ptr], #+8
        ldrd root2, root2_twisted, [root_ptr], #+8

        mov lr, #4
        vldrw.u32 q4, [r0, #128]          // *.
        vmul.s32 q0, q4, r2               // .*
        
        // original source code
        // vldrw.u32 q4, [r0, #128]       // *. 
        // vmul.s32 q0, q4, r2            // .* 
        
        sub lr, lr, #1
.p2align 2
layer34_loop:
        vqrdmulh.s32 q5, q4, r3           // .....*......................
        vldrw.u32 q4, [r0, #192]          // ...*........................
        vmul.s32 q2, q4, r2               // .........*..................
        vldrw.u32 q6, [r0]                // *...........................
        vqrdmulh.s32 q4, q4, r3           // ..........*.................
        vldrw.u32 q7, [r0, #64]           // .*..........................
        vmla.s32 q2, q4, r12              // ...........*................
        vldrw.u32 q4, [r0, #144]          // ..e.........................
        vmla.s32 q0, q5, r12              // ......*.....................
        vadd.u32 q5, q7, q2               // .............*..............
        vmul.s32 q3, q5, r4               // ..............*.............
        vadd.u32 q1, q6, q0               // ........*...................
        vqrdmulh.s32 q5, q5, r5           // ...............*............
        vsub.u32 q6, q6, q0               // .......*....................
        vmla.s32 q3, q5, r12              // ................*...........
        vsub.u32 q5, q7, q2               // ............*...............
        vqrdmulh.s32 q7, q5, r7           // ....................*.......
        vadd.u32 q2, q1, q3               // ..................*.........
        vmul.s32 q0, q4, r2               // ....e.......................
        vsub.u32 q1, q1, q3               // .................*..........
        vmul.s32 q3, q5, r6               // ...................*........
        vstrw.u32 q2, [r0] , #16          // ........................*...
        vmla.s32 q3, q7, r12              // .....................*......
        vstrw.u32 q1, [r0, #48]           // .........................*..
        vadd.u32 q7, q6, q3               // .......................*....
        vstrw.u32 q7, [r0, #112]          // ..........................*.
        vsub.u32 q6, q6, q3               // ......................*.....
        vstrw.u32 q6, [r0, #176]          // ...........................*
        
        // original source code
        // vldrw.u32 q0, [r0]             // ........................*........................ 
        // vldrw.u32 q1, [r0, #64]        // ..........................*...................... 
        // vldrw.u32 q2, [r0, #128]       // e................................................ 
        // vldrw.u32 q3, [r0, #192]       // ......................*.......................... 
        // vmul.s32 q4, q2, r2            // ...........e..................................... 
        // vqrdmulh.s32 q2, q2, r3        // .....................*........................... 
        // vmla.s32 q4, q2, r12           // .............................*................... 
        // vsub.u32 q2, q0, q4            // ..................................*.............. 
        // vadd.u32 q0, q0, q4            // ................................*................ 
        // vmul.s32 q4, q3, r2            // .......................*......................... 
        // vqrdmulh.s32 q3, q3, r3        // .........................*....................... 
        // vmla.s32 q4, q3, r12           // ...........................*..................... 
        // vsub.u32 q3, q1, q4            // ....................................*............ 
        // vadd.u32 q1, q1, q4            // ..............................*.................. 
        // vmul.s32 q4, q1, r4            // ...............................*................. 
        // vqrdmulh.s32 q1, q1, r5        // .................................*............... 
        // vmla.s32 q4, q1, r12           // ...................................*............. 
        // vsub.u32 q1, q0, q4            // ........................................*........ 
        // vadd.u32 q0, q0, q4            // ......................................*.......... 
        // vmul.s32 q4, q3, r6            // .........................................*....... 
        // vqrdmulh.s32 q3, q3, r7        // .....................................*........... 
        // vmla.s32 q4, q3, r12           // ...........................................*..... 
        // vsub.u32 q3, q2, q4            // ...............................................*. 
        // vadd.u32 q2, q2, q4            // .............................................*... 
        // vstrw.u32 q0, [r0] , #16       // ..........................................*...... 
        // vstrw.u32 q1, [r0, #48]        // ............................................*.... 
        // vstrw.u32 q2, [r0, #112]       // ..............................................*.. 
        // vstrw.u32 q3, [r0, #176]       // ................................................* 
        
        le lr, layer34_loop
        vqrdmulh.s32 q1, q4, r3           // *.........................
        vldrw.u32 q3, [r0, #192]          // .*........................
        vmul.s32 q7, q3, r2               // ..*.......................
        vldrw.u32 q2, [r0, #64]           // .....*....................
        vqrdmulh.s32 q6, q3, r3           // ....*.....................
        // gap                            // ..........................
        vmla.s32 q7, q6, r12              // ......*...................
        vldrw.u32 q6, [r0]                // ...*......................
        vmla.s32 q0, q1, r12              // .......*..................
        vadd.u32 q4, q2, q7               // ........*.................
        vmul.s32 q5, q4, r4               // .........*................
        vsub.u32 q1, q6, q0               // ............*.............
        vqrdmulh.s32 q3, q4, r5           // ...........*..............
        vadd.u32 q6, q6, q0               // ..........*...............
        vmla.s32 q5, q3, r12              // .............*............
        vsub.u32 q0, q2, q7               // ..............*...........
        vqrdmulh.s32 q2, q0, r7           // ...............*..........
        vadd.u32 q7, q6, q5               // ................*.........
        vmul.s32 q0, q0, r6               // ..................*.......
        vsub.u32 q4, q6, q5               // .................*........
        vstrw.u32 q7, [r0] , #16          // ...................*......
        vmla.s32 q0, q2, r12              // ....................*.....
        vstrw.u32 q4, [r0, #48]           // .....................*....
        vadd.u32 q3, q1, q0               // ......................*...
        vstrw.u32 q3, [r0, #112]          // .......................*..
        vsub.u32 q0, q1, q0               // ........................*.
        vstrw.u32 q0, [r0, #176]          // .........................*
        
        // original source code
        // vqrdmulh.s32 q5, q4, r3        // *......................... 
        // vldrw.u32 q4, [r0, #192]       // .*........................ 
        // vmul.s32 q2, q4, r2            // ..*....................... 
        // vldrw.u32 q6, [r0]             // ......*................... 
        // vqrdmulh.s32 q4, q4, r3        // ....*..................... 
        // vldrw.u32 q7, [r0, #64]        // ...*...................... 
        // vmla.s32 q2, q4, r12           // .....*.................... 
        // vmla.s32 q0, q5, r12           // .......*.................. 
        // vadd.u32 q5, q7, q2            // ........*................. 
        // vmul.s32 q3, q5, r4            // .........*................ 
        // vadd.u32 q1, q6, q0            // ............*............. 
        // vqrdmulh.s32 q5, q5, r5        // ...........*.............. 
        // vsub.u32 q6, q6, q0            // ..........*............... 
        // vmla.s32 q3, q5, r12           // .............*............ 
        // vsub.u32 q5, q7, q2            // ..............*........... 
        // vqrdmulh.s32 q7, q5, r7        // ...............*.......... 
        // vadd.u32 q2, q1, q3            // ................*......... 
        // vsub.u32 q1, q1, q3            // ..................*....... 
        // vmul.s32 q3, q5, r6            // .................*........ 
        // vstrw.u32 q2, [r0] , #16       // ...................*...... 
        // vmla.s32 q3, q7, r12           // ....................*..... 
        // vstrw.u32 q1, [r0, #48]        // .....................*.... 
        // vadd.u32 q7, q6, q3            // ......................*... 
        // vstrw.u32 q7, [r0, #112]       // .......................*.. 
        // vsub.u32 q6, q6, q3            // ........................*. 
        // vstrw.u32 q6, [r0, #176]       // .........................* 
        

        add in, in, #(4*64 - 4*16)
        subs count, count, #1
        bne out_start

        // Layers 5,6
        sub in, in, #(4*256)

        mov lr, #16
.p2align 2
layer56_loop:
        ldrd r4, r9, [r11] , #24          // *..............................
        vldrw.u32 q6, [r0, #48]           // ......*........................
        vmul.s32 q4, q6, r4               // ............*..................
        vldrw.u32 q1, [r0, #32]           // .....*.........................
        vqrdmulh.s32 q0, q6, r9           // .............*.................
        vldrw.u32 q3, [r0]                // ...*...........................
        vqrdmulh.s32 q7, q1, r9           // ........*......................
        vldrw.u32 q5, [r0, #16]           // ....*..........................
        vmla.s32 q4, q0, r12              // ..............*................
        ldrd r6, r7, [r11, #-8]           // ..*............................
        vmul.s32 q0, q1, r4               // .......*.......................
        vsub.u32 q2, q5, q4               // ...............*...............
        vmla.s32 q0, q7, r12              // .........*.....................
        vadd.u32 q5, q5, q4               // ................*..............
        vqrdmulh.s32 q4, q2, r7           // .......................*.......
        vadd.u32 q7, q3, q0               // ...........*...................
        vmul.s32 q1, q2, r6               // ......................*........
        vsub.u32 q3, q3, q0               // ..........*....................
        vmla.s32 q1, q4, r12              // ........................*......
        ldrd r2, r3, [r11, #-16]          // .*.............................
        vadd.u32 q4, q3, q1               // ..........................*....
        vmul.s32 q0, q5, r2               // .................*.............
        vstrw.u32 q4, [r0, #32]           // .............................*.
        vqrdmulh.s32 q2, q5, r3           // ..................*............
        vsub.u32 q5, q3, q1               // .........................*.....
        vmla.s32 q0, q2, r12              // ...................*...........
        vstrw.u32 q5, [r0, #48]           // ..............................*
        vsub.u32 q5, q7, q0               // ....................*..........
        vstrw.u32 q5, [r0, #16]           // ............................*..
        vadd.u32 q0, q7, q0               // .....................*.........
        vstrw.u32 q0, [r0] , #64          // ...........................*...
        
        // original source code
        // ldrd r2, r3, [r11] , #24       // *.............................. 
        // ldrd r4, r5, [r11, #-16]       // ...................*........... 
        // ldrd r6, r7, [r11, #-8]        // .........*..................... 
        // vldrw.u32 q0, [r0]             // .....*......................... 
        // vldrw.u32 q1, [r0, #16]        // .......*....................... 
        // vldrw.u32 q2, [r0, #32]        // ...*........................... 
        // vldrw.u32 q3, [r0, #48]        // .*............................. 
        // vmul.s32 q4, q2, r2            // ..........*.................... 
        // vqrdmulh.s32 q2, q2, r3        // ......*........................ 
        // vmla.s32 q4, q2, r12           // ............*.................. 
        // vsub.u32 q2, q0, q4            // .................*............. 
        // vadd.u32 q0, q0, q4            // ...............*............... 
        // vmul.s32 q4, q3, r2            // ..*............................ 
        // vqrdmulh.s32 q3, q3, r3        // ....*.......................... 
        // vmla.s32 q4, q3, r12           // ........*...................... 
        // vsub.u32 q3, q1, q4            // ...........*................... 
        // vadd.u32 q1, q1, q4            // .............*................. 
        // vmul.s32 q4, q1, r4            // .....................*......... 
        // vqrdmulh.s32 q1, q1, r5        // .......................*....... 
        // vmla.s32 q4, q1, r12           // .........................*..... 
        // vsub.u32 q1, q0, q4            // ...........................*... 
        // vadd.u32 q0, q0, q4            // .............................*. 
        // vmul.s32 q4, q3, r6            // ................*.............. 
        // vqrdmulh.s32 q3, q3, r7        // ..............*................ 
        // vmla.s32 q4, q3, r12           // ..................*............ 
        // vsub.u32 q3, q2, q4            // ........................*...... 
        // vadd.u32 q2, q2, q4            // ....................*.......... 
        // vstrw.u32 q0, [r0] , #64       // ..............................* 
        // vstrw.u32 q1, [r0, #-48]       // ............................*.. 
        // vstrw.u32 q2, [r0, #-32]       // ......................*........ 
        // vstrw.u32 q3, [r0, #-16]       // ..........................*.... 
        
        le lr, layer56_loop
        layer56_loop_end:
        sub r0, r0, #(4*256)                   // *.......
        vld40.u32 {q3,q4,q5,q6}, [r0]          // ..*.....
        mov r14, #15                           // .*......
        vld41.u32 {q3,q4,q5,q6}, [r0]          // ...*....
        // gap                                 // ........
        vld42.u32 {q3,q4,q5,q6}, [r0]          // ....*...
        // gap                                 // ........
        vld43.u32 {q3,q4,q5,q6}, [r0]!         // .....*..
        // gap                                 // ........
        vldrw.u32 q2, [r11] , #96              // ......*.
        // gap                                 // ........
        vmul.s32 q0, q6, q2                    // .......*
        
        // original source code
        // sub r0, r0, #(4*256)                // *....... 
        // mov r14, #15                        // ..*..... 
        // vld40.u32 {q3,q4,q5,q6}, [r0]       // .*...... 
        // vld41.u32 {q3,q4,q5,q6}, [r0]       // ...*.... 
        // vld42.u32 {q3,q4,q5,q6}, [r0]       // ....*... 
        // vld43.u32 {q3,q4,q5,q6}, [r0]!      // .....*.. 
        // vldrw.u32 q2, [r11] , #96           // ......*. 
        // vmul.s32 q0, q6, q2                 // .......* 
        
        layer78_loop:

        vmul.s32 q1, q5, q2                    // ......*...........................
        vldrw.u32 q7, [r11, #-80]              // .....*............................
        vqrdmulh.s32 q6, q6, q7                // ............*.....................
        vldrw.u32 q2, [r11, #-16]              // ........................*.........
        vmla.s32 q0, q6, r12                   // .............*....................
        vldrw.u32 q6, [r11, #-32]              // .......................*..........
        vqrdmulh.s32 q7, q5, q7                // .......*..........................
        vsub.u32 q5, q4, q0                    // ..............*...................
        vmla.s32 q1, q7, r12                   // ........*.........................
        vadd.u32 q0, q4, q0                    // ...............*..................
        vqrdmulh.s32 q4, q5, q2                // ..........................*.......
        vsub.u32 q7, q3, q1                    // .........*........................
        vmul.s32 q5, q5, q6                    // .........................*........
        vadd.u32 q1, q3, q1                    // ..........*.......................
        vmla.s32 q5, q4, r12                   // ...........................*......
        vldrw.u32 q2, [r11, #-64]              // ................*.................
        vadd.u32 q4, q7, q5                    // .............................*....
        vstrw.u32 q4, [r0, #-32]               // ................................*.
        vsub.u32 q7, q7, q5                    // ............................*.....
        vstrw.u32 q7, [r0, #-16]               // .................................*
        vld40.u32 {q3,q4,q5,q6}, [r0]          // e.................................
        vmul.s32 q7, q0, q2                    // ..................*...............
        vldrw.u32 q2, [r11, #-48]              // .................*................
        vqrdmulh.s32 q0, q0, q2                // ...................*..............
        vld41.u32 {q3,q4,q5,q6}, [r0]          // .e................................
        vmla.s32 q7, q0, r12                   // ....................*.............
        vld42.u32 {q3,q4,q5,q6}, [r0]          // ..e...............................
        vadd.u32 q0, q1, q7                    // ......................*...........
        vld43.u32 {q3,q4,q5,q6}, [r0]!         // ...e..............................
        vsub.u32 q1, q1, q7                    // .....................*............
        vldrw.u32 q2, [r11] , #96              // ....e.............................
        vstrw.u32 q0, [r0, #-128]              // ..............................*...
        vmul.s32 q0, q6, q2                    // ...........e......................
        vstrw.u32 q1, [r0, #-112]              // ...............................*..
        
        // original source code
        // vld40.u32 {q0,q1,q2,q3}, [r0]       // e............................................... 
        // vld41.u32 {q0,q1,q2,q3}, [r0]       // ....e........................................... 
        // vld42.u32 {q0,q1,q2,q3}, [r0]       // ......e......................................... 
        // vld43.u32 {q0,q1,q2,q3}, [r0]!      // ........e....................................... 
        // vldrw.u32 q5, [r11] , #96           // ..........e..................................... 
        // vldrw.u32 q6, [r11, #-80]           // ...............*................................ 
        // vmul.s32 q4, q2, q5                 // ..............*................................. 
        // vqrdmulh.s32 q2, q2, q6             // ....................*........................... 
        // vmla.s32 q4, q2, r12                // ......................*......................... 
        // vsub.u32 q2, q0, q4                 // .........................*...................... 
        // vadd.u32 q0, q0, q4                 // ...........................*.................... 
        // vmul.s32 q4, q3, q5                 // ............e................................... 
        // vqrdmulh.s32 q3, q3, q6             // ................*............................... 
        // vmla.s32 q4, q3, r12                // ..................*............................. 
        // vsub.u32 q3, q1, q4                 // .....................*.......................... 
        // vadd.u32 q1, q1, q4                 // .......................*........................ 
        // vldrw.u32 q5, [r11, #-64]           // .............................*.................. 
        // vldrw.u32 q6, [r11, #-48]           // ....................................*........... 
        // vmul.s32 q4, q1, q5                 // ...................................*............ 
        // vqrdmulh.s32 q1, q1, q6             // .....................................*.......... 
        // vmla.s32 q4, q1, r12                // .......................................*........ 
        // vsub.u32 q1, q0, q4                 // ...........................................*.... 
        // vadd.u32 q0, q0, q4                 // .........................................*...... 
        // vldrw.u32 q5, [r11, #-32]           // ...................*............................ 
        // vldrw.u32 q6, [r11, #-16]           // .................*.............................. 
        // vmul.s32 q4, q3, q5                 // ..........................*..................... 
        // vqrdmulh.s32 q3, q3, q6             // ........................*....................... 
        // vmla.s32 q4, q3, r12                // ............................*................... 
        // vsub.u32 q3, q2, q4                 // ................................*............... 
        // vadd.u32 q2, q2, q4                 // ..............................*................. 
        // vstrw.u32 q0, [r0, #-64]            // .............................................*.. 
        // vstrw.u32 q1, [r0, #-48]            // ...............................................* 
        // vstrw.u32 q2, [r0, #-32]            // ...............................*................ 
        // vstrw.u32 q3, [r0, #-16]            // .................................*.............. 
        
        le lr, layer78_loop
        vmul.s32 q7, q5, q2                // *...........................
        vldrw.u32 q2, [r11, #-80]          // .*..........................
        vqrdmulh.s32 q1, q6, q2            // ..*.........................
        vldrw.u32 q6, [r11, #-32]          // .....*......................
        vmla.s32 q0, q1, r12               // ....*.......................
        vldrw.u32 q1, [r11, #-16]          // ...*........................
        vqrdmulh.s32 q5, q5, q2            // ......*.....................
        vadd.u32 q2, q4, q0                // .........*..................
        vmla.s32 q7, q5, r12               // ........*...................
        vsub.u32 q0, q4, q0                // .......*....................
        vmul.s32 q6, q0, q6                // ............*...............
        vadd.u32 q5, q3, q7                // .............*..............
        vqrdmulh.s32 q0, q0, q1            // ..........*.................
        vsub.u32 q1, q3, q7                // ...........*................
        vmla.s32 q6, q0, r12               // ..............*.............
        vldrw.u32 q0, [r11, #-64]          // ...............*............
        vsub.u32 q3, q1, q6                // ..................*.........
        vstrw.u32 q3, [r0, #-16]           // ...................*........
        vmul.s32 q3, q2, q0                // ....................*.......
        vldrw.u32 q0, [r11, #-48]          // .....................*......
        vqrdmulh.s32 q0, q2, q0            // ......................*.....
        vadd.u32 q6, q1, q6                // ................*...........
        vmla.s32 q3, q0, r12               // .......................*....
        vstrw.u32 q6, [r0, #-32]           // .................*..........
        vadd.u32 q0, q5, q3                // ........................*...
        vstrw.u32 q0, [r0, #-64]           // ..........................*.
        vsub.u32 q0, q5, q3                // .........................*..
        vstrw.u32 q0, [r0, #-48]           // ...........................*
        
        // original source code
        // vmul.s32 q1, q5, q2             // *........................... 
        // vldrw.u32 q7, [r11, #-80]       // .*.......................... 
        // vqrdmulh.s32 q6, q6, q7         // ..*......................... 
        // vldrw.u32 q2, [r11, #-16]       // .....*...................... 
        // vmla.s32 q0, q6, r12            // ....*....................... 
        // vldrw.u32 q6, [r11, #-32]       // ...*........................ 
        // vqrdmulh.s32 q7, q5, q7         // ......*..................... 
        // vsub.u32 q5, q4, q0             // .........*.................. 
        // vmla.s32 q1, q7, r12            // ........*................... 
        // vadd.u32 q0, q4, q0             // .......*.................... 
        // vqrdmulh.s32 q4, q5, q2         // ............*............... 
        // vsub.u32 q7, q3, q1             // .............*.............. 
        // vmul.s32 q5, q5, q6             // ..........*................. 
        // vadd.u32 q1, q3, q1             // ...........*................ 
        // vmla.s32 q5, q4, r12            // ..............*............. 
        // vldrw.u32 q2, [r11, #-64]       // ...............*............ 
        // vadd.u32 q4, q7, q5             // .....................*...... 
        // vstrw.u32 q4, [r0, #-32]        // .......................*.... 
        // vsub.u32 q7, q7, q5             // ................*........... 
        // vstrw.u32 q7, [r0, #-16]        // .................*.......... 
        // vmul.s32 q7, q0, q2             // ..................*......... 
        // vldrw.u32 q2, [r11, #-48]       // ...................*........ 
        // vqrdmulh.s32 q0, q0, q2         // ....................*....... 
        // vmla.s32 q7, q0, r12            // ......................*..... 
        // vadd.u32 q0, q1, q7             // ........................*... 
        // vsub.u32 q1, q1, q7             // ..........................*. 
        // vstrw.u32 q0, [r0, #-64]        // .........................*.. 
        // vstrw.u32 q1, [r0, #-48]        // ...........................* 
        

        // Restore MVE vector registers
        vpop {d8-d15}
        // Restore GPRs
        pop {r4-r11,lr}
        bx lr