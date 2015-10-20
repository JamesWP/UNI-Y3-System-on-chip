
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

always @(posedge error)
begin
  $display("[%4d] Error occured", clkNo);
  #100 $stop;
end

always @(posedge clk)
case (clkNo)
  10: testSignals;

  100: test1;
  
  200: test2;

  300: $stop;
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

