// axi_stream.v
// AMBA AXI-Stream handshake on the veryVerilog Mini FPGA Kit (PIC16F13145).
//
// Two pushbuttons drive the two handshake lines
//     BTN_VALID: TVALID   (source)
//     BTN_READY: TREADY   (sink)
//
// A slow clock (the ACLK) samples both lines on every rising
// edge, exactly like AXI-Stream. A transfer (beat) occurs when both
// lines are high at a rising clock edge. This lets you demonstrate all four
// handshake states by hand:
//     neither: idle
//     VALID: source offering, sink not ready (backpressure)
//     READY: sink ready, source has nothing (no transfer)
//     both:beat transfers; every 8th beat asserts TLAST (packet done)

 
module axi_stream (
    input        CLK,        // slow ACLK from a timer (~60 Hz)
    input        btn_valid,  // source button - TVALID (Button 3)
    input        btn_ready,  // sink button - TREADY (Button 4)
    output       o_transfer, // valid & ready - a beat moved     (LED3: TRANSFER)
    output       o_wait,     // exactly one side asserted        (LED1: WAIT)
    output       o_done      // toggles at TLAST (packet complete)(LED2: DONE)
);
 
    localparam BTN_ACTIVE_LOW = 1'b0;
 
    // polarity. If 1'b0, then vbttn gets btn_valid (value of input) if 1'b1, then vbtn will get the opposite (active low)
    wire vbtn = BTN_ACTIVE_LOW ? ~btn_valid : btn_valid;
    wire rbtn = BTN_ACTIVE_LOW ? ~btn_ready : btn_ready;
 
    // Sample the asynchronous presses onto the clock
    reg tvalid, tready;
    always @(posedge CLK) begin
        tvalid <= vbtn;
        tready <= rbtn;
    end
 
    localparam [6:0] LAST_BEAT = 7'd127;    // increased number of beats from 8 to 128 so the 60hz clock would be easier to see 
    reg [6:0] count;                         // increased count register size
    reg       done_ff;                        // flips when a packet completes
 
    // AXI-Stream rule: a beat transfers only when BOTH VALID and READY are high.
    wire beat        = tvalid & tready;
    wire tlast       = (count == LAST_BEAT);
    wire packet_done = beat & tlast;
 
    // No reset needed: the counter always wraps at LAST_BEAT, so it self corrects
    // within one packet regardless of its power up value. This frees both buttons
    // for the handshake.
    always @(posedge CLK) begin
        if (beat) count <= tlast ? 7'd0 : count + 7'd1;
        if (packet_done) done_ff <= ~done_ff;
    end
 
    assign o_transfer = beat;                 // data is moving - LED3
    assign o_wait     = tvalid ^ tready;      // one side waiting - LED1
    assign o_done     = done_ff;              // packet complete  - LED2
 
endmodule