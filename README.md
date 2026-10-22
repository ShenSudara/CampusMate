# CampusMate

CampusMate is a personal safety app for university students. A student shares their journey with a trusted group, and guardians in that group can follow it live, send check-ins and get alerted when something looks wrong.

## Features

- **Accounts with two modes**: switch between Student mode (share your journeys) and Guardian mode (watch others).
- **Trusted groups**: create a group, invite members by email and manage them as the admin.
- **Destination and journeys**: search for a destination, see the route and start a journey that shares your live location.
- **Guardian live map**: follow a student's position and journey path in real time, with a warning when the signal goes stale.
- **Check-in pings**: guardians send a check-in and the student answers with "I'm Fine". An unanswered check-in becomes a missed check-in alert.
- **Motion detection**: a sudden fall or impact shows an "Are you OK?" countdown. If nobody answers, the group is alerted.
- **SOS**: send an emergency alert to the group with one tap during a journey.
- **Alerts and notifications**: local notifications for check-ins, missed check-ins and emergencies.
- **Destination weather**: current conditions at the destination, from Open-Meteo.
- **Touch ID app lock**: optionally lock the app when it opens or returns from the background. It never locks during an active journey.

## Screenshots

Save the images in `docs/screenshots/` with the file names below.

### Getting started

<!-- Screenshot: the Sign In screen with the email and password fields empty. -->
<img src="docs/screenshots/sign-in.png" alt="Sign in" width="250">

<!-- Screenshot: the Create Account screen, ideally with the Student / Guardian mode choice visible. -->
<img src="docs/screenshots/sign-up.png" alt="Create account" width="250">

### Student

<!-- Screenshot: the student Home tab with a destination selected, showing the destination card and its weather line. -->
<img src="docs/screenshots/student-home.png" alt="Student home" width="250">

<!-- Screenshot: the Destination tab while typing a search, with the list of place suggestions showing. -->
<img src="docs/screenshots/destination-search.png" alt="Destination search" width="250">

<!-- Screenshot: the Destination tab with a place selected, showing the map pin, route summary, weather and the Start Journey button. -->
<img src="docs/screenshots/destination-selected.png" alt="Destination selected" width="250">

<!-- Screenshot: the Destination tab during an active journey, showing the "Journey in progress" banner, the SOS button and Cancel Journey. -->
<img src="docs/screenshots/active-journey.png" alt="Active journey" width="250">

<!-- Screenshot: the check-in prompt a student sees when a guardian sends a ping, with the "I'm Fine" button. -->
<img src="docs/screenshots/check-in-prompt.png" alt="Check-in prompt" width="250">

<!-- Screenshot: the "Are you OK?" countdown screen that appears after motion detection (shake the phone to trigger it). -->
<img src="docs/screenshots/are-you-ok.png" alt="Are you OK countdown" width="250">

<!-- Screenshot: the journey History list with a few completed journeys. -->
<img src="docs/screenshots/history.png" alt="Journey history" width="250">

### Guardian

<!-- Screenshot: the guardian Home tab while a student is travelling, showing the trip status card with destination and weather. -->
<img src="docs/screenshots/guardian-home.png" alt="Guardian home" width="250">

<!-- Screenshot: the guardian live map showing the student's position and the journey path line. -->
<img src="docs/screenshots/guardian-live-map.png" alt="Guardian live map" width="250">

<!-- Screenshot: the Alerts list showing at least one missed check-in or SOS alert. -->
<img src="docs/screenshots/alerts.png" alt="Alerts" width="250">

<!-- Screenshot: a notification banner on the lock screen or home screen, for example a missed check-in or SOS alert. -->
<img src="docs/screenshots/notification.png" alt="Notification" width="250">

### Groups and profile

<!-- Screenshot: the Groups list with one or two trusted groups. -->
<img src="docs/screenshots/groups.png" alt="Groups" width="250">

<!-- Screenshot: a group's detail screen showing its members, their modes and the admin badge. -->
<img src="docs/screenshots/group-detail.png" alt="Group detail" width="250">

<!-- Screenshot: the Profile tab showing the mode switch, safety settings and the Security section with "Unlock with Touch ID". -->
<img src="docs/screenshots/profile.png" alt="Profile" width="250">

<!-- Screenshot: the Touch ID lock screen ("CampusMate is locked") with the Unlock with Touch ID button. -->
<img src="docs/screenshots/lock-screen.png" alt="Touch ID lock screen" width="250">

## Tech stack

- Swift and SwiftUI, using the MVVM pattern
- MapKit and Core Location for maps, routes and live location
- Core Motion for fall and impact detection
- User Notifications for local alerts
- Local Authentication for Touch ID
- Core Data for safety settings
- Firebase Authentication and Cloud Firestore (free plan, no Cloud Functions)
- Open-Meteo for destination weather (no API key)

## How it works without a server

The app runs on the free Firebase plan, so there are no Cloud Functions or push notifications. Safety checks happen in the guardian's app instead. It listens to Firestore in real time and uses timestamps to notice missed check-ins and stale locations, then shows a local notification.

## Getting started

1. Clone the repository and open `CampusMate.xcodeproj` in Xcode.
2. Create a Firebase project with **Email/Password** sign-in and a **Cloud Firestore** database.
3. Add an iOS app to the Firebase project with this app's bundle ID, download `GoogleService-Info.plist` and put it in the `CampusMate` folder. It is not included in the repository.
4. Publish the security rules from [`firestore.rules`](firestore.rules) in the Firebase console under **Firestore Database > Rules**.
5. Select your team under **Signing & Capabilities**, then build and run on a real iPhone. Location, motion and Touch ID work best on a real device.

If the guardian Home shows an error that a query requires an index, open the link in the error and click **Create Index** in Firebase.

## Project structure

```
CampusMate/
├── App/          App entry point
├── Models/       Data models
├── Views/        SwiftUI screens and components
├── ViewModels/   Screen logic
├── Services/     Firebase, location, motion, notifications, weather, security
└── Utilities/    Shared helpers and formatters
```

## Credits

Weather data by [Open-Meteo.com](https://open-meteo.com/).
