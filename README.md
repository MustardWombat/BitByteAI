# BitByte

> Productivity and focus app designed to make study time quantifiable, rewarding, and personalized.

Welcome to **BitByteAI** — your companion for staying focused, leveling up with XP, and tracking your study patterns. This iOS app gamifies productivity with live activities, session tracking, and even cosmic mining rewards.


---
## 📑 Table of Contents

1. [BitByte](#bitbyte)
2. [Features](#features)
3. [Support / Bug Report / Feature Requests](#support--bug-report--feature-requests)
4. [🧭 Roadmap](#-roadmap)
5. [Documentation](#documentation)
   - [CloudKit Documentation](#cloudkit-documentation)
   - [Data Structure Overview](#data-structure-overview)
   - [Record Types](#record-types)
     - [UserProfile](#1-userprofile)
     - [UserProgress](#2-userprogress)

---

## Features

---

## Support / bug report / feature requests

Thank you for taking the time to report issues as this helps a lot with development

https://mustardwombat.github.io/BitByteAI/

---

## 🧭 Roadmap

| Status | Feature                              | Target |
|--------|--------------------------------------|--------|
| x      | Public release                       | v1.1   |
| x      | Fleshed out Progression and tools    | v1.2   |
| x      | Widgets / dynamic island functionality | v1.3   |
| x      | AI powered                           | v2.0   |


---

## Documentation

CloudKit Documentation
This application uses Apple’s CloudKit framework to securely save and synchronize data across devices. CloudKit ensures that user data remains consistent and accessible on all signed-in devices.
Data Structure Overview
The app defines two primary record types: UserProfile and UserProgress. Each record type stores specific fields as outlined below.
Record Types
1. UserProfile
Holds identifying and profile-related information for each user.
Fields:
creationDate — The date the profile was created.
displayName — The user’s chosen display name.
lastLoginDate — The most recent login timestamp.
profileImage — A stored image representing the user’s profile picture.
userID — A unique identifier for the user.
username — The user’s account or application username.
2. UserProgress
Tracks study activity, currency, and progress metrics tied to the user.
Fields:
coinBalance — Current balance of in-app currency.
dailyMinutes — Minutes studied during the current day.
level — The user’s current level.
streak — Consecutive days of study activity.
totalStudyMinutes — Accumulated minutes studied across all sessions.
userID — The user’s unique identifier (links to UserProfile).
xp — Experience points earned by the user.
