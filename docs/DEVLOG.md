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

## [2026-09-11] — Jyotsna Kapoor — My Bookings

**Files touched:** `lib/booking_store.dart`, `lib/booking_summary_screen.dart`, `lib/main.dart`, `lib/my_bookings_screen.dart`

**Commit(s):**
- `83bdb3c` — feat: add my bookings screen

**What was done:**
- Confirmed booking ko app ke current session mein store karne ke liye `BookingStore` add kiya.
- New `booking_store.dart` file create ki.
- Booking details store karne ke liye Booking model add kiya.
- `CONFIRM BOOKING` ke time booking ko `BookingStore` mein add kiya.
- New `My Bookings` screen create ki.
- Home Screen par `MY BOOKINGS` button add kiya.
- My Bookings screen ko Home Screen se connect kiya.
- Confirmed booking ka Booking ID, pickup location, date, time, duration aur total fare display kiya.
- Booking status ko `Confirmed` ke roop mein display kiya.
- Empty state add ki jab user ki koi booking nahi hoti.

**Tested:**
- Android emulator par `MY BOOKINGS` screen open karke empty state verify ki.
- `No bookings yet` message correctly display hua.
- New booking create karke `CONFIRM BOOKING` flow test kiya.
- Booking Confirmation screen se `DONE` press kiya.
- Home Screen se `MY BOOKINGS` open kiya.
- Confirmed booking successfully My Bookings mein appear hui.
- Booking ID correctly display hui.
- Pickup location, date, time, duration aur total fare correctly display hue.
- `Confirmed` status correctly display hua.
- `flutter analyze` run kiya; koi compilation error nahi mila.

**Decisions/Notes:**
- Abhi bookings sirf current app session mein memory mein store ho rahi hain.
- App completely restart hone par bookings currently persist nahi hoti.
- Abhi database/backend integration nahi kiya gaya hai.
- Upcoming, Completed aur Cancelled booking management abhi basic stage par hai.
- Driver matching, driver assignment, payments aur live tracking abhi implement nahi kiye gaye hain.
- Future mein `BookingStore` ko proper backend/database se replace kiya jayega.

---

## [2026-09-11] — Jyotsna Kapoor — Booking Confirmation & Booking ID

**Files touched:** `lib/booking_summary_screen.dart`, `lib/booking_confirmation_screen.dart`

**Commit(s):**
- `7047c8b` — feat: add booking confirmation screen

**What was done:**
- Booking Summary screen ke `CONFIRM BOOKING` button ko Booking Confirmation screen ke saath connect kiya.
- `booking_confirmation_screen.dart` naam ki new screen create ki.
- `CONFIRM BOOKING` press karne ke baad Booking Confirmation screen open hone ka flow add kiya.
- Booking ke liye unique Booking ID generate karne ka logic add kiya.
- Booking ID ko `DOD-YYYYMMDD-XXXXX` format mein display kiya.
- Pickup location, date, time, duration aur total fare Confirmation screen par pass kiya.
- Confirmation screen par complete booking details display ki.
- `DONE` button add kiya jo user ko Home Screen par wapas le jata hai.

**Tested:**
- Android emulator par complete booking confirmation flow test kiya.
- `CONFIRM BOOKING` press karne par Booking Confirmation screen successfully open hui.
- Unique Booking ID successfully generate hui.
- Example Booking ID: `DOD-20260911-60777`
- Pickup location, date, time, duration aur total fare correctly display hue.
- `₹300 × 2 hours = ₹600` fare correctly display hua.
- `DONE` button se Home Screen par wapas aana verify kiya.
- `flutter analyze` run kiya; koi compilation error nahi mila.

**Decisions/Notes:**
- Booking ID abhi locally generate ho rahi hai.
- Booking details abhi database/backend mein permanently save nahi ho rahi hain.
- Actual booking record creation abhi implement nahi hua hai.
- Driver matching, driver assignment, driver verification, live tracking aur payments abhi implement nahi kiye gaye hain.
- `map_screen.dart` ka remaining `unnecessary_underscores` message informational lint hai aur compilation ko affect nahi karta.

---

## [2026-09-10] — Jyotsna Kapoor — Booking Summary & Confirmation

**Files touched:** `lib/booking_screen.dart`, `lib/booking_summary_screen.dart`, `test/widget_test.dart`

**Commit(s):**

- `905b983` — feat: add booking summary and confirmation

**What was done:**

- Booking screen ko Booking Summary screen ke saath connect kiya.
- `FIND A DRIVER` button ko `REVIEW BOOKING` mein change kiya
- Booking details validate hone ke baad Booking Summary screen par navigation add kiya.
- Booking screen se pickup location, pickup address, date, time, duration aur hourly rate Booking Summary screen par pass kiya.
- Naya `booking_summary_screen.dart` screen create kiya.
- Booking Summary mein selected pickup location dikhaya.
- Selected date aur time dikhaya.
- Selected booking duration dikhayi.
- Total fare ka section add kiya.
- Fare ko selected duration ke according dynamically calculate kiya.
- Current hourly rate `₹300/hour` rakha.
- Example ke liye 2 hours select karne par total fare `₹600` correctly show hua.
- `CONFIRM BOOKING` button add kiya.
- Confirm button press karne par `Booking details confirmed!` Snackbar show kiya.
- Existing Flutter widget test ko update kiya kyunki old test `MyApp` ko reference kar raha tha aur analyzer error aa raha tha.

**Tested:**

- Android emulator par complete booking flow test kiya.
- `BOOK A DRIVER` se Booking Screen open hui.
- Pickup location successfully select ki.
- Date select ki.
- Time select ki.
- Duration select ki.
- `REVIEW BOOKING` press karne par Booking Summary screen open hui.
- Pickup location, date, time aur duration correctly display hue.
- `₹300 × 2 hours = ₹600` fare calculation verify ki.
- `CONFIRM BOOKING` press kiya.
- `Booking details confirmed!` Snackbar successfully show hua.
- `flutter analyze` run kiya.
- Booking Summary se related koi compilation error nahi raha.

**Decisions/Notes:**

- Abhi `CONFIRM BOOKING` sirf confirmation Snackbar show karta hai.
- Abhi actual booking database/backend mein save nahi ho rahi hai.
- Abhi unique Booking ID generate nahi ho rahi hai.
- Driver matching aur driver assignment abhi implement nahi kiya gaya hai.
- Driver verification/background check abhi implement nahi kiya gaya hai.
- Live tracking aur payment system abhi implement nahi kiya gaya hai.
- In features ko later development phases mein implement kiya jayega.

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