// Verilog HDL for "COMP32211", "drawing_jp_rect" "functional"

/*
 *
 * Verilog rectangle drawing module
 *
 * Module will draw rectangles on the screen with the given colors and pattern
 *
 * The modules inputs are as follows
 *
 * wire_name | bits | description      | example
 * ----------|------|------------------|--------
 * r0        | 16   | start x pos      | 16'd10
 * r1        | 16   | start y pos      | 16'd10
 * r2[15:8]  | 8    | width            | 16'd200
 * r2[ 7:0]  | 8    | height           | 16'd200
 * r3[15:8]  | 8    | colour 1         |  8'b111_111_11
 * r3[ 7:0]  | 8    | colour 2         |  8'b101_100_01
 * r4        | 16   | pattern rows 1-2 | 16'b11111111_11111111
 * r5        | 16   | pattern rows 3-4 | 16'b11111111_11111111
 * r6        | 16   | pattern rows 5-6 | 16'b11111111_11111111
 * r7        | 16   | pattern rows 7-8 | 16'b11111111_11111111
 * */

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


// state enumeration
`define STATE_START 0      // state to await input request
`define STATE_ACK 1        // state to send ACK signal and latch params
`define STATE_CALCULATE 2  // state to calculate the next column params
`define STATE_DRAW 3       // state to draw the curent pixel block
`define STATE_DONE 4       // state to signal finished drawing

// fsm state
reg  [2:0]  state;
initial state = `STATE_START; // added to fix bug of module starting on FPGA
                              // in incorrect state

// internal transition signals, used by the fsm to decide on next state
wire        cols_to_draw;  // are there more columns to draw after this?
wire        last_col;      // is this the last column in the rectangle?
wire        rows_to_draw;  // is there any more rows to draw after this one?

// request params
reg  [15:0] startx;        // stores the curent start x position value
reg  [15:0] starty;        // stores the starting y position value
reg  [ 7:0] width;         // stores the remaining width left to
                           // draw (from startx)
reg  [ 7:0] height;        // stores the height of the rectangle
reg  [ 7:0] colourPalet [1:0];
                           // stores the two colours to be drawn
reg  [15:0] patternRegBank [3:0];
                           // stores the 8x8 pattern in 4 "reg's"
                           // these are arranged as follows
                           //0[----|----]
                           // [----|----]
                           //1[----|----]
                           // [----|----]
                           //2[----|----]
                           // [----|----]
                           //3[----|----]
                           // [----|----]
                           //
                           // where each row above is supplied in a seperate
                           // reg

// calculated values (assigns)
wire [15:0] startxWord;    // word alligned value of startx
wire [15:0] nextStartx;    // next value of startx (after this col is done) 
wire [ 2:0] pxDone;        // number of pixels complete in this col (1,2,3,4)
wire [15:0] nextWidth;     // the next value of width (after this col)

// coldraw params
reg  [15:0] remHeight;     // remaining height to draw in this column

// calculated values (assigns)
wire [15:0] nextRemHeight; // the next value of remHeight
wire [15:0] colx;          // column to draw (word alligned)
reg  [ 3:0] colmask;       // this columns mask
wire [15:0] coloffset;     // the offset into this column of the first drawn px
wire [15:0] curY;          // the current Y value of this row


wire [ 1:0] patternRegSel; // the selected pattern from bank
wire [15:0] patternReg;    // the value of the selected pattern bank
wire [ 7:0] row;           // the row from the selected pattern bank
wire [ 3:0] pattern;       // the column from the row

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
      if(rows_to_draw || !de_ack)
        state <= `STATE_DRAW;
      else
        state <= (last_col)? `STATE_CALCULATE:`STATE_DONE;
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
        startx = r0;
        starty = r1;
        width  = r2[15:8];
        height = r2[ 7:0];
        colourPalet[0]= r3[15:8];
        colourPalet[1]= r3[ 7:0];
        patternRegBank[0] = r4;
        patternRegBank[1] = r5;
        patternRegBank[2] = r6;
        patternRegBank[3] = r7;
      end
    end
    `STATE_ACK:
    begin
      
    end
    `STATE_CALCULATE:
    begin
      if(cols_to_draw)
      begin
        remHeight = height; // store complete height
      end
    end
    `STATE_DRAW:
    begin
      if(!de_ack)
        ;
      else if(rows_to_draw)
        remHeight = remHeight - 1;
      else if(last_col)
        begin
          startx = nextStartx;
          width = nextWidth;
        end
    end
    //`STATE_DONE:
    
  endcase
end

// assign outputs
assign busy = (state==`STATE_START||state==`STATE_DONE)? 0:1;
assign ack = (state==`STATE_ACK)? 1:0;
// assign signals for fsm
assign cols_to_draw = (width>0)? 1:0;
assign last_col = (nextWidth>0)? 1:0;
assign rows_to_draw = nextRemHeight>0;
// assign helper signals
assign startxWord = startx&((0-1)<<2);
assign pxDone = (width>3)? (4) - (startx & 2'h3):width;
assign nextStartx = startxWord + (1<<2);
assign nextWidth = width - pxDone;
assign nextRemHeight = remHeight - 1;
assign curY = starty+nextRemHeight;
assign colx = startxWord;
assign coloffset = startx - startxWord;
// color assignments
assign patternRegSel = curY[2:1];
assign patternReg = patternRegBank[patternRegSel];
assign row = curY[0]? patternReg[15:8]:patternReg[7:0];
assign pattern = startxWord[2]? row[3:0]:row[7:4];


// assign output pixel draw
assign de_req = (state==`STATE_DRAW)? 1:0;
assign de_addr =  ( (curY<<5) + (curY<<7) + (startxWord>>2) );
assign de_nbyte = ~colmask;
assign de_rnw = 0;
assign de_w_data = {
  colourPalet[pattern[0]],
  colourPalet[pattern[1]],
  colourPalet[pattern[2]],
  colourPalet[pattern[3]]};


// calculate colmask
// this is a selection of which pixels to draw
always @ (coloffset,pxDone)
begin
  case(pxDone)
    1: begin case (coloffset)
        3:colmask <= 4'b1000;
        2:colmask <= 4'b0100;
        1:colmask <= 4'b0010;
        0:colmask <= 4'b0001;
        default colmask<=4'bxxxx;
       endcase end
    2: begin case (coloffset)
        2:colmask <= 4'b1100;
        1:colmask <= 4'b0110;
        0:colmask <= 4'b0011;
        default colmask<=4'bxxxx;
       endcase end
    3: colmask <= (coloffset==0)? 4'b1110:4'b0111;
    4: colmask <= 4'b1111;
    default: colmask<=4'bxxxx;
  endcase
end
endmodule
