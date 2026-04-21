`timescale 1ns / 1ps

// ------------------------------------------------------------
// VN8W: 8-bit Von Neumann Debiasing with Buffering
// ------------------------------------------------------------
// Function:
// - Processes 8-bit input words
// - Applies Von Neumann extraction on 2-bit pairs
// - Outputs debiased bits via FIFO
// - Uses secondary "waiting" FIFO when primary is full
//
// Pair mapping:
//   01 -> 1
//   10 -> 0
//   00/11 -> discard
//
// NOTE:
// - Improves randomness but reduces throughput
// ------------------------------------------------------------

module vn8w (
    input  wire        CLK,
    input  wire        RSTB,        // Active-LOW reset
    input  wire        valid_in,
    input  wire [7:0]  word_in,
    output reg         DOUT,
    output reg         DVALID,
    output reg         DOUT_WAIT,
    output reg         DVALID_WAIT
);

    // ------------------------------------------------------------
    // FIFO storage
    // ------------------------------------------------------------
    reg [7:0] fifo;
    reg [3:0] fifo_head, fifo_tail;

    reg [7:0] wait_fifo;
    reg [3:0] w_head, w_tail;

    wire fifo_empty = (fifo_head == fifo_tail);
    wire fifo_full  = ((fifo_tail + 1'b1) == fifo_head);

    wire wait_empty = (w_head == w_tail);
    wire wait_full  = ((w_tail + 1'b1) == w_head);

    integer i;
    reg [1:0] pair;

    always @(posedge CLK or negedge RSTB) begin
        if (!RSTB) begin
            fifo       <= 8'b0;
            wait_fifo  <= 8'b0;
            fifo_head  <= 0;
            fifo_tail  <= 0;
            w_head     <= 0;
            w_tail     <= 0;
            DOUT       <= 0;
            DVALID     <= 0;
            DOUT_WAIT  <= 0;
            DVALID_WAIT<= 0;
        end else begin
            // Default outputs
            DVALID      <= 0;
            DOUT        <= 0;
            DVALID_WAIT <= 0;
            DOUT_WAIT   <= 0;

            // ------------------------------------------------------------
            // Process incoming 8-bit word
            // ------------------------------------------------------------
            if (valid_in) begin
                for (i = 3; i >= 0; i = i - 1) begin
                    pair = word_in[i*2 +: 2];

                    case (pair)
                        2'b01: begin
                            if (!fifo_full) begin
                                fifo[fifo_tail[2:0]] <= 1'b1;
                                fifo_tail <= fifo_tail + 1'b1;
                            end else if (!wait_full) begin
                                wait_fifo[w_tail[2:0]] <= 1'b1;
                                w_tail <= w_tail + 1'b1;
                            end
                        end

                        2'b10: begin
                            if (!fifo_full) begin
                                fifo[fifo_tail[2:0]] <= 1'b0;
                                fifo_tail <= fifo_tail + 1'b1;
                            end else if (!wait_full) begin
                                wait_fifo[w_tail[2:0]] <= 1'b0;
                                w_tail <= w_tail + 1'b1;
                            end
                        end

                        default: ; // discard
                    endcase
                end
            end

            // ------------------------------------------------------------
            // Primary output from FIFO
            // ------------------------------------------------------------
            if (!fifo_empty) begin
                DOUT   <= fifo[fifo_head[2:0]];
                DVALID <= 1'b1;
                fifo_head <= fifo_head + 1'b1;

                // Move waiting data if space available
                if (!wait_empty && !fifo_full) begin
                    fifo[fifo_tail[2:0]] <= wait_fifo[w_head[2:0]];
                    fifo_tail <= fifo_tail + 1'b1;
                    w_head <= w_head + 1'b1;
                end
            end 
            else if (!wait_empty) begin
                // Secondary output path
                DOUT_WAIT   <= wait_fifo[w_head[2:0]];
                DVALID_WAIT <= 1'b1;
                w_head <= w_head + 1'b1;
            end
        end
    end

endmodule
