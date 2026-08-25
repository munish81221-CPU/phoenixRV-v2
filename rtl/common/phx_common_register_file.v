module phx_common_register_file
#(parameter DATA_WIDTH=32,
  parameter REG_COUNT=32 )
  (input clk,
   input reset,
   
   input [$clog2(REG_COUNT)-1:0] rs1,
   input [$clog2(REG_COUNT)-1:0] rs2,

   input [$clog2(REG_COUNT)-1:0] rd,
   input [DATA_WIDTH-1:0] write_data,
   input write_enable,

   output reg[DATA_WIDTH-1:0] read_data1,
   output reg[DATA_WIDTH-1:0] read_data2

   
);

//defining registers
reg [DATA_WIDTH-1:0] registers [0:REG_COUNT-1];

integer i;

//sequential write and reset logic

always @(posedge clk) begin

    if(reset)
    begin

        for(i=0;i<REG_COUNT;i=i+1)begin
            registers[i] ='0;

        end
    end
    else
    begin
        if(write_enable && (rd !=0))begin
            registers[rd] <= write_data;
        end
    end
end

//combinational read logic
always@(*)begin
    
    //instructions for reading from port 1
    if(rs1==0)
    read_data1 ='0;
    else if(write_enable && (rd==rs1))
    read_data1 =write_data;
    else 
    read_data1 = registers[rs1];

    //instructions for reading from port 2
     if(rs2==0)
    read_data2 ='0;
    else if(write_enable && (rd==rs2))
    read_data2 =write_data;
    else 
    read_data2 = registers[rs2];
end
endmodule