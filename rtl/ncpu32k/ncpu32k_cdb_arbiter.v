/***************************************************************************/
/*  Nano-cpu 32000 (Scalable Ultra-Low-Power Processor)                    */
/*                                                                         */
/*  Copyright (C) 2021 cassuto <psc-system@outlook.com>, China.            */
/*  This project is free edition; you can redistribute it and/or           */
/*  modify it under the terms of the GNU Lesser General Public             */
/*  License(GPL) as published by the Free Software Foundation; either      */
/*  version 2.1 of the License, or (at your option) any later version.     */
/*                                                                         */
/*  This project is distributed in the hope that it will be useful,        */
/*  but WITHOUT ANY WARRANTY; without even the implied warranty of         */
/*  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU      */
/*  Lesser General Public License for more details.                        */
/***************************************************************************/

`include "ncpu32k_config.h"

module ncpu32k_cdb_arbiter
#(
   parameter WAYS,
   parameter TAG_WIDTH,
   parameter ID_WIDTH
)
(
   input                      clk,
   input                      rst_n,
   input [WAYS-1:0]           fu_commit_BVALID,
   output [WAYS-1:0]          fu_commit_BREADY,
   input [WAYS*`NCPU_DW-1:0]  fu_commit_BDATA,
   input [WAYS*TAG_WIDTH-1:0] fu_commit_BTAG,
   input [WAYS*ID_WIDTH-1:0]  fu_commit_id,
   output                     rob_commit_BVALID,
   input                      rob_commit_BREADY,
   output [`NCPU_DW-1:0]      rob_commit_BDATA,
   output [TAG_WIDTH-1:0]     rob_commit_BTAG,
   output [ID_WIDTH-1:0]      rob_commit_id
);

   wire [WAYS-1:0] grant;
   genvar i;
   
   ncpu32k_priority_onehot
      #(
         .DW            (WAYS),
         .POLARITY_DIN  (1),
         .POLARITY_DOUT (1)
      )
   P_ONEHOT_ARBITER
      (
         .DIN  (fu_commit_BVALID),
         .DOUT (grant)
      );
   
   generate
      wire [`NCPU_DW-1:0]  BDATA [WAYS:0];
      wire [TAG_WIDTH-1:0] BTAG  [WAYS:0];
      wire [ID_WIDTH-1:0]  id    [WAYS:0];
      
      assign BDATA[0] = {`NCPU_DW{1'b0}};
      assign BTAG[0] = {TAG_WIDTH{1'b0}};
      assign id[0] = {ID_WIDTH{1'b0}};
      
      for(i=0;i<WAYS;i=i+1)
         begin : gen_sel
            assign fu_commit_BREADY[i] = grant[i] & rob_commit_BREADY;
            
            assign BDATA[i+1] = BDATA[i] | (fu_commit_BDATA[(i+1)*`NCPU_DW-1: i*`NCPU_DW] & {`NCPU_DW{grant[i]}});
            assign BTAG[i+1] = BTAG[i] | (fu_commit_BTAG[(i+1)*TAG_WIDTH-1: i*TAG_WIDTH] & {TAG_WIDTH{grant[i]}});
            assign id[i+1] = id[i] | (fu_commit_id[(i+1)*ID_WIDTH-1: i*ID_WIDTH] & {ID_WIDTH{grant[i]}});
         end
      
      assign rob_commit_BDATA = BDATA[WAYS];
      assign rob_commit_BTAG = BTAG[WAYS];
      assign rob_commit_id = id[WAYS];
   endgenerate
   
   assign rob_commit_BVALID = |fu_commit_BVALID;

   
   // synthesis translate_off
`ifndef SYNTHESIS
   `include "ncpu32k_assert.h"

   // Assertions
`ifdef NCPU_ENABLE_ASSERT
   always @(posedge clk)
      begin
         if (rob_commit_BVALID ^ |grant)
            $fatal("\n Check the CDB arbiter schema\n");
      end
`endif

`endif
   // synthesis translate_on
   
endmodule