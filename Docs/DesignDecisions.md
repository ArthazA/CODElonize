# Edge Cases & Design Decisions

## Purpose

This document records gameplay edge cases and the expected system behavior for CODElonize. It serves as a reference during implementation to ensure consistent behavior across all clients and to reduce ambiguity when new features are added.

---

# Lobby

## EC-001 — Host disconnects before the game starts

**Question**

> What should happen?

**Decision**

> TODO

---

## EC-002 — Host disconnects during a match

**Question**

> Does the match immediately end? Is host migration supported?

**Decision**

> TODO

---

## EC-003 — Player disconnects during a match

**Question**

> Can the player reconnect?

**Decision**

> TODO

---

## EC-004 — Player reconnects

**Question**

> Should they continue where they left off?

**Decision**

> TODO

---

## EC-005 — Lobby reaches maximum capacity

**Question**

> What message is shown?

**Decision**

> TODO

---

# Shared AR

## EC-006 — Player joins after the island has been placed

**Question**

> How does the player synchronize with the host's anchor?

**Decision**

> TODO

---

## EC-007 — AR tracking is temporarily lost

**Question**

> Does gameplay pause? Does only the visualization pause?

**Decision**

> TODO

---

## EC-008 — Two players see slightly different anchor positions

**Question**

> How should alignment be corrected?

**Decision**

> TODO

---

# Area Conquest

## EC-009 — Two players finish with identical completion times

**Question**

> Who becomes the owner?

**Decision**

> TODO

---

## EC-010 — Player quits while answering questions

**Question**

> Is the attempt consumed?

**Decision**

> TODO

---

## EC-011 — Player accidentally closes the quiz UI

**Question**

> Resume or cancel?

**Decision**

> Disable closing quiz UI, only until the player is finished the UI will close.

---

## EC-012 — Player attempts an already completed area

**Question**

> Prevent the attempt or allow viewing?

**Decision**

> Allow viewing, no attempting.

---

## EC-013 — Area becomes locked while a player is selecting it

**Question**

> What happens?

**Decision**

> Closes the UI but keeps progress.

---

# Quiz System

## EC-014 — Player submits after the timer expires

**Decision**

> Submission is voided.

---

## EC-015 — Player answers incorrectly

**Decision**

> Freeze the UI, rendering it uninteractable for 3 seconds.

---

## EC-016 — JSON question file fails to load

**Decision**

> TODO

---

## EC-017 — Insufficient questions available for a topic

**Decision**

> TODO

---

# Power-ups

## EC-018 — Two players tap the same power-up simultaneously

**Decision**

> Server decides and has highest authority

---

## EC-019 — Power-up spawns inside an unreachable location

**Decision**

> TODO

---

## EC-020 — Player activates a power-up while another one is resolving

**Decision**

> TODO

---

## EC-021 — Player disconnects while owning unused power-ups

**Decision**

> TODO

---

## EC-022 — Earthquake used on an already unconquered area

**Decision**

> Same effects still happen

---

## EC-023 — Tsunami targets an already locked area

**Decision**

> Same effects still happen, but renew the locked timer 

---

## EC-024 — Pocket Watch creates a new fastest time

**Decision**

> Player with the fastest time conquers the area

---

## EC-025 — Pocket Watch used on an unconquered area

**Decision**

> Nothing happens

---

# Match Flow

## EC-026 — Every area has been conquered

**Decision**

> Spawn an earthquake power-up

---

## EC-027 — Match timer expires (if applicable)

**Decision**

> TODO

---

## EC-028 — Winner determination

**Question**

> Is the winner based on:
>
> * Number of conquered areas?
> * Total score?
> * Total completion time?
> * Another metric?

**Decision**

> Winner is based on number of conquered areas, then total completion time.

---

# Networking

## EC-029 — Temporary packet loss

**Decision**

> TODO

---

## EC-030 — Delayed synchronization

**Decision**

> TODO

---

## EC-031 — Duplicate network message

**Decision**

> TODO

---

## EC-032 — Conflicting updates

**Decision**

> TODO

---

# User Interface

## EC-033 — Player rotates device

**Decision**

> TODO

---

## EC-034 — Application enters background

**Decision**

> TODO

---

## EC-035 — Low battery warning

**Decision**

> TODO

---

## EC-036 — Device overheats

**Decision**

> TODO

---

# Future Features

Use this section to record future gameplay ideas before implementation.

| ID    | Feature | Status | Notes |
| ----- | ------- | ------ | ----- |
| F-001 |         |        |       |
| F-002 |         |        |       |
| F-003 |         |        |       |

---

# Open Questions

Use this section for design questions that have not yet been answered.

* TODO
* TODO
* TODO

---

# Changelog

| Version | Date          | Changes                   |
| ------- | ------------- | ------------------------- |
| 1.0     | Initial draft | Created edge case tracker |

