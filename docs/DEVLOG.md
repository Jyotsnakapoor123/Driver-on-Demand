Problem Statement

Many people own a car but do not always have someone available to drive it. This becomes a problem when they need to travel after parties or events, when elderly parents need to travel, when someone is unable to drive, or when they want to take their own car on a long trip.

Currently, people often depend on friends, family members, local drivers, or informal contacts to find a driver. This process can be unreliable, time-consuming, and lacks proper trust and safety. Users may not know whether the driver is verified, experienced, or trustworthy. There is also limited visibility about the driver's location and booking details.

Solution

Driver-on-Demand is a mobile application that allows users to book a verified driver to drive their own car for a selected date, time, duration, and pickup location.

The app aims to make hiring a driver simple, convenient, and safer by providing:

Verified drivers so users have more confidence in who is driving their car.
Easy booking based on date, time, and number of hours.
Pickup location selection using a map and location search.
Transparent pricing based on the selected duration.
Driver ratings and reviews to help users choose better drivers.
Live location tracking and safety features as the product develops.
A simple booking experience where the user can book a driver instead of looking for one manually.


“You own the car. We provide the driver.”

---

## [2026-09-10] — Jyotsna Kapoor — Mappls pickup location

**Files touched:** `lib/map_screen.dart`, `lib/booking_screen.dart`, `pubspec.yaml`, `pubspec.lock`

**Commit(s):**

- `64b3dc1` — feat: integrate Mappls pickup location search

**What was done:**

- Booking screen se pickup location choose karne ka option add kiya.
- Mappls se location search karna add kiya.
- Search karne par nearby/location ke suggestions dikhaye.
- Kisi location ko select karne par map us jagah chala jata hai.
- Map par directly tap karke bhi location choose kar sakte hain.
- Selected location ka proper address booking screen par dikhaya.
- Current location button se phone ki location lene ka option add kiya.
- Search ko thoda delay diya taaki har ek letter par alag request na jaye.

**Tested:**

- `45/12 shastri nagar, ganaur, 131101` search kiya.
- `57/12 — Ganaur, Haryana, 131101` select kiya.
- Map Ganaur par move hua.
- Booking screen par `Ganaur, Haryana. (India)` show hua.
- Android app successfully build aur install hui.

**Decisions/Notes:**

- Google Maps ki jagah Mappls use kar rahe hain.
- Phone ki GPS/GNSS location current location ke liye use ho rahi hai.
- Abhi focus free/zero-cost MVP banane par hai.

---

## [2026-09-10] — Jyotsna Kapoor — Mappls Android setup

**Files touched:** Android Gradle/configuration files

**Commit(s):**

- `8e6d9cb` — feat: integrate Mappls Android SDK

**What was done:**

- App mein Mappls ko connect kiya.
- Mappls ki required settings add ki.
- Android app ko location aur internet ki permission di.
- Mappls ki secret configuration files ko GitHub se hide kiya.

**Tested:**

- Android app successfully build hui.
- Mappls app mein load hua.

**Decisions/Notes:**

- Google Maps use nahi kiya kyunki usme billing setup chahiye.
- Map aur location ke liye Mappls use karne ka decision liya.

---

## [2026-09-10] — Jyotsna Kapoor — Map aur location

**Files touched:** `lib/map_screen.dart`

**Commit(s):**

- `656d179` — feat: add map functionality with location search and geolocation features

**What was done:**

- App mein map add kiya.
- Location search add ki.
- Current location lene ka option add kiya.
- Map par location select karne ka option add kiya.
- Selected location ka address nikala.

**Tested:**

- Map Android phone/emulator par open hua.
- Location search work ki.
- Map par location select karke check kiya.

**Decisions/Notes:**

- User ki location phone ke GPS/GNSS se lene ka decision liya.

---

## [2026-09-10] — Jyotsna Kapoor — Booking screen

**Files touched:** `lib/main.dart`, `lib/booking_screen.dart`

**Commit(s):**

- `20f1bae` — feat: add booking screen navigation

**What was done:**

- Home screen se booking screen par jane ka button connect kiya.
- Date choose karne ka option add kiya.
- Time choose karne ka option add kiya.
- Driver kitne hours ke liye chahiye, uska option add kiya.
- Hours ke according total price automatically calculate kiya.
- Driver verification ka information add kiya.

**Tested:**

- Home → BOOK A DRIVER → Booking Screen successfully work kiya.

**Decisions/Notes:**

- Starting driver price ₹300/hour rakha.

---

## [2026-09-10] — Jyotsna Kapoor — Home screen

**Files touched:** `lib/main.dart`

**Commit(s):**

- `966d7f8` — feat: create driver on demand home screen

**What was done:**

- App ka first home screen banaya.
- Driver-on-Demand ka main message add kiya.
- `BOOK A DRIVER` button add kiya.

**Tested:**

- App open karke home screen check ki.
- Button properly show hua.

**Decisions/Notes:**

- App ka main idea clear rakhne ke liye simple home screen banaya.

---

## [2026-09-10] — Jyotsna Kapoor — Project setup

**Files touched:** Flutter project files

**Commit(s):**

- `5c6309c` — Initial Flutter project setup

**What was done:**

- Flutter ka new project banaya.
- Project ka basic structure ready kiya.
- Git ko project ke saath connect kiya.
- GitHub par project push kiya.

**Tested:**

- Flutter project successfully run kiya.

**Decisions/Notes:**

- App banane ke liye Flutter use karne ka decision liya.

---