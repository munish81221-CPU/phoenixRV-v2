\# PhoenixRV Module Interface Specification



\## 1. Common Modules



\### 1.1 `phx\_common\_mux2`



\### Purpose



`phx\_common\_mux2` is a parameterized 2:1 multiplexer used to

select one of two WIDTH-bit input buses.



\### Parameters



| Parameter | Default | Description                              |

|-----------|--------:|------------------------------------------|

| WIDTH     |      32 | Width of the input and output data buses |



\### Interface



| Signal | Direction | Width | Description       |

|--------|-----------|------:|-------------------|

| in0    | Input     | WIDTH | First input bus   |

| in1    | Input     | WIDTH | Second input bus  |

| sel    | Input     | 1     | Select signal     |

| out    | Output    | WIDTH | Selected output   |



\### RTL Behavior



When `sel = 0`, `out` follows `in0`.



When `sel = 1`, `out` follows `in1`.



The module is purely combinational and does not require a clock.



\### Verification



The module was verified using a self-checking testbench with

three functional test cases. All three tests passed.



Waveform inspection in GTKWave also confirmed correct MUX behavior.



\### 1.2 `phx\_common\_mux4`



\### Purpose



`phx\_common\_mux4` is a parameterized 4:1 multiplexer used to

select one of four WIDTH-bit input buses. It is constructed

hierarchically using three instances of `phx\_common\_mux2`.



\### Parameters



| Parameter | Default | Description                              |

|-----------|--------:|------------------------------------------|

| WIDTH     |      32 | Width of the input and output data buses |



\### Interface



| Signal | Direction | Width | Description       |

|--------|-----------|------:|-------------------|

| in0    | Input     | WIDTH | First input bus   |

| in1    | Input     | WIDTH | Second input bus  |

| in2    | Input     | WIDTH | Third input bus   |

| in3    | Input     | WIDTH | Fourth input bus  |

| sel    | Input     | 2     | Select signal     |

| out    | Output    | WIDTH | Selected output   |



\### RTL Behavior



When `sel = 2'b00`, `out` follows `in0`.



When `sel = 2'b01`, `out` follows `in1`.



When `sel = 2'b10`, `out` follows `in2`.



When `sel = 2'b11`, `out` follows `in3`.



The module is purely combinational and does not require a clock.



\### Verification



The module was verified using a self-checking testbench with

four functional selection cases. All four tests passed.



Waveform inspection in GTKWave also confirmed correct MUX behavior.











\### 1.3 `phx\_common\_adder`



\### Purpose



`phx\_common\_adder` is a parameterized binary adder based on a

parallel-prefix Kogge-Stone carry network. It computes the sum of

two WIDTH-bit operands with an input carry.



\### Parameters



| Parameter | Default | Description                         |

| --------- | ------: | ----------------------------------- |

| WIDTH     |      32 | Width of the input and output buses |



\### Interface



| Signal   | Direction | Width | Description     |

| -------- | --------- | ----: | --------------- |

| add\_in0  | Input     | WIDTH | First operand   |

| add\_in1  | Input     | WIDTH | Second operand  |

| cin      | Input     |     1 | Input carry     |

| sum      | Output    | WIDTH | Addition result |

| cout     | Output    |     1 | Output carry    |



\### RTL Behavior



The module computes the binary addition of `add\_in0`, `add\_in1`, and

`cin`.



The carry signals are calculated using a parallel-prefix Kogge-Stone

carry network.



The module is purely combinational and does not require a clock.



\### Verification



The module was verified using a self-checking testbench with five

directed test cases and 1000 random test vectors. All 1005 tests passed.



Waveform inspection in GTKWave also confirmed correct adder behavior.



\### 1.4 `phx\_common\_add\_sub`



\### Purpose



`phx\_common\_add\_sub` is a parameterized combinational arithmetic

module that performs addition or subtraction using a shared

Kogge-Stone adder.



\### Parameters



| Parameter | Default | Description                         |

| --------- | ------: | ----------------------------------- |

| WIDTH     |      32 | Width of the input and output buses |



\### Interface



| Signal  | Direction | Width | Description |

| ------- | --------- | ----: | ----------- |

| add\_in0 | Input     | WIDTH | First operand |

| add\_in1 | Input     | WIDTH | Second operand |

| sel     | Input     | 1 | Operation select |

| result  | Output    | WIDTH | Arithmetic result |

| cout    | Output    | 1 | Carry/borrow indication |



\### RTL Behavior



When `sel = 0`, the module performs:



`add\_in0 + add\_in1`



When `sel = 1`, the module performs subtraction using two's-complement

arithmetic:



`add\_in0 + \~add\_in1 + 1`



The module reuses `phx\_common\_adder` as the underlying Kogge-Stone

arithmetic engine.



The module is purely combinational and does not require a clock.



\### Verification



The module was verified using a self-checking testbench with nine

directed test cases and 1000 random test vectors. All 1009 tests passed.



Waveform inspection in GTKWave also confirmed correct addition,

subtraction, and carry/borrow behavior.



\### 1.5 `phx\_common\_comparator`



\### Purpose



`phx\_common\_comparator` is a parameterized combinational comparison

module used to compare two WIDTH-bit operands. It supports both

unsigned and signed comparison modes.



\### Parameters



| Parameter | Default | Description                         |

| --------- | ------: | ----------------------------------- |

| WIDTH     |      32 | Width of the input operand buses    |



\### Interface



| Signal      | Direction | Width | Description |

| ----------- | --------- | ----: | ----------- |

| add\_in0     | Input     | WIDTH | First operand |

| add\_in1     | Input     | WIDTH | Second operand |

| signed\_mode | Input     | 1 | Selects signed or unsigned comparison |

| eq          | Output    | 1 | Asserted when operands are equal |

| lt          | Output    | 1 | Asserted when add\_in0 is less than add\_in1 |

| gt          | Output    | 1 | Asserted when add\_in0 is greater than add\_in1 |



\### RTL Behavior



The module first determines bit-wise equality between the two

operands.



The comparison network evaluates the operands from the most

significant bit toward the least significant bit. The first

different bit determines the unsigned comparison result.



When `signed\_mode = 0`, the module performs unsigned comparison.



When `signed\_mode = 1`, the module performs signed two's-complement

comparison. The sign bits are evaluated first, while operands having

the same sign use the unsigned comparison ordering.



The module generates three mutually exclusive comparison outputs:



\- `eq = 1` when `add\_in0 == add\_in1`

\- `lt = 1` when `add\_in0 < add\_in1`

\- `gt = 1` when `add\_in0 > add\_in1`



The module is purely combinational and does not require a clock.



\### Verification



The module was verified using a self-checking testbench with

11 directed test cases and 1000 random test vectors covering both

signed and unsigned comparison modes. All 1011 tests passed.



Waveform inspection in GTKWave also confirmed correct equality,

less-than, greater-than, signed, and unsigned comparison behavior.



\### 1.6 `phx\_common\_shifter`



\### Purpose



`phx\_common\_shifter` is a parameterized combinational barrel shifter designed to perform logical left shift, logical right shift, and arithmetic right shift operations on a WIDTH-bit data bus.



The shifter uses a multi-stage barrel-shifter structure, where each stage can shift the data by a power-of-two distance.



\### Parameters



| Parameter | Default | Description |

| --------- | ------: | ----------- |

| WIDTH     |      32 | Width of the input and output data buses |



\### Interface



| Signal | Direction | Width | Description |

| ------ | --------- | ----: | ----------- |

| data\_in | Input | WIDTH | Input data to be shifted |

| shift\_amount | Input | `$clog2(WIDTH)` | Amount by which the input data is shifted |

| operation | Input | 2 | Selects the shift operation |

| shift\_out | Output | WIDTH | Shifted output data |



\### Operation Encoding



| `operation` | Operation | Description |

| ----------- | --------- | ----------- |

| `2'b00` | SLL | Shift Left Logical |

| `2'b01` | SRL | Shift Right Logical |

| `2'b10` | SRA | Shift Right Arithmetic |

| `2'b11` | Reserved | Reserved for future use |



\### RTL Behavior



The barrel-shifter network consists of `$clog2(WIDTH)` stages.



For the default `WIDTH = 32`, the five stages perform shifts of:



```text

Stage 0 → 1 bit

Stage 1 → 2 bits

Stage 2 → 4 bits

Stage 3 → 8 bits

Stage 4 → 16 bits

```



\### Verification



The module was verified using a self-checking testbench with directed

and random test cases.



The testbench verified all three supported operations:



\- SLL (Shift Left Logical)

\- SRL (Shift Right Logical)

\- SRA (Shift Right Arithmetic)



The verification also covered zero-shift operation, different shift

amounts, sign extension for arithmetic right shifts, and multi-stage

barrel-shifter operation.



A total of 515 test cases were executed, and all 515 tests passed with

zero failures.



Waveform inspection in GTKWave also confirmed correct shifter behavior

and verified the expected data propagation through the barrel-shifter

stages.



\### 1.7 `phx\_common\_signext`



\### Purpose



`phx\_common\_signext` is a parameterized combinational sign-extension module used to expand a smaller signed value to a larger datapath width while preserving its numerical value.



The module preserves the original input bits and fills the newly added upper bits with copies of the input sign bit (MSB).



\### Parameters



| Parameter | Default | Description |

| --------- | ------: | ----------- |

| IN\_WIDTH  |       8 | Width of the input data |

| OUT\_WIDTH |      32 | Width of the output data |



`IN\_WIDTH` must be less than or equal to `OUT\_WIDTH`.



\### Interface



| Signal | Direction | Width | Description |

| ------ | --------- | ----: | ----------- |

| data\_in | Input | IN\_WIDTH | Input signed value to be extended |

| data\_out | Output | OUT\_WIDTH | Sign-extended output value |



\### RTL Behavior



The module is purely combinational and does not require a clock.



The number of newly generated upper bits is:



```text

OUT\_WIDTH - IN\_WIDTH

```



\### verification



The module was verified using a self-checking testbench containing directed test cases across three parameterized configurations.



The verification covered:



\- 8 → 32-bit sign extension: 11 tests passed, 0 failed

\- 5 → 32-bit sign extension: 4 tests passed, 0 failed

\- 16 → 32-bit sign extension: 4 tests passed, 0 failed



A total of \*\*19 tests were executed, and all 19 tests passed with zero failures\*\*.



GTKWave waveform inspection was also completed successfully. The waveforms confirmed correct replication of the input MSB into the newly added upper bits and preservation of the original input bits for all tested parameterized configurations.



\### 1.8 `phx\_common\_mux`



\### Purpose



`phx\_common\_mux` is a parameterized combinational multiplexer used to select one data word from multiple input data words and forward the selected value to the output.



The module supports configurable data width and number of input channels.



\### Parameters



| Parameter | Default | Description |

| --------- | ------: | ----------- |

| WIDTH     |      32 | Width of each input and output data word |

| INPUTS    |       4 | Number of input data words |



For the default configuration, the module operates as a 4:1 multiplexer with 32-bit data inputs.



\### Interface



| Signal | Direction | Width | Description |

| ------ | --------- | ----: | ----------- |

| input\_data | Input | `WIDTH × INPUTS` | Array of input data words |

| sel | Input | `$clog2(INPUTS)` | Selects which input data word is forwarded |

| mux\_out | Output | `WIDTH` | Selected input data word |



\### Selection Behavior



For the default `INPUTS = 4` configuration:



| `sel` | Selected Input | `mux\_out` |

| ----- | -------------- | --------- |

| `2'b00` | `input\_data\[0]` | `input\_data\[0]` |

| `2'b01` | `input\_data\[1]` | `input\_data\[1]` |

| `2'b10` | `input\_data\[2]` | `input\_data\[2]` |

| `2'b11` | `input\_data\[3]` | `input\_data\[3]` |



\### RTL Behavior



The MUX is implemented using an indexed input array.



The selected input is directly assigned to the output:



```text

mux\_out = input\_data\[sel]

```

\### verification

in total 8 direct and 200 random test were applied and all passed succesfully . GTK wave outcone are verified succesfully and module if fully verified and tested.



\### 1.9 `phx\_common\_decoder`



\### Purpose



`phx\_common\_decoder` is a parameterized combinational decoder that converts an encoded binary input into a one-hot output.



For an `INPUT\_WIDTH`-bit input, the decoder generates `2^INPUT\_WIDTH` output lines. For each input combination, exactly one output line is asserted.



The module is designed as a reusable control-logic building block for PhoenixRV.



\### Parameters



| Parameter | Default | Description |

| --------- | ------: | ----------- |

| INPUT\_WIDTH | 2 | Width of the encoded input |



The number of decoder output lines is derived as:



```text

OUTPUTS = 2^INPUT\_WIDTH

```

\### interface

| Signal | Direction | Width | Description |

| ------ | --------- | ----: | ----------- |

| sel   | Input | `INPUT\_WIDTH` | Encoded input used to select the active output|

|decoder| output| `2^INPUT\_WIDTH` | one-hot decoded output|



\### RTL behaviour

\### RTL Behavior



`phx\_common\_decoder` is implemented as purely combinational logic using a left-shift operation.



The RTL starts with a single logic `1` and shifts it left by the value of `sel`:



```text

decoded = 1'b1 << sel

```

\### verification

The module was verified using a self-checking testbench with exhaustive directed testing.



The verification covered every possible input state for each parameterized configuration:



2 → 4 decoder: 4 tests

3 → 8 decoder: 8 tests

4 → 16 decoder: 16 tests



A total of 28 tests were executed, and all 28 tests passed with zero failures.



GTKWave waveform inspection was also completed successfully. The waveforms confirmed correct one-hot output generation for all tested input combinations and parameterized decoder configurations.



\### 1.10 `phx\_common\_priority\_encoder`



\### Purpose



`phx\_common\_priority\_encoder` is a parameterized combinational priority encoder that converts multiple input request lines into a binary encoded output.



The module assigns priority according to the input index, with the highest-numbered input having the highest priority.



If multiple input bits are active at the same time, only the highest-priority active input is encoded.



A `valid` output indicates whether any input is active.



\### Parameters



| Parameter | Default | Description |

| --------- | ------: | ----------- |

| INPUT | 8 | Number of input lines |



The encoded output width is derived using:



```text

$clog2(INPUT)

```

\### RTL Specification



`phx\_common\_priority\_encoder` is implemented as a purely combinational priority encoder.



The RTL uses a descending `for` loop to examine the input lines from the highest-priority index to the lowest-priority index.



For the default configuration:



```text

INPUT = 8

Priority order: 7 → 6 → 5 → 4 → 3 → 2 → 1 → 0

```





\### Verification



The module was verified using a self-checking testbench.



Verification included:



\- All-zero input condition

\- Individual activation of each input

\- Multiple simultaneously active inputs

\- Highest-priority input selection

\- Lowest-priority input selection

\- All inputs active

\- Complete input-space verification



For the default `INPUT = 8` configuration, the total number of possible input combinations is:



```text

2^8 = 256

```

\### 1.11 `phx\_common\_register\_file`



\### Purpose



`phx\_common\_register\_file` provides the register storage required by the PhoenixRV datapath.



The module implements a parameterized register file with two independent read ports and one write port. Register reads are combinational, while register writes occur synchronously with the clock.



The default configuration contains 32 registers, each 32 bits wide.



\### Parameters



| Parameter | Default | Description |

| --------- | ------: | ----------- |

| DATA\_WIDTH | 32 | Width of each register |

| REG\_COUNT | 32 | Number of registers |



The register address width is derived using:



```text

$clog2(REG\_COUNT)

```



\### One important point



I deliberately wrote the documentation around the \*\*actual RTL behavior we finalized\*\*:



```text

2 read ports

1 write port

32 × 32 default

x0 protection

combinational reads

clocked writes

write-through

```

\### RTL Behavior



`phx\_common\_register\_file` is a parameterized register file with two combinational read ports and one synchronous write port.



The default configuration contains 32 registers, each 32 bits wide.



The register storage is implemented as:



```text

registers\[0:REG\_COUNT-1]

```

\### Port Interface



| Port | Direction | Width | Function |

|---|---|---:|---|

| `clk` | Input | 1 bit | Clock signal. Register write operations occur on the positive edge of this clock. |

| `reset` | Input | 1 bit | Clears the register file when asserted. |

| `rs1` | Input | 5 bits\* | Selects the register to be read through the first read port. |

| `rs2` | Input | 5 bits\* | Selects the register to be read through the second read port. |

| `rd` | Input | 5 bits\* | Selects the destination register for a write operation. |

| `write\_data` | Input | 32 bits\* | Data that is written into the selected register. |

| `write\_enable` | Input | 1 bit | Enables the write operation when asserted. |

| `read\_data1` | Output | 32 bits\* | Provides the data stored in the register selected by `rs1`. |

| `read\_data2` | Output | 32 bits\* | Provides the data stored in the register selected by `rs2`. |



\\\* Width is parameterized and depends on `DATA\_WIDTH` and `REG\_COUNT`.



\### Verification



The `phx\_common\_register\_file` module was verified using a self-checking testbench containing directed tests and randomized read/write transactions.



The verification covered:



\- Register file reset behavior

\- Basic register write and read operations

\- Register overwrite operation

\- Simultaneous operation of both read ports

\- Reading the same register through both read ports

\- x0 read behavior

\- Attempted write to x0

\- Write-through behavior on read port 1

\- Write-through behavior on read port 2

\- Write-through when both read ports select the register being written

\- Randomized register addresses

\- Randomized write data

\- Randomized write enable

\- Sequential read/write transactions



An independent reference register array was maintained in the testbench to calculate the expected register contents and read outputs. This allowed the DUT outputs to be compared against an independent expected model.



The final simulation result was:



```text

Total Tests : 511

Passed      : 511

Failed      : 0

```

\### COM-012 — Immediate Generator



\#### Module Name



`phx\_common\_imm\_gen`



\#### Purpose



The `phx\_common\_imm\_gen` module generates a 32-bit immediate value from a 32-bit RISC-V instruction.



RISC-V uses different instruction formats in which the immediate bits are arranged differently. The Immediate Generator extracts, rearranges, and extends these bits to produce a consistent 32-bit immediate output.



The supported immediate formats are:



\- I-type

\- S-type

\- B-type

\- U-type

\- J-type



The module is purely combinational and does not require a clock or reset signal.



\---



\### Module Interface Specification



\#### Port Interface



| Port | Direction | Width | Function |

|---|---|---:|---|

| `instruction` | Input | 32 bits | 32-bit RISC-V instruction from which the immediate value is extracted. |

| `imm\_type` | Input | 3 bits | Selects the immediate format to be generated. |

| `immediate` | Output | 32 bits | Generated 32-bit immediate value corresponding to the selected instruction format. |



\#### Immediate Type Encoding



| `imm\_type` | Format | Description |

|---|---|---|

| `3'b000` | I-type | 12-bit immediate from `instruction\[31:20]`, sign extended to 32 bits. |

| `3'b001` | S-type | Immediate reconstructed from `instruction\[31:25]` and `instruction\[11:7]`, then sign extended. |

| `3'b010` | B-type | Branch immediate reconstructed from separated instruction fields and sign extended. |

| `3'b011` | U-type | Upper 20 instruction bits followed by 12 zero bits. |

| `3'b100` | J-type | Jump immediate reconstructed from separated instruction fields and sign extended. |

| Other | Invalid | Output is set to zero. |



\---



\### RTL Behavior



The module is implemented as a combinational RTL block using an `always @(\*)` block and a `case` statement based on `imm\_type`.



The output is given a default value of zero before format selection. This ensures deterministic behavior for unsupported immediate types.



```text

instruction\[31:0]

&#x20;      │

&#x20;      │

&#x20;      ▼

┌─────────────────────┐

│ Immediate Generator │

│                     │

│   imm\_type\[2:0]     │

└──────────┬──────────┘

&#x20;          │

&#x20;          ▼

&#x20;    immediate\[31:0]



```

\### verification

The phx\_common\_imm\_gen module was verified using a self-checking directed testbench.



Since the module is purely combinational, no clock or reset sequence is required. Each test applies an instruction and immediate type, waits for the combinational logic to settle, and compares the generated immediate against an independently specified expected value.



The expected values were specified directly for each test case rather than reproducing the DUT's concatenation logic inside the testbench.



The verification covered:



I-type positive immediate

I-type negative immediate

I-type sign extension

S-type positive immediate

S-type negative immediate

S-type bit reconstruction

B-type zero offset

B-type positive offset

B-type negative offset

B-type bit reconstruction

U-type immediate generation

U-type lower-bit zeroing

J-type zero offset

J-type positive offset

J-type negative offset

Invalid immediate type behavior

Directed Test Result

Total Tests : 14

Passed      : 14

Failed      : 0



All directed tests passed successfully.



The testbench also uses waveform dumping for GTKWave analysis.



GTKWave verification was performed to inspect:



Immediate type selection

Instruction bit extraction

Sign extension

B-type and J-type bit reconstruction

U-type zero extension

Invalid-type behavior



The module is considered verified after successful simulation and waveform inspection.



\# COM-013 — PC Target Adder



\## 1. Module Name



`phx\_common\_pc\_target`



\## 2. Purpose



The `phx\_common\_pc\_target` module calculates a target address by adding the current program counter with a 32-bit immediate value.



The operation performed is:



```text

target\_address = pc + immediate

```

\## 3. Module Interface Specification



\### 3.1 Port Specification



| Port | Direction | Width | Description |

|---|---|---:|---|

| `pc` | Input | 32 bits | Current 32-bit program counter value used as the base address for target calculation. |

| `immediate` | Input | 32 bits | 32-bit sign-extended immediate/offset value generated by the Immediate Generator. |

| `target\_address` | Output | 32 bits | 32-bit target address obtained by adding `pc` and `immediate`. |



\### 3.2 Functional Interface



The module performs the following operation:



```text

target\_address = pc + immediate

```

\## 5. Verification



The `phx\_common\_pc\_target` module was verified using a self-checking Verilog testbench.



\### 5.1 Directed Tests



7 directed test cases were performed to verify:



\- Zero values

\- Normal addition

\- Positive immediate

\- Negative immediate

\- Large values

\- 32-bit wraparound



```text

Directed Tests : 7

Passed         : 7

Failed         : 0

```

\# COM-014 — Next PC Multiplexer



\## 1. Module Name



`phx\_common\_next\_pc\_mux`



\---



\## 2. Purpose



The `phx\_common\_next\_pc\_mux` module selects the address that will be used as the next Program Counter (PC) value.



The module supports four possible next-PC sources:



\- Normal sequential address (`pc\_plus\_4`)

\- Branch target address (`branch\_target`)

\- Jump target address (`jump\_target`)

\- Alternate target address (`alternate\_target`)



The required input is selected using a 2-bit `select` signal.



The functional behavior is:



```text

select = 2'b00 → next\_pc = pc\_plus\_4

select = 2'b01 → next\_pc = branch\_target

select = 2'b10 → next\_pc = jump\_target

select = 2'b11 → next\_pc = alternate\_target

```

\## 3. Module Interface Specification



\### Port Specification



| Port | Direction | Width | Description |

|---|---|---:|---|

| `pc\_plus\_4` | Input | 32 bits | Provides the normal sequential PC address, typically calculated as the current PC plus 4. |

| `branch\_target` | Input | 32 bits | Provides the target address for a taken branch instruction. |

| `jump\_target` | Input | 32 bits | Provides the target address for a jump instruction. |

| `alternate\_target` | Input | 32 bits | Provides an additional next-PC target for future control-flow operations. |

| `select` | Input | 2 bits | Selects which input address is transferred to the output. |

| `next\_pc` | Output | 32 bits | Provides the selected address that will be used as the next Program Counter value. |



\### Selection Specification



| `select` | Selected Source | `next\_pc` |

|---|---|---|

| `2'b00` | `pc\_plus\_4` | `pc\_plus\_4` |

| `2'b01` | `branch\_target` | `branch\_target` |

| `2'b10` | `jump\_target` | `jump\_target` |

| `2'b11` | `alternate\_target` | `alternate\_target` |



\### Interface Summary



The module accepts four possible 32-bit next-PC address sources and uses the 2-bit `select` signal to choose one of them.



The selected 32-bit address is provided through the `next\_pc` output.



The module does not require a clock, reset, or enable signal because it performs only combinational selection.



\## 5. Verification



The `phx\_common\_next\_pc\_mux` module was verified using a self-checking Verilog testbench.



\### Directed Tests



8 directed test cases were performed to verify all four selection paths of the multiplexer.



The following conditions were tested:



\- `select = 2'b00` → `pc\_plus\_4`

\- `select = 2'b01` → `branch\_target`

\- `select = 2'b10` → `jump\_target`

\- `select = 2'b11` → `alternate\_target`



Different input values were applied to ensure that each selection path correctly produced the expected output.



```text

Directed Tests : 8

Passed         : 8

Failed         : 0

```



\# COM-015 — Program Counter Register



\## 1. Module Name



`phx\_common\_pc\_register`



\---



\## 2. Purpose



The `phx\_common\_pc\_register` module stores the current Program Counter (PC) value of the processor.



The module receives a 32-bit `next\_pc` value and updates the stored PC value on every positive edge of the clock.



The module also supports a synchronous reset. When reset is active at the positive clock edge, the Program Counter is initialized to the configured `RESET\_ADDRESS`.



The basic operation is:



```text

At posedge clk:



reset = 1 → current\_pc = RESET\_ADDRESS



reset = 0 → current\_pc = next\_pc

```

\## 3. Module Interface Specification



\### 3.1 Port Interface Specification



| Port Name | Direction | Width | Description |

|---|---|---:|---|

| `clk` | Input | 1 bit | Clock signal used to synchronize Program Counter updates. The PC register updates on the positive edge of this clock. |

| `reset` | Input | 1 bit | Active-high synchronous reset signal. When asserted during a positive clock edge, `current\_pc` is loaded with `RESET\_ADDRESS`. |

| `next\_pc` | Input | 32 bits | Provides the next Program Counter address that will be stored when reset is inactive. |

| `current\_pc` | Output | 32 bits | Provides the currently stored Program Counter value. |



\### 3.2 Parameter Specification



| Parameter Name | Width | Default Value | Description |

|---|---:|---|---|

| `RESET\_ADDRESS` | 32 bits | `32'h00000000` | Defines the Program Counter value loaded when the synchronous reset is active. |



\### 3.3 Interface Operation



The module operates according to the following behavior at every positive edge of `clk`:



```text

reset = 1 → current\_pc = RESET\_ADDRESS



reset = 0 → current\_pc = next\_pc

```

\## 5. Verification



The `phx\_common\_pc\_register` module was verified using a self-checking Verilog testbench.



\### Directed Tests



Directed tests were performed to verify the main sequential behavior of the Program Counter Register.



The following conditions were tested:



\- Synchronous reset operation.

\- Loading `RESET\_ADDRESS` when `reset` is active.

\- Normal PC update when `reset` is inactive.

\- Multiple sequential updates of `current\_pc`.

\- Different 32-bit `next\_pc` values.

\- Reset priority over `next\_pc`.



The expected behavior at every positive edge of the clock was:



```text

reset = 1 → current\_pc = RESET\_ADDRESS



reset = 0 → current\_pc = next\_pc

```

