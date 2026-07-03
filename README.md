# AXI4-Lite Slave Interface and SystemVerilog Verification

## Overview

This project implements a simplified **AXI4-Lite Slave Interface** in **Verilog HDL** with a parameterized memory. The design supports single-beat read and write transactions using the AXI4-Lite protocol and is verified using both a directed Verilog testbench and a SystemVerilog class-based constrained-random verification environment.

---

## Features

- AXI4-Lite compliant single-beat read and write transactions
- FSM-based RTL implementation for read and write channels
- Parameterized memory architecture
- VALID/READY handshake implementation
- AXI response generation (OKAY/SLVERR)
- Directed Verilog testbench
- SystemVerilog class-based verification environment
- Constrained-random stimulus generation
- Self-checking scoreboard
- Virtual Interface and Mailbox based communication

---

## Project Structure

```
AXI4-Lite-Slave-SystemVerilog-Verification
│
├── RTL
│   └── axilite_s.v
│
├── Verilog_TB
│   └── tb_axilite.v
│
├── SV_TB
│   └── tb_axilite_sv.sv
│
├── docs
│   ├── BlockDiagram.png
│   ├── AXI_Write_Waveform.png
│   ├── AXI_Read_Waveform.png
│   └── Verification_Architecture.png
│
└── README.md
```

---

# RTL Architecture

The RTL consists of:

- AXI Write Address Channel
- AXI Write Data Channel
- AXI Write Response Channel
- AXI Read Address Channel
- AXI Read Data Channel
- Parameterized Memory
- Read and Write FSMs

---

# Verification Environment

The SystemVerilog verification environment follows a class-based architecture.

```
                +----------------+
                |   Generator    |
                +----------------+
                        |
                        |
                 Mailbox Transfer
                        |
                        v
                +----------------+
                |     Driver     |
                +----------------+
                        |
                Virtual Interface
                        |
                        v
                +----------------+
                |      DUT       |
                +----------------+
                        |
                Virtual Interface
                        |
                        v
                +----------------+
                |    Monitor     |
                +----------------+
                        |
                 Mailbox Transfer
                        |
                        v
                +----------------+
                |  Scoreboard    |
                +----------------+
```

The verification environment consists of:

- Transaction
- Generator
- Driver
- Monitor
- Scoreboard
- Virtual Interface
- Mailboxes
- Constrained-Random Verification

---

# FSM Overview

## Write FSM

```
IDLE
  |
  v
WRITE ADDRESS
  |
  v
WRITE DATA
  |
  v
WRITE RESPONSE
  |
  v
IDLE
```

## Read FSM

```
IDLE
  |
  v
READ ADDRESS
  |
  v
READ DATA
  |
  v
READ RESPONSE
  |
  v
IDLE
```

---

# Verification Flow

1. Generator randomizes AXI transactions.
2. Driver converts transactions into AXI bus activity.
3. DUT performs memory read/write operations.
4. Monitor captures DUT responses.
5. Scoreboard compares DUT outputs against a reference memory model.
6. PASS/FAIL messages are automatically reported.

---

# Simulation Results

The verification environment successfully validates:

- Write Transactions
- Read Transactions
- VALID/READY Handshaking
- Memory Read/Write Operations
- AXI Response Generation

Example scoreboard output:

```
[GEN] WRITE Address=1 Data=10
[DRV] WRITE Transaction
[MON] Write Response = OKAY
[SCO] DATA STORED

[GEN] READ Address=1
[DRV] READ Transaction
[MON] Read Data = 10
[SCO] DATA MATCHED
```

---

# Tools Used

- Verilog HDL
- SystemVerilog
- EDA Playground

---

# Key Concepts Demonstrated

- RTL Design
- Finite State Machines (FSM)
- AXI4-Lite Protocol
- Memory Interface Design
- Directed Verification
- Constrained-Random Verification
- Mailbox Communication
- Virtual Interface
- Self-Checking Scoreboard
- Transaction-Based Verification

---

# Future Improvements

- Functional Coverage
- SystemVerilog Assertions (SVA)
- UVM-Based Verification Environment
- Burst Transfer Support
- Parameterized Memory Depth
- AXI Master Verification

---

# Author

**Sachin Kumar Mishra**

B.Tech | Electronics Engineering

MNNIT Allahabad

GitHub: https://github.com/sachin4144
