/**@file
 * Generated by 'gen_priority_encoder.py'
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

module priority_encoder
#(
   parameter P_DW = 0
)
(
   input [(1<<P_DW)-1:0] din,
   output reg [P_DW-1:0] dout
);

   generate
      if (P_DW==1)
        begin : gen_enc_1
            always @(*)
                begin
                    casez(din)
                       2'b?1: dout = 1'd0;
                       2'b10: dout = 1'd1;
                       default: begin dout = 1'd0; end
                    endcase
                end
        end
      else if (P_DW==2)
        begin : gen_enc_2
            always @(*)
                begin
                    casez(din)
                       4'b???1: dout = 2'd0;
                       4'b??10: dout = 2'd1;
                       4'b?100: dout = 2'd2;
                       4'b1000: dout = 2'd3;
                       default: begin dout = 2'd0; end
                    endcase
                end
        end
      else if (P_DW==3)
        begin : gen_enc_3
            always @(*)
                begin
                    casez(din)
                       8'b???????1: dout = 3'd0;
                       8'b??????10: dout = 3'd1;
                       8'b?????100: dout = 3'd2;
                       8'b????1000: dout = 3'd3;
                       8'b???10000: dout = 3'd4;
                       8'b??100000: dout = 3'd5;
                       8'b?1000000: dout = 3'd6;
                       8'b10000000: dout = 3'd7;
                       default: begin dout = 3'd0; end
                    endcase
                end
        end
      else if (P_DW==4)
        begin : gen_enc_4
            always @(*)
                begin
                    casez(din)
                       16'b???????????????1: dout = 4'd0;
                       16'b??????????????10: dout = 4'd1;
                       16'b?????????????100: dout = 4'd2;
                       16'b????????????1000: dout = 4'd3;
                       16'b???????????10000: dout = 4'd4;
                       16'b??????????100000: dout = 4'd5;
                       16'b?????????1000000: dout = 4'd6;
                       16'b????????10000000: dout = 4'd7;
                       16'b???????100000000: dout = 4'd8;
                       16'b??????1000000000: dout = 4'd9;
                       16'b?????10000000000: dout = 4'd10;
                       16'b????100000000000: dout = 4'd11;
                       16'b???1000000000000: dout = 4'd12;
                       16'b??10000000000000: dout = 4'd13;
                       16'b?100000000000000: dout = 4'd14;
                       16'b1000000000000000: dout = 4'd15;
                       default: begin dout = 4'd0; end
                    endcase
                end
        end
      else if (P_DW==5)
        begin : gen_enc_5
            always @(*)
                begin
                    casez(din)
                       32'b???????????????????????????????1: dout = 5'd0;
                       32'b??????????????????????????????10: dout = 5'd1;
                       32'b?????????????????????????????100: dout = 5'd2;
                       32'b????????????????????????????1000: dout = 5'd3;
                       32'b???????????????????????????10000: dout = 5'd4;
                       32'b??????????????????????????100000: dout = 5'd5;
                       32'b?????????????????????????1000000: dout = 5'd6;
                       32'b????????????????????????10000000: dout = 5'd7;
                       32'b???????????????????????100000000: dout = 5'd8;
                       32'b??????????????????????1000000000: dout = 5'd9;
                       32'b?????????????????????10000000000: dout = 5'd10;
                       32'b????????????????????100000000000: dout = 5'd11;
                       32'b???????????????????1000000000000: dout = 5'd12;
                       32'b??????????????????10000000000000: dout = 5'd13;
                       32'b?????????????????100000000000000: dout = 5'd14;
                       32'b????????????????1000000000000000: dout = 5'd15;
                       32'b???????????????10000000000000000: dout = 5'd16;
                       32'b??????????????100000000000000000: dout = 5'd17;
                       32'b?????????????1000000000000000000: dout = 5'd18;
                       32'b????????????10000000000000000000: dout = 5'd19;
                       32'b???????????100000000000000000000: dout = 5'd20;
                       32'b??????????1000000000000000000000: dout = 5'd21;
                       32'b?????????10000000000000000000000: dout = 5'd22;
                       32'b????????100000000000000000000000: dout = 5'd23;
                       32'b???????1000000000000000000000000: dout = 5'd24;
                       32'b??????10000000000000000000000000: dout = 5'd25;
                       32'b?????100000000000000000000000000: dout = 5'd26;
                       32'b????1000000000000000000000000000: dout = 5'd27;
                       32'b???10000000000000000000000000000: dout = 5'd28;
                       32'b??100000000000000000000000000000: dout = 5'd29;
                       32'b?1000000000000000000000000000000: dout = 5'd30;
                       32'b10000000000000000000000000000000: dout = 5'd31;
                       default: begin dout = 5'd0; end
                    endcase
                end
        end
      else 
         begin : gen_enc_fail
            initial
                $fatal("\n Unimplemented size of binary encoder. Please update parameters of generator. \n");
         end

    endgenerate

endmodule
