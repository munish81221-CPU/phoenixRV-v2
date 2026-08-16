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
