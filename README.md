# GhostRace: Exploiting and Mitigating Speculative Race Conditions

This repository contains:
- A PoC code of Speculative Race Condition (SRC).
- Coccinelle scripts used to scan the Linux kernel v5.15.83 for Speculative Concurrent Use-After-Free (SCUAF) gadgets.
- 1200+ SCUAF gadgets found.
- The IPI storming code used to create an architectural unbounded UAF exploitation window.

More details on www.vusec.net/projects/ghostrace
