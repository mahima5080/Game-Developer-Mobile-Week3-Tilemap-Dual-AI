# Tilemap Game Level with Dual AI & Audio (Game Developer Internship — Week 3)

A complete 2D mobile game level built with **Flutter**, **Flame Engine**, and **Flame Audio**. Includes a tilemap grid layout, 2 distinct enemy AI behaviors (Patrol & Proximity Chase), collectible items, a finish flag endpoint, sound effects, and touch controls[cite: 28].

---

## 📌 Features & Mechanics

- **Tilemap Grid Layout:** Structured platform obstacles and level topography[cite: 28].
- **Dual Enemy AI Behaviours:**
  - 🟠 **Patrol Enemy:** Moves back and forth along a fixed path[cite: 28].
  - 🔴 **Chase Enemy:** Detects player proximity (<200px distance) and aggressively pursues the player[cite: 28].
- **Collectibles & Goal:** Collectible gems for points and a victory finish flag[cite: 28].
- **Audio Feedback Engine:** Audio triggers via `FlameAudio` for collection, taking damage, and level completion[cite: 28].
- **Mobile Touch Controls:** On-screen D-Pad and Jump buttons with responsive touch handling[cite: 28].

---



## 📁 Repository Structure

**Plaintext**

```
mobile_tilemap_game_week3/
├── lib/
│   ├── main.dart       # Flutter app entry point
│   └── game.dart       # Tilemap game loop, Dual AI logic, audio, & rendering
├── pubspec.yaml        # Dependencies (flame, flame_audio)
└── README.md           # Project documentation
```


## 🚀 How to Run

1. **Install Dependencies:**
   ```bash
   flutter pub get
   ```
