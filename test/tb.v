`default_nettype none
`timescale 1ns / 1ps

/* This testbench instantiates the module and makes signals available
   to the cocotb test.py 
*/
module tb ();

  // Dump các tín hiệu ra file FST để xem dạng sóng bằng GTKWave hoặc Surfer
  initial begin
    $dumpfile("tb.fst");
    $dumpvars(0, tb);
    #1;
  end

  // Khai báo các tín hiệu điều khiển từ phía Cocotb (Python)
  reg clk;
  reg rst_n;
  reg ena;
  reg [7:0] ui_in;
  reg [7:0] uio_in;
  wire [7:0] uo_out;
  wire [7:0] uio_out;
  wire [7:0] uio_oe;

`ifdef GL_TEST
  wire VPWR = 1'b1;
  wire VGND = 1'b0;
`endif

  // Kết nối vào Module MAC của bạn
  tt_um_mac_8bit_signed user_project (
`ifdef GL_TEST
      .VPWR(VPWR),
      .VGND(VGND),
`endif
      .ui_in  (ui_in),    // Chân input chính [7:4]=in_a, [3:0]=in_b
      .uo_out (uo_out),   // Chân output chính: 8-bit kết quả tích lũy
      .uio_in (uio_in),   // IO in: [0]=clear, [1]=in_valid, [2]=in_last
      .uio_out(uio_out),  // IO out: [3]=in_ready, [4]=out_valid
      .uio_oe (uio_oe),   // IO enable
      .ena    (ena),      
      .clk    (clk),      
      .rst_n  (rst_n)     
  );

endmodule
