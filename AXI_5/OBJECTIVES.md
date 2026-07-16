# Project Objectives

## Project Title
**Design and Verification of an AXI5 Multi-Master Interconnect with NSAID Security Extensions and AXI5-to-AXI4 Protocol Conversion**

---

## 1. Abstract
This project implements and verifies a synthesizable multi-master **AMBA AXI** interconnect that natively supports the **AXI5 security extension (NSAID — Non-Secure Access ID)**. AXI5 masters are bridged onto a standard AXI4 crossbar fabric through dedicated protocol-conversion and security-remapping blocks. The design is validated using a UVM-style, self-checking verification environment with directed test scenarios and automated waveform capture.

---

## 2. Aim
To build a configurable, protocol-compliant AXI5/AXI4 interconnect that correctly routes concurrent multi-master traffic, enforces security-ID remapping, and is proven correct through a reusable, self-checking verification flow.

---

## 3. Objectives

### 3.1 Design Objectives (RTL)
1. Develop a parameterizable multi-master **AXI4 crossbar** (`axi_xbar_intf`) with address-map decoding and full AW/W/B/AR/R channel routing across multiple slave ports.
2. Define an **AXI5 bus interface** (`AXI5_BUS`) that extends AXI4 with the NSAID sideband on the AW and AR channels.
3. Implement an **NSAID remapper** that translates a matching security ID to a configured target ID while passing all other transactions through unchanged.
4. Implement an **AXI5-to-AXI4 adapter** that forwards common channels and safely drops AXI5-only signals, enabling AXI5 masters to drive an AXI4 fabric.
5. Provide an **AXI-Stream 5 (AXIS5) datapath** supporting AMBA5 extensions (TWAKEUP power management and TPARITY data integrity), including clock-gated variants.
6. Keep all address, data, and ID widths and the master/slave port counts **fully parameterizable** for both simulation and synthesis.

### 3.2 Verification Objectives (UVM)
7. Build a **self-checking UVM environment** with a memory-model scoreboard that records writes and verifies read-back data with pass/error accounting.
8. Provide **sequencer-driven stimulus** and a **RAL register model** (control/status registers) for register-level access.
9. Achieve functional coverage through **directed test scenarios**:
   - `direct_rw` — single write/read data integrity
   - `multi_slave` — address decode and routing across slave windows
   - `back_to_back` — write/read response (B/R) FIFO behaviour
   - `concurrent_masters` — parallel multi-master, origin-tracked response routing
   - `sequence_rw` — UVM sequence-driven traffic
   - `nsaid_remap` — AXI5 NSAID remap and passthrough correctness
   - `uvm_smoke` — minimal UVM bring-up / smoke check

### 3.3 Tooling and Flow Objectives
10. Provide an **automated test-run and waveform-capture flow** that selects tests via a `+TESTNAME` plusarg, displays only the signals relevant to each test, and snapshots each waveform for review.

---

## 4. Scope
- **In scope:** AXI5 → AXI4 conversion, NSAID remapping, multi-master crossbar routing, AXIS5 stream master/slave, UVM self-checking verification, directed tests, waveform automation.
- **Out of scope:** Full AXI5 cache-coherency (ACE) support, physical implementation/timing closure beyond behavioural simulation, and production-grade formal verification.

---

## 5. Deliverables
1. Synthesizable RTL for the interconnect, AXI5 interface, NSAID remapper, and AXI5/AXI4 adapters.
2. AXIS5 stream master/slave modules (standard and clock-gated).
3. UVM-style verification environment (scoreboard, sequencer, RAL model).
4. A directed test suite covering the seven scenarios listed above.
5. Automated test-run and waveform-capture scripts.

---

## 6. Expected Outcome
A verified, parameterizable AXI5 interconnect demonstrating correct multi-master routing, protocol conversion, and security-ID remapping, with all directed tests passing under the self-checking scoreboard and reproducible waveform evidence for each scenario.
