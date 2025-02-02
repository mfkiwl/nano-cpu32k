/*
Copyright 2021 GaoZiBo <diyer175@hotmail.com>
Powered by YSYX https://oscpu.github.io/ysyx

Licensed under The MIT License (MIT).
-------------------------------------
Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
the Software, and to permit persons to whom the Software is furnished to do so,
subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED,INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

module mRF_nwnr_r
#(
   parameter DW = 1,
   parameter AW = 0,
   parameter NUM_READ = 0,
   parameter NUM_WRITE = 0,
   parameter [DW*(1<<AW)-1:0] RST_VECTOR = {DW*(1<<AW){1'b0}}
)
(
   input CLK,
   input RST,
   input [NUM_READ-1:0] RE,
   input [NUM_READ*AW-1:0] RADDR,
   output [NUM_READ*DW-1:0] RDATA,
   input [NUM_WRITE-1:0] WE,
   input [AW*NUM_WRITE-1:0] WADDR,
   input [DW*NUM_WRITE-1:0] WDATA
);
   reg [DW-1:0] regfile [(1<<AW)-1:0];
   reg [DW-1:0] ff_dout [NUM_READ-1:0];
   genvar i;
   integer j;
   
`ifdef NCPU_RST_ASYNC
 `ifdef NCPU_RST_POS_POLARITY
   always @(posedge CLK or posedge RST) begin
 `else // neg polarity
   always @(posedge CLK or negedge RST) begin
 `endif
`else // synchronous
   always @(posedge CLK) begin
`endif
`ifdef NCPU_RST_POS_POLARITY
      if (RST)
`else // neg polarity
      if (~RST)
`endif
         for(j=0;j<(1<<AW);j=j+1)
            regfile[j] <= RST_VECTOR[j*DW +: DW];

      else
         for(j=0;j<NUM_WRITE;j=j+1) // This generates a priority MUX to resolve WAW hazard, if we have multiple write ports.
            if (WE[j])
               regfile[WADDR[j*AW +: AW]] <= WDATA[j*DW +: DW];
   end
   
   generate for(i=0;i<NUM_READ;i=i+1)
      begin : gen_rdata
`ifdef NCPU_RST_ASYNC
 `ifdef NCPU_RST_POS_POLARITY
   always @(posedge CLK or posedge RST) begin
 `else // neg polarity
   always @(posedge CLK or negedge RST) begin
 `endif
`else // synchronous
   always @(posedge CLK) begin
`endif
`ifdef NCPU_RST_POS_POLARITY
      if (RST)
`else // neg polarity
      if (~RST)
`endif
         ff_dout[i] <= {DW{1'b0}};
      else
         if (RE[i])
            ff_dout[i] <= regfile[RADDR[i*AW +: AW]];
   end
   
         assign RDATA[i*DW +: DW] = ff_dout[i];
      end
   endgenerate
   
endmodule
