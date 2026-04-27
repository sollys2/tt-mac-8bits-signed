# SPDX-FileCopyrightText: © 2024 Tiny Tapeout
# SPDX-License-Identifier: Apache-2.0

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, RisingEdge

@cocotb.test()
async def test_project(dut):
    dut._log.info("Bắt đầu chạy Testbench cho bộ MAC...")

    # Thiết lập Clock 10 MHz (chu kỳ 100ns)
    clock = Clock(dut.clk, 100, units="ns")
    cocotb.start_soon(clock.start())

    # --- Bước 1: Reset hệ thống ---
    dut._log.info("Thực hiện Reset")
    dut.ena.value = 1
    dut.ui_in.value = 0
    dut.uio_in.value = 0
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 10)
    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 2)

    # --- Bước 2: Test Case 1: 1 * 4 = 4 ---
    # ui_in[7:4] = a = 1 (0001), ui_in[3:0] = b = 4 (0100) -> ui_in = 0001 0100 (0x14)
    # uio_in[1] = in_valid = 1 -> uio_in = 0x02
    dut.ui_in.value = 0x14
    dut.uio_in.value = 0x02 
    await RisingEdge(dut.clk) # Chờ cạnh lên để mạch nhận dữ liệu
    
    # Chờ 1 chu kỳ để kết quả cập nhật vào thanh ghi acc
    await ClockCycles(dut.clk, 1)
    dut._log.info(f"Test 1*4: Output thực tế = {int(dut.uo_out.value)}")
    assert int(dut.uo_out.value) == 4

    # --- Bước 3: Test Case 2: Cộng dồn tiếp 2 * 5 = 10 (Tổng cũ 4 + 10 = 14) ---
    # ui_in[7:4] = a = 2 (0010), ui_in[3:0] = b = 5 (0101) -> ui_in = 0010 0101 (0x25)
    dut.ui_in.value = 0x25
    await RisingEdge(dut.clk)
    await ClockCycles(dut.clk, 1)
    dut._log.info(f"Test +2*5: Output thực tế = {int(dut.uo_out.value)}")
    assert int(dut.uo_out.value) == 14

    # --- Bước 4: Test Case 3: Cộng dồn tiếp 3 * 6 = 18 (Tổng cũ 14 + 18 = 32) ---
    # Đánh dấu đây là dữ liệu cuối cùng (in_last)
    # ui_in[7:4] = 3, ui_in[3:0] = 6 -> ui_in = 0x36
    # uio_in[1] = valid, uio_in[2] = in_last -> uio_in = 0x02 | 0x04 = 0x06
    dut.ui_in.value = 0x36
    dut.uio_in.value = 0x06
    await RisingEdge(dut.clk)
    await ClockCycles(dut.clk, 1)
    
    dut._log.info(f"Test +3*6: Output thực tế = {int(dut.uo_out.value)}")
    assert int(dut.uo_out.value) == 32
    
    # Kiểm tra cờ out_valid ở chân uio_out[4] (0x10 trong hệ hex)
    out_valid = (int(dut.uio_out.value) >> 4) & 1
    assert out_valid == 1
    dut._log.info("Cờ out_valid đã bật thành công.")

    # --- Bước 5: Test tính năng Clear ---
    # uio_in[0] = clear -> uio_in = 0x01
    dut.uio_in.value = 0x01
    await RisingEdge(dut.clk)
    await ClockCycles(dut.clk, 1)
    dut._log.info(f"Test Clear: Output thực tế = {int(dut.uo_out.value)}")
    assert int(dut.uo_out.value) == 0

    dut._log.info("Tất cả các bài test đã vượt qua!")
