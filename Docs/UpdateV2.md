# CODElonize
### Multiplayer Augmented Reality Territory Conquest Game

Version: Prototype v2

Platform:
- iOS
- SwiftUI
- ARKit
- RealityKit
- GameKit (peer-to-peer networking)

---

# Overview

CODElonize is a local multiplayer Augmented Reality educational game where players compete to conquer islands by answering programming-related questions.

The game is designed for 2–5 players physically standing around the same table.

One shared AR island map is anchored onto the table.

Players walk around the table while interacting with the virtual islands and collecting power-ups.

The player with the highest score at the end of the match wins.

---

# Core Gameplay Loop

Host creates room

↓

Players join room

↓

Host scans table

↓

Host places shared island

↓

All players synchronize to the same ARWorldMap

↓

All players press READY

↓

Game starts

↓

Players explore island

↓

Select an area

↓

Complete five programming questions based on area's topic

↓

Record completion time

↓

Server determines ownership

↓

Island appearance updates for every player

↓

Collect / Use power-ups

↓

Repeat until timer ends

↓

Final ranking

---

# Multiplayer

Networking uses GameKit.

One host creates the room.

Joiners enter the room code.

Host shares:

- ARWorldMap
- Game start
- Island state
- Power-up events

Gameplay is synchronized through GameKit events.

Players DO NOT synchronize camera position or movement.

Only gameplay events are synchronized.

Examples:

- Island conquered
- Power-up collected
- Power-up activated
- Armageddon Phase
- Game end

---

# Shared AR Environment

Only ONE island map exists.

All players view the same island.

Host performs AR plane detection.

Host places the island.

ARWorldMap is serialized and shared with every player.

Each player relocalizes into the same coordinate system.

---

# Island Layout

Current number of areas:

7

Topics:

- SwiftUI
- Algorithms
- Data Structures
- Networking
- Databases
- OOP
- Frameworks

One additional area remains locked until Armageddon Phase.

---

# Area Rules

Every area contains

5 questions

Question order:

Question 1
MCQ

Question 2
MCQ

Question 3
MCQ

Question 4
Code Arrangement

Question 5
Code Arrangement

A player may only attempt an area once.

The player with the fastest completion time owns the island.

If another player beats the recorded time, ownership transfers.

---

# Question Types

## Multiple Choice

Four options.

Player taps an answer.

Submission occurs immediately.

Correct:

Continue to next question.

Incorrect:

Player screen freezes for 3 seconds.

No interaction allowed during freeze.

No submit button.

---

## Code Arrangement

Player drags code blocks into slots.

Each question contains:

3 answer slots

4 draggable code blocks

Exactly ONE correct combination.

One option is a distractor.

A Submit button validates the arrangement.

Correct:

Continue.

Incorrect:

Freeze player input for 3 seconds.

---

# Code Arrangement Behaviour

Each answer block exists only once.

Dragging a block into an occupied slot causes:

Current block inside slot

↓

Returns to its original answer option location

↓

Dragged block occupies slot

No duplicate blocks may exist.

Always maintain exactly

3 filled slots maximum.

---

# Code Arrangement JSON Schema (not final)

Example

{
  "id": 101,
  "type": "code_arrangement",
  "topic": "SwiftUI",
  "question": "Complete the SwiftUI modifier.",
  "codeTemplate": [
    "Text(\"Hello\")",
    "_____",
    "font(.title)",
    "_____",
    "padding()",
    "_____"
  ],
  "slots": 3,
  "options": [
    ".foregroundStyle(.blue)",
    ".background(Color.red)",
    ".cornerRadius(10)",
    ";"
  ],
  "correctAnswer": [
    ".foregroundStyle(.blue)",
    ".background(Color.red)",
    ".cornerRadius(10)"
  ]
}

The fourth option acts as a distractor.

There is only ONE valid answer.

---

# Area Ownership

Each area stores

Topic

Owner

Best Time

Visual State

Question Set

Attempt History

Players cannot retry unless reset by Earthquake.

---

# Scoring

Points determine ranking.

Area conquered

+1 point

Ember Moth

+0.5 points

Ranking priority

1.
Highest points

2.
Lowest accumulated elapsed time across conquered areas

---

# Power-Up System

Each player has

ONE power-up inventory slot.

If inventory is full

Player cannot interact with any power-up entity.

Touches are ignored.

---

# Power-Up Spawn

Power-ups appear randomly.

Each power-up exists as a RealityKit Entity.

Power-ups relocate every

2 seconds

to another nearby spawn point.

---

# Claiming a Power-Up

Player taps power-up.

Initial success chance

10%

Failure

Power-up instantly relocates

Claim chance increases

+7.5%

Repeat until claimed.

After successful claim

Chance resets.

---

# Standard Power-Ups

## Earthquake

Resets an area.

Effects

- Remove owner
- Remove best time
- Clear attempt history
- Generate new question set

Visual

Island shakes

Terrain changes

---

## Tsunami

Effects

Cancel every player currently attempting that area.

Area becomes locked.

Players cannot enter until timer expires.

Visual

Water rises

Flood

Water recedes

---

## Pocket Watch

Reduce recorded completion time by

20%

---

# Ember Moth

Special collectible.

Does NOT occupy inventory.

Uses the same claiming mechanic.

Immediately awards

+0.5 points

after successful claim.

Disappears immediately.

No activation required.

---

# Armageddon Phase

Triggered automatically

Final 60 seconds.

Effects

Unlock predetermined locked area.

(No Tsunami animation.)

Spawn one Ember Moth.

Broadcast event to every player.

---

# Animation Events

Earthquake

- Shake island
- Terrain change
- Dust particles

Tsunami

- Water rises
- Flood animation
- Water recedes

Capture

- Island changes owner color
- Flag animation

Power-Up Spawn

- Floating animation
- Rotation

Power-Up Relocation

- Fade out
- Teleport
- Fade in

Ember Moth

- Floating
- Flutter animation

---

# Configurable Gameplay Constants

All balancing values MUST exist in one file.

Example

GameBalance.swift

Variables

initialClaimChance = 0.10

claimIncrease = 0.075

powerupMoveInterval = 2

freezeDuration = 3

tsunamiLockDuration = configurable

pocketWatchReduction = 0.20

emberMothPoints = 0.5

armageddonRemainingTime = 60

Changing balancing should never require editing gameplay logic.

---

# Suggested Managers

GameManager

Controls overall game state.

QuestionManager

Loads questions.

Handles progression.

PowerUpManager

Spawn

Movement

Claim

Activation

Inventory

IslandManager

Ownership

Visual state

ScoreManager

Points

Leaderboard

Tie-breaking

ARSessionManager

Plane detection

WorldMap

Relocalization

IslandRenderer

RealityKit rendering

AnimationManager

Earthquake

Tsunami

Capture

Power-ups

NetworkManager

GameKit communication

Synchronization

---

# Game States

Main Menu

↓

Lobby

↓

Preparation

↓

Gameplay

↓

Armageddon Phase

↓

Match End

---

# Win Condition

When timer reaches zero

Calculate

Points

↓

Tie?

↓

Compare total elapsed completion time

↓

Declare winner

---

# Future Improvements

- AI-generated question packs
- Dynamic difficulty
- Additional power-ups
- More question types
- Persistent player progression
- Leaderboards
