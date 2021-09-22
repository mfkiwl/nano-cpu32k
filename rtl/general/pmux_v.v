/**@file
 * Generated by 'gen_pmux.py'
 * IMPORTANT: Do NOT modify this file manually! 
 */
 
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

module pmux_v
#(
   parameter SELW = 0,
   parameter DW = 0
)
(
   input [SELW-1:0] sel,
   input [DW*SELW-1:0] din,
   output reg [DW-1:0] dout

   , output reg valid

);

   generate
      
      if (SELW==2)
         begin : gen_enc_2
            always @(*)
                begin

                    valid = 'b1;

                    casez(sel)
                       2'b?1: dout = din[0*DW +: DW];
                       2'b10: dout = din[1*DW +: DW];
                       default: begin dout = din[0 +: DW]; valid = 'b0; end
                    endcase
                end
         end

      else

      if (SELW==3)
         begin : gen_enc_3
            always @(*)
                begin

                    valid = 'b1;

                    casez(sel)
                       3'b??1: dout = din[0*DW +: DW];
                       3'b?10: dout = din[1*DW +: DW];
                       3'b100: dout = din[2*DW +: DW];
                       default: begin dout = din[0 +: DW]; valid = 'b0; end
                    endcase
                end
         end

      else

      if (SELW==4)
         begin : gen_enc_4
            always @(*)
                begin

                    valid = 'b1;

                    casez(sel)
                       4'b???1: dout = din[0*DW +: DW];
                       4'b??10: dout = din[1*DW +: DW];
                       4'b?100: dout = din[2*DW +: DW];
                       4'b1000: dout = din[3*DW +: DW];
                       default: begin dout = din[0 +: DW]; valid = 'b0; end
                    endcase
                end
         end

      else

      if (SELW==5)
         begin : gen_enc_5
            always @(*)
                begin

                    valid = 'b1;

                    casez(sel)
                       5'b????1: dout = din[0*DW +: DW];
                       5'b???10: dout = din[1*DW +: DW];
                       5'b??100: dout = din[2*DW +: DW];
                       5'b?1000: dout = din[3*DW +: DW];
                       5'b10000: dout = din[4*DW +: DW];
                       default: begin dout = din[0 +: DW]; valid = 'b0; end
                    endcase
                end
         end

      else

      if (SELW==6)
         begin : gen_enc_6
            always @(*)
                begin

                    valid = 'b1;

                    casez(sel)
                       6'b?????1: dout = din[0*DW +: DW];
                       6'b????10: dout = din[1*DW +: DW];
                       6'b???100: dout = din[2*DW +: DW];
                       6'b??1000: dout = din[3*DW +: DW];
                       6'b?10000: dout = din[4*DW +: DW];
                       6'b100000: dout = din[5*DW +: DW];
                       default: begin dout = din[0 +: DW]; valid = 'b0; end
                    endcase
                end
         end

      else

      if (SELW==7)
         begin : gen_enc_7
            always @(*)
                begin

                    valid = 'b1;

                    casez(sel)
                       7'b??????1: dout = din[0*DW +: DW];
                       7'b?????10: dout = din[1*DW +: DW];
                       7'b????100: dout = din[2*DW +: DW];
                       7'b???1000: dout = din[3*DW +: DW];
                       7'b??10000: dout = din[4*DW +: DW];
                       7'b?100000: dout = din[5*DW +: DW];
                       7'b1000000: dout = din[6*DW +: DW];
                       default: begin dout = din[0 +: DW]; valid = 'b0; end
                    endcase
                end
         end

      else

      if (SELW==8)
         begin : gen_enc_8
            always @(*)
                begin

                    valid = 'b1;

                    casez(sel)
                       8'b???????1: dout = din[0*DW +: DW];
                       8'b??????10: dout = din[1*DW +: DW];
                       8'b?????100: dout = din[2*DW +: DW];
                       8'b????1000: dout = din[3*DW +: DW];
                       8'b???10000: dout = din[4*DW +: DW];
                       8'b??100000: dout = din[5*DW +: DW];
                       8'b?1000000: dout = din[6*DW +: DW];
                       8'b10000000: dout = din[7*DW +: DW];
                       default: begin dout = din[0 +: DW]; valid = 'b0; end
                    endcase
                end
         end

      else

      if (SELW==9)
         begin : gen_enc_9
            always @(*)
                begin

                    valid = 'b1;

                    casez(sel)
                       9'b????????1: dout = din[0*DW +: DW];
                       9'b???????10: dout = din[1*DW +: DW];
                       9'b??????100: dout = din[2*DW +: DW];
                       9'b?????1000: dout = din[3*DW +: DW];
                       9'b????10000: dout = din[4*DW +: DW];
                       9'b???100000: dout = din[5*DW +: DW];
                       9'b??1000000: dout = din[6*DW +: DW];
                       9'b?10000000: dout = din[7*DW +: DW];
                       9'b100000000: dout = din[8*DW +: DW];
                       default: begin dout = din[0 +: DW]; valid = 'b0; end
                    endcase
                end
         end

      else
      begin : gen_enc_fail
            initial
                $fatal("\n Unimplemented size. Please update parameters of generator. \n");
         end

    endgenerate

endmodule
