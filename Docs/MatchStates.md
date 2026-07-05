# Shared Match State

## Overview

The **Shared Match State** is the authoritative representation of the current game session. It contains every piece of information that all players must agree upon during gameplay.

Since CODElonize follows a **host-authoritative peer-to-peer architecture**, the host device owns the master copy of the Shared Match State. Whenever the state changes (e.g., an area is conquered or a power-up is collected), the host updates the state and synchronizes the changes to every connected client.

Rather than synchronizing every individual object independently, the game synchronizes changes to this centralized state. This ensures that every player sees an identical match progression throughout the game.

---

# Architecture

```text
                Shared Match State
                        │
        ┌───────────────┼───────────────┐
        │               │               │
    Gameplay        Networking       AR Display
        │               │               │
        └───────────────┼───────────────┘
                    Player Devices
```

The Shared Match State serves as the single source of truth for all gameplay systems.

---

# Components

## 1. Lobby State

Stores information required before the match begins.

### Contains

* Lobby Code
* Host Player
* Connected Players
* Player Ready Status
* Match Status (Waiting / Countdown / In Progress / Finished)

### Example

```text
Lobby
│
├── Lobby Code
├── Host
├── Players
├── Ready Status
└── Match Started
```

---

## 2. Player State

Stores information unique to each player.

### Contains

* Player ID
* Display Name
* Connection Status
* Inventory (Power-ups)
* Current Area Attempt
* Completed Areas
* Recorded Completion Times

### Example

```text
Player
│
├── Name
├── Inventory
├── Attempting Area
├── Completed Areas
└── Completion Times
```

---

## 3. Island State

Represents the current condition of the shared island.

Each of the six areas maintains its own state.

### Contains

* Area Owner
* Best Completion Time
* Locked Status
* Lock Timer
* Current Question Set
* Attempt History

### Example

```text
Island
│
├── Area 1
├── Area 2
├── Area 3
├── Area 4
├── Area 5
└── Area 6
```

Each area may internally contain

```text
Area
│
├── Topic
├── Owner
├── Best Time
├── Locked
├── Lock Remaining
└── Current Question Set
```

---

## 4. Quiz State

Tracks every active quiz session.

### Contains

* Current Questions
* Question Order
* Active Players
* Quiz Start Time
* Quiz Completion Time

The host uses this information to determine the winner of each area.

---

## 5. Power-up State

Maintains the global power-up system.

### Contains

* Spawned Power-ups
* Spawn Locations
* Spawn Timers
* Collected Status
* Player Inventories

### Example

```text
Power-ups
│
├── Spawned
├── Available
├── Collected
└── Inventory
```

---

## 6. Match State

Represents the overall progress of the game.

### Contains

* Remaining Match Time (if applicable)
* Current Scores
* Number of Conquered Areas
* Winning Player
* Match Finished Flag

---

# Synchronized Events

The following events are synchronized by the host.

## Lobby Events

* Player joins
* Player leaves
* Player ready
* Match start

## Gameplay Events

* Area selected
* Quiz started
* Quiz completed
* Best time updated
* Area ownership changed

## Power-up Events

* Power-up spawned
* Power-up collected
* Power-up activated
* Power-up expired

## Area Events

* Area locked
* Area unlocked
* Area reset
* Questions regenerated

---

# Synchronization Principle

The host is the authoritative source of all gameplay decisions.

Clients never directly modify the Shared Match State. Instead, they send gameplay requests (such as collecting a power-up or completing a quiz) to the host. The host validates the request, updates the Shared Match State, and broadcasts the resulting changes to every connected player.

This approach guarantees that every device maintains a consistent representation of the game while minimizing synchronization conflicts.

---

# Design Principles

The Shared Match State follows several core principles:

* **Single Source of Truth** – Only one authoritative copy of the game state exists.
* **Event-Driven Synchronization** – Only gameplay events are synchronized rather than continuously transmitting data.
* **Modular Design** – Lobby, gameplay, AR, quiz, and power-up systems remain independent while sharing the same central state.
* **Temporary Lifetime** – The Shared Match State exists only for the duration of a match and is discarded once the match ends.

