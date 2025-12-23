//*****Module Name: Token Bucket Rate Limiter*******//
//***Author: Pooja Ramesh<poojarchawde@gmail.com>***//
//****************Date: 23/12/2025******************//

module token_bucket_rate_limiter_sram #(
    parameter int N_CLIENTS = 1024,             //Number of clients//
    parameter int TOKEN_W   = 16,               //Token Width//
    parameter int CLIENT_W  = $clog2(N_CLIENTS),//Client Width//
    parameter int T_REFILL  = 1000              //Refill-cycles//
)(
    input  logic                   clk,             //Synchronous design - single clock//
    input  logic                   rst_n,           //Active low - reset//

    input  logic                   pkt_valid,       //Packet Valid indicator//
    input  logic [CLIENT_W-1:0]    pkt_client_id,   //Client ID for the packet//

    input  logic [TOKEN_W-1:0]     max_tokens    [N_CLIENTS],   //Maximum tokens per client//
    input  logic [TOKEN_W-1:0]     refill_tokens [N_CLIENTS],   //refill token every T_REFILL cycles//

    output logic                   pkt_accept,      //Output packet accept indicator//
    output logic                   pkt_drop         //Output packet drop indicator//
);

    // ------------------------------------------------------------------
    // STATE REGISTERS
    // ------------------------------------------------------------------
    logic [TOKEN_W-1:0] token_sram   [N_CLIENTS]; // BRAM/array storage
    logic [CLIENT_W-1:0] refill_ptr;              //Refill pointer
    logic [$clog2(T_REFILL)-1:0] refill_cnt;      //Refill count

    // ------------------------------------------------------------------
    // COMBINATIONAL LOGIC
    // ------------------------------------------------------------------
    logic pkt_accept_next, pkt_drop_next;
    logic [TOKEN_W-1:0] token_next;
    logic refill_wrap;

    // Default values
    assign pkt_accept_next = 1'b0;
    assign pkt_drop_next   = 1'b0;
    assign refill_wrap     = (refill_ptr == N_CLIENTS-1);

    // Packet consume combinational logic
    always_comb begin
        token_next = token_sram[pkt_client_id];  // default
        pkt_accept_next = 1'b0;
        pkt_drop_next   = 1'b0;

        if (pkt_valid) begin
            if (token_sram[pkt_client_id] > 0) begin
                token_next = token_sram[pkt_client_id] - 1'b1;
                pkt_accept_next = 1'b1;
            end else
                pkt_drop_next = 1'b1;
        end
    end

    // Refill combinational logic
    logic [TOKEN_W-1:0] refill_token_next;
    always_comb begin
        refill_token_next = token_sram[refill_ptr]; // default
        if (refill_cnt == T_REFILL-1) begin
            if (token_sram[refill_ptr] + refill_tokens[refill_ptr] >= max_tokens[refill_ptr])
                refill_token_next = max_tokens[refill_ptr];
            else
                refill_token_next = token_sram[refill_ptr] + refill_tokens[refill_ptr];
        end
    end

    // ------------------------------------------------------------------
    // SEQUENTIAL LOGIC
    // ------------------------------------------------------------------

    //Refill Counter Logic//
    always_ff@(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            refill_cnt <= '0;
        end else if(refill_cnt == T_REFILL-1) begin
            refill_cnt <= '0;
        end else begin
            refill_cnt <= refill_cnt + 1'b1;
        end
    end

    //Refill Pointer Logic//
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            refill_ptr <= '0;
        end else begin
            refill_ptr <= refill_wrap ? 0 : refill_ptr + 1;
        end
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pkt_accept <= 1'b0;
            pkt_drop   <= 1'b0;
        end else begin
            pkt_accept <= pkt_accept_next;
            pkt_drop   <= pkt_drop_next;

            // -----------------------------
            // Case 1: Consume only
            // -----------------------------
            if (pkt_valid && !(refill_cnt == T_REFILL-1 && pkt_client_id == refill_ptr)) begin
                token_sram[pkt_client_id]   <= token_next;
            end

            // -----------------------------
            // Case 2: Refill only
            // -----------------------------
            if (refill_cnt == T_REFILL-1 && !(pkt_valid && pkt_client_id == refill_ptr)) begin
                token_sram[refill_ptr]      <= refill_token_next;
            end

            // -----------------------------
            // Case 3: Consume + refill collision
            // -----------------------------
            if (pkt_valid && refill_cnt == T_REFILL-1 && pkt_client_id == refill_ptr) begin
                token_sram[pkt_client_id]   <= (token_next + refill_tokens[pkt_client_id] >= max_tokens[pkt_client_id]) ?
                                                max_tokens[pkt_client_id] : token_next + refill_tokens[pkt_client_id];
            end
        end
    end


endmodule
