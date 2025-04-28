# 🚀 BitByteAI

> AI-powered productivity and focus assistant designed to make study time immersive, rewarding, and personalized.

Welcome to **BitByteAI** — your companion for staying focused, leveling up with XP, and tracking your study patterns. This iOS app gamifies productivity with live activities, session tracking, and even cosmic mining rewards.

---

## ✨ Features

- ⏱️ **Study Timer** with XP rewards  
- 🌌 **Planet Mining Rewards System**  
- 🪐 **Live Activities** to show progress in real time  
- 🧠 **Weekly Progress Analytics**  
- 🔔 **Focus Check-ins** for accountability  
- 🧬 **XP & Leveling System** with multipliers  
- 📊 **Topic-based Tracking** (Math, CSE, etc.)

---

## 🧭 Roadmap

| Status | Feature                              | Target |
|--------|--------------------------------------|--------|
| ✅     | Core timer & XP system               | v1.0   |
| ✅     | Reward planets based on session time | v1.0   |
| ✅     | Local data persistence               | v1.0   |
| 🔜     | User profiles & custom themes        | v1.1   |
| 🔜     | Siri Shortcuts integration           | v1.1   |
| 🔜     | External device sync (iPad/Mac)      | v1.2   |
| 🧪     | AI suggestion system for study focus | v2.0   |

---

## 🧩 Documentation

### Timer Engine
- `StudyTimerModel.swift`: Main logic for session timing, XP generation, and reward logic.

### XP System
- `XPModel.swift`: Tracks user XP, level, and progression logic.

### UI Components
- `StarOverlay.swift`: Background animation of twinkling stars.
- `StarSpriteSheet.swift`: Animated star effects using a custom sprite sheet.
- `StudyTimerView.swift`: Main view showing timer, control buttons, and topic selection.

### Data Persistence
- `UserDefaults`: Used for saving earned rewards, XP, and focus streaks.
- Future plan: migrate to `CoreData` or `CloudKit`.

---

## 🔧 Setup & Run

1. Clone the repo:
   ```bash
   git clone https://github.com/yourname/BitByteAI.git
   cd BitByteAI
