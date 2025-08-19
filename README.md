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
| x      | Public release                       | v1.1   |

---

## 🧩 Documentation

## Cloudkit information

⸻

4. Querying

• Use NSPredicate to filter records.
• Use CKQueryOperation for more advanced queries or large result sets.

⸻

5. Sync and Notifications

• Use CKSubscription to get notified of changes.
• Use background fetch or silent push notifications to sync data.

⸻

6. Sharing

• Use CKShare and the shared database to enable user-to-user sharing.

⸻

7. Error Handling

• CloudKit operations are asynchronous and may fail due to network or permission issues.
• Always handle errors by checking the error parameter in completion blocks.
• For certain errors (like rate limiting), CloudKit will suggest a retry-after time.

⸻

8. Security and Privacy

• User data in the private database is encrypted and only accessible by the user.
• Public data is readable by all users, but writable only by your app.

⸻

9. Example Use Case: Syncing Tasks

Storing a Task:
• Create a CKRecord with fields like title, dueDate, etc.
• Save to the private database.

Fetching Tasks:
• Use a CKQuery to retrieve current user’s tasks.

Reacting to Changes:
• Set up a CKQuerySubscription to watch for changes and update your UI.

⸻

10. Useful Links

• Apple CloudKit Documentation
• Sample Code: CloudKit Quick Start
• Privacy Overview

⸻

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
