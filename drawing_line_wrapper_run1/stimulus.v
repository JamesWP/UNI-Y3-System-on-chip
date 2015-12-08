// James Peach
// test module for rectangle drawer jp_rect

// Verilog stimulus file.
// Please do not create a module in this file.
/*

#VALUE      creates a delay of VALUE ns
a=VALUE;    sets the value of input 'a' to VALUE
$stop;      tells the simulator to stop

*/

// clock code
integer clkNo = 0;
initial clk = 0;
initial req = 0;
integer startClk;  
always #10 clk = ~clk;
always @(posedge clk) clkNo = clkNo +1;

reg error = 0;

// always process requests from the module to
// draw pixels if de_req is high at a clock edge
always @(posedge clk)
begin
  if(de_req)
    process_draw_request;
end

// if error occurs stop simulation
always @(posedge error)
begin
  $display("[%4d] Error occured", clkNo);
  #100 $finish;
end


// log a request to the module to draw line
always @(posedge clk)
begin
  if(ack)
  begin
    $display("[%4d] Test Rectangle (%3d,%3d) size [%3dx%3d]",clkNo, 
      r0, r1, r2, r3);
    @(negedge ack); // wait for ack to remove (avoid printing twice)
  end
end

// run tests at appropiate times
always @(posedge clk)
case (clkNo)
  10: test1;
  10000: $finish;
endcase


task test1;
begin

  req = 0;
  r0 = 0;
  r1 = 0;
  r2 = 10;
  r3 = 10;

  #10 req = 1;

  // wait for ack
  if (ack !== 1) @(posedge clk);
  if (ack !== 1) @(posedge clk);
  if (ack !== 1) @(posedge clk);
  if (ack !== 1) @(posedge clk);

  #10 req = 0;

  $display("[%4d] Test Complete",clkNo);
end
endtask


reg [17:0] de_addr_tmp;
reg [31:0] de_data_tmp;
// listens to the module and takes one request to draw
// this will also simulate a memory cycle after the request
// is accepted before returning to accept another request
task process_draw_request;
begin
  // then on the next clock cycle...
  @(posedge clk)
  
  de_addr_tmp = de_addr;
  de_data_tmp = de_data; 

  $display("[%4d] Plot(x=%3d,y=%3d,d=%x,e=%b)",clkNo,(de_addr%160)*4,de_addr/160,de_data,de_nbyte);
  #1 de_ack = 1;
  // for one clock
  @(posedge clk)

  if(de_addr_tmp != de_addr) error=1;
  if(de_data_tmp != de_data) error=1;

  #1 de_ack = 0;
  // await one cycle to simulate memory bus delay
  @(posedge clk);

end
endtask

