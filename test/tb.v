`default_nettype none
`timescale 1ns / 1ps

module tb ();

  // Dump waveform
  initial begin
    $dumpfile("tb.fst");
    $dumpvars(0, tb);
    #1;
  end

  // ======================
  // Tiny Tapeout signals
  // ======================
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

  // ======================
  // Instantiate wrapper
  // ======================
  tt_um_mac dut (
`ifdef GL_TEST
      .VPWR(VPWR),
      .VGND(VGND),
`endif
      .ui_in  (ui_in),
      .uo_out (uo_out),
      .uio_in (uio_in),
      .uio_out(uio_out),
      .uio_oe (uio_oe),
      .ena    (ena),
      .clk    (clk),
      .rst_n  (rst_n)
  );

  // ======================
  // Clock
  // ======================
  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end

  // ======================
  // Internal signals (giữ logic cũ)
  // ======================
  localparam DATA_WIDTH = 8;

  reg clear;
  reg in_valid;
  reg signed [DATA_WIDTH-1:0] in_a;
  reg signed [DATA_WIDTH-1:0] in_b;
  reg in_last;
  reg out_ready;

  wire signed [DATA_WIDTH*2+7:0] out_acc;

  // Vì wrapper đã hardcode → ta chỉ test logic giả lập
  assign out_acc = {16'b0, uo_out};  // lấy 8 bit thấp

  // ======================
  // Expect task (giữ nguyên)
  // ======================
  task expect;
    input signed [DATA_WIDTH*2+7:0] actual;
    input signed [DATA_WIDTH*2+7:0] expected;
    begin
      if (actual !== expected) begin
        $display("TEST FAILED");
        $display("Expect: %0d", expected);
        $display("Actual: %0d", actual);
        $finish;
      end
    end
  endtask

  // ======================
  // Test sequence (giữ logic)
  // ======================
  initial begin
    rst_n = 0;
    ena   = 1;
    ui_in = 0;
    uio_in = 0;

    repeat (3) @(posedge clk);
    rst_n = 1;

    // Cycle 1
    @(posedge clk);
    ui_in  = 8'd1;
    uio_in = 8'd4;

    @(posedge clk);
    expect(out_acc, 4);

    // Cycle 2
    ui_in  = 8'd2;
    uio_in = 8'd5;

    @(posedge clk);
    expect(out_acc, 14);

    // Cycle 3
    ui_in  = 8'd3;
    uio_in = 8'd6;

    @(posedge clk);
    expect(out_acc, 32);

    // Reset (simulate clear)
    @(posedge clk);
    rst_n = 0;
    @(posedge clk);
    rst_n = 1;

    @(posedge clk);
    expect(out_acc, 0);

    $display("TEST PASSED");
    $finish;
  end

endmodule
