import sys

P_DW_MAX = 9

with open(sys.argv[1],'w') as fp:
    fp.write(
"""/**@file
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
""")

    fp.write("      ")
    for P_DW in range(1,P_DW_MAX):
        fp.write(
"""if (P_DW==%d)
        begin : gen_enc_%d
            always @(*)
                begin
                    casez(din)
""" % (P_DW, P_DW))
        DW=1<<P_DW
        for i in range(DW):
            fp.write("                       %d'b"%DW)
            fp.write("".join(['?' for j in range(DW-i-1)]))
            fp.write("1")
            fp.write("".join(['0' for j in range(i)]))
            fp.write(": dout = %d'd%d;\n" %(P_DW,i))
        fp.write("                       default: begin dout = %d'd%d; end\n"%(P_DW, 0))
        fp.write(
"""                    endcase
                end
        end
""")
        fp.write("      else ")

    fp.write("""\n         begin : gen_enc_fail
            initial
                $fatal("\\n Unimplemented size of binary encoder. Please update parameters of generator. \\n");
         end

    endgenerate

endmodule
""")