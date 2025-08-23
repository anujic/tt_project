# SPDX-FileCopyrightText: © 2024 Tiny Tapeout
# SPDX-License-Identifier: Apache-2.0

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles


@cocotb.test()
async def test_morse_trainer(dut):
    dut._log.info("Start Morse Code Trainer Test")

    # Set the clock period to 10 ms for 100Hz clock to match your timing parameters
    # Your DOT_TIME = 20 cycles @ 100Hz = 200ms, DASH_TIME = 60 cycles = 600ms
    clock = Clock(dut.clk, 10, units="ms")
    cocotb.start_soon(clock.start())

    # Reset
    dut._log.info("Reset")
    dut.ena.value = 1
    dut.ui_in.value = 0
    dut.uio_in.value = 0
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 10)
    dut.rst_n.value = 1

    dut._log.info("Test 1: Wait for display to initialize")
    await ClockCycles(dut.clk, 50)
    
    # Start the system - press start button
    dut._log.info("Pressing start button to begin")
    await ClockCycles(dut.clk, 5)
    dut.ui_in.value = 0b001  # ui_in[0] is start
    
    # Should display first letter and be ready for input
    display = dut.uo_out.value & 0x7F  # 7-segment display bits [6:0]
    status_led = (dut.uo_out.value >> 7) & 1  # Status LED bit [7]
    dut._log.info(f"Initial display: 0x{display:02x}, Ready status: {status_led}")
    
    dut._log.info("Test 2: Input morse code - Testing dot (short press)")
    
    # Input a dot - short press (< DASH_TIME = 60 cycles)
    dut.ui_in.value = 0b011  # ui_in[1] is morse key, ui_in[0] is start
    await ClockCycles(dut.clk, 25)  # Short press ~25 cycles = 250ms (< 60 cycles = 600ms)
    dut.ui_in.value = 0b001  # Release morse key, keep start active
    await ClockCycles(dut.clk, 45)  # Wait for character completion timeout (CHAR_TIME = 40 cycles = 400ms)
    
    # Check if input was processed
    status_led = (dut.uo_out.value >> 7) & 1
    dut._log.info(f"After dot input - Status: {status_led}")
    
    dut._log.info("Test 3: Input morse code - Testing dash (long press)")
    
    # Reset and test dash input
    dut.ui_in.value = 0b000  # Release all
    await ClockCycles(dut.clk, 10)
    dut.ui_in.value = 0b001  # Press start again
    await ClockCycles(dut.clk, 5)
    
    # Input a dash - long press (>= DASH_TIME = 60 cycles = 600ms)
    dut.ui_in.value = 0b011  # Press morse key + start
    await ClockCycles(dut.clk, 65)  # Long press >= 60 cycles = 650ms
    dut.ui_in.value = 0b001  # Release morse key
    await ClockCycles(dut.clk, 45)  # Wait for character completion
    
    status_led = (dut.uo_out.value >> 7) & 1
    dut._log.info(f"After dash input - Status: {status_led}")
    
    dut._log.info("Test 4: Test sequence input (dot-dash)")
    
    # Reset for new test
    dut.ui_in.value = 0b000
    await ClockCycles(dut.clk, 10)
    dut.ui_in.value = 0b001  # Start
    await ClockCycles(dut.clk, 5)
    
    # Input dot
    dut.ui_in.value = 0b011  # Press morse + start
    await ClockCycles(dut.clk, 25)  # Short press = 250ms
    dut.ui_in.value = 0b001  # Release morse
    await ClockCycles(dut.clk, 12)  # Short gap between symbols (< CHAR_TIME)
    
    # Input dash
    dut.ui_in.value = 0b011  # Press morse + start
    await ClockCycles(dut.clk, 65)  # Long press = 650ms
    dut.ui_in.value = 0b001  # Release morse
    await ClockCycles(dut.clk, 45)  # Wait for character completion
    
    status_led = (dut.uo_out.value >> 7) & 1
    dut._log.info(f"After dot-dash sequence - Status: {status_led}")
    
    dut._log.info("Test 5: Test state transitions")
    
    # Test going back to IDLE by releasing start
    dut.ui_in.value = 0b000  # Release start - should go to IDLE
    await ClockCycles(dut.clk, 20)
    
    # Restart
    dut.ui_in.value = 0b001  # Press start again
    await ClockCycles(dut.clk, 20)
    
    display = dut.uo_out.value & 0x7F
    dut._log.info(f"After restart - Display: 0x{display:02x}")
    
    dut._log.info("Test 6: Test timeout behavior")
    
    # Test morse input timeout (holding morse key too long)
    dut.ui_in.value = 0b011  # Press morse + start
    await ClockCycles(dut.clk, 70)  # Hold for maximum time + some extra (700ms)
    # Should timeout and return to IDLE
    status_led = (dut.uo_out.value >> 7) & 1
    dut._log.info(f"After timeout test - Status: {status_led}")
    
    dut.ui_in.value = 0b000  # Release all
    await ClockCycles(dut.clk, 20)

    dut._log.info("Morse Code Trainer testbench completed successfully!")
