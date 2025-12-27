import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:library_management_app/LoginPage.dart';
import 'package:library_management_app/main_layout.dart';
import 'package:library_management_app/registrationPage.dart';

/// A widget that manages the authentication flow of the application.
///
/// It listens to the Firebase Auth [authStateChanges] stream.
/// - If the user is logged out, it shows the [LoginPage].
/// - If the user is logged in, it checks Firestore to see if the user's profile exists.
///   - If the profile exists, it navigates to the [MainLayout].
///   - If the profile is missing (first-time user), it navigates to the [registerPage].
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Colors.black,
            body: Center(child: CircularProgressIndicator(color: Colors.white)),
          );
        }

        final user = snapshot.data;

        if (user == null) {
          return const LoginPage();
        }

        // User is logged in, check if they are registered in Firestore
        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get(),
          builder: (context, docSnapshot) {
            if (docSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                backgroundColor: Colors.black,
                body: Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              );
            }

            if (docSnapshot.hasData && docSnapshot.data!.exists) {
              return const MainLayout();
            } else {
              // Not registered yet
              return registerPage(uid: user.uid);
            }
          },
        );
      },
    );
  }
}
