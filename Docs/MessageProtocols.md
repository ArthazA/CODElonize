# CODElonize Multiplayer Message Protocol

## Purpose

This document defines every network message exchanged between players during a multiplayer match.

CODElonize follows a **host-authoritative peer-to-peer architecture**, meaning that the host device owns the authoritative Shared Match State. Clients never directly modify the game state. Instead, clients send **requests**, the host validates those requests, updates the Shared Match State, and broadcasts the results to all connected players.

This protocol serves as the communication contract between all devices.

---

# General Message Flow

```text
Client

↓

Request

↓

Host

↓

Validate

↓

Update Shared Match State

↓

Broadcast Update

↓

All Clients
```

Only the host may broadcast authoritative game state changes.

---

# Message Categories

The protocol is divided into the following categories:

1. Lobby Messages
2. Match Messages
3. Gameplay Messages
4. Quiz Messages
5. Power-up Messages
6. Synchronization Messages
7. System Messages

---

# 1. Lobby Messages

---

## CreateLobby

Direction

Client → Host (or local host initialization)

Purpose

Creates a new multiplayer lobby.

Data

* Player Name
* Device ID

Host Response

* Lobby Code
* Host Confirmation

---

## JoinLobby

Direction

Client → Host

Purpose

Requests to join an existing lobby.

Data

* Lobby Code
* Player Name
* Device ID

Host Response

* Join Accepted
* Join Rejected

---

## PlayerJoined

Direction

Host → All Clients

Purpose

Broadcasts that a new player has entered the lobby.

---

## PlayerLeft

Direction

Host → All Clients

Purpose

Broadcasts that a player disconnected.

---

## PlayerReady

Direction

Client → Host

Purpose

Player indicates readiness.

Host updates ready status and broadcasts.

---

## MatchStart

Direction

Host → All Clients

Purpose

Signals the official beginning of gameplay.

---

# 2. Shared AR Messages

---

## AnchorPlaced

Direction

Host → All Clients

Purpose

Broadcasts the shared AR anchor.

Data

* Anchor Transform
* Island Rotation
* Island Scale

---

## AnchorConfirmed

Direction

Client → Host

Purpose

Confirms successful anchor synchronization.

---

# 3. Gameplay Messages

---

## AreaSelected

Direction

Client → Host

Purpose

Player begins interacting with an area.

Data

* Player ID
* Area ID

---

## QuizBegin

Direction

Host → Client

Purpose

Host authorizes the quiz to begin.

Data

* Question Set
* Start Time

---

## QuizFinished

Direction

Client → Host

Purpose

Player submits quiz completion.

Data

* Answers
* Completion Time

Host validates and determines ownership.

---

## AreaOwnershipChanged

Direction

Host → All Clients

Purpose

Broadcasts new owner.

Data

* Area ID
* Owner
* Best Time

---

## AreaLocked

Direction

Host → All Clients

Purpose

Marks an area as temporarily unavailable.

---

## AreaUnlocked

Direction

Host → All Clients

Purpose

Allows interaction again.

---

# 4. Power-up Messages

---

## SpawnPowerUp

Direction

Host → All Clients

Purpose

Creates a new power-up.

Data

* Power-up Type
* Spawn Position
* Spawn ID

---

## CollectPowerUp

Direction

Client → Host

Purpose

Requests to collect a power-up.

Data

* Player ID
* Spawn ID

Host validates collection.

---

## PowerUpCollected

Direction

Host → All Clients

Purpose

Removes power-up from island.

Updates inventory.

---

## ActivatePowerUp

Direction

Client → Host

Purpose

Requests activation.

Data

* Player ID
* Power-up Type
* Target Area

---

## EarthquakeActivated

Direction

Host → All Clients

Purpose

Synchronizes Earthquake.

Effects

* New question set
* Reset times
* Remove owner

---

## TsunamiActivated

Direction

Host → All Clients

Purpose

Synchronizes Tsunami.

Effects

* Remove current attempts
* Lock area

---

## PocketWatchActivated

Direction

Host → All Clients

Purpose

Synchronizes Pocket Watch.

Effects

* Reduce completion time
* Recalculate owner

---

# 5. Match Messages

---

## MatchStateUpdate

Direction

Host → All Clients

Purpose

Broadcasts latest Shared Match State.

Typically includes

* Area owners
* Scores
* Inventories
* Locks
* Timers

---

## MatchFinished

Direction

Host → All Clients

Purpose

Ends gameplay.

Data

* Winner
* Final Scores

---

# 6. Synchronization Messages

---

## SyncRequest

Direction

Client → Host

Purpose

Client requests latest Shared Match State.

Used after temporary disconnection.

---

## SyncResponse

Direction

Host → Client

Purpose

Returns the newest Shared Match State.

---

## Heartbeat

Direction

Host ↔ Clients

Purpose

Confirms connection is alive.

---

## Ping

Direction

Client → Host

Purpose

Measures latency.

---

# 7. System Messages

---

## Error

Purpose

Communicates an error.

Examples

* Lobby Full
* Invalid Lobby Code
* Invalid Power-up
* Area Locked

---

## Warning

Purpose

Communicates non-critical issues.

Examples

* Weak Tracking
* Connection Weak

---

## Disconnect

Purpose

Graceful player disconnect.

---

# Typical Message Flow

## Creating a Lobby

```text
Player

↓

CreateLobby

↓

Host Created

↓

Lobby Code Generated

↓

Waiting Room
```

---

## Joining a Lobby

```text
JoinLobby

↓

Host Validation

↓

PlayerJoined

↓

Lobby Updated
```

---

## Starting a Quiz

```text
AreaSelected

↓

Host Validation

↓

QuizBegin

↓

Questions Displayed
```

---

## Completing a Quiz

```text
QuizFinished

↓

Host Validation

↓

Compare Best Time

↓

AreaOwnershipChanged

↓

Broadcast
```

---

## Collecting a Power-up

```text
CollectPowerUp

↓

Host Validation

↓

PowerUpCollected

↓

Inventory Updated

↓

Broadcast
```

---

## Activating Earthquake

```text
ActivatePowerUp

↓

Host Validation

↓

Generate New Questions

↓

Reset Area

↓

AreaOwnershipChanged

↓

Broadcast
```

---

# Design Principles

The networking protocol follows several principles:

* **Host Authority** — The host is responsible for validating and applying all gameplay changes.
* **Clients Request, Hosts Decide** — Clients never directly modify the Shared Match State.
* **Event-Driven Synchronization** — Only gameplay events are transmitted rather than continuously synchronizing all objects.
* **Deterministic Gameplay** — Every client receives identical authoritative updates, ensuring consistent gameplay across all devices.
* **Extensibility** — New gameplay mechanics should be introduced by defining new message types without changing the overall protocol structure.

---

# Version History

| Version | Changes                        |
| ------- | ------------------------------ |
| 1.0     | Initial protocol specification |

