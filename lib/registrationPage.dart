import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:library_management_app/main_layout.dart';
import 'package:slide_to_act/slide_to_act.dart';

class registerPage extends StatefulWidget {
  final String uid;

  const registerPage({super.key, required this.uid});

  @override
  State<registerPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<registerPage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _enrollment = TextEditingController();
  final _mobile = TextEditingController();

  String? _department;
  String? _semester;

  final _departments = ["CSE", "IT", "ECE", "ME", "Civil"];
  final _semesters = ["1", "2", "3", "4", "5", "6", "7", "8"];

  bool _busy = false;
  final GlobalKey<SlideActionState> _slideKey = GlobalKey();

  Future<void> _registerUser() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _busy = true);
    try {
      final user = FirebaseAuth.instance.currentUser!;
      await FirebaseFirestore.instance.collection("users").doc(user.uid).set({
        "fullName": _name.text.trim(),
        "enrollment": _enrollment.text.trim(),
        "department": _department,
        "semester": _semester,
        "mobile": _mobile.text.trim(),
        "email": user.email,
        "createdAt": FieldValue.serverTimestamp(),
      });

      // ✅ After registration → go HomePage
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => MainLayout()),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      _slideKey.currentState?.reset();
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // dark background
      body: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeOutCubic,
        builder: (context, value, child) {
          return Opacity(
            opacity: value,
            child: Transform.translate(
              offset: Offset(0, 20 * (1 - value)),
              child: child,
            ),
          );
        },
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Center(
                    child: Text(
                      "Complete Registration",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white, // white text
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Name
                  TextFormField(
                    controller: _name,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: "Full Name",
                      labelStyle: const TextStyle(color: Colors.white70),
                      enabledBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.white38),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.white),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (v) => v!.isEmpty ? "Enter your name" : null,
                  ),
                  const SizedBox(height: 12),

                  // Enrollment
                  TextFormField(
                    controller: _enrollment,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: "Enrollment No.",
                      labelStyle: const TextStyle(color: Colors.white70),
                      enabledBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.white38),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.white),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (v) =>
                        v!.isEmpty ? "Enter enrollment no." : null,
                  ),
                  const SizedBox(height: 12),

                  // Department dropdown
                  DropdownButtonFormField<String>(
                    dropdownColor: Colors.black,
                    initialValue: _department,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: "Department",
                      labelStyle: const TextStyle(color: Colors.white70),
                      enabledBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.white38),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.white),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    items: _departments
                        .map(
                          (d) => DropdownMenuItem(
                            value: d,
                            child: Text(
                              d,
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => _department = v),
                    validator: (v) => v == null ? "Select department" : null,
                  ),
                  const SizedBox(height: 12),

                  // Semester dropdown
                  DropdownButtonFormField<String>(
                    dropdownColor: Colors.black,
                    initialValue: _semester,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: "Semester",
                      labelStyle: const TextStyle(color: Colors.white70),
                      enabledBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.white38),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.white),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    items: _semesters
                        .map(
                          (s) => DropdownMenuItem(
                            value: s,
                            child: Text(
                              s,
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => _semester = v),
                    validator: (v) => v == null ? "Select semester" : null,
                  ),
                  const SizedBox(height: 12),

                  // Mobile number
                  TextFormField(
                    controller: _mobile,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: "Mobile Number",
                      labelStyle: const TextStyle(color: Colors.white70),
                      enabledBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.white38),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.white),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    keyboardType: TextInputType.phone,
                    validator: (v) => v!.isEmpty ? "Enter mobile number" : null,
                  ),
                  const SizedBox(height: 30),

                  // Swipe to register button
                  SlideAction(
                    key: _slideKey,
                    text: _busy ? "Registering..." : "Slide to Register",
                    textStyle: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                    outerColor: Colors.white,
                    innerColor: Colors.black,
                    onSubmit: _registerUser,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
