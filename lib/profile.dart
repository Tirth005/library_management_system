import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'services/auth_service.dart';

/// Displays and allows editing of user profile information.
///
/// Fetches user data from Firestore and displays it in a form.
/// Users can update their:
/// - Full Name
/// - Enrollment Number
/// - Department
/// - Semester
/// - Mobile Number
///
/// Also handles the logout functionality.
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool isEditing = false;
  final _formKey = GlobalKey<FormState>(); // Form Key to validate input
  final _authService = AuthService();

  // Text controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _enrollmentController = TextEditingController();
  final TextEditingController _departmentController = TextEditingController();
  final TextEditingController _semesterController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _enrollmentController.dispose();
    _departmentController.dispose();
    _semesterController.dispose();
    _mobileController.dispose();
    super.dispose();
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'fullName': _nameController.text,
        'enrollment': _enrollmentController.text,
        'department': _departmentController.text,
        'semester': _semesterController.text,
        'mobile': _mobileController.text,
      });

      if (mounted) {
        Navigator.pop(context); // Remove loading
        setState(() => isEditing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Remove loading
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to update profile: $e')));
      }
    }
  }

  Future<void> _handleLogout() async {
    try {
      await _authService.signOut();
      if (mounted) {
        // Pop all routes and go to login/auth wrapper handle by main.dart
        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error signing out: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: Colors.grey[900],
        title: const Text('Profile', style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: Icon(isEditing ? Icons.save : Icons.edit),
            onPressed: () {
              if (isEditing) {
                _updateProfile();
              } else {
                setState(() => isEditing = true);
              }
            },
            tooltip: isEditing ? 'Save Profile' : 'Edit Profile',
            color: Colors.white,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: Colors.grey[900],
                  title: const Text(
                    'Logout',
                    style: TextStyle(color: Colors.white),
                  ),
                  content: const Text(
                    'Are you sure you want to logout?',
                    style: TextStyle(color: Colors.white70),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _handleLogout();
                      },
                      child: const Text(
                        'Logout',
                        style: TextStyle(color: Colors.redAccent),
                      ),
                    ),
                  ],
                ),
              );
            },
            tooltip: 'Logout',
            color: Colors.redAccent,
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(FirebaseAuth.instance.currentUser?.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text(
                'Error loading profile',
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final userData = snapshot.data?.data() as Map<String, dynamic>?;
          if (userData == null) {
            return const Center(
              child: Text(
                'No profile data found',
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          // Update controllers if not editing to keep in sync with DB
          if (!isEditing) {
            _nameController.text = userData['fullName'] ?? '';
            _enrollmentController.text = userData['enrollment'] ?? '';
            _departmentController.text = userData['department'] ?? '';
            _semesterController.text = userData['semester'] ?? '';
            _mobileController.text = userData['mobile'] ?? '';
          }

          return TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 600),
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Padding(
                  padding: EdgeInsets.only(top: 20 * (1 - value)),
                  child: child,
                ),
              );
            },
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    const Hero(
                      tag: 'profile-pic',
                      child: CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.white24,
                        child: Icon(
                          Icons.person,
                          size: 50,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    _buildTextField(
                      'Full Name',
                      _nameController,
                      enabled: isEditing,
                      icon: Icons.person_outline,
                    ),
                    _buildTextField(
                      'Enrollment Number',
                      _enrollmentController,
                      enabled: isEditing,
                      icon: Icons.numbers,
                    ),
                    _buildTextField(
                      'Department',
                      _departmentController,
                      enabled: isEditing,
                      icon: Icons.school,
                    ),
                    _buildTextField(
                      'Semester',
                      _semesterController,
                      enabled: isEditing,
                      icon: Icons.calendar_today,
                    ),
                    _buildTextField(
                      'Mobile Number',
                      _mobileController,
                      enabled: isEditing,
                      icon: Icons.phone,
                    ),
                    _buildTextField(
                      'Email',
                      TextEditingController(text: userData['email'] ?? ''),
                      enabled: false,
                      icon: Icons.email,
                    ),

                    const SizedBox(height: 30),
                    if (isEditing)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: _updateProfile,
                          child: const Text(
                            'Save Changes',
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),

      // Add Bottom Navigation Bar
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    bool enabled = true,
    IconData? icon,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        enabled: enabled,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: enabled ? Colors.white : Colors.white54),
          prefixIcon: Icon(icon, color: Colors.white54),
          filled: true,
          fillColor: Colors.white10,
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide.none,
            borderRadius: BorderRadius.circular(12),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.blueAccent),
            borderRadius: BorderRadius.circular(12),
          ),
          disabledBorder: OutlineInputBorder(
            borderSide: BorderSide.none,
            borderRadius: BorderRadius.circular(12),
          ),
          errorBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.redAccent),
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'This field is required';
          }
          return null;
        },
      ),
    );
  }
}
