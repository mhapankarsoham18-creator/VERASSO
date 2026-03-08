# Asset Requirements: Codemaster Odyssey

This document provides a detailed inventory of all required assets for the **Codemaster Odyssey** game engine.

## 1. Core Player Assets (Aria Vale)
Aria's sprites are 2D pixel art, using a **64x64 pixel** grid per frame. Animations are **4-frame sequenced** strips.

| Asset Path | Description | Spec |
|------------|-------------|------|
| `characters/aria/aria_idle.png` | Default static pose | 256x64 (4 frames) |
| `characters/aria/aria_run.png` | Running animation | 256x64 (4 frames) |
| `characters/aria/aria_attack.png` | Basic sword strike | 256x64 (4 frames) |
| `characters/aria/player_white_jacket.png`| Region 1-5 Costume | 256x64 (4 frames) |
| `characters/aria/player_biker.png` | Region 6-10 Costume | 256x64 (4 frames) |
| `characters/aria/player_leather.png` | Region 11-15 Costume | 256x64 (4 frames) |
| `characters/aria/player_purple.png` | Region 16-20 Costume | 256x64 (4 frames) |
| `characters/aria/player_racing.png` | Region 21-25 Costume | 256x64 (4 frames) |

## 2. NPCs & Story Characters
| Asset Path | Description | Spec |
|------------|-------------|------|
| `characters/lyra/lyra.png` | Aria's sister / Guide | 64x64 static or strip |
| `ui/book_icon.png` | Codedex menu icon | 32x32 or 64x64 |
| `assets/avatars/zephyr.png` | Multiplayer Avatar 1 | 128x128 |
| `assets/avatars/nova.png` | Multiplayer Avatar 2 | 128x128 |
| `assets/avatars/merlin.png` | Multiplayer Avatar 3 | 128x128 |

## 3. Enemies (Python Arc)
All enemies follow the same **64x64** frame standard as the player.

| Asset Path | Enemy Name | Behavior |
|------------|------------|----------|
| `characters/enemies/python/variable_viper.png` | Variable Viper | Patrol & horizontal strike |
| `characters/enemies/python/syntax_error_enemy.png` | Syntax Error | Erratic jumping |
| `characters/enemies/python/recursion_raven.png` | Recursion Raven| Flying & dives |
| `characters/enemies/python/looping_lynx.png` | Looping Lynx | Rapid repetitive attacks |
| `characters/enemies/python/class_chimera.png` | Class Chimera | Large, multi-stage attacks|

## 4. Bosses
Bosses can exceed the 64x64 size but are usually pre-cached.
| Asset Path | Boss Name | Spec |
|------------|-----------|------|
| `characters/bosses/lambda_seraph.png` | Lambda Seraph | 128x128 or 256x256 |

## 5. Environment & World
| Asset Path | Description |
|------------|-------------|
| `assets/data/regions.json` | **CRITICAL**: Defines map layout, NPC text, and enemy spawns. |
| `region_portal.png` | The exit portal for each region level. |
| `assets/tiles/` | (Optional) Tilemaps for high-fidelity levels (Tiled `.tmx` format). |
| `environment/` | Background layers (parallax backgrounds for Regions 1-5). |

## 6. Audio (Music & SFX)
### Music (.mp3)
- `audio/music/region_1_theme.mp3` through `region_5_theme.mp3`
- `audio/music/boss_theme.mp3` (Recommended)

### Sound Effects (.wav)
- `collect.wav` — Picking up fragments.
- `boss_intro.wav` — Boss encounter start.
- `challenge_complete.wav` — Successful code solution.
- `death.wav` — Player respawn.
- `portal_enter.wav` — Entering a region portal.
- `ui_click.wav` — Menu navigation.

## 7. Engine Metadata
The game preloads these assets in `odyssey_game.dart`. If any files are missing, the game falls back to a **Gold Rect (Aria)** or **Cyan Rect (Enemies)**.
