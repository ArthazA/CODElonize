# Project Folder Structure

## Overview

The CODElonize project is organized into independent modules that separate responsibilities between augmented reality, networking, gameplay logic, quiz management, user interface, and shared data models.

This modular architecture improves maintainability, readability, scalability, and testing while minimizing coupling between systems.

---

# Project Structure

```text
CODElonize/
│
├── README.md
├── LICENSE
├── .gitignore
│
├── Docs/
├── Assets/
├── Questions/
├── CODElonize/
└── Tests/
```

---

# Root Directory

## README.md

Contains the project's overview, installation instructions, architecture summary, gameplay explanation, and development guidelines.

---

## LICENSE

Specifies the software license governing the project.

---

## .gitignore

Defines files and folders excluded from version control.

---

# Docs/

Contains all software engineering documentation.

Examples include:

* Software architecture
* Technical Design Document (TDD)
* UML diagrams
* Networking documentation
* Gameplay specifications
* Development notes

---

# Assets/

Stores all media resources used by the application.

## Models/

Contains RealityKit-compatible 3D models.

Examples include:

* Island model
* Power-up models
* Virtual pinpoints

---

## Textures/

Stores textures and materials used by 3D assets.

---

## Icons/

Contains icons used throughout the user interface.

---

## Audio/

Stores music and sound effects.

---

## Animations/

Contains animations for models and gameplay effects.

---

# Questions/

Contains JSON files that define the educational content.

Each file represents a learning topic.

Example

```text
Questions/
├── algorithms.json
├── ai.json
├── cybersecurity.json
├── oop.json
├── computernetworks.json
└── database.json
```

The Question Loader randomly selects questions from these files while ensuring that all players attempting the same area receive identical question sets.

---

# CODElonize/

Contains the application's source code.

---

## App/

Responsible for application startup and global state.

Typical responsibilities include:

* App entry point
* Global application state
* Initial configuration

---

## AR/

Contains all augmented reality functionality.

Responsibilities include:

* AR session management
* Shared world anchor placement
* Island placement
* RealityKit entities
* Pinpoint management

This module is responsible only for the visual AR experience and does not contain gameplay logic.

---

## Networking/

Responsible for multiplayer communication.

Responsibilities include:

* Lobby creation
* Lobby joining
* Peer discovery
* Host management
* Client management
* Network messages
* Match synchronization

The networking module distributes updates from the host to every connected player.

---

## Gameplay/

Contains the core game rules.

Responsibilities include:

* Match management
* Area conquest
* Timer calculations
* Score calculation
* Power-up spawning
* Power-up effects
* Win condition evaluation

This module determines how the game behaves independently of AR rendering.

---

## Quiz/

Manages the educational component of the game.

Responsibilities include:

* Loading JSON question files
* Question randomization
* Answer validation
* Quiz progression
* Completion time recording

This module guarantees that all players receive identical questions for the same area.

---

## Models/

Contains shared data models used throughout the application.

Examples include:

* Player
* Area
* Match
* Lobby
* Question
* Power-up
* Shared Match State

These models define the structure of all synchronized game data.

---

## UI/

Contains all SwiftUI user interfaces.

Example screens include:

* Home
* Lobby
* Heads-Up Display (HUD)
* Quiz
* Results
* Reusable UI components

The UI module is responsible only for presentation and user interaction.

---

## Utilities/

Contains reusable helper code.

Typical contents include:

* Constants
* Extensions
* Logging
* Helper functions
* Utility classes

---

## Resources/

Stores application resources such as:

* Configuration files
* Localization strings
* Application metadata

---

# Tests/

Contains automated tests organized by module.

Suggested organization:

```text
Tests/
├── GameplayTests/
├── NetworkingTests/
├── QuizTests/
└── ARTests/
```

Separating tests by subsystem improves maintainability and allows each module to be verified independently.

---

# Architectural Principles

The project follows several software engineering principles:

* **Separation of Concerns** – Each module has a single, clearly defined responsibility.
* **Modularity** – Features are isolated into independent components that communicate through well-defined interfaces.
* **Single Source of Truth** – The Shared Match State acts as the authoritative representation of the game during a match.
* **Scalability** – New gameplay mechanics, power-ups, quiz topics, or UI screens can be added without restructuring the project.
* **Maintainability** – A consistent directory structure allows future contributors to quickly understand and extend the codebase.
