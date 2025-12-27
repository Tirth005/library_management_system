# Library Management App

A comprehensive Flutter application for managing library operations, built with Firebase backend. This app facilitates user authentication, book borrowing/returning via barcode scanning, and digital identity management.

## Features

*   **User Authentication**:
    *   Secure login and registration using Firebase Auth.
    *   Google Sign-In integration.
    *   First-time user registration flow to capture student details (Enrollment, Department, etc.).

*   **Dashboard (Home)**:
    *   **Digital ID Card**: Generates a QR code containing student details for easy library check-in.
    *   **Check-in Status**: Displays current library check-in status.
    *   **Issued Books**: Real-time list of currently borrowed books with due dates and overdue alerts.
    *   **Personalized Experience**: Dynamic greeting with the user's name.

*   **Book Management**:
    *   **Barcode Scanning**: Use the device camera to scan book ISBNs/barcodes.
    *   **Borrow/Return**: Seamless workflow to borrow available books or return books currently in possession.
    *   **Availability Checker**: Instantly check if a book is available or currently borrowed by another user.

*   **Profile Management**:
    *   View and edit personal details (Name, Enrollment, Mobile, etc.).
    *   Digital profile picture management.

*   **Smooth UI/UX**:
    *   **Persistent Navigation**: Smooth transitions between tabs using a persistent bottom navigation bar.
    *   **Animations**: Entrance animations and stagger effects for a polished look.

## Tech Stack

*   **Frontend**: Flutter (Dart)
*   **Backend**: Firebase (Auth, Firestore)
*   **Key Packages**:
    *   `firebase_auth`, `cloud_firestore`: Backend services.
    *   `mobile_scanner`: For scanning book barcodes.
    *   `qr_flutter`: For generating the digital ID QR code.
    *   `google_sign_in`: Social auth.
    *   `slide_to_act`: Interactive UI elements.

## Getting Started

1.  **Prerequisites**:
    *   Flutter SDK installed.
    *   Firebase project set up.

2.  **Installation**:
    ```bash
    git clone <repository-url>
    cd library_management_app
    flutter pub get
    ```

3.  **Firebase Setup**:
    *   Ensure `google-services.json` (Android) or `GoogleService-Info.plist` (iOS) is placed in the respective app directories.
    *   Currently configured for Android. Run `flutterfire configure` to set up for other platforms.

4.  **Run the App**:
    ```bash
    flutter run
    ```

## Project Structure

*   `lib/main.dart`: Entry point of the application.
*   `lib/main_layout.dart`: Main container with persistent bottom navigation.
*   `lib/services/auth_wrapper.dart`: Handles authentication state and routing.
*   `lib/HomePage.dart`: Dashboard showing ID card and issued books.
*   `lib/BooksPage.dart`: Scanner interface for borrowing/returning books.
*   `lib/profile.dart`: User profile management.
*   `lib/registrationPage.dart`: First-time user setup.
