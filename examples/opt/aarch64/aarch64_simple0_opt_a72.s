        ldr q29, [x0, #16]                      // ..*................
        ldr q8, [x1, #0]                        // *..................
// gap                                  // ...................
        ldr q22, [x0]                           // .*.................
        ldr q17, [x0, #32]                      // ...*...............
// gap                                  // ...................
        ldr q26, [x0, #48]                      // ....*..............
// gap                                  // ...................
// gap                                  // ...................
// gap                                  // ...................
// gap                                  // ...................
// gap                                  // ...................
        mul v6.8H, v29.8H, v8.H[0]              // .....*.............
// gap                                  // ...................
// gap                                  // ...................
// gap                                  // ...................
// gap                                  // ...................
// gap                                  // ...................
        sqrdmulh v29.8H, v29.8H, v8.H[1]        // ......*............
// gap                                  // ...................
// gap                                  // ...................
// gap                                  // ...................
// gap                                  // ...................
// gap                                  // ...................
        sqrdmulh v4.8H, v26.8H, v8.H[1]         // ...........*.......
// gap                                  // ...................
// gap                                  // ...................
// gap                                  // ...................
// gap                                  // ...................
// gap                                  // ...................
        mul v8.8H, v26.8H, v8.H[0]              // ..........*........
// gap                                  // ...................
// gap                                  // ...................
// gap                                  // ...................
// gap                                  // ...................
// gap                                  // ...................
        mls v6.8H, v29.8H, v1.H[0]              // .......*...........
// gap                                  // ...................
// gap                                  // ...................
// gap                                  // ...................
// gap                                  // ...................
// gap                                  // ...................
        mls v8.8H, v4.8H, v1.H[0]               // ............*......
// gap                                  // ...................
// gap                                  // ...................
// gap                                  // ...................
// gap                                  // ...................
// gap                                  // ...................
// gap                                  // ...................
// gap                                  // ...................
// gap                                  // ...................
        sub v29.8H, v22.8H, v6.8H               // ........*..........
        add v22.8H, v22.8H, v6.8H               // .........*.........
// gap                                  // ...................
// gap                                  // ...................
// gap                                  // ...................
// gap                                  // ...................
        sub v26.8H, v17.8H, v8.8H               // .............*.....
        add v8.8H, v17.8H, v8.8H                // ..............*....
// gap                                  // ...................
        str q29, [x0, #16]                      // ................*..
        str q22, [x0], #4*16                    // ...............*...
// gap                                  // ...................
// gap                                  // ...................
// gap                                  // ...................
// gap                                  // ...................
        str q26, [x0, #-16]                     // ..................*
        str q8, [x0, #-32]                      // .................*.
// gap                                  // ...................

// original source code
// ldr q0, [x1, #0]                       // .*.................
// ldr q8,  [x0]                          // ..*................
// ldr q9,  [x0, #1*16]                   // *..................
// ldr q10, [x0, #2*16]                   // ...*...............
// ldr q11, [x0, #3*16]                   // ....*..............
// mul v24.8h, v9.8h, v0.h[0]             // .....*.............
// sqrdmulh v9.8h, v9.8h, v0.h[1]         // ......*............
// mls v24.8h, v9.8h, v1.h[0]             // .........*.........
// sub     v9.8h,    v8.8h, v24.8h        // ...........*.......
// add     v8.8h,    v8.8h, v24.8h        // ............*......
// mul v24.8h, v11.8h, v0.h[0]            // ........*..........
// sqrdmulh v11.8h, v11.8h, v0.h[1]       // .......*...........
// mls v24.8h, v11.8h, v1.h[0]            // ..........*........
// sub     v11.8h,    v10.8h, v24.8h      // .............*.....
// add     v10.8h,    v10.8h, v24.8h      // ..............*....
// str q8,  [x0], #4*16                   // ................*..
// str q9,  [x0, #-3*16]                  // ...............*...
// str q10, [x0, #-2*16]                  // ..................*
// str q11, [x0, #-1*16]                  // .................*.