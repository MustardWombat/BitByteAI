# 🚀 BitByteAI

> AI-powered productivity and focus assistant designed to make study time immersive, rewarding, and personalized.

## Overview

BitByteAI is an iOS app that gamifies productivity with features like live activities, session tracking, and cosmic mining rewards. It uses machine learning to personalize the user experience and help users stay focused while leveling up with XP.

---

## Features

- **Timer Engine**: Tracks study sessions and generates XP and rewards.
- **XP System**: Tracks user progression and levels.
- **UI Components**: Includes animated star effects and a user-friendly timer interface.
- **Data Persistence**: Saves user data locally with plans to migrate to `CoreData` or `CloudKit`.
- **Machine Learning**: Personalizes study patterns and predictions.

---

## Setup & Run

1. Clone the repository:
   ```bash
   git clone https://github.com/yourname/BitByteAI.git
   cd BitByteAI
   ```

2. Open the project in Xcode:
   - Double-click the `.xcodeproj` or `.xcworkspace` file.

3. Build and run the app on a simulator or connected device.

---

## Documentation

- **Timer Engine**: `StudyTimerModel.swift`
- **XP System**: `XPModel.swift`
- **UI Components**: `StarOverlay.swift`, `StarSpriteSheet.swift`, `StudyTimerView.swift`
- **Data Persistence**: Uses `UserDefaults` for now, with plans for `CoreData` or `CloudKit`.

---

## Contributing

Feel free to fork the repository and submit pull requests. Contributions are welcome!

---

## License

This project is licensed under the MIT License.
