# CODElonize — Integration & Handoff Notes (v2)

**Purpose of this document:** a single, self-contained reference for continuing work on this project in a fresh chat with no prior context. It covers the project, the current codebase state, the architecture decisions finalized between the two developers, the concrete bugs found, and the work still needed — split so the next assistant/contributor can pick up the "game logic" side of the work immediately.

---

## 1. Project Summary

CODElonize is a local-multiplayer (2–5 players, same table) AR educational game built in SwiftUI + RealityKit + ARKit (iOS 26 target). Players each anchor their own copy of a shared virtual island in AR, tap pinpoints representing 7 topic areas, and answer 5 programming questions per area (3 MCQ + 2 code-arrangement). The fastest correct player owns that area. Power-up entities (Earthquake, Tsunami, Pocket Watch) and a bonus collectible (Ember Moth) spawn on the island and add strategy. Match length is 5 minutes; the winner is decided by points, tiebreak on total completion time.

Design spec: `Docs/UpdateV2.md` (note: this doc describes GameKit-based networking and a single shared ARWorldMap — both are **outdated** relative to current implementation/decisions; see §3).

## 2. Tech Stack

- SwiftUI (UI), RealityKit + ARKit (AR/3D), Combine (reactive state)
- Apple's low-level `Network` framework (`NWListener`/`NWBrowser`/`NWConnection` over Bonjour, service type `_codelonize._tcp`) for peer discovery + messaging
- `os.Logger` centralized via `AppLogger` (categories: AR, networking, gameplay, quiz, ui)
- JSON question banks bundled under `Questions/`

## 3. Task Split & Finalized Architecture Decisions

**Teammate owns:** networking/synchronization transport, host-authoritative sync research/implementation.
**You own:** game logic — quiz system, area conquest, power-up system, scoring, and now the AR-side gameplay presentation (pinpoints/power-ups as AR entities, replacing the old screen-UI mockups).

Decisions finalized in discussion:

1. **Host is the source of truth for synchronization.** Teammate is still researching the transport-level "how," but a concrete contract is needed now (see §7) because it affects how `MatchManager` must branch its logic between host and client.
2. **Islands are anchored individually per device** (no shared `ARWorldMap`/relocalization needed) — only the *logical* game state (conquests, power-up effects, timer, scores) is synchronized across devices, not physical AR world coordinates. This significantly simplifies the previously-unbuilt `AR/SharedAnchorManager.swift`.
3. **Pinpoints are fixed 3D entities on the virtual island**, tap-detected via AR hit-testing — not on-screen UI overlays. (Your task.)
4. **Power-ups are also 3D entities on the virtual island**, not on-screen UI overlays. Clarified mechanic: **a power-up is static in place until either (a) a player taps it, or (b) 2 seconds elapse without interaction** — at which point it relocates. This is a per-power-up independent behavior, not a single global synchronized tick (see §5.4 for why this matters — current code does the latter).
5. **Timer** should visually update every second. Resolved as: no host broadcast needed, no per-client independent countdown-by-decrement either — compute `remainingTime` on each device from a single shared `startTime` timestamp (already available via `StartGameMessage`), recalculated every second locally. Self-correcting, no drift, no network chatter.
6. **Host generates all 7 `questionSeed` values at match start** and transmits them to all clients, so everyone receives identical randomized question sets per area (fairness requirement already designed into `Randomizer`/`QuizManager`, just not currently wired to network).
7. **Gameplay routes through the live AR view** — the current `GameScreen` mock (`Island3DView` + tappable `MapPin` SwiftUI overlays) is a placeholder to be replaced by rendering HUD/quiz overlays on top of the real `ARViewContainer`, driven by real AR pinpoint/power-up entities.
8. **Canonical 7-area topic list confirmed:** `SwiftUI, Algorithms, Data Structures, Networking, Databases, OOP, Frameworks` (matches `GameConstants.areaTopics` and the currently-used `Questions/*.json` files). The older 6-topic naming referenced in stale comments (`Algorithms, AI, Cybersecurity, OOP, Computer Networks, Database`) is **not** canonical and should be cleaned up.
9. **`defaultIslandScale` will be fixed** to a sensible value within the existing `minIslandScale`/`maxIslandScale` range (0.005–0.05) — currently set to `2`, which is out of range.

## 4. Files Relevant to Your Side of the Work

| System | Files |
|---|---|
| Quiz System | `CODElonize/Quiz/QuizManager.swift`, `Quiz/QuestionLoader.swift`, `Quiz/Randomizer.swift`, `Quiz/AnswerValidator.swift`, `Models/Question.swift`, `UI/Quiz/QuestionView.swift`, `UI/Quiz/CodeArrangementView.swift` |
| Area Conquest | `Gameplay/AreaManager.swift`, `Gameplay/ConquestSystem.swift`, `Models/Area.swift` |
| Power-ups | `Gameplay/PowerUpManager.swift`, `Gameplay/SpawnManager.swift`, `Models/PowerUp.swift`, `UI/Quiz/AreaPicker.swift` |
| Scoring / orchestration | `Gameplay/ScoreManager.swift`, `Gameplay/MatchManager.swift`, `Gameplay/TimerSystem.swift` |
| UI | `UI/Home.swift`, `UI/Lobby.swift`, `UI/GameScreen.swift`, `UI/HUD.swift`, `UI/Results.swift`, `UI/HowToPlayView.swift`, `UI/UIComponents.swift`, `UI/IslandPreviewView.swift` |
| AR (shared boundary with teammate) | `AR/ARSessionManager.swift`, `AR/PinpointSystem.swift`, `AR/IslandPlacement.swift`, `AR/RealityKitExtensions.swift`, `AR/ARViewContainer.swift` — you'll likely need to extend/add to these for power-up AR entities and to route gameplay through them |
| Constants | `Utilities/Constants.swift` (`GameConstants`) |

## 5. Bugs Found (confirmed, need fixing regardless of AR work)

### 5.1 `PinpointSystem.areaColors` array too short
`GameConstants.areaCount = 7`, but `PinpointSystem.areaColors` only has 6 entries (`.systemRed, .systemPurple, .systemGreen, .systemBlue, .systemOrange, .systemYellow`). `spawnPinpoints()` loops `0..<GameConstants.areaCount` and will index out of bounds on `areaColors[6]` → **crash** once area 6 (Frameworks) is actually spawned. Needs a 7th color added.

### 5.2 Root cause of "power-ups only appear after Armageddon" and "timer only updates on interaction"
Both are the **same underlying bug**: `MatchManager` owns `spawnManager`, `timerSystem`, and `quizManager` as separate `ObservableObject`s, but never forwards their `objectWillChange` publishers into its own, the way `AppState` already does for `lobbyManager`:

```swift
// AppState.swift — already does this correctly for lobbyManager:
lobbyManager.objectWillChange
    .sink { [weak self] _ in self?.objectWillChange.send() }
    .store(in: &cancellables)
```

`GameScreen`/`HUD` only observe `matchManager` via `@EnvironmentObject`, so SwiftUI only re-renders when *MatchManager's own* `@Published` properties change (`leaderboard`, `isQuizActive`, etc.) — not when `spawnManager.spawnedPowerUps` or `timerSystem.remainingTime` mutate internally. `spawnManager.startSpawning()` genuinely does spawn power-ups on schedule (15–45s in) and the timer genuinely does tick every second — the view simply isn't told to redraw until something touches `MatchManager`'s own published state (e.g. a pinpoint tap → `refreshLeaderboard()`, or Armageddon triggering → `gameState.areas` mutation → debounced leaderboard refresh). That's why power-ups seem to "suddenly appear" and the timer seems to "only update on interaction" — everything was already correct internally, it just wasn't being rendered.

**Fix:** forward `objectWillChange` from `spawnManager`, `timerSystem`, and `quizManager` up through `MatchManager`, same pattern as `AppState` uses for `lobbyManager`. **Do this before building the AR power-up entity system**, or the new system will inherit the same invisible-update bug.

### 5.3 Drag-and-drop doesn't actually exist in `CodeArrangementView`
Despite `Docs/UpdateV2.md` describing "Player drags code blocks into slots," and despite the file importing `UniformTypeIdentifiers` (typically used for `.draggable`/`.onDrop`), the actual implementation in `CodeArrangementView.swift` is a **tap-to-select, tap-to-place** mechanic (`selectedOption` state + `handleTap()` in `SlotView`) — there is no `DragGesture`, `.draggable`, or `.onDrop` anywhere in the file. The `UniformTypeIdentifiers` import is unused dead weight from an earlier, abandoned drag-and-drop attempt. This isn't a small bug — it's a mismatch between the documented design and the shipped interaction model. **Needs a decision** (see open questions §8) on whether to implement true drag-and-drop or formally adopt tap-to-select as the intended mechanic (arguably better for AR/mobile use anyway, since dragging a small UI onto AR-anchored space is awkward).

### 5.4 Power-up relocation is a single global tick, not per-entity
`SpawnManager.startRelocationTimer()` runs one shared `Timer.publish(every: GameConstants.powerUpMoveInterval, ...)` that calls `relocateAllActive()`, moving **every** active power-up and Ember Moth simultaneously every 2 seconds. This contradicts the now-clarified design ("static until tapped or 2 seconds pass" — implying each power-up has its **own** independent 2-second window that resets on tap, not a synchronized global tick affecting all of them at once). This needs a redesign: each spawned power-up/moth needs its own timer/expiry tracked individually (e.g., a `lastInteractionTime` per instance, checked/reset per-entity), not a single shared `Timer.publish`.

### 5.5 No 3D positions exist for power-up spawn slots
`GameConstants.powerUpSpawnSlots: Int = 5` only defines a *count* of abstract slots — there is no equivalent of `GameConstants.pinpointPositions` (a `[SIMD3<Float>]`) for power-ups. Building power-ups as real AR entities will require adding real 3D positions per slot, analogous to how pinpoints are positioned.

### 5.6 `defaultIslandScale` out of documented range
`GameConstants.defaultIslandScale = 2`, but `minIslandScale = 0.005` / `maxIslandScale = 0.05`. To be fixed per decision #9 above.

### 5.7 Stale/inconsistent topic naming and orphaned question files
`PinpointSystem.areaColors`' inline comments still reference the old 6-topic naming (`Algorithms, AI, Cybersecurity, OOP, Computer Networks, Database`), which contradicts the now-confirmed canonical list (`SwiftUI, Algorithms, Data Structures, Networking, Databases, OOP, Frameworks`). Additionally, `Questions/ai.json`, `Questions/cybersecurity.json`, and `Questions/computernetworks.json` don't correspond to any current area and are never loaded by `QuestionLoader` — safe to delete once confirmed unneeded.

### 5.8 `GameScreen` always starts a local single-player match
`GameScreen.onAppear` unconditionally calls `matchManager.startSinglePlayerMatch(playerName:)` if no match is active — it never uses the real `LobbyModel.players` list or checks host/client role. This needs to be replaced with proper match initialization driven by the new match-start payload (see §6.3) once your teammate's networking contract is available, but the **local single-player path should probably be kept as a dev/testing fallback**, not deleted outright.

## 6. New/Changed Work Needed On Your Side

### 6.1 Host/client branching in `MatchManager`
`MatchManager` currently has no concept of "am I the host." With host-authoritative sync, only the host should actually execute `ConquestSystem.processAttemptResult`, `PowerUpManager.activate*`, `ScoreManager.determineResult`; clients should receive and apply results rather than compute them locally. This needs an `isHost` flag (or equivalent) threaded through `MatchManager`, and its methods (`handleQuizCompletion`, `handlePowerUpActivation`, `handlePowerUpCollection`, `handleEmberMothCollection`, `endMatch`) split into "host computes + broadcasts" vs. "client applies received state" paths. **This is blocked on your teammate's sync contract (§7)** but the branch structure can be scaffolded now against a stub/mock transport.

### 6.2 Timer driven by shared start timestamp
Replace/augment `TimerSystem`'s per-second decrement with a calculation from a shared `startTime: Date` (already present in `StartGameMessage`): `remainingTime = matchDuration - Date().timeIntervalSince(startTime)`, recalculated on a local 1-second `Timer.publish` tick per device (no network traffic needed for this, just a shared epoch). Combine with the fix in §5.2 so the UI actually redraws every second.

### 6.3 Extend match-start payload with question seeds (and likely player list)
Extend `StartGameMessage` (or introduce a new payload type if your teammate prefers) to carry `questionSeeds: [UInt64]` (7 values, one per area) generated once on the host, plus whatever player-list data is needed to call `GameState.initializeMatch(players:localPlayerID:)` on every device consistently. `Area.createAllAreas()` will need a variant that accepts externally-provided seeds instead of calling `Randomizer.generateSeed()` per-device.

### 6.4 AR pinpoint + power-up entity system (routing gameplay through AR)
- Reuse/extend `PinpointSystem`'s existing pattern (entity creation, `Entity.findPinpointAreaIndex()` ancestor-walk, `arView.entity(at:)` hit-testing) as the template for a new power-up entity system.
- Power-ups/Ember Moths need: a 3D position table (§5.5), static placement until tap-or-2s-elapsed (§5.4, redesigned as per-entity), tap detection analogous to `detectPinpointTap`, and removal/respawn animation hooks (visual polish can come later — the state-tracking plumbing is the priority).
- Replace `GameScreen`'s mock `Island3DView` + `MapPin` overlay approach with rendering the HUD/quiz overlays on top of the real `ARViewContainer`, driven by `ARSessionManager.tappedAreaIndex` (already wired to `MatchManager.handlePinpointTap` via `AppState`) and a new equivalent signal for power-up taps.
- **Clarify with teammate:** since power-up AR entities sit right at the boundary between "AR scaffolding" (her domain) and "power-up system" (your domain), confirm who owns writing the entity/hit-testing code vs. who owns the spawn/claim/relocation logic behind it.

### 6.5 Code arrangement interaction model
Once decided (§8), either implement genuine `DragGesture`/`.onDrop`-based drag-and-drop in `CodeArrangementView`, or formally document tap-to-select as the intended mechanic and remove the unused `UniformTypeIdentifiers` import.

### 6.6 Cleanup once confirmed safe
- Add a 7th color to `PinpointSystem.areaColors` and update its stale topic-naming comments.
- Delete `Questions/ai.json`, `cybersecurity.json`, `computernetworks.json` if teammate confirms they're not needed.
- Fix `GameConstants.defaultIslandScale`.
- Fix docstring in `PowerUpManager.activatePocketWatch` (says "10%" in comments, actually uses the correct 20% constant — comment-only fix).

## 7. Networking/Sync Contract Needed From Teammate

You don't need her full transport implementation to start, but you do need agreement on:

1. A minimal interface you can code against now (even a stub): something like "send event up to host," "receive event down from host," plus an `isHost`/`localPlayerID` accessor.
2. The following message payloads, eventually, in whatever form her transport layer prefers (extending existing `MessageType`/`NetworkMessage<T>` pattern, which already has unused `.areaCaptured`, `.powerUp`, `.timer`, `.score`, `.finish` cases reserved):
   - **Match start:** players list + `startTime` + `questionSeeds: [UInt64]` (7 values).
   - **Area conquest result:** area index, new owner, new best time (host → clients).
   - **Power-up event:** collected (spawn id, player, type), activated (type, target area, result description), relocated (spawn id, new position/slot) (host → clients, or client → host request then host → clients confirm, depending on her authority model).
   - **Ember Moth event:** collected (spawn id, player).
   - **Score/finish:** final leaderboard + winner (host → clients) at match end.
3. Confirmation of the individually-anchored-islands decision so she doesn't spend research time on `ARWorldMap`/relocalization (§3.2) — this significantly narrows her scope.

## 8. Open Questions Still Needing Decisions

1. **Code arrangement interaction:** true drag-and-drop (matching the original doc) or formally adopt tap-to-select-then-place (already implemented, arguably better suited to AR/mobile)?
2. **Power-up AR entity ownership:** who writes the entity creation/hit-testing plumbing (teammate, as AR infra) vs. who writes spawn/claim/relocation logic (you, as power-up system) — and where's the line?
3. **Per-power-up timer granularity:** should each spawned power-up independently track "time since last tap" (reset on tap, triggers relocation at 2s), or is there a simpler acceptable approximation? (Needed to properly fix §5.4.)
4. **Host authority granularity:** does the host compute *and* broadcast the full new `GameState` diff, or does it broadcast just the specific event (e.g., "area 3 conquered by player X, time Y") and let each client apply that single event to its own local state? (Affects payload design in §7.)
5. **Fallback/dev mode:** should the existing `startSinglePlayerMatch` local-only path be kept permanently as a testing/dev shortcut (recommended), or removed entirely once real multiplayer match-start is wired?

## 9. Suggested Order of Work

1. Fix the low-risk, self-contained bugs first: `areaColors` array size (§5.1), `defaultIslandScale` (§5.6), stale comments/orphaned JSON (§5.7), docstring typo.
2. Fix the `objectWillChange` forwarding bug in `MatchManager` (§5.2) — small, high-impact, and must happen before building new AR-driven UI on top of these systems.
3. Decide the code-arrangement interaction model (§8.1) and implement accordingly (§6.5).
4. Scaffold the host/client branch in `MatchManager` against a stub sync interface (§6.1), so your logic is ready the moment your teammate's transport lands.
5. Switch `TimerSystem` to shared-start-timestamp calculation (§6.2).
6. Build the AR power-up entity system with correct per-entity static/relocate-on-timeout behavior (§6.4, §5.4, §5.5) — after confirming ownership boundary with teammate (§8.2).
7. Replace `GameScreen`'s mock overlay with real AR-routed gameplay (§6.4).
8. Once teammate's real transport is ready: wire the extended match-start payload (§6.3) and the host-authoritative event flow (§6.1) into the real network layer, replacing the stub interface.
