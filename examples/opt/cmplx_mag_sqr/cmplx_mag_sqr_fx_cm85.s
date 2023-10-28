        .syntax unified
        .type   cmplx_mag_sqr_fx_opt_m85, %function
        .global cmplx_mag_sqr_fx_opt_m85

        .text
        .align 4
cmplx_mag_sqr_fx_opt_m85:
        push {r4-r12,lr}
        vpush {d0-d15}

        out   .req r0
        in    .req r1
        sz    .req r2

        qr   .req q0
        qi   .req q1
        qtmp .req q2
        qout .req q3

        lsr lr, sz, #2
        wls lr, lr, end
        vld20.32 {q0,q1}, [r1]          // *.....
        // gap                          // ......
        vld20.32 {q2,q3}, [r1]          // ..*...
        // gap                          // ......
        vld21.32 {q0,q1}, [r1]!         // .*....
        // gap                          // ......
        vld21.32 {q2,q3}, [r1]!         // ....*.
        // gap                          // ......
        vmulh.s32 q6, q0, q0            // ...*..
        // gap                          // ......
        vmulh.s32 q4, q1, q1            // .....*
        
        // original source code
        // vld20.32 {q0,q1}, [r1]       // *..... 
        // vld21.32 {q0,q1}, [r1]!      // ..*... 
        // vld20.32 {q2,q3}, [r1]       // .*.... 
        // vmulh.s32 q6, q0, q0         // ....*. 
        // vld21.32 {q2,q3}, [r1]!      // ...*.. 
        // vmulh.s32 q4, q1, q1         // .....* 
        
        lsr lr, lr, #1
        sub lr, lr, #1
.p2align 2
start:
        vld20.32 {q0,q1}, [r1]           // e...........
        vhadd.s32 q4, q4, q6             // ....*.......
        vstrw.u32 q4, [r0] , #16         // .....*......
        vmulh.s32 q4, q2, q2             // ........*...
        vld21.32 {q0,q1}, [r1]!          // .e..........
        vmulh.s32 q6, q3, q3             // .........*..
        vld20.32 {q2,q3}, [r1]           // ......e.....
        vhadd.s32 q4, q6, q4             // ..........*.
        vmulh.s32 q6, q0, q0             // ..e.........
        vstrw.u32 q4, [r0] , #16         // ...........*
        vld21.32 {q2,q3}, [r1]!          // .......e....
        vmulh.s32 q4, q1, q1             // ...e........
        
        // original source code
        // vld20.32 {q0,q1}, [r1]        // e..................... 
        // vld21.32 {q0,q1}, [r1]!       // ....e................. 
        // vmulh.s32 q2, q0, q0          // ........e............. 
        // vmulh.s32 q3, q1, q1          // ...........e.......... 
        // vhadd.s32 q3, q3, q2          // .............*........ 
        // vstrw.u32 q3, [r0] , #16      // ..............*....... 
        // vld20.32 {q0,q1}, [r1]        // ......e............... 
        // vld21.32 {q0,q1}, [r1]!       // ..........e........... 
        // vmulh.s32 q2, q0, q0          // ...............*...... 
        // vmulh.s32 q3, q1, q1          // .................*.... 
        // vhadd.s32 q3, q3, q2          // ...................*.. 
        // vstrw.u32 q3, [r0] , #16      // .....................* 
        
        le lr, start
        vmulh.s32 q0, q2, q2             // ..*...
        vhadd.s32 q4, q4, q6             // *.....
        vmulh.s32 q6, q3, q3             // ...*..
        vstrw.u32 q4, [r0] , #16         // .*....
        vhadd.s32 q4, q6, q0             // ....*.
        vstrw.u32 q4, [r0] , #16         // .....*
        
        // original source code
        // vhadd.s32 q4, q4, q6          // .*.... 
        // vstrw.u32 q4, [r0] , #16      // ...*.. 
        // vmulh.s32 q4, q2, q2          // *..... 
        // vmulh.s32 q6, q3, q3          // ..*... 
        // vhadd.s32 q4, q6, q4          // ....*. 
        // vstrw.u32 q4, [r0] , #16      // .....* 
        
end:

        vpop {d0-d15}
        pop {r4-r12,lr}

        bx lr