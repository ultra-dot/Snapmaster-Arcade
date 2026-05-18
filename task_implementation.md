# PROJECT CONTEXT: "PhotoHunt Arcade"
**Engine:** Godot 4.x
**Language:** GDScript
**Genre:** Arcade / Photography (Inspired by Retro Duck Hunt)

## 1. Project Overview
The game is a photography-themed arcade game where players must "frame and capture" (shoot) moving targets (birds/ducks) across the screen. 
This project is divided into two development phases. The AI Agent must strictly focus on **Phase 1** while building a modular architecture that supports Phase 2 without requiring major refactoring.

- **Phase 1 (Current Focus):** Core gameplay loop. Spawning targets, aiming with a crosshair, taking photos (shooting), scoring, and using Mouse/Joystick as the primary input.
- **Phase 2 (Future Scope):** Replacing the mouse input with a Python + MediaPipe UDP Hand Tracking system using a "Hold and Steady" trigger mechanic.

## 2. Core Architecture Directive: Separation of Input
To support the transition from Mouse to UDP Hand Tracking later, the project MUST use an Input Manager pattern.
- **DO NOT** hardcode `get_global_mouse_position()` directly into the player/crosshair scripts.
- **DO CREATE** an Autoload/Singleton named `InputManager.gd`.

### InputManager.gd (Singleton) Structure:
- `var target_pos: Vector2`: The current position the crosshair should be at.
- `var is_trigger_pulled: bool`: A boolean representing if the player is taking a photo (clicking/triggering).
- **In Phase 1:** `_process()` updates `target_pos` using the mouse position, and `is_trigger_pulled` using `Input.is_action_just_pressed("click")`.

## 3. Key Game Systems to Implement

### A. The Crosshair / Camera Frame (Player)
- A visual node (Sprite2D/Control) representing the camera viewfinder.
- Its position is strictly updated by reading `InputManager.target_pos`.
- When `InputManager.is_trigger_pulled` is true, it performs a RayCast2D or Area2D overlap check to see if a target is perfectly framed.
- Add visual feedback (a quick flash or shutter animation) when triggered.

### B. The Target (Duck/Bird)
- **Scene structure:** CharacterBody2D or Area2D.
- **Movement:** Simple linear movement from one side of the screen to the other (left-to-right or right-to-left).
- **States:** 
  1. `Moving` (flying across the screen).
  2. `Captured` (successfully photographed, stops moving, plays a flash/freeze animation, then queue_free).
  3. `Escaped` (reached the end of the screen without being photographed, queue_free).

### C. Visual Layout & Layering (Z-Index / CanvasLayer)
The game must be rendered in three distinct layers to create a camera viewfinder aesthetic:
1. **Background Layer (Lowest Z-index):** A static `TextureRect` or `Sprite2D` (e.g., a landscape scene).
2. **Playable Area (Middle):** Targets (Ducks) spawn and move strictly in front of the background.
3. **Static Overlay Frame (Highest Z-index/Top CanvasLayer):** A transparent UI overlay (e.g., a camera border, arcade bezel, or lens UI with REC/Battery indicators) covering the edges of the screen. Targets MUST render *behind* this frame.

### D. User Interface (HUD)
- Create a `CanvasLayer` node named `HUD` to separate UI from the 2D game world. Ensure it renders correctly with the Static Overlay Frame.
- Include a Score counter (`Label`).
- Include a Timer or Ammo/Film limit indicator (`Label` or `TextureProgressBar`).

### E. Screen Boundaries & Project Settings
- Set the base window resolution to a standard 16:9 aspect ratio (e.g., 1920x1080 or 1280x720) in Project Settings.
- Use the `VisibleOnScreenNotifier2D` node on the Target (`Duck.tscn`) to accurately detect when the target completely leaves the screen, triggering the 'Escaped' state and safely calling `queue_free()`.
- Add a Game Manager script/node to handle spawning targets at random Y-axis positions from the screen edges, keeping track of the score and time/film limits.

## 4. Current Tasks for Godot MCP
1. Initialize the project structure (create folders for `Scenes`, `Scripts`, `Assets`).
2. Setup the Project Settings (Resolution 16:9).
3. Create and configure the `InputManager.gd` Autoload.
4. Build the Target (`Duck.tscn`) scene with simple horizontal movement and `VisibleOnScreenNotifier2D` logic.
5. Build the Crosshair (`CameraFrame.tscn`) scene that follows the `InputManager`.
6. Create the Main Game scene (`Main.tscn`) implementing the strict Layering Rules (Background -> Target -> Overlay Frame + HUD) and basic spawning logic.