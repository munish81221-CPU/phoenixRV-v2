# REG-001 — Register File

## 1. Module Name

**Register File**

Module: `register_file`  
RTL File: `rtl/Datapath/phx_datapath_register_file.v`  
Testbench: `tb/Datapath/phx_datapath_register_file_tb.v`

## 2. Purpose

The Register File provides the processor's general-purpose registers used to store
and retrieve operand data during instruction execution.

The PhoenixRV Register File is parameterized so that the register data width and
register address width can be changed without modifying the fundamental module
structure.

The register file supports:

- Two asynchronous read ports.
- One synchronous write port.
- Register reset.
- Protection of register x0 from modification.
- Parameterized data width.
- Parameterized address width.

## 3. Module Interface Specification

### Port Interface Specification

| Port | Direction | Width | Description |
|---|---|---:|---|
| `clk` | Input | 1 | Clock signal |
| `reset` | Input | 1 | Asynchronous reset |
| `read_address1` | Input | `ADDR_WIDTH` | Address of first read register |
| `read_address2` | Input | `ADDR_WIDTH` | Address of second read register |
| `write_address` | Input | `ADDR_WIDTH` | Address of register to be written |
| `write_data` | Input | `DATA_WIDTH` | Data written to the register file |
| `write_enable` | Input | 1 | Enables register write |
| `read_data1` | Output | `DATA_WIDTH` | Data from first read port |
| `read_data2` | Output | `DATA_WIDTH` | Data from second read port |

### Parameters

| Parameter | Default | Description |
|---|---:|---|
| `DATA_WIDTH` | `32` | Width of each register |
| `ADDR_WIDTH` | `5` | Width of register addresses |

With `ADDR_WIDTH = 5`, the register file can address 32 registers (`x0`–`x31`).

## 4. RTL Behavior

### 4.1 Read Operation

The register file provides two independent asynchronous read ports.

The values stored at `read_address1` and `read_address2` are continuously available
at `read_data1` and `read_data2`, respectively.

Therefore, a clock edge is not required to perform a read operation.

### 4.2 Write Operation

Register writes occur synchronously with the rising edge of `clk`.

A write occurs when:

```text
write_enable = 1
```
## 5. Verification

The Register File was verified using a dedicated SystemVerilog testbench:

`tb/Datapath/phx_datapath_register_file_tb.v`

The testbench uses an independent reference model to compare the expected
register-file state against the actual DUT behavior.

### 5.1 Verification Features

The following behaviors were verified:

- Asynchronous read operation through both read ports.
- Synchronous register write on the rising edge of `clk`.
- Asynchronous reset behavior.
- Correct storage and retrieval of register data.
- Simultaneous operation of the two read ports.
- Register `x0` protection.
- Attempted writes to `x0` do not modify its value.
- Parameterized register data width and address width behavior.

### 5.2 Test Strategy

Verification consists of both directed and randomized transactions.

Directed tests are used to verify important architectural cases such as:

- Resetting the register file.
- Writing data to registers.
- Reading previously written data.
- Reading from multiple registers simultaneously.
- Attempting to write to `x0`.
- Confirming that `x0` remains zero.

Randomized testing is then used to exercise a wider range of register
addresses, data values, read operations, and write operations.

The testbench maintains an independent reference model and compares the DUT
outputs and register state against the expected values.

### 5.3 Verification Result

The Register File verification completed successfully.

- Directed tests: **PASS**
- Randomized tests: **500 transactions**
- Reference-model comparison: **PASS**
- `x0` protection: **PASS**
- Reset behavior: **PASS**
- Dual asynchronous read operation: **PASS**
- Synchronous write operation: **PASS**

### 5.4 Waveform Verification

The Register File was also verified using GTKWave.

The waveform was inspected to confirm the relationship between:

- `clk`
- `reset`
- `read_address1`
- `read_address2`
- `read_data1`
- `read_data2`
- `write_address`
- `write_data`
- `write_enable`

The waveform confirms that register writes occur on the appropriate clock
edge while read outputs respond asynchronously to changes in the read
addresses.

### 5.5 Final Verification Status

**REG-001 — Register File: VERIFIED**

# COM-021 — PC Target Adder

## 1. Module Name

**PC Target Adder**

Module: `phx_datapath_pc_target_adder`  
RTL File: `rtl/Datapath/phx_datapath_pc_target_adder.v`

## 2. Purpose

The PC Target Adder calculates a target program-counter address by adding the
current PC value to the instruction immediate.

The module is used for control-flow instructions that calculate their target
address relative to the current PC, including:

- Conditional branch instructions.
- JAL instructions.

The module performs the operation:

Target = PC + Immediate

The module is implemented as a combinational datapath component.

## 3. Module Interface Specification

### Port Interface Specification

| Port | Direction | Width | Description |
|---|---|---:|---|
| `pc` | Input | `WIDTH` | Current program counter value |
| `immediate` | Input | `WIDTH` | Sign-extended instruction immediate |
| `target` | Output | `WIDTH` | Calculated PC-relative target address |

### Parameters

| Parameter | Default | Description |
|---|---:|---|
| `WIDTH` | `32` | Width of the PC and immediate operands |

## 4. RTL Behavior

The PC Target Adder performs unsigned binary addition on the two input
operands:

Target = PC + Immediate

The addition is performed using the reusable `phx_common_adder` module.

The carry-out generated by the common adder is not required by the PC target
calculation and is therefore not exposed as an output of this module.

### 4.1 Branch Target

For a conditional branch:

Target = PC + B-type Immediate

The calculated target is supplied to the PC selection logic when the branch
condition is satisfied.

### 4.2 JAL Target

For a JAL instruction:

Target = PC + J-type Immediate

The calculated target is supplied to the next-PC selection logic when a JAL
instruction is executed.

### 4.3 Negative Offsets

Because the immediate is supplied as a sign-extended `WIDTH`-bit value,
negative branch or jump offsets are naturally handled by two's-complement
addition.

### 4.4 Combinational Operation

The module contains no clock or storage element.

Whenever `pc` or `immediate` changes, the `target` output is updated
combinationally.

## 5. Verification

The PC Target Adder was verified using a dedicated testbench.

### 5.1 Verification Features

The following cases were verified:

- Addition of positive PC-relative offsets.
- Addition of zero immediate.
- Addition of negative offsets.
- Boundary-value PC addresses.
- Maximum and minimum relevant operand values.
- Correct propagation of the calculated target address.

The testbench also verifies that the module correctly performs the same
addition expected from the independent reference calculation.

### 5.2 Test Result

A total of **108 test cases** were executed.

All test cases passed successfully.

**Result: 108/108 PASS**

### 5.3 Waveform Verification

The PC Target Adder was also inspected using GTKWave.

The waveform was used to verify that:

- `pc` is correctly applied as the first operand.
- `immediate` is correctly applied as the second operand.
- `target` follows the combinational sum of the two inputs.
- Positive and negative offsets produce the expected target addresses.

### 5.4 Final Verification Status

**COM-021 — PC Target Adder: VERIFIED**


# COM-020 — Operand-A MUX

## 1. Module Name

**Operand-A MUX**

Module: `phx_datapath_operand_a_mux`

## 2. Purpose

The Operand-A MUX selects the first operand supplied to the ALU.

PhoenixRV supports two possible sources for the first ALU operand:

- Register File `read_data1`
- Current Program Counter (`PC`)

The selection is controlled by the `ALUSrcA` control signal.

This allows the same ALU to be used for both register-based arithmetic
operations and instructions that require the PC as an ALU operand, such as
AUIPC.

## 3. Module Interface Specification

### Port Interface Specification

| Port | Direction | Width | Description |
|---|---|---:|---|
| `read_data1` | Input | `WIDTH` | First operand from the Register File |
| `pc` | Input | `WIDTH` | Current program counter value |
| `alu_src_a` | Input | 1 | Select signal for the ALU first operand |
| `operand_a` | Output | `WIDTH` | Selected ALU first operand |

### Parameters

| Parameter | Default | Description |
|---|---:|---|
| `WIDTH` | `32` | Width of the datapath operands |

## 4. RTL Behavior

The module operates as a 2-to-1 multiplexer.

The `alu_src_a` control signal determines which input is forwarded to
`operand_a`.

### 4.1 Register Operand Selection

When:

```text
alu_src_a = 0
```
## 5. Verification

The Operand-A MUX was verified using a dedicated SystemVerilog testbench.

### 5.1 Verification Strategy

The testbench verifies both possible input-selection paths of the multiplexer.

The expected behavior is:

```text
alu_src_a = 0  →  operand_a = read_data1
alu_src_a = 1  →  operand_a = pc
```
