import sys

def gen(filename, with_valid):
    SELW_MAX = 10

    with open(filename,'w') as fp:
        fp.write(
"""/**@file
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

module %s
#(
   parameter SELW = 0,
   parameter DW = 0
)
(
   input [SELW-1:0] sel,
   input [DW*SELW-1:0] din,
   output reg [DW-1:0] dout
""" % ("pmux_v" if with_valid else "pmux"))
        if (with_valid):
            fp.write(
"""
   , output reg valid
""")
        fp.write(
"""
);

   generate
""")

        fp.write("      ")
        for SELW in range(2,SELW_MAX):
            fp.write(
"""
      if (SELW==%d)
         begin : gen_enc_%d
            always @(*)
                begin
""" % (SELW, SELW))
            if (with_valid):
                fp.write(
"""
                    valid = 1'b1;
""")
            fp.write(
"""
                    casez(sel)
""")
            for i in range(SELW):
                fp.write("                       %d'b"%SELW)
                fp.write("".join(['?' for j in range(SELW-i-1)]))
                fp.write("1")
                fp.write("".join(['0' for j in range(i)]))
                fp.write(": dout = din[%d*DW +: DW];\n" %i)
            if (with_valid):
                fp.write("                       default: begin dout = din[0 +: DW]; valid = 1'b0; end\n")
            else:
                fp.write("                       default: begin dout = din[0 +: DW]; end\n")
            fp.write(
"""                    endcase
                end
         end
""")
            if SELW != SELW_MAX-1:
                fp.write(
"""
      else
""")

        fp.write(
"""`ifndef SYNTHESIS
else
      begin : gen_enc_fail
            initial
                $fatal("\\n Unimplemented size. Please update parameters of generator. \\n");
         end
`endif

    endgenerate

endmodule
""")

fn = sys.argv[1]
gen(fn, fn.find('_v.v')!=-1)
