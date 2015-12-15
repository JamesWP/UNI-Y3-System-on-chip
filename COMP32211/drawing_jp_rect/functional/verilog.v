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


// state enumeration
`define STATE_START 0
`define STATE_ACK 1
`define STATE_CALCULATE 2
`define STATE_DRAW 3
`define STATE_DONE 4

// fsm state
reg  [2:0]  state;
initial state = `STATE_START;
// internal transition signals
wire        cols_to_draw;  // are there more columns to draw after this
wire        last_col;
wire        rows_to_draw;
// request params
reg  [15:0] startx;
wire [15:0] startxWord; // word alligned value of startx
wire [15:0] nextStartx; // next value of startx (after this col is done) 
wire [ 2:0] pxDone; // number of pixels complete in this col (0,1,2,3,4)
reg  [15:0] starty;
reg  [ 7:0] width;
wire [15:0] nextWidth; // the next value of width (after this col)
reg  [ 7:0] height;
// coldraw params
reg  [15:0] remHeight; //remaining height to draw
wire [15:0] nextRemHeight;
wire [15:0] colx; // column to draw (word alligned)
reg  [ 3:0] colmask;
wire [15:0] coloffset;
wire [15:0] curY;

reg  [ 7:0] colourPalet [1:0];

reg  [15:0] patternRegBank [3:0]; // all the patterns
wire [ 1:0] patternRegSel; // the selected pattern from bank
wire [15:0] patternReg; // the value of the selected pattern bank
wire [ 7:0] row; // the row from the selected pattern bank
wire [ 3:0] pattern; // the column from the row

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


assign busy = (state==`STATE_START||state==`STATE_DONE)? 0:1;
assign ack = (state==`STATE_ACK)? 1:0;
assign cols_to_draw = (width>0)? 1:0;
assign last_col = (nextWidth>0)? 1:0;
assign startxWord = startx&((0-1)<<2);
assign pxDone = (width>3)? (4) - (startx & 2'h3):width;
assign nextStartx = startxWord + (1<<2);
assign nextWidth = width - pxDone;
assign nextRemHeight = remHeight - 1;
assign rows_to_draw = nextRemHeight>0;

assign curY = starty+nextRemHeight;

assign colx = startxWord;
assign coloffset = startx - startxWord;

// color assignments
assign patternRegSel = curY[2:1];
assign patternReg = patternRegBank[patternRegSel];
assign row = curY[0]? patternReg[15:8]:patternReg[7:0];
assign pattern = startxWord[2]? row[3:0]:row[7:4];


//TODO: assign values
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
