qdata0   .req q8
qdata1   .req q9
qdata2   .req q10
qdata3   .req q11

qtwiddle .req q0
qmodulus .req q1

data0    .req v8
data1    .req v9
data2    .req v10
data3    .req v11

twiddle  .req v0
modulus  .req v1

tmp      .req v12

data_ptr      .req x0
twiddle_ptr   .req x1
modulus_ptr   .req x2

.macro barmul out, in, twiddle, modulus
    mul      \out.8h,   \in.8h, \twiddle.h[0]
    sqrdmulh \in.8h,    \in.8h, \twiddle.h[1]
    mls      \out.8h,   \in.8h, \modulus.h[0]
.endm

.macro butterfly data0, data1, tmp, twiddle, modulus
    barmul \tmp, \data1, \twiddle, \modulus
    sub    \data1.8h, \data0.8h, \tmp.8h
    add    \data0.8h, \data0.8h, \tmp.8h
.endm

count .req x2

        start:
        ldr q3, [x1, #0]                        // *...................
        // gap                                  // ....................
        // gap                                  // ....................
        // gap                                  // ....................
        ldr q24, [x0, #16]                      // ...*................
        // gap                                  // ....................
        // gap                                  // ....................
        // gap                                  // ....................
        ldr q26, [x0, #48]                      // .....*..............
        // gap                                  // ....................
        // gap                                  // ....................
        // gap                                  // ....................
        mul v10.8H, v24.8H, v3.H[0]             // ......*.............
        // gap                                  // ....................
        ldr q15, [x2, #0]                       // .*..................
        // gap                                  // ....................
        // gap                                  // ....................
        // gap                                  // ....................
        sqrdmulh v20.8H, v26.8H, v3.H[1]        // ............*.......
        // gap                                  // ....................
        mul v26.8H, v26.8H, v3.H[0]             // ...........*........
        // gap                                  // ....................
        sqrdmulh v22.8H, v24.8H, v3.H[1]        // .......*............
        // gap                                  // ....................
        ldr q21, [x0, #32]                      // ....*...............
        // gap                                  // ....................
        // gap                                  // ....................
        // gap                                  // ....................
        mls v26.8H, v20.8H, v15.H[0]            // .............*......
        // gap                                  // ....................
        mls v10.8H, v22.8H, v15.H[0]            // ........*...........
        // gap                                  // ....................
        ldr q30, [x0, #0]                       // ..*.................
        // gap                                  // ....................
        // gap                                  // ....................
        // gap                                  // ....................
        add v11.8H, v21.8H, v26.8H              // ...............*....
        // gap                                  // ....................
        sub v0.8H, v21.8H, v26.8H               // ..............*.....
        // gap                                  // ....................
        sub v28.8H, v30.8H, v10.8H              // .........*..........
        // gap                                  // ....................
        str q11, [x0, #32]                      // ..................*.
        // gap                                  // ....................
        // gap                                  // ....................
        // gap                                  // ....................
        str q28, [x0, #16]                      // .................*..
        // gap                                  // ....................
        add v28.8H, v30.8H, v10.8H              // ..........*.........
        // gap                                  // ....................
        str q0, [x0, #48]                       // ...................*
        // gap                                  // ....................
        // gap                                  // ....................
        // gap                                  // ....................
        str q28, [x0], #4*16                    // ................*...
        // gap                                  // ....................

        // original source code
        // ldr q0, [x1, #0]                         // *...................
        // ldr q1, [x2, #0]                         // ....*...............
        // ldr q8, [x0, #0*16]                      // ...........*........
        // ldr q9, [x0, #1*16]                      // .*..................
        // ldr q10, [x0, #2*16]                     // ........*...........
        // ldr q11, [x0, #3*16]                     // ..*.................
        // mul      v12.8h,   v9.8h, v0.h[0]        // ...*................
        // sqrdmulh v9.8h,    v9.8h, v0.h[1]        // .......*............
        // mls      v12.8h,   v9.8h, v1.h[0]        // ..........*.........
        // sub    v9.8h, v8.8h, v12.8h              // ..............*.....
        // add    v8.8h, v8.8h, v12.8h              // .................*..
        // mul      v12.8h,   v11.8h, v0.h[0]       // ......*.............
        // sqrdmulh v11.8h,    v11.8h, v0.h[1]      // .....*..............
        // mls      v12.8h,   v11.8h, v1.h[0]       // .........*..........
        // sub    v11.8h, v10.8h, v12.8h            // .............*......
        // add    v10.8h, v10.8h, v12.8h            // ............*.......
        // str q8, [x0], #4*16                      // ...................*
        // str q9, [x0, #-3*16]                     // ................*...
        // str q10, [x0, #-2*16]                    // ...............*....
        // str q11, [x0, #-1*16]                    // ..................*.

        end:
