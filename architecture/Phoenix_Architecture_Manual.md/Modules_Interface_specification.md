# PhoenixRV Module Interface Specification

## 1. Common Modules

### 1.1 `phx_common_mux2`

### Purpose

`phx_common_mux2` is a parameterized 2:1 multiplexer used to
select one of two WIDTH-bit input buses.

### Parameters

| Parameter | Default | Description                              |
|-----------|--------:|------------------------------------------|
| WIDTH     |      32 | Width of the input and output data buses |

### Interface

| Signal | Direction | Width | Description       |
|--------|-----------|------:|-------------------|
| in0    | Input     | WIDTH | First input bus   |
| in1    | Input     | WIDTH | Second input bus  |
| sel    | Input     | 1     | Select signal     |
| out    | Output    | WIDTH | Selected output   |

### RTL Behavior

When `sel = 0`, `out` follows `in0`.

When `sel = 1`, `out` follows `in1`.

The module is purely combinational and does not require a clock.

### Verification

The module was verified using a self-checking testbench with
three functional test cases. All three tests passed.

Waveform inspection in GTKWave also confirmed correct MUX behavior.

### 1.2 `phx_common_mux4`

### Purpose

`phx_common_mux4` is a parameterized 4:1 multiplexer used to
select one of four WIDTH-bit input buses. It is constructed
hierarchically using three instances of `phx_common_mux2`.

### Parameters

| Parameter | Default | Description                              |
|-----------|--------:|------------------------------------------|
| WIDTH     |      32 | Width of the input and output data buses |

### Interface

| Signal | Direction | Width | Description       |
|--------|-----------|------:|-------------------|
| in0    | Input     | WIDTH | First input bus   |
| in1    | Input     | WIDTH | Second input bus  |
| in2    | Input     | WIDTH | Third input bus   |
| in3    | Input     | WIDTH | Fourth input bus  |
| sel    | Input     | 2     | Select signal     |
| out    | Output    | WIDTH | Selected output   |

### RTL Behavior

When `sel = 2'b00`, `out` follows `in0`.

When `sel = 2'b01`, `out` follows `in1`.

When `sel = 2'b10`, `out` follows `in2`.

When `sel = 2'b11`, `out` follows `in3`.

The module is purely combinational and does not require a clock.

### Verification

The module was verified using a self-checking testbench with
four functional selection cases. All four tests passed.

Waveform inspection in GTKWave also confirmed correct MUX behavior.





### 1.3 `phx_common_adder`

### Purpose

`phx_common_adder` is a parameterized binary adder based on a
parallel-prefix Kogge-Stone carry network. It computes the sum of
two WIDTH-bit operands with an input carry.

### Parameters

| Parameter | Default | Description                         |
| --------- | ------: | ----------------------------------- |
| WIDTH     |      32 | Width of the input and output buses |

### Interface

| Signal   | Direction | Width | Description     |
| -------- | --------- | ----: | --------------- |
| add_in0  | Input     | WIDTH | First operand   |
| add_in1  | Input     | WIDTH | Second operand  |
| cin      | Input     |     1 | Input carry     |
| sum      | Output    | WIDTH | Addition result |
| cout     | Output    |     1 | Output carry    |

### RTL Behavior

The module computes the binary addition of `add_in0`, `add_in1`, and
`cin`.

The carry signals are calculated using a parallel-prefix Kogge-Stone
carry network.

The module is purely combinational and does not require a clock.

### Verification

The module was verified using a self-checking testbench with five
directed test cases and 1000 random test vectors. All 1005 tests passed.

Waveform inspection in GTKWave also confirmed correct adder behavior.

### 1.4 `phx_common_add_sub`

### Purpose

`phx_common_add_sub` is a parameterized combinational arithmetic
module that performs addition or subtraction using a shared
Kogge-Stone adder.

### Parameters

| Parameter | Default | Description                         |
| --------- | ------: | ----------------------------------- |
| WIDTH     |      32 | Width of the input and output buses |

### Interface

| Signal  | Direction | Width | Description |
| ------- | --------- | ----: | ----------- |
| add_in0 | Input     | WIDTH | First operand |
| add_in1 | Input     | WIDTH | Second operand |
| sel     | Input     | 1 | Operation select |
| result  | Output    | WIDTH | Arithmetic result |
| cout    | Output    | 1 | Carry/borrow indication |

### RTL Behavior

When `sel = 0`, the module performs:

`add_in0 + add_in1`

When `sel = 1`, the module performs subtraction using two's-complement
arithmetic:

`add_in0 + ~add_in1 + 1`

The module reuses `phx_common_adder` as the underlying Kogge-Stone
arithmetic engine.

The module is purely combinational and does not require a clock.

### Verification

The module was verified using a self-checking testbench with nine
directed test cases and 1000 random test vectors. All 1009 tests passed.

Waveform inspection in GTKWave also confirmed correct addition,
subtraction, and carry/borrow behavior.

### 1.5 `phx_common_comparator`

### Purpose

`phx_common_comparator` is a parameterized combinational comparison
module used to compare two WIDTH-bit operands. It supports both
unsigned and signed comparison modes.

### Parameters

| Parameter | Default | Description                         |
| --------- | ------: | ----------------------------------- |
| WIDTH     |      32 | Width of the input operand buses    |

### Interface

| Signal      | Direction | Width | Description |
| ----------- | --------- | ----: | ----------- |
| add_in0     | Input     | WIDTH | First operand |
| add_in1     | Input     | WIDTH | Second operand |
| signed_mode | Input     | 1 | Selects signed or unsigned comparison |
| eq          | Output    | 1 | Asserted when operands are equal |
| lt          | Output    | 1 | Asserted when add_in0 is less than add_in1 |
| gt          | Output    | 1 | Asserted when add_in0 is greater than add_in1 |

### RTL Behavior

The module first determines bit-wise equality between the two
operands.

The comparison network evaluates the operands from the most
significant bit toward the least significant bit. The first
different bit determines the unsigned comparison result.

When `signed_mode = 0`, the module performs unsigned comparison.

When `signed_mode = 1`, the module performs signed two's-complement
comparison. The sign bits are evaluated first, while operands having
the same sign use the unsigned comparison ordering.

The module generates three mutually exclusive comparison outputs:

- `eq = 1` when `add_in0 == add_in1`
- `lt = 1` when `add_in0 < add_in1`
- `gt = 1` when `add_in0 > add_in1`

The module is purely combinational and does not require a clock.

### Verification

The module was verified using a self-checking testbench with
11 directed test cases and 1000 random test vectors covering both
signed and unsigned comparison modes. All 1011 tests passed.

Waveform inspection in GTKWave also confirmed correct equality,
less-than, greater-than, signed, and unsigned comparison behavior.

### 1.6 `phx_common_shifter`

### Purpose

`phx_common_shifter` is a parameterized combinational barrel shifter designed to perform logical left shift, logical right shift, and arithmetic right shift operations on a WIDTH-bit data bus.

The shifter uses a multi-stage barrel-shifter structure, where each stage can shift the data by a power-of-two distance.

### Parameters

| Parameter | Default | Description |
| --------- | ------: | ----------- |
| WIDTH     |      32 | Width of the input and output data buses |

### Interface

| Signal | Direction | Width | Description |
| ------ | --------- | ----: | ----------- |
| data_in | Input | WIDTH | Input data to be shifted |
| shift_amount | Input | `$clog2(WIDTH)` | Amount by which the input data is shifted |
| operation | Input | 2 | Selects the shift operation |
| shift_out | Output | WIDTH | Shifted output data |

### Operation Encoding

| `operation` | Operation | Description |
| ----------- | --------- | ----------- |
| `2'b00` | SLL | Shift Left Logical |
| `2'b01` | SRL | Shift Right Logical |
| `2'b10` | SRA | Shift Right Arithmetic |
| `2'b11` | Reserved | Reserved for future use |

### RTL Behavior

The barrel-shifter network consists of `$clog2(WIDTH)` stages.

For the default `WIDTH = 32`, the five stages perform shifts of:

```text
Stage 0 → 1 bit
Stage 1 → 2 bits
Stage 2 → 4 bits
Stage 3 → 8 bits
Stage 4 → 16 bits
```

### Verification

The module was verified using a self-checking testbench with directed
and random test cases.

The testbench verified all three supported operations:

- SLL (Shift Left Logical)
- SRL (Shift Right Logical)
- SRA (Shift Right Arithmetic)

The verification also covered zero-shift operation, different shift
amounts, sign extension for arithmetic right shifts, and multi-stage
barrel-shifter operation.

A total of 515 test cases were executed, and all 515 tests passed with
zero failures.

Waveform inspection in GTKWave also confirmed correct shifter behavior
and verified the expected data propagation through the barrel-shifter
stages.

### 1.7 `phx_common_signext`

### Purpose

`phx_common_signext` is a parameterized combinational sign-extension module used to expand a smaller signed value to a larger datapath width while preserving its numerical value.

The module preserves the original input bits and fills the newly added upper bits with copies of the input sign bit (MSB).

### Parameters

| Parameter | Default | Description |
| --------- | ------: | ----------- |
| IN_WIDTH  |       8 | Width of the input data |
| OUT_WIDTH |      32 | Width of the output data |

`IN_WIDTH` must be less than or equal to `OUT_WIDTH`.

### Interface

| Signal | Direction | Width | Description |
| ------ | --------- | ----: | ----------- |
| data_in | Input | IN_WIDTH | Input signed value to be extended |
| data_out | Output | OUT_WIDTH | Sign-extended output value |

### RTL Behavior

The module is purely combinational and does not require a clock.

The number of newly generated upper bits is:

```text
OUT_WIDTH - IN_WIDTH
```

### verification

The module was verified using a self-checking testbench containing directed test cases across three parameterized configurations.

The verification covered:

- 8 → 32-bit sign extension: 11 tests passed, 0 failed
- 5 → 32-bit sign extension: 4 tests passed, 0 failed
- 16 → 32-bit sign extension: 4 tests passed, 0 failed

A total of **19 tests were executed, and all 19 tests passed with zero failures**.

GTKWave waveform inspection was also completed successfully. The waveforms confirmed correct replication of the input MSB into the newly added upper bits and preservation of the original input bits for all tested parameterized configurations.

### 1.8 `phx_common_mux`

### Purpose

`phx_common_mux` is a parameterized combinational multiplexer used to select one data word from multiple input data words and forward the selected value to the output.

The module supports configurable data width and number of input channels.

### Parameters

| Parameter | Default | Description |
| --------- | ------: | ----------- |
| WIDTH     |      32 | Width of each input and output data word |
| INPUTS    |       4 | Number of input data words |

For the default configuration, the module operates as a 4:1 multiplexer with 32-bit data inputs.

### Interface

| Signal | Direction | Width | Description |
| ------ | --------- | ----: | ----------- |
| input_data | Input | `WIDTH × INPUTS` | Array of input data words |
| sel | Input | `$clog2(INPUTS)` | Selects which input data word is forwarded |
| mux_out | Output | `WIDTH` | Selected input data word |

### Selection Behavior

For the default `INPUTS = 4` configuration:

| `sel` | Selected Input | `mux_out` |
| ----- | -------------- | --------- |
| `2'b00` | `input_data[0]` | `input_data[0]` |
| `2'b01` | `input_data[1]` | `input_data[1]` |
| `2'b10` | `input_data[2]` | `input_data[2]` |
| `2'b11` | `input_data[3]` | `input_data[3]` |

### RTL Behavior

The MUX is implemented using an indexed input array.

The selected input is directly assigned to the output:

```text
mux_out = input_data[sel]
```
### verification
in total 8 direct and 200 random test were applied and all passed succesfully . GTK wave outcone are verified succesfully and module if fully verified and tested.

### 1.9 `phx_common_decoder`

### Purpose

`phx_common_decoder` is a parameterized combinational decoder that converts an encoded binary input into a one-hot output.

For an `INPUT_WIDTH`-bit input, the decoder generates `2^INPUT_WIDTH` output lines. For each input combination, exactly one output line is asserted.

The module is designed as a reusable control-logic building block for PhoenixRV.

### Parameters

| Parameter | Default | Description |
| --------- | ------: | ----------- |
| INPUT_WIDTH | 2 | Width of the encoded input |

The number of decoder output lines is derived as:

```text
OUTPUTS = 2^INPUT_WIDTH
```
### interface
| Signal | Direction | Width | Description |
| ------ | --------- | ----: | ----------- |
| sel   | Input | `INPUT_WIDTH` | Encoded input used to select the active output|
|decoder| output| `2^INPUT_WIDTH` | one-hot decoded output|

### RTL behaviour
### RTL Behavior

`phx_common_decoder` is implemented as purely combinational logic using a left-shift operation.

The RTL starts with a single logic `1` and shifts it left by the value of `sel`:

```text
decoded = 1'b1 << sel
```
### verification
The module was verified using a self-checking testbench with exhaustive directed testing.

The verification covered every possible input state for each parameterized configuration:

2 → 4 decoder: 4 tests
3 → 8 decoder: 8 tests
4 → 16 decoder: 16 tests

A total of 28 tests were executed, and all 28 tests passed with zero failures.

GTKWave waveform inspection was also completed successfully. The waveforms confirmed correct one-hot output generation for all tested input combinations and parameterized decoder configurations.

### 1.10 `phx_common_priority_encoder`

### Purpose

`phx_common_priority_encoder` is a parameterized combinational priority encoder that converts multiple input request lines into a binary encoded output.

The module assigns priority according to the input index, with the highest-numbered input having the highest priority.

If multiple input bits are active at the same time, only the highest-priority active input is encoded.

A `valid` output indicates whether any input is active.

### Parameters

| Parameter | Default | Description |
| --------- | ------: | ----------- |
| INPUT | 8 | Number of input lines |

The encoded output width is derived using:

```text
$clog2(INPUT)
```
### RTL Specification

`phx_common_priority_encoder` is implemented as a purely combinational priority encoder.

The RTL uses a descending `for` loop to examine the input lines from the highest-priority index to the lowest-priority index.

For the default configuration:

```text
INPUT = 8
Priority order: 7 → 6 → 5 → 4 → 3 → 2 → 1 → 0
```


### Verification

The module was verified using a self-checking testbench.

Verification included:

- All-zero input condition
- Individual activation of each input
- Multiple simultaneously active inputs
- Highest-priority input selection
- Lowest-priority input selection
- All inputs active
- Complete input-space verification

For the default `INPUT = 8` configuration, the total number of possible input combinations is:

```text
2^8 = 256
```
### 1.11 `phx_common_register_file`

### Purpose

`phx_common_register_file` provides the register storage required by the PhoenixRV datapath.

The module implements a parameterized register file with two independent read ports and one write port. Register reads are combinational, while register writes occur synchronously with the clock.

The default configuration contains 32 registers, each 32 bits wide.

### Parameters

| Parameter | Default | Description |
| --------- | ------: | ----------- |
| DATA_WIDTH | 32 | Width of each register |
| REG_COUNT | 32 | Number of registers |

The register address width is derived using:

```text
$clog2(REG_COUNT)
```

### One important point

I deliberately wrote the documentation around the **actual RTL behavior we finalized**:

```text
2 read ports
1 write port
32 × 32 default
x0 protection
combinational reads
clocked writes
write-through
```
### RTL Behavior

`phx_common_register_file` is a parameterized register file with two combinational read ports and one synchronous write port.

The default configuration contains 32 registers, each 32 bits wide.

The register storage is implemented as:

```text
registers[0:REG_COUNT-1]
```
### Port Interface

| Port | Direction | Width | Function |
|---|---|---:|---|
| `clk` | Input | 1 bit | Clock signal. Register write operations occur on the positive edge of this clock. |
| `reset` | Input | 1 bit | Clears the register file when asserted. |
| `rs1` | Input | 5 bits* | Selects the register to be read through the first read port. |
| `rs2` | Input | 5 bits* | Selects the register to be read through the second read port. |
| `rd` | Input | 5 bits* | Selects the destination register for a write operation. |
| `write_data` | Input | 32 bits* | Data that is written into the selected register. |
| `write_enable` | Input | 1 bit | Enables the write operation when asserted. |
| `read_data1` | Output | 32 bits* | Provides the data stored in the register selected by `rs1`. |
| `read_data2` | Output | 32 bits* | Provides the data stored in the register selected by `rs2`. |

\* Width is parameterized and depends on `DATA_WIDTH` and `REG_COUNT`.

### Verification

The `phx_common_register_file` module was verified using a self-checking testbench containing directed tests and randomized read/write transactions.

The verification covered:

- Register file reset behavior
- Basic register write and read operations
- Register overwrite operation
- Simultaneous operation of both read ports
- Reading the same register through both read ports
- x0 read behavior
- Attempted write to x0
- Write-through behavior on read port 1
- Write-through behavior on read port 2
- Write-through when both read ports select the register being written
- Randomized register addresses
- Randomized write data
- Randomized write enable
- Sequential read/write transactions

An independent reference register array was maintained in the testbench to calculate the expected register contents and read outputs. This allowed the DUT outputs to be compared against an independent expected model.

The final simulation result was:

```text
Total Tests : 511
Passed      : 511
Failed      : 0
```