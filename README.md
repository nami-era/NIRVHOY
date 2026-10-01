# Nirbhoy (নির্ভয়)

**Nirbhoy**, meaning "fearless" in Bangla, is a Flutter-based emergency safety app designed for women and children. In a dangerous situation, one quick action sends an SOS alert with the user's live GPS location to trusted contacts, even without an internet connection.

## Features

- **Quick SOS activation:** trigger an alert in seconds with the power button (3 clicks) or by shaking the phone
- **Offline emergency SMS:** sends GPS coordinates to your emergency contacts by SMS, no internet needed
- **Selective alerting:** choose exactly who gets notified
- **Siren and strobe flash:** draws attention and deters attackers
- **Slide-to-stop:** deactivate the alert with a deliberate slide gesture
- **Privacy first:** contacts and settings are stored locally on the device
- **Lightweight:** built for low battery drain

## How It Works

Nirbhoy is built around three modules:

1. **Activate:** detects the trigger (power button, shake)
2. **Control:** manages contacts, settings, and privacy
3. **Respond:** gets the GPS location, sends the SMS, and starts the siren and flash

## Tech Stack

| Purpose | Package |
|---|---|
| Framework | Flutter / Dart |
| Location | `geolocator` |
| Emergency SMS | `flutter_sms` |
| Local storage | `shared_preferences` |
| Authentication | `firebase_core`, `firebase_auth` |

## Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (Dart SDK `>=3.0.0 <4.0.0`)
- Android Studio or VS Code
- An Android device or emulator
- A Firebase project (for authentication)

### Installation

```bash
# Clone the repository
git clone https://github.com/<your-username>/nirbhoy_app.git
cd nirbhoy_app

# Install dependencies
flutter pub get

# Run the app
flutter run
```

### Firebase Setup

1. Create a project in the [Firebase Console](https://console.firebase.google.com/)
2. Add an Android app with the package name used in this project
3. Download `google-services.json` and place it in `android/app/`
4. Enable **Email/Password** sign-in under Authentication

### Permissions

The app needs the following permissions to work properly:

- **Location:** to get the user's GPS coordinates
- **SMS:** to send emergency messages

## Future Plans

- Voice-activated SOS
- Automatic audio recording with cloud backup
- Smartwatch / IoT integration
- Android cell-broadcast partnership

## Team

- Muhammad Ashraful Hossain
- Faizoh Meraj
- Namira Tabassum

## License

This project was built as a university course project. Add a license of your choice (for example, MIT) before reusing or distributing it.
