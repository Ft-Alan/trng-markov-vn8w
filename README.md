# Markov-Based TRNG Post-Processing with VN8W

## Problem

Random bitstreams often exhibit correlation between consecutive bits, reducing randomness quality even when bias is addressed.

## Approach

A Markov-based conditioning stage is used to decorrelate the input stream by separating bits based on the previous state.
The conditioned data is grouped into 8-bit words and processed using a VN8W debiasing block.

## Architecture

```
Input Bitstream
        ↓
Previous Bit Register
        ↓
State-Based Split (Markov Conditioning)
     ↓              ↓
   Queue0         Queue1
     ↓              ↓
   8-bit          8-bit
   Words          Words
        \        /
         ↓      ↓
       VN8W Debiasing
            ↓
        FIFO Buffer
         ↓      ↓
      Output   Wait Output
```

## Key Features

* Markov-based decorrelation using previous-bit conditioning
* Dual-queue architecture (state-dependent buffering)
* 8-bit batch processing for efficient extraction
* VN8W debiasing with FIFO-based output handling

## Results

* Reduced correlation between consecutive bits
* Improved statistical randomness of output
* Buffered architecture handles variable output rate

## Key Insight

Improving randomness requires addressing both:

* Bias (Von Neumann extraction)
* Correlation (Markov conditioning)

## Note

This design is implemented as a behavioral model for simulation and architectural exploration.
It is not optimized for synthesis.

## Future Work

* Add statistical evaluation (transition probability, autocorrelation)
* Compare with simpler VN-based approaches
* Explore synthesizable hardware implementations
