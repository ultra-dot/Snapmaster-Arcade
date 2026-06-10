# 🎯 Snapmaster Arcade — Project Documentation

> **Arcade-style wildlife photography game** built with Godot 4.6 + MediaPipe hand tracking via Python.
> Players capture animals by aiming a camera crosshair and holding steady. Supports both mouse and computer-vision hand controls.

---

## Table of Contents

- [Quick Start](#quick-start)
- [Tech Stack](#tech-stack)
- [Project Structure](#project-structure)
- [Architecture Overview](#architecture-overview)
- [Core Systems Deep Dive](#core-systems-deep-dive)
- [Game Flow & State Machine](#game-flow--state-machine)
- [Hand Tracking System](#hand-tracking-system)
- [Known Issues & Bugs](#known-issues--bugs)
- [Improvement Roadmap](#improvement-roadmap)
- [Developer Shortcuts](#developer-shortcuts)

---

## Quick Start

### Prerequisites
- **Godot 4.6** (Forward+ renderer, D3D12 on Windows)
- **Python 3.11** (for hand tracking only)
- `pip install opencv-python mediapipe` (for hand tracking only)

### Running
1. Open `project.godot` in Godot Editor.
2. Press **F5** to run. The game starts in **mouse mode** by default.
3. To enable hand tracking: go to **Settings → Enable Hand Tracking** checkbox.

---

## Tech Stack

| Component | Technology | Purpose |
|-----------|-----------|---------|
| Game Engine | Godot 4.6 (GDScript) | Core game logic, rendering, UI |
| Hand Tracking | Python + MediaPipe | Real-time hand detection via webcam |
| Communication | TCP Socket (port 5050) | Python ↔ Godot data bridge |
| Rendering | Forward+ / D3D12 | Canvas 2D with shaders |
| Audio | OGG Vorbis | BGM + SFX with crossfade |

---

## Project Structure

```
DuckGo/
├── Scenes/                    # All .tscn scene files
│   ├── Main.tscn              # ★ Main gameplay scene (root)
│   ├── MainMenu.tscn          # Title screen + difficulty select
│   ├── SettingsPanel.tscn     # Settings overlay (volume + hand tracking toggle)
│   ├── CameraFrame.tscn       # Player's crosshair/viewfinder
│   ├── Duck.tscn              # Target entity scenes...
│   ├── Chicken.tscn
│   ├── Chicks.tscn
│   ├── Penguin.tscn
│   ├── Bear.tscn
│   ├── PolarBear.tscn
│   ├── Panglima.tscn          # Boss entity
│   ├── Pig.tscn
│   ├── Mushroom.tscn          # Healer entity (+1 life)
│   ├── Frog.tscn              # Zonk entities (penalty)...
│   ├── Kitty.tscn
│   ├── Bat.tscn
│   ├── Slime.tscn
│   └── Skeleton.tscn
│
├── scripts/                   # All GDScript files
│   ├── GameManager.gd         # ★ Central game controller (~720 lines)
│   ├── InputManager.gd        # ★ Autoload: input abstraction (mouse/hand)
│   ├── CameraFrame.gd         # Hold-and-Steady capture mechanic
│   ├── Target.gd              # Base entity behavior (movement, HP, capture)
│   ├── EduCard.gd             # Educational popup after each wave
│   ├── MainMenu.gd            # Menu logic + difficulty selection
│   ├── AudioManager.gd        # Autoload: BGM crossfade + SFX
│   ├── Global.gd              # Autoload: persistent state (highscore, settings)
│   ├── SettingsPanel.gd       # Settings UI logic
│   └── scroll_shader.gdshader # Background parallax shader
│
├── assets/
│   ├── Audio/ogg/             # BGM tracks per wave + SFX
│   ├── background/            # Per-wave background images
│   ├── buttons/               # UI button textures
│   ├── characters/            # Sprite sheets for all entities
│   ├── circle bars/           # Circular progress bar textures
│   ├── fonts/                 # Custom fonts
│   ├── ui/                    # HUD elements, logos
│   └── waterfall.mp4          # Main menu background video
│
├── tracker.py                 # ★ Python MediaPipe hand tracker
├── project.godot              # Engine config
├── main_theme.tres            # Global UI theme
└── docs/
    └── README.md              # This file
```

---

## Architecture Overview

### Autoload Singletons (always alive across scenes)

| Singleton | File | Role |
|-----------|------|------|
| `InputManager` | `InputManager.gd` | Abstracts input source (mouse vs hand tracking). Exposes `target_pos`, `is_trigger_held`, `is_trigger_pulled`. All gameplay code reads from this — never directly from `Input`. |
| `AudioManager` | `AudioManager.gd` | Dual `AudioStreamPlayer` system with crossfade for seamless BGM transitions between waves. |
| `Global` | `Global.gd` | Persistent data: `highscore`, `difficulty_multiplier`, `max_waves`, `hand_tracking_enabled`. Saves/loads highscore to `user://highscore.save`. |

### Scene Hierarchy (Main.tscn)

```
Main (Node) [GameManager.gd]
├── BackgroundLayer (TextureRect)
├── CanvasModulate
├── DuckSpawner (Node2D)
├── Camera2D
├── LightningFlash (ColorRect)
├── LightningTimer (Timer)
├── SpawnTimer (Timer)
├── HUD (CanvasLayer)
│   ├── ScoreLabel
│   ├── WaveLabel
│   ├── ComboLabel
│   ├── HeartsContainer (HBoxContainer)
│   │   ├── Heart1..Heart3 (TextureRect)
│   ├── TaskHolder / TaskHolderShadow
│   │   └── TaskLabel (RichTextLabel)
│   ├── GameOverPanel (hidden by default)
│   │   ├── GameOverImage
│   │   ├── Label
│   │   ├── FinalScoreLabel
│   │   ├── NewHighscoreLabel
│   │   ├── HomeButton
│   │   ├── RetryButton
│   │   └── SettingButton
│   ├── EduCard (TextureRect)
│   │   ├── PhotoRect, NameLabel, LatinLabel, DescLabel
│   │   └── NextButton
│   └── SettingsPanel (CanvasLayer, layer 10)
└── CameraFrame (Area2D) [CameraFrame.gd]
    ├── CollisionShape2D
    ├── Crosshair sprites
    ├── TextureProgressBar (circular)
    └── PointLight2D (flashlight for dark waves)
```

---

## Core Systems Deep Dive

### 1. Wave System (`GameManager.gd`)

The game progresses through waves with increasing difficulty:

| Wave (mod 3) | Environment | Entities | Zonks | BGM |
|--------------|-------------|----------|-------|-----|
| 1 | Farm (bright) | Duck | Frog | `Pineapple Under The Sea` |
| 2 | Meadow (warm) | Duck, Chicken, Chicks, Pig | Frog, Kitty | `Chickens In The Meadow` |
| 3 | Arctic (cold) | Penguin, PolarBear | Slime, Bat | `Polar Lights` |
| Final | Dark Castle | Panglima (boss), Bear | Bat, Skeleton | `Forgotten Biomes` |
| Bonus | Random + Disco shader | All + no zonks | None | Same as final |

**Key variables:**
- `max_wave` — set by difficulty (Easy=5, Medium=10, Hard=15)
- `speed_multiplier` — set by difficulty (1.0, 1.3, 1.6)
- `ducks_per_wave` — 5 normal, 15 for bonus wave
- `spawn_interval` — decreases per wave: `max(0.5, 2.0 - wave*0.2) / speed_multiplier`

### 2. Entity System (`Target.gd`)

All animals/enemies extend `Area2D` with these properties:

| Property | Type | Description |
|----------|------|-------------|
| `point_value` | int | Score points when captured |
| `is_zonk` | bool | If true, capturing HURTS the player |
| `is_healer` | bool | If true, capturing HEALS +1 heart |
| `base_speed` | float | Horizontal movement speed |
| `movement_type` | enum | `STRAIGHT`, `SINE_WAVE`, or `BOUNCE` |
| `max_hp` | int | Hits required to capture (boss = 3) |
| `allowed_bounces` | int | Times entity can bounce off screen edges |

**Spawn randomization:**
- 5% chance → Mushroom (healer)
- 20% chance → Zonk (penalty)
- 75% chance → Normal target
- Size variants: 15% Giant (slow, 50pts), 15% Tiny (fast, 300pts), 70% Normal

### 3. Capture Mechanic (`CameraFrame.gd`)

The "Hold and Steady" system:
1. `CameraFrame.global_position` follows `InputManager.target_pos` every frame.
2. When `InputManager.is_trigger_held` is `true`:
   - Check `get_overlapping_areas()` for valid targets.
   - If overlapping the SAME target continuously, increment `current_capture_timer`.
   - When timer reaches `capture_time` (0.5s): trigger capture.
3. On capture:
   - Hide crosshair → wait 0.05s → take viewport screenshot → call `target.capture()`.
   - Register snapshot with GameManager for EduCard display.

### 4. Scoring & Combo

- Base score from `target.point_value`.
- **Combo system:** Each consecutive capture increases `combo_multiplier` by 0.2.
- Formula: `final_score = point_value * (1.0 + combo_count * 0.2)`.
- Combo resets on `lose_life()` (zonk hit or target escape).

### 5. Health System

- 3 hearts, each with 2 HP = **6 total HP** (Zelda-style half-hearts).
- Lose 1 HP when: a non-zonk target escapes the screen, or a zonk is captured.
- Gain 2 HP when: Mushroom (healer) is captured.
- 0 HP → Game Over.
- During **Bonus Wave**: health is hidden, no HP loss (immortal mode).

### 6. Educational Card (`EduCard.gd`)

After each wave, an `EduCard` popup shows:
- **Snapshot photo** of the captured animal.
- **Species name** (Indonesian) + **Latin name** + **Fun fact description**.
- Pressing "Continue" calls `GameManager.advance_wave()`.
- Each species card is only shown **once** per game session (tracked via `shown_edu_cards` array).

### 7. Audio System (`AudioManager.gd`)

- Two `AudioStreamPlayer` nodes for **seamless crossfade** between BGM tracks.
- `play_bgm(track_name)` fades out current, fades in new over 2 seconds.
- Separate `sfx_player` for one-shot sound effects (camera click, game over, victory).

### 8. Bonus Wave (Frenzy Mode)

Triggered after completing the final wave:
- **GLSL disco shader** with 3 additive neon blobs (Pink, Cyan, Yellow) layered on HUD.
- All UI removed: no hearts, no task panel, no task shadow.
- Immortal mode: targets escaping don't reduce HP.
- 15 rapid spawns with 0.5s interval.
- After bonus wave ends → `game_over(true)` → Victory screen.

### 9. Pause System (Escape)

- `KEY_ESCAPE` toggles `toggle_pause()`.
- Reuses the `GameOverPanel` but hides the Game Over image, shows "PAUSED" label.
- `get_tree().paused = true` freezes all nodes except `GameManager` (which has `PROCESS_MODE_ALWAYS`).
- Mouse cursor is forced visible during pause.

---

## Game Flow & State Machine

```
MainMenu
  ├── Play → DifficultyPanel (Easy/Medium/Hard)
  │         └── Start → Main Scene
  │                      ├── Wave Loop:
  │                      │   ├── start_wave(n)
  │                      │   ├── Spawn entities...
  │                      │   ├── Player captures / entities escape
  │                      │   ├── duck_resolved() → update_hud()
  │                      │   ├── All resolved → end_wave()
  │                      │   ├── Show EduCard (if new species)
  │                      │   └── advance_wave() → next wave / bonus
  │                      │
  │                      ├── Bonus Wave (if final wave completed):
  │                      │   ├── Disco shader overlay
  │                      │   ├── Immortal mode, no UI
  │                      │   └── After 15 targets → game_over(true)
  │                      │
  │                      ├── Game Over (HP = 0):
  │                      │   └── game_over(false) → GameOverPanel
  │                      │
  │                      ├── Victory:
  │                      │   └── game_over(true) → Confetti + "YOU WIN"
  │                      │
  │                      └── Pause (Escape):
  │                          └── toggle_pause() → Freeze + "PAUSED"
  │
  ├── Settings → Volume slider + Hand Tracking toggle
  └── Quit → Exit
```

---

## Hand Tracking System

### Architecture

```
[Webcam] → [Python: tracker.py] →(TCP:5050)→ [Godot: InputManager.gd] → [CameraFrame.gd]
```

### Python Side (`tracker.py`)

**3-thread architecture for minimal latency:**

| Thread | Job |
|--------|-----|
| Camera Thread | Continuously grabs latest webcam frame |
| AI Thread | Processes frame with MediaPipe (downscaled to 320×240, `model_complexity=0`) |
| Main Thread | Sends data to Godot via TCP + renders debug window (unless `--headless`) |

**Gesture Detection:**

| Gesture | Detection Logic | Sent Value |
|---------|----------------|------------|
| **Open Palm** (4-5 fingers up) | `count_fingers_up() >= 4` | `x,y,0` (move cursor) |
| **Fist** (0-1 fingers up) | `count_fingers_up() <= 1` | `x,y,1` (click/hold) |

**Coordinate remapping:**
- Raw MediaPipe coords are 0.0-1.0 within the camera frame.
- A "tracking zone" (default 15%-85%) is remapped to 0%-100% game screen.
- This allows reaching all screen edges without moving the hand to the camera edge.

**TCP Packet Format:** `aim_x,aim_y,is_clicking\n` (newline-delimited, `TCP_NODELAY` enabled).

### Godot Side (`InputManager.gd`)

**Default mode:** Mouse only. No TCP server started.

**When hand tracking is enabled (via Settings checkbox):**
1. Starts `TCPServer` on `127.0.0.1:5050`.
2. Launches `python tracker.py --headless` as a subprocess.
3. Reads TCP packets every frame, parses `x,y,click`.
4. **Speed-adaptive smoothing:** Fast hand movement = snappy response, slow/still = smooth (no jitter).
5. **Fist debounce (0.1s):** Prevents flicker during palm↔fist transitions.
6. **Mouse confinement:** `MOUSE_MODE_CONFINED` keeps OS cursor inside game window.
7. **Mouse warp:** `Input.warp_mouse()` moves OS cursor so UI hover effects work.
8. **Fake mouse injection:** `_inject_mouse_event()` creates `InputEventMouseButton` so UI buttons respond to fist gesture.
9. **Auto fallback:** If no hand data for 0.5s, falls back to regular mouse input.
10. **Auto cleanup:** `OS.kill(tracker_pid)` on game exit.

---

## Known Issues & Bugs

### Critical
| # | Issue | Location | Description |
|---|-------|----------|-------------|
| 1 | **EduCard snapshot mismatch** | `GameManager.register_capture()` | The snapshot stored is based on `last_snapshot` which may not match the species shown on the EduCard if multiple captures happen rapidly. The dictionary `captured_snapshots_this_wave` exists but isn't fully utilized. |
| 2 | **Shader memory leak** | `GameManager.start_wave()` (bonus wave block) | The disco `ColorRect` with shader is added to `$HUD` but never explicitly removed when transitioning to the victory screen. If the game loops back somehow, multiple shader overlays could stack. |
| 3 | **Pause + Retry interaction** | `toggle_pause()` / `restart_game()` | If the user presses Retry while paused, `get_tree().paused` remains `true` on the reloaded scene because `restart_game()` doesn't call `get_tree().paused = false` first. |

### Minor
| # | Issue | Description |
|---|-------|-------------|
| 4 | Hand tracking checkbox doesn't persist | Toggling hand tracking in Settings doesn't save to disk. Restarting the game resets to mouse mode. |
| 5 | `udp_test.py` leftover | Test file from development still in project root. Should be deleted. |
| 6 | `task_implementation.md` and `godot_setup_guide.md` | Development docs in project root. Consider moving to `docs/`. |
| 7 | Webcam index hardcoded | `cv2.VideoCapture(0)` in `tracker.py`. External webcams may need a different index. Should be configurable. |
| 8 | `GameManager.gd` is 720+ lines | God-class anti-pattern. Wave logic, UI updates, scoring, spawning, effects, and pause are all in one file. |

---

## Improvement Roadmap

### 🔴 High Priority (Functional)

1. **Fix Retry-while-paused bug**
   - In `restart_game()`, add `get_tree().paused = false` before `reload_current_scene()`.

2. **Fix shader cleanup on victory**
   - Store reference to disco `ColorRect` and call `queue_free()` in `game_over()`.

3. **Snapshot-to-species mapping**
   - Use `captured_snapshots_this_wave` dictionary (already exists) to match each species to its actual snapshot in `end_wave()`.

4. **Persist hand tracking preference**
   - Save `hand_tracking_enabled` to `user://settings.save` in `Global.gd`.

### 🟡 Medium Priority (Polish)

5. **Refactor GameManager.gd**
   - Extract into smaller classes:
     - `WaveManager` — wave config, progression, spawning.
     - `UIManager` — HUD updates, popups, combo display.
     - `EffectsManager` — shake, lightning, confetti, disco shader.

6. **Add visual feedback for hand tracking status**
   - Show a small hand/camera icon in the HUD corner when hand tracking is active.

7. **Configurable webcam index**
   - Add a dropdown or text field in Settings for webcam selection.
   - Send the webcam index from Godot to tracker.py via command-line argument.

8. **Victory screen improvements**
   - Show a summary of all captured species.
   - Display total time played.
   - Add a "Play Again" button directly.

9. **Better EduCard flow**
   - Queue multiple EduCards if multiple new species were captured in one wave (currently only shows the first new one).

### 🟢 Low Priority (Nice-to-have)

10. **Mobile / Touch support**
    - The `InputManager` abstraction already supports this — add touch input as another mode.

11. **Leaderboard system**
    - Online highscore board with player names.

12. **More entity behaviors**
    - Entities that zigzag, fly in formation, or split on hit.

13. **Accessibility**
    - Colorblind mode for the disco shader.
    - Adjustable capture time (`capture_time` in CameraFrame).

14. **Performance profiling**
    - The disco shader uses additive blending on a full-screen `ColorRect`. Profile GPU impact on lower-end devices.

15. **Localization**
    - All text is currently Indonesian. Add English support with Godot's `TranslationServer`.

---

## Developer Shortcuts

These keyboard shortcuts work during gameplay (added to `_unhandled_input` in `GameManager.gd`):

| Key | Action |
|-----|--------|
| `N` | Skip current wave → `advance_wave()` |
| `B` | Warp directly to Bonus Wave |
| `Escape` | Toggle pause menu |

---

## Configuration Reference

### `project.godot`
- **Resolution:** 1280×720 with `canvas_items` stretch mode.
- **Pixel art rendering:** `default_texture_filter = 0` (Nearest).
- **Input map:** `click` action = Left Mouse Button.

### `tracker.py` Sensitivity Tuning
```python
X_MIN = 0.15   # Left boundary of tracking zone (decrease = more sensitive)
X_MAX = 0.85   # Right boundary
Y_MIN = 0.15   # Top boundary
Y_MAX = 0.85   # Bottom boundary
```

### `InputManager.gd` Smoothing Tuning
```gdscript
# Speed-adaptive smoothing range
var smooth = lerpf(8.0, 60.0, speed_factor)  # 8 = smooth, 60 = snappy

# Fist debounce duration
const FIST_HOLD_MIN: float = 0.1  # seconds
```

---

*Last updated: June 2026*
