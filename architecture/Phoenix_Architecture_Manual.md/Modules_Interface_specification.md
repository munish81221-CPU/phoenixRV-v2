###### **module1**

\## RTL Module: phx\_common\_mux2

\### Purpose

`phx\_common\_mux2` is a parameterized 2:1 multiplexer used to

select one of two WIDTH-bit input buses.

\### Parameters

| Parameter | Default | Description                              |

|-----------|---------|------------------------------------------|

| WIDTH     | 32      | Width of the input and output data buses |


\### Interface

|----------------------------------------------|

| Signal | Direction | Width | Description     |

|--------|-----------|-------|-----------------|

| in0    | Input     | WIDTH | First input bus |

| in1 	 | Input     | WIDTH | Second input bus|

| sel	 | Input     | 1     | Select signal   |

| out	 | Output    | WIDTH | Selected output |

|----------------------------------------------|

\### RTL Behavior



When "sel = 0", "out follows in0".



When "sel = 1", "out follows in1".



The module is purely combinational and does not require a clock.



\### Verification



The module was verified using a self-checking testbench with

three functional test cases. All three tests passed.



Waveform inspection in GTKWave also confirmed correct MUX behavior.

