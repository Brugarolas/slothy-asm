# SLOTHY

## Introduction & Overview

This tutorial covers using the superoptimizer SLOTHY for optimizing assembly programs for a specific microarchitecture.
It goes beyond what it is written in the README in that it gives more examples on how we (the developers of SLOTHY) are commonly using SLOTHY to optimize cryptographic code.
This should get you familiar with the workflow and a number of common ways to debug or improve your results.

SLOTHY is a fixed instruction superoptimizer. That means that the input to the program is assembly and the output is semantically-equivalent optimized assembly. In particular, SLOTHY performs three main jobs:
1) (Re-)schedule instructions to hide latencies and improve utilization of all execution units
2) Rename registers in case this results in a better scheduling
3) Perform software pipelining (aka periodic loop interleaving). We will cover software pipelining in more depth later in this tutorial. 

SLOTHY performs these jobs by first transforming the input assembly into a data-flow graph (DFG) modelling the dependencies between all instructions. 
The goal of SLOTHY is to find a traversal of the DFG (and register allocation) that results in the least number of pipeline stalls.
A traversal of the graph is basically assigning each instruction an index at which the instruction will be in the output.
SLOTHY does so by turning the graph together with information about the microarchitecture into constraints that are fed into a generic constraint solver. We have been using Google OR-tools, but it can be replaced easily.
Modelling the graph itself as constraints is straightforward: Each instruction depending on data from another instruction has to be after said instruction.
The microarchitecture is modelled in terms of latencies, throughput, forwarding paths, and the number of execution units able to execute certain instructions.
Lastly, constraints are added that a register allocation must exist with the number of architectural registers available.

Note that SLOTHY does not change instructions itself, i.e., instruction selection is left to the developer.
For cryptographic code -- which is what SLOTHY was developed for -- instructions selection is a core focus of research and highly-optimized instruction sequences implementing a cryptographic (sub-)routine usually exist. 

**High-assurance cryptography**: While formal verification is not part of the SLOTHY tool as of now, we do see potential for combining formal verification tools with SLOTHY. Right now, SLOTHY checks that the output is correct through a simple selfcheck: 
SLOTHY transform the output code back into a DFG and checks that this graph is isomorphic to the input graph.
Since all operations optimizations performed by SLOTHY (except for software pipelining) should not change the (isomorphism class of the) DFG, this selfcheck is mostly intended for finding bugs in SLOTHY. 


Content of this tutorial:
1) Installation. This is limited to the fastest way of installing SLOTHY using pip. For more compete instructions, see the README.
2) Getting started
3) Using SLOTHY for your own code
4) Using SLOTHY's Software Pipelining
5) Optimizing a full Neon NTT
6) Visualising SLOTHY optimizations
7) Optimizing larger pieces of code
8) Adding a new microarchitecture


## 1. Installation

SLOTHY requires python3 (>= 3.10).
The easiest way to install the dependencies of SLOTHY is using pip.
It's advised to make use of [virtual environment](https://docs.python.org/3/library/venv.html).

The following steps should get you started:

```
git clone https://github.com/slothy-optimizer/slothy
cd slothy
# setup venv
python3 -m venv venv
source venv/bin/activate
# install dependencies
pip install -r requirements.txt
```

You can try to run SLOTHY on one of the examples that come with SLOTHY to make sure it runs without errors:
```
python3 example.py --examples simple0
```

We will look into more examples shortly and discuss input, output, and available flags.

## 2. Getting Started

The simplest way to get started using SLOTHY is by trying out some of the examples that come with SLOTHY.
Once you work on your own code, you will likely be using the `slothy-cli` command or calling the SLOTHY module from your own Python script for invoking SLOTHY allowing you to control all the different options SLOTHY has. 
However, for now we will be using the `example.py` script and containing a number of examples including the ones we have optimized in the SLOTHY paper.
You can run `python3 example.py --help` to see all examples available. 

Let's look at a very simple example from the previous section called `aarch64_simple0`.
You can find the corresponding code in `examples/naive/aarch64/aarch64_simple0.s`:
```
ldr q0, [x1, #0]

ldr q8,  [x0]
ldr q9,  [x0, #1*16]
ldr q10, [x0, #2*16]
ldr q11, [x0, #3*16]

mul v24.8h, v9.8h, v0.h[0]
sqrdmulh v9.8h, v9.8h, v0.h[1]
mls v24.8h, v9.8h, v1.h[0]
sub     v9.8h,    v8.8h, v24.8h
add     v8.8h,    v8.8h, v24.8h

mul v24.8h, v11.8h, v0.h[0]
sqrdmulh v11.8h, v11.8h, v0.h[1]
mls v24.8h, v11.8h, v1.h[0]
sub     v11.8h,    v10.8h, v24.8h
add     v10.8h,    v10.8h, v24.8h

str q8,  [x0], #4*16
str q9,  [x0, #-3*16]
str q10, [x0, #-2*16]
str q11, [x0, #-1*16]
```

It contains a straight-line piece of assembly for the Armv8-A architecture. This architecture implements the Neon vector instruction extension and all the instructions in this example are Neon vector instructions.
If you have never written Neon assembly before, you do not have to worry about it at this point. 
All you need to know about the code is that it loads some vectors from memory, performs some arithmetic operations, and writes back the result to memory. 
Note that there is two independent streams of computation on the four vectors loaded from memory, and, hence, there is quite some possibilities to re-order this code without affecting its semantics.
This code is able to run on a variety of different microarchitectures, ranging from low-end energy efficient in-order cores like the Arm Cortex-A55 to high-end out-of-order CPUs with very complex pipelines like the Apple M1 or Arm Neoverse server CPUs.
For the in-order cores, the instruction scheduling plays the most essential role as poorly scheduled code is very likely to have terrible performance, and hence, we will focus on the Cortex-A55 architecture in the following.
Note, however, that SLOTHY has been used to also obtain significant speed-ups for out-of-order cores.

SLOTHY already includes models for the Arm Cortex-A55 microarchitecture, so we can now optimize this piece of code for that microarchitecture.
`example.py` contains the needed SLOTHY incarnations for convenience, so we can simply run `python3 example.py --examples aarch64_simple0_a55` which will optimize for the Cortex-A55 microarchitecture. You can check `example.py` for the details. 
This will optimize the piece of code above and write the output code to `examples/opt/aarch64/aarch64_simple0_opt_a55.s`. 
SLOTHY should print something similar to this:
```
INFO:aarch64_simple0_a55:Instructions in body: 19
INFO:aarch64_simple0_a55.slothy:Perform internal binary search for minimal number of stalls...
INFO:aarch64_simple0_a55.slothy:Attempt optimization with max 32 stalls...
INFO:aarch64_simple0_a55.slothy:Objective: minimize number of stalls
INFO:aarch64_simple0_a55.slothy:Invoking external constraint solver (OR-Tools CP-SAT v9.7.2996) ...
INFO:aarch64_simple0_a55.slothy:[0.0659s]: Found 1 solutions so far... objective 17.0, bound 11.0 (minimize number of stalls)
INFO:aarch64_simple0_a55.slothy:[0.0805s]: Found 2 solutions so far... objective 16.0, bound 11.0 (minimize number of stalls)
INFO:aarch64_simple0_a55.slothy:OPTIMAL, wall time: 0.158787 s
INFO:aarch64_simple0_a55.slothy:Booleans in result: 424
INFO:aarch64_simple0_a55.slothy.selfcheck:OK!
INFO:aarch64_simple0_a55.slothy:Minimum number of stalls: 16
```

You can follow the steps SLOTHY performs and see the calls the constraint solver trying to find a re-scheduling of this code containing at most 32 stalls (a default starting point we have set here to speed up the example).
At the same time it is trying to minimize the number of stalls. This is past as an objective to the constraint solver (OR-tools) which tries to find a solution with the minimum number of stalls.
The best solution it can find has 16 stalls -- which is guaranteed to be the minimum number of stalls given this piece of code and the model of the microarchitecture in SLOTHY.
In the last step, SLOTHY will transform the found traversal of the DFG into actual assembly and write it to the file. 
To make sure everything worked out as expected, it will perform a selfcheck which consists of transforming the output assembly into a DFG again and testing that the resulting graph is isomorphic to the input DFG.

We can now take a look at the output assembly in `examples/opt/aarch64/aarch64_simple0_opt_a55.s`:
```
ldr q8, [x1, #0]                       // *..................
// gap                                 // ...................
// gap                                 // ...................
// gap                                 // ...................
ldr q29, [x0, #16]                     // ..*................
// gap                                 // ...................
// gap                                 // ...................
// gap                                 // ...................
ldr q26, [x0, #48]                     // ....*..............
// gap                                 // ...................
// gap                                 // ...................
// gap                                 // ...................
mul v10.8H, v29.8H, v8.H[0]            // .....*.............
// gap                                 // ...................
sqrdmulh v4.8H, v29.8H, v8.H[1]        // ......*............
// gap                                 // ...................
mul v25.8H, v26.8H, v8.H[0]            // ..........*........
// gap                                 // ...................
ldr q29, [x0]                          // .*.................
// gap                                 // ...................
// gap                                 // ...................
// gap                                 // ...................
mls v10.8H, v4.8H, v1.H[0]             // .......*...........
// gap                                 // ...................
sqrdmulh v3.8H, v26.8H, v8.H[1]        // ...........*.......
// gap                                 // ...................
ldr q4, [x0, #32]                      // ...*...............
// gap                                 // ...................
// gap                                 // ...................
// gap                                 // ...................
sub v26.8H, v29.8H, v10.8H             // ........*..........
// gap                                 // ...................
mls v25.8H, v3.8H, v1.H[0]             // ............*......
// gap                                 // ...................
add v2.8H, v29.8H, v10.8H              // .........*.........
// gap                                 // ...................
str q26, [x0, #16]                     // ................*..
// gap                                 // ...................
// gap                                 // ...................
// gap                                 // ...................
add v10.8H, v4.8H, v25.8H              // ..............*....
// gap                                 // ...................
str q2, [x0], #4*16                    // ...............*...
// gap                                 // ...................
sub v5.8H, v4.8H, v25.8H               // .............*.....
// gap                                 // ...................
str q10, [x0, #-32]                    // .................*.
// gap                                 // ...................
// gap                                 // ...................
// gap                                 // ...................
str q5, [x0, #-16]                     // ..................*
// gap                                 // ...................

// original source code
// ldr q0, [x1, #0]                       // *..................
// ldr q8,  [x0]                          // ......*............
// ldr q9,  [x0, #1*16]                   // .*.................
// ldr q10, [x0, #2*16]                   // .........*.........
// ldr q11, [x0, #3*16]                   // ..*................
// mul v24.8h, v9.8h, v0.h[0]             // ...*...............
// sqrdmulh v9.8h, v9.8h, v0.h[1]         // ....*..............
// mls v24.8h, v9.8h, v1.h[0]             // .......*...........
// sub     v9.8h,    v8.8h, v24.8h        // ..........*........
// add     v8.8h,    v8.8h, v24.8h        // ............*......
// mul v24.8h, v11.8h, v0.h[0]            // .....*.............
// sqrdmulh v11.8h, v11.8h, v0.h[1]       // ........*..........
// mls v24.8h, v11.8h, v1.h[0]            // ...........*.......
// sub     v11.8h,    v10.8h, v24.8h      // ................*..
// add     v10.8h,    v10.8h, v24.8h      // ..............*....
// str q8,  [x0], #4*16                   // ...............*...
// str q9,  [x0, #-3*16]                  // .............*.....
// str q10, [x0, #-2*16]                  // .................*.
// str q11, [x0, #-1*16]                  // ..................*

```

At the top you can see the re-scheduled assembly and at the bottom you find the original source code as a comment. 
As comments next to the two sections, you can also see a visual representation on how these instructions have been rescheduled.
You can see that various instructions have been moved around to achieve fewer stalls. 
In the scheduled code, you can `// gap` where SLOTHY would expect a `gap` given the current model.
Note that this does not equal a pipeline stall in the sense of a wasted cycle, but rather in an issue slot of the CPU that was not used.
The Cortex-A55 is a dual-issue CPU meaning in ideal circumstances 2 instructions can be issued per cycle.
However, the Neon pipeline can only issue a single (128-bit/q-form) Neon instruction per cycle.
Since our code only consists of (128-bit/q-form) Neon instructions, the best we can hope for is a single `gap` after each instruction.
To make use of these issue slots one would have to mix in scalar instructions (or use 64-bit (d-form) Neon instructions).

Also note the registers used: In the original code `v24` was as a temporary register in both computation streams preventing to effectively interleave them.
SLOTHY renamed those registers to be able to interleave both computations. Other registers have also been arbitrarily renamed, but without any specific reason.
Even with this small Neon example, you can see that understanding the input code is much easier than the output code which is the reason why we believe SLOTHY can help with writing auditable code.

## 3. Writing your own calling code

When writing your own calls to SLOTHY, there are generally two options:
(1) Using SLOTHY as a Python module, or (2) using `slothy-cli` using command line options. We will continue with (1) to demonstrate some features. 
To reproduce the example above, you can place the following code into your own Python script in the root directory of SLOTHY:

```
import logging
import sys

from slothy import Slothy

import slothy.targets.aarch64.aarch64_neon as AArch64_Neon
import slothy.targets.aarch64.cortex_a55 as Target_CortexA55

logging.basicConfig(stream=sys.stdout, level=logging.INFO)

arch = AArch64_Neon
target = Target_CortexA55

slothy = Slothy(arch, target)

# example
slothy.load_source_from_file("examples/naive/aarch64/aarch64_simple0.s")
slothy.config.variable_size=True
slothy.config.constraints.stalls_first_attempt=32

slothy.optimize()
slothy.write_source_to_file("examples/opt/aarch64/aarch64_simple0_a55.s")
```

You will need to pass to SLOTHY both the architecture model (containing the instruction mnemonics and which registers are input and outputs for each instruction) and the microarchitectual model (containing latencies, throughputs, execution units, etc.).
In this case, we use the AArch64+Neon architecture model and the Arm Cortex-A55 microarchitecture model that come with SLOTHY.

The calls to SLOTHY should be self-explanatory:
 - `load_source_from_file` loads an assembly file to be optimized
 - `slothy.config` can be used to configure SLOTHY. For the documentation of the configuration options, see the comments in [config.py](./slothy/core/config.py).
 - `optimize` performs the actual optimizations by calling the external constraint solver
 - `write_source_to_file` writes back the optimized assembly to a file

Setting `slothy.config.variable_size` results in the number of stalls being a parameter of the model and the constraint solver is trying to minimize.
One still has to pass a maximum number of stalls to the constraint solver. By default, SLOTHY starts with 0 stalls as a maximum and then exponentially increases it if no solution could be found.
To speed this process up one can set a `stalls_first_attempt` to a reasonable number.
The `variable_size` may not perform well for large examples. The default strategy (`variable_size=False`) is, hence, to pass a fixed number of allowed stalls to the constraint solver and performing a binary search to find the minimum number of stalls for which a solution exists.

## 4. Software Pipelining

One of the most powerful features of SLOTHY is software pipelining (also known as periodic loop interleaving).
The core idea of software pipelining is that even though the body of a loop itself may not have a stall-free scheduling, it may still be possible to eliminate more stalls when moving some instructions to earlier or later iterations of the loop. 
Note that this does not mean that the loop has to be unrolled -- by maintaining the periodicity of the code, it is possible to keep the code within a loop resulting in compact code size. Only the first and last iteration may require to be treated separately.

Let's look at an example demonstrating how SLOTHY can perform software pipelining for you.
Consider the simple case of performing the code from the previous example within a loop. This is exactly what the `aarch64_simple0_loop` example in SLOTHY does:
```
count .req x2

mov count, #16

start:
    ldr q0, [x1, #0]

    ldr q8,  [x0]
    ldr q9,  [x0, #1*16]
    ldr q10, [x0, #2*16]
    ldr q11, [x0, #3*16]

    mul v24.8h, v9.8h, v0.h[0]
    sqrdmulh v9.8h, v9.8h, v0.h[1]
    mls v24.8h, v9.8h, v1.h[0]
    sub     v9.8h,    v8.8h, v24.8h
    add     v8.8h,    v8.8h, v24.8h

    mul v24.8h, v11.8h, v0.h[0]
    sqrdmulh v11.8h, v11.8h, v0.h[1]
    mls v24.8h, v11.8h, v1.h[0]
    sub     v11.8h,    v10.8h, v24.8h
    add     v10.8h,    v10.8h, v24.8h

    str q8,  [x0], #4*16
    str q9,  [x0, #-3*16]
    str q10, [x0, #-2*16]
    str q11, [x0, #-1*16]

    subs count, count, #1
    cbnz count, start

```

Let's use SLOTHY to superoptimize this loop:
```
slothy.load_source_from_file("examples/naive/aarch64/aarch64_simple0_loop.s")
slothy.config.variable_size=True
slothy.config.constraints.stalls_first_attempt=32

slothy.config.sw_pipelining.enabled = True
slothy.optimize_loop("start")
slothy.write_source_to_file("examples/opt/aarch64/aarch64_simple0_loop_a55.s")
```

Software pipelining needs to be enabled by setting `slothy.config.sw_pipelining.enabled = True`.
We also need to specifically tell SLOTHY that we would like to optimize the loop starting at `start` -- SLOTHY will automatically detect that the loop ends at `cbnz count, start`. 
The produced output will look like this:

```
count .req x2

mov count, #16

        ldr q14, [x0, #16]        // *.
        // gap                    // ..
        // gap                    // ..
        // gap                    // ..
        ldr q6, [x1, #0]          // .*
        // gap                    // ..

        // original source code
        // ldr q14, [x0, #16]      // *.
        // ldr q6, [x1, #0]        // .*

        sub count, count, #1
start:
        ldr q23, [x0, #48]                      // ....*..............
        // gap                                  // ...................
        // gap                                  // ...................
        // gap                                  // ...................
        mul v11.8H, v14.8H, v6.H[0]             // .....*.............
        // gap                                  // ...................
        sqrdmulh v21.8H, v14.8H, v6.H[1]        // ......*............
        // gap                                  // ...................
        mul v16.8H, v23.8H, v6.H[0]             // ..........*........
        // gap                                  // ...................
        sqrdmulh v29.8H, v23.8H, v6.H[1]        // ...........*.......
        // gap                                  // ...................
        ldr q4, [x0]                            // .*.................
        // gap                                  // ...................
        // gap                                  // ...................
        // gap                                  // ...................
        mls v11.8H, v21.8H, v1.H[0]             // .......*...........
        // gap                                  // ...................
        ldr q13, [x0, #32]                      // ...*...............
        // gap                                  // ...................
        // gap                                  // ...................
        // gap                                  // ...................
        mls v16.8H, v29.8H, v1.H[0]             // ............*......
        // gap                                  // ...................
        sub v23.8H, v4.8H, v11.8H               // ........*..........
        // gap                                  // ...................
        add v22.8H, v4.8H, v11.8H               // .........*.........
        // gap                                  // ...................
        ldr q14, [x0, #80]                      // ..e................
        // gap                                  // ...................
        // gap                                  // ...................
        // gap                                  // ...................
        str q23, [x0, #16]                      // ................*..
        // gap                                  // ...................
        add v29.8H, v13.8H, v16.8H              // ..............*....
        // gap                                  // ...................
        str q22, [x0], #4*16                    // ...............*...
        // gap                                  // ...................
        sub v5.8H, v13.8H, v16.8H               // .............*.....
        // gap                                  // ...................
        str q29, [x0, #-32]                     // .................*.
        // gap                                  // ...................
        ldr q6, [x1, #0]                        // e..................
        // gap                                  // ...................
        // gap                                  // ...................
        // gap                                  // ...................
        str q5, [x0, #-16]                      // ..................*
        // gap                                  // ...................

        // original source code
        // ldr q0, [x1, #0]                       // ......e.|................e.
        // ldr q8,  [x0]                          // ........|....*.............
        // ldr q9,  [x0, #1*16]                   // e.......|..........e.......
        // ldr q10, [x0, #2*16]                   // ........|......*...........
        // ldr q11, [x0, #3*16]                   // ........*..................
        // mul v24.8h, v9.8h, v0.h[0]             // ........|*.................
        // sqrdmulh v9.8h, v9.8h, v0.h[1]         // ........|.*................
        // mls v24.8h, v9.8h, v1.h[0]             // ........|.....*............
        // sub     v9.8h,    v8.8h, v24.8h        // ........|........*.........
        // add     v8.8h,    v8.8h, v24.8h        // ........|.........*........
        // mul v24.8h, v11.8h, v0.h[0]            // ........|..*...............
        // sqrdmulh v11.8h, v11.8h, v0.h[1]       // ........|...*..............
        // mls v24.8h, v11.8h, v1.h[0]            // ........|.......*..........
        // sub     v11.8h,    v10.8h, v24.8h      // ....*...|..............*...
        // add     v10.8h,    v10.8h, v24.8h      // ..*.....|............*.....
        // str q8,  [x0], #4*16                   // ...*....|.............*....
        // str q9,  [x0, #-3*16]                  // .*......|...........*......
        // str q10, [x0, #-2*16]                  // .....*..|...............*..
        // str q11, [x0, #-1*16]                  // .......*|.................*

        sub count, count, #1
        cbnz count, start
        ldr q5, [x0, #48]                       // *................
        // gap                                  // .................
        // gap                                  // .................
        // gap                                  // .................
        sqrdmulh v23.8H, v14.8H, v6.H[1]        // ..*..............
        // gap                                  // .................
        mul v25.8H, v14.8H, v6.H[0]             // .*...............
        // gap                                  // .................
        mul v22.8H, v5.8H, v6.H[0]              // ...*.............
        // gap                                  // .................
        sqrdmulh v6.8H, v5.8H, v6.H[1]          // ....*............
        // gap                                  // .................
        ldr q15, [x0]                           // .....*...........
        // gap                                  // .................
        // gap                                  // .................
        // gap                                  // .................
        mls v25.8H, v23.8H, v1.H[0]             // ......*..........
        // gap                                  // .................
        mls v22.8H, v6.8H, v1.H[0]              // ........*........
        // gap                                  // .................
        ldr q11, [x0, #32]                      // .......*.........
        // gap                                  // .................
        // gap                                  // .................
        // gap                                  // .................
        sub v5.8H, v15.8H, v25.8H               // .........*.......
        // gap                                  // .................
        // gap                                  // .................
        // gap                                  // .................
        add v29.8H, v11.8H, v22.8H              // ............*....
        // gap                                  // .................
        str q5, [x0, #16]                       // ...........*.....
        // gap                                  // .................
        sub v5.8H, v11.8H, v22.8H               // ..............*..
        // gap                                  // .................
        str q29, [x0, #32]                      // ...............*.
        // gap                                  // .................
        add v29.8H, v15.8H, v25.8H              // ..........*......
        // gap                                  // .................
        str q5, [x0, #48]                       // ................*
        // gap                                  // .................
        // gap                                  // .................
        // gap                                  // .................
        str q29, [x0], #4*16                    // .............*...
        // gap                                  // .................

        // original source code
        // ldr q23, [x0, #48]                    // *................
        // mul v11.8H, v14.8H, v6.H[0]           // ..*..............
        // sqrdmulh v21.8H, v14.8H, v6.H[1]      // .*...............
        // mul v16.8H, v23.8H, v6.H[0]           // ...*.............
        // sqrdmulh v29.8H, v23.8H, v6.H[1]      // ....*............
        // ldr q4, [x0]                          // .....*...........
        // mls v11.8H, v21.8H, v1.H[0]           // ......*..........
        // ldr q13, [x0, #32]                    // ........*........
        // mls v16.8H, v29.8H, v1.H[0]           // .......*.........
        // sub v23.8H, v4.8H, v11.8H             // .........*.......
        // add v22.8H, v4.8H, v11.8H             // ..............*..
        // str q23, [x0, #16]                    // ...........*.....
        // add v29.8H, v13.8H, v16.8H            // ..........*......
        // str q22, [x0], #4*16                  // ................*
        // sub v5.8H, v13.8H, v16.8H             // ............*....
        // str q29, [x0, #-32]                   // .............*...
        // str q5, [x0, #-16]                    // ...............*.

```

Let's start by looking at the loop body going from `start:` to `cbnz count, start`.
We see that the loop now has 4 blocks of 3 `gap`s meaning that there are 4 1-cycle stalls. This compares to 7 stalls in the version without software pipelining.
We see that 2 instructions are marked as early (e) instructions meaning they are merged into the previous iteration. 
For the code to still be correct, SLOTHY decreases the number of iterations by one (`sub count, count, #1`), adds the missing early-instructions for the first iteration before the loop, and finally adds the non-early instructions of the last iteration after the loop.
Also note that addresses have been adjusted accordingly.

## 5. Optimizing a full Neon NTT

The examples previously considered were all toy examples, so you may wonder how to apply SLOTHY to actual cryptographic code.
Let's look at a real-world example: The Kyber number-theoretic transform -- a core arithmetic function of the Kyber key-encapsulation mechanism making up a large chunk of the total run-time.
The target platform is again the Arm Cortex-M55 and the code primarily consists of Helium instructions.
We'll consider a straightforward implementation available here: [ntt_kyber_123_4567.s](./examples/naive/aarch64/ntt_kyber_123_4567.s). 
If you have ever written an NTT, it should be fairly easy to understand what the code is doing. 
The code consists of 2 main loops implementing layers 1+2+3 and 4+5+6+7 of the NTT.
The actual operations are wrapped in macros implementing butterflies on single vector registers. 
Note that this code performs very poorly: It does not consideration was given to the intricacies of the microarchitecture.

Let's run SLOTHY on this code:
```
slothy.load_source_from_file("examples/naive/aarch64/ntt_kyber_123_4567.s")
slothy.config.sw_pipelining.enabled = True
slothy.config.inputs_are_outputs = True
slothy.config.sw_pipelining.minimize_overlapping = False
slothy.config.variable_size = True
slothy.config.reserved_regs = [f"x{i}" for i in range(0, 7)] + ["x30", "sp"]
slothy.config.constraints.stalls_first_attempt = 64
slothy.optimize_loop("layer123_start")
slothy.optimize_loop("layer4567_start")
slothy.write_source_to_file("examples/opt/aarch64/ntt_kyber_123_4567_opt_a55.s")
```

We simply optimize both loops separately.
You will notice some additional flags we have set. To read the documentation of those, please have a look at [config.py](./slothy/core/config.py).
We have set an additional flag: `inputs_are_outputs = True`. This is required to tell SLOTHY that the registers that are used as inputs to the loop (e.g., the pointer to the polynomial input) are also outputs of the loop, otherwise SLOTHY may re-use those registers for something else once they are no longer needed.
This is commonly needed when optimizing loops.
We also use the `reserved_regs` option to tell SLOTHY that registers `x0, ..., x7, x30, sp` are used for other purposes and should not be used by SLOTHY. When optimizing only parts of a function, it is essential to tell SLOTHY which registers should not be used. By default SLOTHY will use any of the architectural registers.


When running this example, you will notice that it has a significantly longer runtime. 
On my Intel i7-1360P it takes approximately 15 minutes to optimize both loops.
You may instead look at an optimized version of the same code [ntt_kyber_123_4567_opt_a55.s](examples/opt/aarch64/ntt_kyber_123_4567_opt_a55.s).
You notice that both loops have many early instructions, and coming up with this code by hand seems nearly impossible.

## 6. Visualizing SLOTHY optimizations


## 7. Optimizing larger pieces of code


## 8. Adding a new microarchitecture

You may wonder how to extend SLOTHY to include a new microarchitecture.
For example, you may want to optimize code for a newer iteration of the Arm Cortex-A55, e.g., the Arm Cortex-A510.
To understand what is needed for that, let's look at the microarchitectural model for the Cortex-A55 available in [../slothy/targets/aarch64/cortex_a55.py](../slothy/targets/aarch64/cortex_a55.py). 

Skipping some boilerplate code, you will see the following structure:
```
from slothy.targets.aarch64.aarch64_neon import *

issue_rate = 2
class ExecutionUnit(Enum):
    """Enumeration of execution units in Cortex-A55 model"""
    SCALAR_ALU0=1
    SCALAR_ALU1=2
    SCALAR_MAC=3
    SCALAR_LOAD=4
    SCALAR_STORE=5
    VEC0=6
    VEC1=7
    # ...
    
execution_units = {
        // ... 
}

inverse_throughput = {
        // ...
}

default_latencies = {
        // ...
}


def get_latency(src, out_idx, dst):
    // ...
    latency = lookup_multidict(
        default_latencies, src)
    // ...
    return latency

def get_units(src):
    units = lookup_multidict(execution_units, src)
    if isinstance(units,list):
        return units
    return [units]

def get_inverse_throughput(src):
    return lookup_multidict(
        inverse_throughput, src)
```

Going through the snippet, we can see the core components:
 - Definition of the `issue_rate` corresponding to the number of issue slots available per cycle. Since the Cortex-A55 is a dual-issue CPU, this is 2
 - Definition of an `Enum` modelling the different execution units available. In this case, we model 2 scalar units, one MAC unit, 2 vector units, one load unit, and one store unit.
 - Finally, we need to implement the functions `get_latency`, `get_units`, `get_inverse_throughput` returning the latency, occupied execution units, and throughputs. The input to these functions is a class from the architectural model representing the instruction in question. For example, the class `vmull` in [](../slothy/targets/aarch64/aarch64_neon.py) corresponds to the `umull` instruction. We commonly implement this using dictionaries above.

For example, for the `vmull` instruction, we can find in the Arm Cortex-A55 SWOG, that it occupies both vector execution units, has an inverse throughput of 1, and a latency of 4 cycles. We can model this in the following way: 

```
execution_units = {
    ( vmull ): [[ExecutionUnit.VEC0, ExecutionUnit.VEC1]], 
}

inverse_throughput = {
    ( vmull ) : 1,
}

default_latencies = {
    ( vmull ) : 4,
}
```

We mostly use the tuple-syntax, so we can group together instructions that belong together.
For example, later we may want to add the Neon`add`. From the SWOG we can see that (128-bit) `add` occupies both vector execution units, has a latency of 3 cycles, and throughput of 1 cycle.
We can extend the above model as follows:

```
execution_units = {
    ( vmull, vadd ): [[ExecutionUnit.VEC0, ExecutionUnit.VEC1]], 
}

inverse_throughput = {
    ( vmull, vadd ) : 1,
}

default_latencies = {
    ( vmull ) : 4,
    ( vadd ) : 3,
}
```


(When looking at the actual model, you will notice that this is not quite how it is modelled. You will see that for some instructions, we have to distinguish between the q-form (128-bit) and the d-form (64-bit) of the instruction. Q-form instructions occupy both vector execution units, while most D-form instructions occupy only 1. Latencies also vary depending on the actual for.)

Note that both the architectural model and the micro-architectural model can be built lazily: As long as the corresponding instruction do not appear in your input, you may leave out their description.
As soon as you hit an instruction that is not part of the architectural or micro-architectural model, you will see an error.


## Troubleshooting
- ModuleNotFoundError: No module named 'ortools'

This suggests that you have not installed the required dependencies needed by SLOTHY.
Either you need to follow the installation instructions, or if you have done that already, you likely forgot to enter the virtual environment you have installed them in using `source venv/bin/activate`. You will have to run this every time you open a new terminal.