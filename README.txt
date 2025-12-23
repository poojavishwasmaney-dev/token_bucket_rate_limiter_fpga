# token_bucket_rate_limiter_fpga

Token Bucket Rate Limiter (SRAM-Based, Scalable)
Overview
Scalable FPGA token bucket rate limiter supporting thousands of clients using SRAM-backed state and clean RTL architecture
This repository implements a scalable Token Bucket Rate Limiter in SystemVerilog, designed for large numbers of clients using an SRAM-friendly architecture.

The design supports:
  Per-client rate limiting
  Bounded burst control
  Fair refill without starvation
  Clean handling of consume/refill collisions
  Hardware-scalable behavior for N_CLIENTS up to 1000+

This module is suitable for: FPGA and ASIC designs
  Network interface rate limiting
  AXI / NoC QoS enforcement

Key Features
  SRAM-based token storage (no per-client registers)
  One client checked per cycle for refill (scalable)
  Refill independent of traffic

Bounded refill latency, even for large client counts
  Collision-safe consume + refill logic
  Clean separation of combinational and sequential logic

Design Parameters
  parameter int N_CLIENTS = 1024;   // Number of clients
  parameter int TOKEN_W   = 16;     // Token width
  parameter int CLIENT_W  = $clog2(N_CLIENTS);
  parameter int T_REFILL  = 1000;   // Global refill period (cycles)

Interface Description
  Inputs
      Signal	                  Description
      clk	                      System clock
      rst_n	                    Active-low reset
      pkt_valid	                Indicates incoming packet
      pkt_client_id	            Client ID for the packet
      max_tokens[N_CLIENTS]	    Maximum token capacity per client
      refill_tokens[N_CLIENTS]	Tokens added per refill event

  Outputs
      Signal	                   Description
      pkt_accept	              Packet accepted
      pkt_drop	                Packet dropped due to lack of tokens

Architecture Overview
  Token Storage
  Tokens are stored in an SRAM-style array
  One token counter per client
  No asynchronous reset on memory (BRAM-friendly)

Consume Path
  On pkt_valid, token count for the client is checked
    If token > 0 → packet accepted and token decremented
    Else → packet dropped
Refill Path
  A global refill counter triggers refill events every T_REFILL cycles
  A refill pointer advances every cycle, scanning clients round-robin

Only the client pointed to by refill_ptr is refilled on a refill event
This avoids refill latency scaling as N_CLIENTS × T_REFILL.
Refill Latency & Fairness

Worst-case refill latency is bounded by: max(N_CLIENTS, T_REFILL)

This guarantees:No starvation

Author

Pooja Ramesh
FPGA / RTL Design Engineer
Specializing in scalable hardware architectures and SoC design
