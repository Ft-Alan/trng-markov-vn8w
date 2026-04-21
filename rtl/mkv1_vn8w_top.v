`timescale 1ns / 1ps

// ------------------------------------------------------------
// Top Module: Markov-Based TRNG Post-Processing (MKV1 + VN8W)
// ------------------------------------------------------------
// Function:
// - Applies Markov-based decorrelation using previous-bit conditioning
// - Separates incoming bitstream into two conditioned queues (q0, q1)
// - Groups bits into 8-bit words
// - Feeds words into VN8W debiasing block
//
// NOTE:
// - Simulation-oriented design (not optimized for synthesis)
// ------------------------------------------------------------

module mkv1_vn8w_top (
    input  wire CLK,
    input  wire RSTB,         // Active-LOW reset (important)
    input  wire DIN,          // Input bitstream
    output wire DOUT,         // Debiased output
    output wire DVALID,       // Output valid
    output wire DOUT_WAIT,    // Secondary buffered output
    output wire DVALID_WAIT   // Secondary valid
);

    // ------------------------------------------------------------
    // Previous bit register (for Markov conditioning)
    // ------------------------------------------------------------
    reg prev_bit;

    always @(posedge CLK or negedge RSTB) begin
        if (!RSTB)
            prev_bit <= 1'b0;
        else
            prev_bit <= DIN;
    end

    // ------------------------------------------------------------
    // State-conditioned queues
    // q0: previous bit = 0
    // q1: previous bit = 1
    // ------------------------------------------------------------
    reg [7:0] q0_shift, q1_shift;
    reg [2:0] q0_cnt, q1_cnt;

    wire push_q0 = (prev_bit == 1'b0);
    wire push_q1 = (prev_bit == 1'b1);

    always @(posedge CLK or negedge RSTB) begin
        if (!RSTB) begin
            q0_shift <= 8'b0;
            q1_shift <= 8'b0;
            q0_cnt   <= 3'b0;
            q1_cnt   <= 3'b0;
        end else begin
            if (push_q0) begin
                q0_shift <= {q0_shift[6:0], DIN};
                if (q0_cnt != 3'd7)
                    q0_cnt <= q0_cnt + 1'b1;
            end else begin
                q1_shift <= {q1_shift[6:0], DIN};
                if (q1_cnt != 3'd7)
                    q1_cnt <= q1_cnt + 1'b1;
            end
        end
    end

    // ------------------------------------------------------------
    // Word formation logic (8-bit batches)
    // ------------------------------------------------------------
    reg [7:0] send_word;
    reg       send_valid;

    always @(posedge CLK or negedge RSTB) begin
        if (!RSTB) begin
            send_word  <= 8'b0;
            send_valid <= 1'b0;
        end else begin
            send_valid <= 1'b0;

            if (q0_cnt == 3'd7) begin
                send_word  <= q0_shift;
                send_valid <= 1'b1;
                q0_shift   <= 8'b0;
                q0_cnt     <= 3'b0;
            end else if (q1_cnt == 3'd7) begin
                send_word  <= q1_shift;
                send_valid <= 1'b1;
                q1_shift   <= 8'b0;
                q1_cnt     <= 3'b0;
            end
        end
    end

    // ------------------------------------------------------------
    // VN8W Debiasing Block
    // ------------------------------------------------------------
    wire vn_dout, vn_dvalid, vn_dout_wait, vn_dvalid_wait;

    vn8w u_vn8w (
        .CLK(CLK),
        .RSTB(RSTB),
        .valid_in(send_valid),
        .word_in(send_word),
        .DOUT(vn_dout),
        .DVALID(vn_dvalid),
        .DOUT_WAIT(vn_dout_wait),
        .DVALID_WAIT(vn_dvalid_wait)
    );

    assign DOUT        = vn_dout;
    assign DVALID      = vn_dvalid;
    assign DOUT_WAIT   = vn_dout_wait;
    assign DVALID_WAIT = vn_dvalid_wait;

endmodule
