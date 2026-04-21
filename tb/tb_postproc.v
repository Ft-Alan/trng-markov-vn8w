`timescale 1ns / 1ps

// ------------------------------------------------------------
// Testbench: Markov + VN8W Post-Processing
// ------------------------------------------------------------
// - Feeds random input bitstream
// - Observes debiased outputs
// - Demonstrates buffering behavior
// ------------------------------------------------------------

module tb_postproc;

    reg CLK = 0;
    reg RSTB = 0;
    reg DIN = 0;

    wire DOUT, DVALID;
    wire DOUT_WAIT, DVALID_WAIT;

    // DUT
    mkv1_vn8w_top dut (
        .CLK(CLK),
        .RSTB(RSTB),
        .DIN(DIN),
        .DOUT(DOUT),
        .DVALID(DVALID),
        .DOUT_WAIT(DOUT_WAIT),
        .DVALID_WAIT(DVALID_WAIT)
    );

    // Clock generation (100 MHz)
    always #5 CLK = ~CLK;

    integer i;

    initial begin
        $display("Starting MKV1 + VN8W simulation...");

        // Reset sequence
        RSTB = 0;
        #20;
        RSTB = 1;

        // Feed random bits
        for (i = 0; i < 200; i = i + 1) begin
            DIN = $random;
            #10;

            if (DVALID)
                $display("Time=%0t | OUT=%b (direct)", $time, DOUT);

            if (DVALID_WAIT)
                $display("Time=%0t | OUT_WAIT=%b (buffered)", $time, DOUT_WAIT);
        end

        #50;
        $display("Simulation completed.");
        $finish;
    end

endmodule
