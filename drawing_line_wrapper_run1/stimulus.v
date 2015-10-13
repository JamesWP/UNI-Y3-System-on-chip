
// Verilog stimulus file.
// Please do not create a module in this file.
/*

#VALUE      creates a delay of VALUE ns
a=VALUE;    sets the value of input 'a' to VALUE
$stop;      tells the simulator to stop

*/

initial clk = 0;
always #10 clk = ~clk;
initial #20000 $stop;

//event reset_done;

// always process requests from the module to
// draw pixels if de_req is high at a clock edge
always @(posedge clk)
begin
  if(de_req)
    process_draw_request();
end

initial
begin
  $display("[%t] Test Start",$time);

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

//  -> reset_done;
//end

//initial
//begin
//  @(reset_done) 
  
  #30  

  $display("[%t] Parameters Set",$time);
  // from (r0,r1)
  r0 = 10;
  r1 = 10;
  // to (r2,r3)
  r2 = 20;
  r3 = 20;
  // in color r6
  r6 = 10;

  #1 req = 1;


  $display("[%t] Waiting for ack",$time);
  #1 @(posedge ack)
  $display("[%t] Got ack",$time);  

  @(posedge clk)
  
  #1 req = 0;

  // wait for module to not be busy
  @(negedge busy)
  
  $display("[%t] Finished plotting",$time);

  $stop;
end



// listens to the module and takes one request to draw
// this will also simulate a memory cycle after the request
// is accepted before returning to accept another request
task process_draw_request;
begin
  // then on the next clock cycle...
  @(posedge clk)
  $display("[%t] Plot(x=%3d,y=%3d,d=%x,e=%b)",$time,de_addr%640,de_addr/640,de_data,de_nbyte);
  #1 de_ack = 1;
  // for one clock
  @(posedge clk)
  #1 de_ack = 0;
  // await one cycle to simulate memory bus delay
  @(posedge clk);

  $display("[%t] Plot complete",$time);
end
endtask

