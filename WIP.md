Architecture
============

8 instructions

- `>`
- `<`
- `+`
- `-`
- `.`
- `,`
- `[`
- `]`

Registers:

- pc (usually incremented after work is done, special case for jumps?)
- op (current program memory content)
- address (modified by `>` and `<`)
- mem (value of current memory cell)
- seeking mode and direction
- matching braces counter

Memories:

- 256 bytes of program
- 256 bytes of tape

Busses:

- 8 bits address bus
- 8 bits data bus
- program/memory/[io] selector
- read/write flag (ignored for program)

## `>` and `<`

- route address to ALU
- incr/decrement
- store back to address

## `+` and `-`

- read value from memory
- route to ALU
- incr/decr
- write to memory

## `,`

- read from input
- write to memory

## `.`

- read from memory
- write to output

## `[]`

Complex stuff. Will probably involve setting the processor in a special mode that will seek pc forwards/backwards, counting opening and closing brackets until match. Uh.

- read op
- update matching counter
- incr/decr pc

## Processor cycles

Each processor cycle can comprise all these steps, and we'll ignore them for specific ops.

| OP | Read op | Read from memory or input | Incr/decr something | Write to memory or output | Incr/decr pc |
|:---|:--------|:--------------------------|:--------------------|:--------------------------|:-------------|
| >  | x       |                           | x                   |                           | x            |
| <  | x       |                           | x                   |                           | x            |
| +  | x       | x                         | x                   | x                         | x            |
| -  | x       | x                         | x                   | x                         | x            |
| .  | x       | x                         |                     | x                         | x            |
| ,  | x       | x                         |                     | x                         | x            |
| [  | x       |                           | x                   |                           | x            |
| ]  | x       |                           | x                   |                           | x            |
