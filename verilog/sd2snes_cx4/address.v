`timescale 1 ns / 1 ns
//////////////////////////////////////////////////////////////////////////////////
// Company: Rehkopf
// Engineer: Rehkopf
//
// Create Date:    01:13:46 05/09/2009
// Design Name:
// Module Name:    address
// Project Name:
// Target Devices:
// Tool versions:
// Description: Address logic w/ SaveRAM masking
//
// Dependencies:
//
// Revision:
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////
module address(
  input CLK,
  input [15:0] featurebits,
  input [2:0] MAPPER,       // MCU detected mapper
  input [23:0] SNES_ADDR,   // requested address from SNES
  input [7:0] SNES_PA,      // peripheral address from SNES
  input SNES_ROMSEL,        // ROMSEL from SNES
  output [23:0] ROM_ADDR,   // Address to request from SRAM0
  output ROM_HIT,           // want to access RAM0
  output IS_SAVERAM,        // address/CS mapped as SRAM?
  output IS_ROM,            // address mapped as ROM?
  output IS_WRITABLE,       // address somehow mapped as writable area?
  input [23:0] SAVERAM_MASK,
  input [23:0] ROM_MASK,
  output msu_enable,
  output cx4_enable,
  output cx4_vect_enable,
  output r213f_enable,
  output r2100_hit,
  output snescmd_enable,
  output nmicmd_enable,
  output return_vector_enable,
  output branch1_enable,
  output branch2_enable,
  output branch3_enable
);

parameter [2:0]
  FEAT_MSU1 = 3,
  FEAT_213F = 4,
  FEAT_2100 = 6
;

wire [23:0] SRAM_SNES_ADDR;

/* Cx4 mapper:
   - LoROM (extended to 00-7d, 80-ff)
   - MMIO @ 6000-7fff
   - SRAM @ 70-77:0000-7fff
 */

assign IS_ROM = ~SNES_ROMSEL;

/* SaveRAM decode. Stock, and it must stay stock in THIS core: the Cx4's own
   MMIO window is !A22 & A[15:13]==011, so any SaveRAM window on the A22=0
   side is a strict subset of it -- the read mux (main.v) gives cx4_enable
   priority, while ROM_WE does not check it, so writes would land and reads
   would not. base/address.v's high window is safe there only because base
   has no Cx4 MMIO. This window is at A22=1 and cannot collide. */
assign IS_SAVERAM = |SAVERAM_MASK & (~SNES_ADDR[23] & &SNES_ADDR[22:20] & ~SNES_ADDR[19] & ~SNES_ADDR[15]);

/* ROM decode, selected by the MCU-detected MAPPER.
   The 110 formula is taken from sd2snes_base/address.v, which is the
   authority for mapper decode in this tree. Any mapper this core does not
   recognise falls through to the stock LoROM branch, so an unmodified Cx4
   image is unaffected. The firmware never selects mapper 2 for a Cx4 image
   (src/smc.c), so there is no ExHiROM branch here.

     001 (and default)  LoROM    masked,   reaches  4 MB
     110                SO96     A15 split, unmasked, reaches 16 MB

   110 carries no ROM_MASK in base either: 96 Mbit is 12 MB, not a power of
   two, so it cannot be expressed as a bitmask AND. */
assign SRAM_SNES_ADDR = IS_SAVERAM
                        ? (24'hE00000 | ({SNES_ADDR[19:16], SNES_ADDR[14:0]}
                         & SAVERAM_MASK))
                        : (MAPPER == 3'b110)
                        ? (SNES_ADDR[15]
                           ? ({1'b0, SNES_ADDR[23:16], SNES_ADDR[14:0]})
                           : ({2'b10,
                               SNES_ADDR[23],
                               SNES_ADDR[21:16],
                               SNES_ADDR[14:0]}
                             )
                          )
                        : ({2'b00, SNES_ADDR[22:16], SNES_ADDR[14:0]}
                         & ROM_MASK);

assign ROM_ADDR = SRAM_SNES_ADDR;

assign IS_WRITABLE = IS_SAVERAM;

assign ROM_HIT = IS_ROM | IS_WRITABLE;

wire msu_enable_w = featurebits[FEAT_MSU1] & (!SNES_ADDR[22] && ((SNES_ADDR[15:0] & 16'hfff8) == 16'h2000));
assign msu_enable = msu_enable_w;

wire cx4_enable_w = (!SNES_ADDR[22] && (SNES_ADDR[15:13] == 3'b011));
assign cx4_enable = cx4_enable_w;

assign cx4_vect_enable = &SNES_ADDR[15:5];

assign r213f_enable = featurebits[FEAT_213F] & (SNES_PA == 8'h3f);
assign r2100_hit = (SNES_PA == 8'h00);

assign snescmd_enable = ({SNES_ADDR[22], SNES_ADDR[15:9]} == 8'b0_0010101);
assign nmicmd_enable = (SNES_ADDR == 24'h002BF2);
assign return_vector_enable = (SNES_ADDR == 24'h002A6C);
assign branch1_enable = (SNES_ADDR == 24'h002A1F);
assign branch2_enable = (SNES_ADDR == 24'h002A59);
assign branch3_enable = (SNES_ADDR == 24'h002A5E);
endmodule
