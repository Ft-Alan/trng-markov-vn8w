# Markov-Based TRNG Post-Processing with VN8W Debiasing

## Overview

This project implements a post-processing architecture for improving the statistical randomness of a binary bitstream. A Markov-based conditioning stage is combined with an 8-bit Von Neumann extractor (VN8W) to reduce bias and temporal correlation.

The design is behavioral and intended for simulation-based analysis of randomness characteristics.

---

## Architecture

Input Bitstream → Markov Conditioning → 8-bit Word Formation → VN8W Debiasing → Output Bitstream

---

## Key Features

* Markov-based decorrelation using previous-bit conditioning
* Dual-queue buffering for state-dependent processing
* 8-bit batch processing for efficient extraction
* VN8W debiasing with primary and secondary (waiting) outputs
* Modular Verilog design

---

## Design Details

### Markov Conditioning (MKV1)

* Input stream is conditioned based on the previous bit
* Bits are separated into two queues:

  * `q0`: previous bit = 0
  * `q1`: previous bit = 1
* Reduces temporal correlation by state-based grouping

---

### Word Formation

* Bits from each queue are grouped into 8-bit words
* Words are sent to VN8W when a queue is filled

---

### VN8W Debiasing

* Processes 8-bit input words as 2-bit pairs
* Pair mapping:

  * `01 → 1`
  * `10 → 0`
  * `00 / 11 → discarded`
* Uses FIFO buffering:

  * Primary FIFO for output
  * Secondary FIFO for overflow handling

---

## Outputs

* `DOUT`, `DVALID` → primary debiased output
* `DOUT_WAIT`, `DVALID_WAIT` → buffered output when primary FIFO is full

---

## Simulation

* Tested using a behavioral testbench with random input stream
* Demonstrates:

  * State-based bit separation
  * Batch processing behavior
  * Debiased output generation

---

## Key Learnings

* Raw random streams may exhibit correlation between consecutive bits
* Markov-based conditioning helps reduce dependency
* Post-processing improves statistical randomness but introduces latency
* Buffering is required for handling variable output rates

---

## Note on Implementation

This design is implemented using behavioral constructs and is intended for simulation and architectural exploration. It is not optimized for synthesis.

---

## Future Work

* Add statistical evaluation (transition probability, autocorrelation)
* Compare with simpler Von Neumann implementations
* Explore synthesizable architectures for hardware deployment

---
