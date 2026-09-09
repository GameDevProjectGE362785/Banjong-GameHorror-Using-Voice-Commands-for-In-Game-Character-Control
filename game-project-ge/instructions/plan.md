# Trust Me (คำสั่งตาย) — Junior Dev Implementation Plan

Base: Godot 4.7, Forward+, Jolt Physics. Existing: `Test/Test.tscn`, `player/player.tscn` (WASD + mouse look, capsule collider, forward `RayCast3D`, jump disabled).

Read `Trust_Me_Demo_Architecture.md` §0 before starting — the game is a **first-person survivor**, not the camera-grid/NPC-command mode from the original pitch. That's cut from the demo.

Order below follows dependency chains, not the doc's section numbers: each phase should be playable/testable on its own before moving to the next.

---

## Phase 0 — Foundations (no voice yet)

Goal: a scene you can walk around in with a working clock and lights, zero audio input.

1. **`GameClock` autoload** — counts 00:00→06:00, time-compression config var, emits `hour_tick(hour)` signal.
2. **`EventScheduler` autoload** — listens to `hour_tick`, holds a data table (array/dict) mapping hour → beat id. Stub beats as `print()` calls for now; no real logic yet.
3. **`LightingSystem` autoload** — enum `Normal / Flicker / Blackout`, exposed as a global state + signal on change. Wire the existing player flashlight so its *availability* (not just visibility) is gated by this state.
4. **`DeadBulbZone`** — tagged `Area3D` regions, at least one placed in `Test.tscn` for testing. `LightingSystem` or `RuleManager` (stub is fine here) detects overlap and prints a warning — real death consequence comes in Phase 3.

**Exit criteria:** clock ticks, flashlight turns off during a manually-triggered Blackout, walking into the dead-bulb zone logs a message. No mic, no rules enforced yet.

---

## Phase 1 — Decibel path (silence + knock), still no STT

Goal: prove the two timing-critical rules (8 and 3) work off raw mic amplitude, since these can't wait on STT latency.

1. **`VoiceInputManager` autoload — decibel branch only.** Mic capture → amplitude sampling. Do this before touching STT at all.
2. **`MicCalibration` scene** — 10s "say something / stay quiet" step, stores the player's noise floor. Needed before Silence/Knock detection is reliable.
3. **`SilenceTracker`** — rolling 30s window, fails if no sample exceeds threshold (Rule 8).
4. **`KnockPatternDetector`** — counts amplitude spikes within a window (Rule 3, and reused later for `DoorKnockFinale`).
5. **`RuleManager` autoload — skeleton.** Just enough to own Rule 8 (always armed) and Rule 3 (armed on a `GhostAI.KnockCue` stub you fire manually via a debug key for now). Consequence = print + placeholder game-over signal, not full death flow yet.

**Exit criteria:** staying silent for 30s in-game triggers the Rule 8 fail signal; a manually-fired knock cue + correct knock-back detects pass/fail. No STT involved.

---

## Phase 2 — STT + Intent Matching (unlocks Rules 2, 4, 5)

Goal: spoken Thai phrases produce dispatched intents.

1. Pick and integrate the STT engine behind an interface (`VoiceInputManager` should not care whether it's Azure or Whisper underneath — architecture doc recommends Azure for demo speed/reliability on Thai). This is an external-service integration; budget extra time here, it's the most likely to slip.
2. **Intent/Keyword Matcher** — small fixed fuzzy-match dictionary (chant phrase, ritual call phrase, self-action commands). Not full NLU — don't over-build this.
3. **Command Dispatcher** — routes matched intents to `RuleManager` / `PlayerController` / `InteractionSystem`. Keep it a thin router; it shouldn't contain rule logic itself.
4. Wire Rules 2, 4, 5 into `RuleManager` now that STT exists:
   - Rule 2 (flicker → chant): armed window ~8-10s, keyword match, forgiving fail (dread spike, not instant death).
   - Rule 4 (name-call → stay silent): pass = no matching response within window.
   - Rule 5 (04:00 fridge ritual): depends on `ObjectiveTracker` existing — see Phase 4. Wire the STT/call-phrase half now, finish the full beat in Phase 4.
5. Add the always-on-mic cooldown after each STT call (avoid the game's own ambient audio re-triggering) — route `AudioDirector` output away from the mic-input channel, or note this as a follow-up if `AudioDirector` isn't built yet.

**Exit criteria:** speaking the chant phrase during a manually-triggered Flicker passes Rule 2; speaking after a manually-triggered name-call fails Rule 4.

---

## Phase 3 — Ghost AI + full Rule consequences

Goal: rules have real teeth, and cues come from the game instead of debug keys.

1. **`GhostAI` autoload** — state machine: `Dormant → Cue → Resolved_Pass / Manifest → PlayerDeath`. `Cue` is generic/parameterized (knock, name-call, cry, flicker) — one state machine, not four scripts.
2. Wire `GhostAI` cues to actually arm the corresponding `RuleManager` rule (replacing the Phase 1/2 debug triggers).
3. Implement Rule 1 (blackout → silence, no flashlight) and Rule 6 (dead-bulb zones) as real instant-death consequences — these are the clearly-detectable ones per the doc's escalation table.
4. Implement Rule 7 (crying → return to break room) — needs a break-room `Area3D` volume and `AudioDirector.CryCue`.
5. Add the **Dread meter** (hidden, no UI) so near-misses on STT-dependent rules (2, 4, 5) escalate gradually instead of instant-failing — this is what makes STT unreliability survivable.
6. Real `GameOverScreen` on hard fail, wired from `GhostAI.PlayerDeath`.

**Exit criteria:** all 8 rules can fail for real reasons (not debug keys) and produce either instant death (1, 3, 6) or escalating dread (2, 4, 5, 8).

---

## Phase 4 — Content & Objectives

Goal: the actual night's worth of things to do.

1. **`ObjectiveTracker` autoload** — current objective(s) + completion state, feeds a minimal HUD.
2. **`InteractionSystem`** — builds on the existing forward `RayCast3D`; pickups/use-prompts.
3. Wire the factory GLB into `Night.tscn` (rename/expand from `Test.tscn`) — this is the main asset-integration item and currently nothing in the main scene references it.
4. Place and wire existing props: `Fuse` ×4 (12:00 beat, restores power → exits intro Blackout), `Wrench` (01:00 beat).
5. Build new props: delivery item (02:00), blood decals + clean interaction (03:00), meat + note (04:00, note may be missing on spawn — search sub-objective).
6. Finish Rule 5 fully now that `ObjectiveTracker` exists: item placed at marked spot AND STT call-phrase match.
7. Author dead-bulb zones per-room to match real level geometry (Phase 0 only had a test zone).

**Exit criteria:** all 6 event-scheduler beats (00:00 through 04:00, plus 05:00 as pure tension ramp) are playable in sequence with real content, not stubs.

---

## Phase 5 — Ending, UI polish, playtest pass

1. **`DoorKnockFinale`** — reuses Rule 3's knock-pattern logic; first knock = fake supervisor (ghost), second = real. Wire to `GameClock == 06:00`.
2. `ResultsScreen` on win.
3. UI pass: rules screen (pre-game, this is the entire tutorial — keep it clean/readable), mic-level indicator (small, unobtrusive — critical since the mechanic is unfamiliar), clock display (physical prop if time allows, HUD fallback otherwise).
4. Full playtest for pacing/timeline tuning — this is where the time-compression constant from Phase 0 gets its real value.

**Exit criteria:** MainMenu → MicCalibration → full night → GameOverScreen or ResultsScreen → back to MainMenu, no debug shortcuts required.

---

## Cross-cutting rules (apply from Phase 0 onward)

- **Signals flow up into autoloads, not sideways.** `player.gd` never calls `ghost_ai.gd` directly — everything routes through the autoload/EventBus layer. This matters because the STT engine choice is still open; keep systems swappable.
- Don't build the CCTV-grid / NPC-command interface — it's a post-demo stretch goal, not in scope (see architecture doc §0).
- Don't build full NLU for voice — fixed keyword/fuzzy matching only.
- No save system needed — `SaveState` is in-memory only, resets on restart.

## Where you're most likely to lose time

- STT integration (Phase 2, step 1) — external service, budget slack.
- Tuning the fuzzy-match thresholds so Thai speech under stress still passes (Phase 2/3).
- Dread-meter escalation balance (Phase 3) — needs actual playtesting, not just code review, to feel fair.
