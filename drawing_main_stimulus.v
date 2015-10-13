// Example test stimulus for drawing_main schematic design //

// Define some register names
`define R0  6'h00
`define R1  6'h01
`define R2  6'h02
`define R3  6'h03
`define R4  6'h04
`define R5  6'h05
`define R6  6'h06
`define R7  6'h07
`define GO  6'h08

`define LINESZ 640


`define LINE  1
/*----------------------------------------------------------------------------*/
// Stop simulator running after a frame scan
initial
begin
#20000000;
$stop;
end
/*----------------------------------------------------------------------------*/
/* Clock generator used for DUT and frame store                                                           */

initial clk = 0;
always #20 clk <= ~clk;

/*----------------------------------------------------------------------------*/
// Reset DUT 
initial
 begin
  reset = 0;
  #102 reset = 1;
  #80  reset = 0;
 end 
/*----------------------------------------------------------------------------*/ 
/* Microprocessor end of test bench                                           */

reg [15:0] status; 
initial
begin
uP_ncs     = 1'b1;
uP_address = 6'h00;
uP_nbs     = 2'b11;
uP_nrd     = 1'b1;
uP_nwr     = 1'b1;
uP_wdata   = 16'h0000;

// wait until the drawing engine is not busy
#200 bus_read(15, status);
while(status[1])
 #200 bus_read(15, status);



/*---------------------------------------------------------------------------------*/
//Draw a white line starting at 100,100 and finishing at 200,150

pre_process_line(100, 100, 200, 150, 255);

// wait until the drawing engine has finished drawing shape
#200 bus_read(15, status);
while(status[1])
 #200 bus_read(15, status);
 
end // Finished sending drawing commands


/*----------------------------------------------------------------------------*/
task pre_process_line(input [15:0] x0, y0, x1, y1, colour);

reg [15:0] dx, dy, adx, ady;            // Coordinate differences & abs()
reg [15:0] sx, sy;                      // Pixel address steps
reg [15:0] m, n;                        // Larger/smaller absolute differences
reg [15:0] a1, a2;                      // Steps in major axis/both axes
reg [19:0] start_addr;                  // start address of line

begin
  dx = x1 - x0;
  dy = y1 - y0;
  if (dx[15]) begin sx =   -1; adx = -dx; end else begin sx =   1; adx = dx; end
  if (dy[15]) begin sy = -640; ady = -dy; end else begin sy = 640; ady = dy; end
  if (adx > ady) begin a1 = sx; m = adx; n = ady; end
  else           begin a1 = sy; m = ady; n = adx; end
  a2 = sx + sy;

  start_addr = y0*`LINESZ + x0;


draw_line(m, n, a1, a2, start_addr[15:0], start_addr[19:16],  colour);
end
endtask





/*----------------------------------------------------------------------------*/
task draw_line(input [15:0] r0, r1, r2, r3, r4, r5, r6);
begin
bus_write(`R0, r0);		// abs(Larger difference)
bus_write(`R1, r1);		// abs(Smaller difference)
bus_write(`R2, r2);		// Primary step
bus_write(`R3, r3);		// Both steps
bus_write(`R4, r4);		// Address (L)
bus_write(`R5, r5);		// Address (H)
bus_write(`R6, r6);		// Colour
bus_write(`GO, `LINE);		// Command
end
endtask

/*----------------------------------------------------------------------------*/
// Microprocessor register write task
// This task is asynchronous; it is not related to the system clock in any way

task bus_write(input [5:0] addr, input [15:0] data);
begin
uP_ncs     = 1'b0;
uP_address = addr;
uP_wdata   = data;
#10				// Set up time
uP_nwr     = 1'b0;		// Activate strobe
#15				// Pulse width
uP_nwr     = 1'b1;		// Deactivate strobe
#10				// Hold time
uP_ncs     = 1'b1;		// Deselect
end
endtask

/*----------------------------------------------------------------------------*/
// Microprocessor register read task
// This task is asynchronous; it is not related to the system clock in any way

task bus_read(input [5:0] addr, output [15:0] data);
begin
uP_ncs     = 1'b0;
uP_address = addr;
uP_nwr     = 1'b1;
#25
data   = uP_rdata;
#10				
uP_ncs     = 1'b1;		
end
endtask


/*----------------------------------------------------------------------------*/
/* Frame store end of test bench                                              */

/* Virtual screen to display shapes                                           */
initial $start_screen("-k123", "-c332", "-s1");

/* Simple test diagnostics                                                    */
integer line_count;
always @ (posedge hsync)
if (vsync) line_count <= 0;
else       line_count <= line_count + 1;


/* (Crude) SRAM model                                                         */

reg [7:0] frame_store0 [0:131071];	// 0.5 MB SRAM
reg [7:0] frame_store1 [0:131071];	//
reg [7:0] frame_store2 [0:131071];	//
reg [7:0] frame_store3 [0:131071];	//
reg [7:0] out_reg0, out_reg1, out_reg2, out_reg3;

// Make into a 'properly' timed async. SRAM @@@
integer fs_addr_t, fs_ncs_t, fs_noe_t, fs_nwe_t;
reg data_valid;

integer i;
initial
for (i = 0; i < 131072; i = i + 1)	// Blank screen, simulation hack
  begin
  frame_store0[i] = 8'h00;
  frame_store1[i] = 8'h00;
  frame_store2[i] = 8'h00;
  frame_store3[i] = 8'h00;
  end

initial
for (i = 0; i < 76800; i = i + 1)      // Blank virtual screen screen
  begin
   $write_screen(123, 0, i, 0);
   $write_screen(123, 1, i, 0);
   $write_screen(123, 2, i, 0);
   $write_screen(123, 3, i, 0);
  end


always @ (fs_address) fs_addr_t = $time;
always @ (fs_ncs)     fs_ncs_t  = $time;
always @ (fs_nwe)     fs_nwe_t  = $time;
always @ (fs_noe)     fs_noe_t  = $time;

always #1
begin
if (!fs_ncs && !fs_noe && fs_nwe && ($time > (fs_addr_t + 55))
                                 && ($time > (fs_ncs_t + 55))
                                 && ($time > (fs_noe_t + 10))
                                 && ($time > (fs_nwe_t + 10)))
  data_valid = 1;
else
  data_valid = 0;
end

always @ (data_valid)
begin
#1
if (data_valid)
  fs_rdata <= {out_reg3, out_reg2, out_reg1, out_reg0};
else
  fs_rdata <= 32'hxxxx;
end

always @ (posedge clk)		// Shouldn't be clocked @@@@
begin
if (!fs_ncs[0])
  if (!fs_nwe)
    begin
    if (!fs_nbyte_sel[0]) begin frame_store0[fs_address[16:0]] <= fs_wdata[7:0]; $write_screen(123, 0, fs_address[16:0], fs_wdata[7:0]); end
    if (!fs_nbyte_sel[1]) begin frame_store1[fs_address[16:0]] <= fs_wdata[15:8]; $write_screen(123, 1, fs_address[16:0], fs_wdata[15:8]); end
    end
  else
    if (!fs_noe)
      begin
      out_reg0 <= frame_store0[fs_address[16:0]];
      out_reg1 <= frame_store1[fs_address[16:0]];
      end
if (!fs_ncs[1])
  if (!fs_nwe)
    begin
    if (!fs_nbyte_sel[2]) begin frame_store2[fs_address[16:0]] <= fs_wdata[23:16]; $write_screen(123, 2, fs_address[16:0], fs_wdata[23:16]); end
    if (!fs_nbyte_sel[3]) begin frame_store3[fs_address[16:0]] <= fs_wdata[31:24]; $write_screen(123, 3, fs_address[16:0], fs_wdata[31:24]); end
    end
  else
    if (!fs_noe)
      begin
      out_reg2 <= frame_store2[fs_address[16:0]];
      out_reg3 <= frame_store3[fs_address[16:0]];
      end
end

/*----------------------------------------------------------------------------*/

