/*
 * Copyright (c) 2024 Your Name
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

// =======================
// Original MAC module
// =======================
module mac_unit #(
    parameter DATA_WIDTH = 8
)(
    input  wire                        clk,
    input  wire                        rst_n,
    input  wire                        clear,
    input  wire                        in_valid,
    input  wire signed [DATA_WIDTH-1:0] in_a,
    input  wire signed [DATA_WIDTH-1:0] in_b,
    input  wire                        in_last,
    input  wire                        out_ready,
    output reg                         in_ready,
    output reg                         out_valid,
    output reg  signed [DATA_WIDTH*2+7:0] out_acc
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out_acc   <= 'b0;
            out_valid <= 'b0;
            in_ready  <= 'b0;
        end else begin
            out_valid <= 'b0;
            in_ready  <= 'b1;

            if (clear) begin
                out_acc <= 'b0;
            end else if (in_valid) begin
                out_acc <= out_acc + (in_a * in_b);

                if (in_last) begin
                    out_valid <= 'b1;
                end
            end
        end
    end

endmodule


// =======================
// Tiny Tapeout wrapper
// =======================
module tt_um_mac (
    input  wire [7:0] ui_in,
    output wire [7:0] uo_out,
    input  wire [7:0] uio_in,
    output wire [7:0] uio_out,
    output wire [7:0] uio_oe,
    input  wire       ena,
    input  wire       clk,
    input  wire       rst_n
);

    // Map inputs (đơn giản hóa để pass flow)
    wire signed [7:0] in_a = ui_in;
    wire signed [7:0] in_b = uio_in;

    wire clear    = 1'b0;
    wire in_valid = 1'b1;
    wire in_last  = 1'b1;
    wire out_ready = 1'b1;

    wire in_ready;
    wire out_valid;
    wire signed [23:0] out_acc;

    mac_unit uut (
        .clk(clk),
        .rst_n(rst_n),
        .clear(clear),
        .in_valid(in_valid),
        .in_a(in_a),
        .in_b(in_b),
        .in_last(in_last),
        .out_ready(out_ready),
        .in_ready(in_ready),
        .out_valid(out_valid),
        .out_acc(out_acc)
    );

    // Output: lấy 8 bit thấp
    assign uo_out = out_acc[7:0];

    // Không dùng IO bidirectional
    assign uio_out = 8'b0;
    assign uio_oe  = 8'b0;

    // tránh warning
    wire _unused = &{ena, in_ready, out_valid, out_acc[23:8], 1'b0};

endmodule
