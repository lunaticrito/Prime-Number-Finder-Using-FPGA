# Prime Number Finder in a Given Range using FPGA

## Overview
This project aims to design and implement a Prime Number Finder on an FPGA board. The system will take a numerical range as input and identify all prime numbers within that range. The output will be displayed through the 7-segment display, indicating which numbers are prime.
The project demonstrates the use of arithmetic operations, conditional checking, and finite state machine (FSM) control in hardware — showcasing how mathematical computations can be efficiently implemented on FPGA platforms.

## Motivation
Prime number calculation is a fundamental mathematical process used in encryption, coding theory, and signal processing. Implementing it on FPGA demonstrates how hardware can perform parallel and efficient computation, as opposed to traditional software-based execution. This project provides a unique opportunity to explore hardware-level logic design and real-time computation for mathematical problems.

## Workflow

### Input Stage:
The user sets the lower limit (L) using the lower bank of switches (SW[7:0]).
The upper limit (U) is set using the upper bank of switches (SW[15:8]).
The Start button begins computation.

### Processing Stage:
The FPGA initializes with the lower limit and sequentially checks each number up to the upper limit.

For each number:
It performs modulo division by all integers between 2 and that number – 1.
If no divisor is found, the number is prime.

### Output Stage
When a prime is detected, the Prime Indicator LED lights up, and  the number is displayed on the 7-segment display.
Once all numbers within the range have been checked, the system stops and returns to Idle mode.

## Required Components
- FPGA Board (e.g., Basys 3 / Nexys A7)
- Switches (SW[7:0])
- Push Button 
- LEDs
- 7-Segment Display 
- Clock (100 MHz)



