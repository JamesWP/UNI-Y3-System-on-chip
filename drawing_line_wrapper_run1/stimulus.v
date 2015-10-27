// James Peach
// test module stimulus.v

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
    $display("[%4d] Test Line Start (%3d,%3d)->(%3d,%3d)",clkNo, 
      r0, r1, r2, r3, r6);
    @(negedge ack); // wait for ack to remove (avoid printing twice)
  end
end

// run tests at appropiate times
always @(posedge clk)
case (clkNo)
// test simple two pixel line
// test ack and busy lines
  10: testSignals;
// test one simple color line
  100: test1;
// test another color line
  200: test2;
// test changing data half though plot
  300: test3;
// test simple horiz line
  400: test_line(010,010,020,010,8'b111_111_11);
// test simple vertical lign
  500: test_line(010,010,010,020,8'b111_111_11);
// test reverse line (start low, move up)
  600: test_line(010,010,000,000,8'b111_111_11);
// test just-off vertical line
  700: test_line(000,000,015,050,8'b111_111_11);
// test just-off horizontal line
  900: test_line(000,000,050,015,8'b111_111_11);
// test long whole-screen line
  1100:test_line(000,000,639,479,8'b111_111_11);
 
  10000: $finish;
endcase

// Tasks
// Below are the tasks for testing the system

task testSignals;
begin
  $display("[%4d] Test Signals",clkNo);

  req = 0;
  r0 = 0;
  r1 = 0;
  r2 = 1;
  r3 = 0;
  r6 = 8'b111_111_11;
  #1 req = 1;

  @(posedge clk);

  startClk = clkNo;  
  while (ack !== 1 && clkNo < startClk + 10) @(posedge clk);

  if(clkNo < startClk + 10)
    $display("[%4d] Got Ack",clkNo);
  else
  begin
    $display("[%4d] No ack after 10 clock",clkNo);
    error = 1;
  end

  #1 req = 0;

  startClk = clkNo;  
  while (busy !== 1 && clkNo < startClk + 10) @(posedge clk);

  if(clkNo < startClk + 10)
    $display("[%4d] Stoped busy",clkNo);
  else
  begin
    $display("[%4d] No end to busy 10 clock",clkNo);
    error = 1;
  end

  
   
  $display("[%4d] Test Complete",clkNo);
end
endtask

task test_line;
input integer sx;
input integer sy;
input integer ex;
input integer ey;
input integer color;
begin

  req = 0;
  r0 = 0;
  r1 = 0;
  r2 = 0;
  r3 = 0;
  r4 = 0;
  r5 = 0;
  r6 = 0;
  r7 = 0;
  
  de_ack = 0;

  #30  

  $display("[%4d] Parameters Set",clkNo);

  // from (r0,r1)
  r0 = sx;
  r1 = sy;
  // to (r2,r3)
  r2 = ex;
  r3 = ey;
  // in color r6
  //      RRR GGG BB
  r6 = color;

  #1 req = 1;

  $display("[%4d] Waiting for ack",clkNo);
  #1 @(posedge ack)
  $display("[%4d] Got ack",clkNo);  

  @(posedge clk)
  #1 req = 0;
  
  // wait for module to not be busy
  @(negedge busy)
  
  $display("[%4d] Finished plotting",clkNo);
end 
endtask


task test3;
begin
  $display("[%4d] Test 3 Start",clkNo);

  req = 0;
  r0 = 0;
  r1 = 0;
  r2 = 0;
  r3 = 0;
  r4 = 0;
  r5 = 0;
  r6 = 0;
  r7 = 0;
  
  de_ack = 0;

  #30  

  $display("[%4d] Parameters Set",clkNo);

  // from (r0,r1)
  r0 = 00;
  r1 = 00;
  // to (r2,r3)
  r2 = 10;
  r3 = 10;
  // in color r6
  //      RRR GGG BB
  r6 = 8'b100_10_10;

  #1 req = 1;

  $display("[%4d] Waiting for ack",clkNo);
  #1 @(posedge ack)
  $display("[%4d] Got ack",clkNo);  

  @(posedge clk)
  #1 req = 0;
  
  @(posedge clk)

  #100 
  r1 = 14;
  r2 = 14; 
  r6 = 0;

  $display("[%4d] Changed data",clkNo);
  
  // wait for module to not be busy
  @(negedge busy)
  
  $display("[%4d] Finished plotting",clkNo);
end 
endtask


task test2;
begin
  $display("[%4d] Test 2 Start",clkNo);

  req = 0;
  r0 = 0;
  r1 = 0;
  r2 = 0;
  r3 = 0;
  r4 = 0;
  r5 = 0;
  r6 = 0;
  r7 = 0;
  
  de_ack = 0;

  #30  

  $display("[%4d] Parameters Set",clkNo);
  // from (r0,r1)
  r0 = 00;
  r1 = 00;
  // to (r2,r3)
  r2 = 10;
  r3 = 10;
  // in color r6
  //      RRR GGG BB
  r6 = 8'b100_10_10;

  #1 req = 1;

  $display("[%4d] Waiting for ack",clkNo);
  #1 @(posedge ack)
  $display("[%4d] Got ack",clkNo);  

  @(posedge clk)
  
  #1 req = 0;

  // wait for module to not be busy
  @(negedge busy)
  
  $display("[%4d] Finished plotting",clkNo);

end
endtask

task test1;
begin
  $display("[%4d] Test 1 Start",clkNo);

  req = 0;
  r0 = 0;
  r1 = 0;
  r2 = 0;
  r3 = 0;
  r4 = 0;
  r5 = 0;
  r6 = 0;
  r7 = 0;
  
  de_ack = 0;

  #30  

  $display("[%4d] Parameters Set",clkNo);
  // from (r0,r1)
  r0 = 00;
  r1 = 00;
  // to (r2,r3)
  r2 = 10;
  r3 = 10;
  // in color r6
  //      RRR GGG BB
  r6 = 8'b111_111_11;

  #1 req = 1;

  $display("[%4d] Waiting for ack",clkNo);
  #1 @(posedge ack)
  $display("[%4d] Got ack",clkNo);  

  @(posedge clk)
  
  #1 req = 0;

  // wait for module to not be busy
  @(negedge busy)
  
  $display("[%4d] Finished plotting",clkNo);

end
endtask


// listens to the module and takes one request to draw
// this will also simulate a memory cycle after the request
// is accepted before returning to accept another request
task process_draw_request;
begin
  // then on the next clock cycle...
  @(posedge clk)
  $display("[%4d] Plot(x=%3d,y=%3d,d=%x,e=%b)",clkNo,(de_addr%160)*4,de_addr/160,de_data,de_nbyte);
  #1 de_ack = 1;
  // for one clock
  @(posedge clk)
  #1 de_ack = 0;
  // await one cycle to simulate memory bus delay
  @(posedge clk);

end
endtask

