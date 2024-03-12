count .req x2

mov count, #16

        ldr q2, [x0, #48]                       // .*.....
        ldr q11, [x1, #0]                       // *......
        // gap                                  // .......
        ldr q0, [x0, #16]                       // ..*....
        // gap                                  // .......
        // gap                                  // .......
        // gap                                  // .......
        // gap                                  // .......
        // gap                                  // .......
        // gap                                  // .......
        // gap                                  // .......
        // gap                                  // .......
        sqrdmulh v8.8H, v2.8H, v11.H[1]         // ...*...
        // gap                                  // .......
        // gap                                  // .......
        // gap                                  // .......
        // gap                                  // .......
        // gap                                  // .......
        mul v25.8H, v2.8H, v11.H[0]             // .....*.
        // gap                                  // .......
        // gap                                  // .......
        // gap                                  // .......
        // gap                                  // .......
        // gap                                  // .......
        sqrdmulh v27.8H, v0.8H, v11.H[1]        // ....*..
        // gap                                  // .......
        // gap                                  // .......
        // gap                                  // .......
        // gap                                  // .......
        // gap                                  // .......
        mls v25.8H, v8.8H, v1.H[0]              // ......*
        // gap                                  // .......
        // gap                                  // .......

        // original source code
        // ldr q11, [x1, #0]                      // .*.....
        // ldr q19, [x0, #48]                     // *......
        // ldr q0, [x0, #16]                      // ..*....
        // sqrdmulh v12.8H, v19.8H, v11.H[1]      // ...*...
        // sqrdmulh v27.8H, v0.8H, v11.H[1]       // .....*.
        // mul v25.8H, v19.8H, v11.H[0]           // ....*..
        // mls v25.8H, v12.8H, v1.H[0]            // ......*

        sub count, count, #1
start:
        mul v30.8H, v0.8H, v11.H[0]              // .....*.............
        ldr q11, [x1, #0]                        // e..................
        ldr q19, [x0, #112]                      // ....e..............
        ldr q5, [x0, #32]                        // ...*...............
        ldr q3, [x0]                             // .*.................
        // gap                                   // ...................
        mls v30.8H, v27.8H, v1.H[0]              // .......*...........
        ldr q0, [x0, #80]                        // ..e................
        // gap                                   // ...................
        // gap                                   // ...................
        // gap                                   // ...................
        // gap                                   // ...................
        // gap                                   // ...................
        // gap                                   // ...................
        sqrdmulh v12.8H, v19.8H, v11.H[1]        // ...........e.......
        // gap                                   // ...................
        // gap                                   // ...................
        sub v2.8H, v5.8H, v25.8H                 // .............*.....
        sqrdmulh v27.8H, v0.8H, v11.H[1]         // ......e............
        // gap                                   // ...................
        add v21.8H, v5.8H, v25.8H                // ..............*....
        // gap                                   // ...................
        // gap                                   // ...................
        sub v18.8H, v3.8H, v30.8H                // ........*..........
        add v3.8H, v3.8H, v30.8H                 // .........*.........
        // gap                                   // ...................
        mul v25.8H, v19.8H, v11.H[0]             // ..........e........
        // gap                                   // ...................
        // gap                                   // ...................
        // gap                                   // ...................
        str q18, [x0, #16]                       // ................*..
        str q21, [x0, #32]                       // .................*.
        mls v25.8H, v12.8H, v1.H[0]              // ............e......
        str q3, [x0], #4*16                      // ...............*...
        // gap                                   // ...................
        str q2, [x0, #-16]                       // ..................*

        // original source code
        // ldr q0, [x1, #0]                       // e.................|e.................
        // ldr q8,  [x0]                          // ...*..............|...*..............
        // ldr q9,  [x0, #1*16]                   // .....e............|.....e............
        // ldr q10, [x0, #2*16]                   // ..*...............|..*...............
        // ldr q11, [x0, #3*16]                   // .e................|.e................
        // mul v24.8h, v9.8h, v0.h[0]             // ..................*..................
        // sqrdmulh v9.8h, v9.8h, v0.h[1]         // ........e.........|........e.........
        // mls v24.8h, v9.8h, v1.h[0]             // ....*.............|....*.............
        // sub     v9.8h,    v8.8h, v24.8h        // ..........*.......|..........*.......
        // add     v8.8h,    v8.8h, v24.8h        // ...........*......|...........*......
        // mul v24.8h, v11.8h, v0.h[0]            // ............e.....|............e.....
        // sqrdmulh v11.8h, v11.8h, v0.h[1]       // ......e...........|......e...........
        // mls v24.8h, v11.8h, v1.h[0]            // ...............e..|...............e..
        // sub     v11.8h,    v10.8h, v24.8h      // .......*..........|.......*..........
        // add     v10.8h,    v10.8h, v24.8h      // .........*........|.........*........
        // str q8,  [x0], #4*16                   // ................*.|................*.
        // str q9,  [x0, #-3*16]                  // .............*....|.............*....
        // str q10, [x0, #-2*16]                  // ..............*...|..............*...
        // str q11, [x0, #-1*16]                  // .................*|.................*

        sub count, count, #1
        cbnz count, start
        mul v12.8H, v0.8H, v11.H[0]        // *...........
        ldr q13, [x0, #32]                 // .*..........
        // gap                             // ............
        ldr q14, [x0]                      // ..*.........
        // gap                             // ............
        // gap                             // ............
        mls v12.8H, v27.8H, v1.H[0]        // ...*........
        // gap                             // ............
        // gap                             // ............
        // gap                             // ............
        // gap                             // ............
        // gap                             // ............
        sub v24.8H, v13.8H, v25.8H         // ....*.......
        // gap                             // ............
        // gap                             // ............
        add v25.8H, v13.8H, v25.8H         // .....*......
        // gap                             // ............
        // gap                             // ............
        // gap                             // ............
        // gap                             // ............
        // gap                             // ............
        sub v15.8H, v14.8H, v12.8H         // ......*.....
        add v6.8H, v14.8H, v12.8H          // .......*....
        str q24, [x0, #48]                 // ...........*
        str q25, [x0, #32]                 // .........*..
        // gap                             // ............
        // gap                             // ............
        // gap                             // ............
        // gap                             // ............
        // gap                             // ............
        str q15, [x0, #16]                 // ........*...
        str q6, [x0], #4*16                // ..........*.
        // gap                             // ............

        // original source code
        // mul v30.8H, v0.8H, v11.H[0]      // *...........
        // ldr q5, [x0, #32]                // .*..........
        // ldr q3, [x0]                     // ..*.........
        // mls v30.8H, v27.8H, v1.H[0]      // ...*........
        // sub v2.8H, v5.8H, v25.8H         // ....*.......
        // add v21.8H, v5.8H, v25.8H        // .....*......
        // sub v18.8H, v3.8H, v30.8H        // ......*.....
        // add v3.8H, v3.8H, v30.8H         // .......*....
        // str q18, [x0, #16]               // ..........*.
        // str q21, [x0, #32]               // .........*..
        // str q3, [x0], #4*16              // ...........*
        // str q2, [x0, #-16]               // ........*...