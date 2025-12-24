# Park30 🚗

Marwadi Parking is a smart parking management application built with Flutter and Firebase. It allows users to view real-time parking availability for cars and bikes, book spots, navigate to the parking location, and manage their bookings.

## ✨ Features

*   **Real-time Availability**: Visual grid view of valid parking spots (Green = Free, Red = Occupied).
*   **User Authentication**: Secure Email/OTP Sign-up and Login.
*   **Smart Booking**:
    *   Book spots for specific durations (1-12 hours).
    *   Simulated Payment Gateway (UPI/Card).
    *   Auto-release of spots after expiry.
*   **Navigation**: One-tap navigation to the parking lot using Google Maps.
*   **Notifications**: Push notifications for booking confirmation and expiry warnings (10 mins before).
*   **Admin Panel**: Analytics dashboard for revenue and occupancy stats.

## 🛠 Prerequisites

*   **Flutter SDK**: >=3.0.0
*   **Dart SDK**: >=3.0.0
*   **Firebase Project**: With Firestore, Authentication, and Messaging enabled.
*   **Android/iOS Device or Emulator**.

## 🚀 Getting Started

### 1. Installation

Clone the repository and install dependencies:

```bash
git clone https://github.com/your-username/marwadi_parking.git
cd marwadi_parking
flutter pub get
```

### 2. Configuration

#### Firebase Setup
1.  Create a project in the [Firebase Console](https://console.firebase.google.com/).
2.  Add an Android App with package name `com.example.marwadi_parking` (or check `android/app/build.gradle`).
3.  Download `google-services.json` and place it in `android/app/`.
4.  Enable **Authentication** (Email/Password).
5.  Enable **Firestore Database**.

#### Secrets Configuration
The app uses Gmail SMTP for sending OTPs. You need to configure your credentials.

1.  Open `lib/secrets.dart`.
2.  Update the file with your App Password (not your regular email password):

```dart
class Secrets {
  static const String gmailEmail = 'your-email@gmail.com';
  static const String gmailAppPassword = 'your-app-password'; // Generate from Google Account > Security > App Passwords
}
```

#### Location Configuration
To change the destination for the "Navigate" feature:
1.  Open `lib/utils/constants.dart`.
2.  Update `parkingLatitude` and `parkingLongitude`.

### 3. Running the App

Connect your device and run:

```bash
# Run on the default connected device
flutter run

# Run on a specific device (get ID from `flutter devices`)
flutter run -d <device_id>
```

## 📱 How to Use

### For Users
1.  **Register**: Create an account using your email. You will receive an OTP.
2.  **Select Zone**: Choose "Car Parking" or "Bike Parking" from the home screen.
3.  **Book a Spot**:
    *   Tap on a **Green (Available)** spot.
    *   Select duration.
    *   Complete the (simulated) payment.
4.  **Navigate**: Tap the **Direction Icon ↗️** in the map screen to open Google Maps.
5.  **My Bookings**: View your active bookings in the "Profile" tab.

### For Admins
*   Login with the admin credentials (configured in `AuthRepository` or `users` collection).
*   Access the **Admin Dashboard** to view realtime revenue, total bookings, and occupancy rates.

## ⚠️ Troubleshooting

*   **"MissingPluginException"**: Stop the app completely (`q` in terminal) and re-run `flutter run`.
*   **Firestore Index Error**: If you see a link in the terminal log starting with `https://console.firebase.google.com/...`, click it to auto-create the required composite index for the History feature.
*   **Asset Errors**: Ensure `flutter pub get` has been run after any `pubspec.yaml` changes.

## 📄 License

This project is licensed for educational purposes.
