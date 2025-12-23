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

This module is suitable for:

FPGA and ASIC designs

Network interface rate limiting

AXI / NoC QoS enforcement

Interview discussions and architectural exploration

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
Signal	Description
clk	System clock
rst_n	Active-low reset
pkt_valid	Indicates incoming packet
pkt_client_id	Client ID for the packet
max_tokens[N_CLIENTS]	Maximum token capacity per client
refill_tokens[N_CLIENTS]	Tokens added per refill event
Outputs
Signal	Description
pkt_accept	Packet accepted
pkt_drop	Packet dropped due to lack of tokens
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
Problem with naive refill

Refilling all clients at once or advancing the pointer only on refill events causes refill latency to grow linearly with N_CLIENTS, leading to starvation-like behavior.

Solution used here

refill_ptr advances every cycle

Refill is applied only when refill_cnt == T_REFILL-1

Result

Worst-case refill latency is bounded by:

max(N_CLIENTS, T_REFILL)


This guarantees:

No starvation

Predictable fairness

Scalable hardware cost

Consume + Refill Collision Handling

If a packet arrives for the same client that is being refilled in the same cycle:

Both operations are merged

Refill is applied after consume

Token value is saturated at max_tokens

This ensures:

No lost updates

Deterministic behavior

Safe SRAM writes (one write per address per cycle)

Important Design Notes

max_tokens and refill_tokens are modeled as arrays for clarity
👉 In real silicon, these would typically reside in a configuration SRAM or be class-based parameters.

The SRAM is modeled as combinational read / synchronous write
👉 For true block RAM, a 1-cycle read latency + bypass logic can be added.

Memory initialization is not handled via reset
👉 A real design would use an init FSM or preload mechanism.

Use Cases

Network packet rate limiting

Per-master AXI QoS enforcement

NoC traffic shaping

FPGA/ASIC architectural exploration

Interview preparation & design discussion

Possible Extensions

Dual-port SRAM (parallel consume + refill)

Multiple refill engines for higher throughput

Fractional / fixed-point refill rates

AXI-Lite configuration interface

Formal assertions for fairness guarantees

Author

Pooja Ramesh
FPGA / RTL Design Engineer
Specializing in scalable hardware architectures and SoC design
