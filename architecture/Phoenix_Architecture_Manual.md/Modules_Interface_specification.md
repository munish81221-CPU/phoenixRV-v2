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