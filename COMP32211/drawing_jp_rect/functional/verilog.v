// Verilog HDL for "COMP32211", "drawing_dummy" "functional"
// This is an inactive cell which takes the place of a drawing function.
// It 'ties off' outputs tidily.

`define TPD 2

module drawing_jp_rect( input  wire        clk,
                      input  wire        req,
                      output wire        ack,
                      output wire        busy,
                      input  wire [15:0] r0,
                      input  wire [15:0] r1,
                      input  wire [15:0] r2,
                      input  wire [15:0] r3,
                      input  wire [15:0] r4,
                      input  wire [15:0] r5,
                      input  wire [15:0] r6,
                      input  wire [15:0] r7,
                      output wire        de_req,
                      input  wire        de_ack,
                      output wire [17:0] de_addr,
                      output wire  [3:0] de_nbyte,
                      output wire        de_rnw,
                      output wire [31:0] de_w_data,
                      input  wire [31:0] de_r_data );


// fsm state
reg  [2:0]  state;
// internal transition signals
wire        cols_to_draw;  // are there more columns to draw after this
wire        rows_to_draw;
// request params
reg  [15:0] startx;
wire [15:0] startxWord; // word alligned value of startx
wire [15:0] nextStartx; // next value of startx (after this col is done) 
wire [15:0] pxDone; // number of pixels complete in this col
reg  [15:0] starty;
reg  [15:0] width;
wire [15:0] nextWidth; // the next value of width (after this col)
reg  [15:0] height;
// coldraw params
reg  [15:0] remHeight; //remaining height to draw
wire [15:0] colx; // column to draw (word alligned)
wire [15:0] colmask;

// state enumeration
`define STATE_START 0
`define STATE_ACK 1
`define STATE_CALCULATE 2
`define STATE_DRAW 3
`define STATE_DONE 4

// STATE TRANSITION FOR FSM
always @ (posedge clk)
begin
  case (state)
    `STATE_START:
      state <= (req)? `STATE_ACK:`STATE_START;
    `STATE_ACK:
      state <= `STATE_CALCULATE;
    `STATE_CALCULATE:
      state <= (cols_to_draw)? `STATE_DRAW:`STATE_DONE; 
    `STATE_DRAW:
      if(rows_to_draw)
        state <= `STATE_DRAW;
      else
        state <= (cols_to_draw)? `STATE_CALCULATE:`STATE_DONE;
    `STATE_DONE:
      state <= `STATE_START;
    default:
      state <= `STATE_START;
  endcase
end

always @ (posedge clk)
begin
  case (state)
    `STATE_START:
    begin
      if(req)
      begin
        startx = r1;
        starty = r2;
        width = r3;
        height = r4;
      end
    end
    //`STATE_ACK:
    `STATE_CALCULATE:
    begin
      if(cols_to_draw)
      begin
        remHeight = height; // store complete height
      end
    end
    //`STATE_DRAW:
    //`STATE_DONE:
    
  endcase
end

assign busy = (state==`STATE_START||state==`STATE_DONE)? 0:1;
assign ack = (state==`STATE_ACK)? 1:0;
assign cols_to_draw = (width - pxDone>=0)? 1:0;
assign startxWord = startx&((0-1)<<2);
assign pxDone = (startx>3)? (1<<2) - (startx & ((1<<2)-1)):width;
assign nextStartx = startxWord + (1<<2);
assign nextWidth = width - pxDone;

assign colx = startxWord;
assign colmask = (pxDone==4)? 4'b1111:0 /*TODO*/;
//TODO: assign values
assign de_req = 0;
assign de_addr = 18'hxxxxx;
assign de_nbyte = 4'b1111;
assign de_rnw = 0;
assign de_w_data = 32'h1111_1111;

endmodule
