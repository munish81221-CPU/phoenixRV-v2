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