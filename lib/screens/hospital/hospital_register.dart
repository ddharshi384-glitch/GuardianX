```dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:guardianx/screens/hospital/hospital_dashboard.dart';

class HospitalRegisterScreen extends StatefulWidget {
  const HospitalRegisterScreen({super.key});

  @override
  State<HospitalRegisterScreen> createState() =>
      _HospitalRegisterScreenState();
}

class _HospitalRegisterScreenState
    extends State<HospitalRegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final hospitalNameController = TextEditingController();
  final hospitalIdController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final phoneController = TextEditingController();
  final addressController = TextEditingController();
  final ambulanceController = TextEditingController();
  final bedsController = TextEditingController();
  final locationController = TextEditingController();

  String hospitalType = 'Government';
  bool isRegistering = false;
  bool obscurePassword = true;

  @override
  void dispose() {
    hospitalNameController.dispose();
    hospitalIdController.dispose();
    emailController.dispose();
    passwordController.dispose();
    phoneController.dispose();
    addressController.dispose();
    ambulanceController.dispose();
    bedsController.dispose();
    locationController.dispose();
    super.dispose();
  }

  Future<void> registerHospital() async {
    if (!_formKey.currentState!.validate()) return;
    if (isRegistering) return;

    setState(() => isRegistering = true);

    User? createdUser;

    try {
      final ambulanceCount =
          int.parse(ambulanceController.text.trim());
      final bedCount = int.parse(bedsController.text.trim());

      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text,
      );

      createdUser = credential.user;

      if (createdUser == null) {
        throw Exception('Hospital account could not be created.');
      }

      await FirebaseFirestore.instance
          .collection('hospitals')
          .doc(createdUser.uid)
          .set({
        'hospitalId': hospitalIdController.text.trim(),
        'hospitalName': hospitalNameController.text.trim(),
        'name': hospitalNameController.text.trim(),
        'email': emailController.text.trim(),
        'phone': phoneController.text.trim(),
        'address': addressController.text.trim(),
        'location': locationController.text.trim(),
        'hospitalType': hospitalType,
        'numberOfAmbulances': ambulanceCount,
        'beds': bedCount,
        'availableBeds': bedCount,
        'role': 'hospital',
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const HospitalDashboard(),
        ),
      );
    } on FirebaseAuthException catch (e) {
      // If Firestore saving failed after account creation,
      // keep the account so the hospital can sign in and retry.
      _showMessage(e.message ?? 'Firebase registration failed.');
    } catch (e) {
      _showMessage(
        'Registration failed. Check the entered details and Firebase setup.',
      );
      debugPrint('Hospital registration error: $e');
    } finally {
      if (mounted) {
        setState(() => isRegistering = false);
      }
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade800,
      ),
    );
  }

  Widget buildField(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool password = false,
    bool number = false,
    bool email = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: TextFormField(
        controller: controller,
        obscureText: password && obscurePassword,
        keyboardType: number
            ? TextInputType.number
            : email
                ? TextInputType.emailAddress
                : TextInputType.text,
        style: const TextStyle(color: Colors.white),
        validator: (value) {
          final text = value?.trim() ?? '';

          if (text.isEmpty) return '$label is required';

          if (email &&
              !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                  .hasMatch(text)) {
            return 'Enter a valid email address';
          }

          if (password && (value?.length ?? 0) < 6) {
            return 'Password must be at least 6 characters';
          }

          if (number && int.tryParse(text) == null) {
            return 'Enter a valid whole number';
          }

          if (number && int.parse(text) < 0) {
            return 'Number cannot be negative';
          }

          return null;
        },
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.red),
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white70),
          filled: true,
          fillColor: Colors.grey.shade900,
          suffixIcon: password
              ? IconButton(
                  icon: Icon(
                    obscurePassword
                        ? Icons.visibility
                        : Icons.visibility_off,
                    color: Colors.white70,
                  ),
                  onPressed: () {
                    setState(() {
                      obscurePassword = !obscurePassword;
                    });
                  },
                )
              : null,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(color: Colors.red),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(
              color: Colors.redAccent,
              width: 2,
            ),
          ),
          errorStyle: const TextStyle(color: Colors.orangeAccent),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF101010),
      appBar: AppBar(
        title: const Text('Hospital Registration'),
        centerTitle: true,
        backgroundColor: Colors.red.shade900,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const Icon(
                Icons.local_hospital,
                color: Colors.redAccent,
                size: 80,
              ),
              const SizedBox(height: 16),
              const Text(
                'Create Hospital Account',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 28),

              buildField(
                hospitalNameController,
                'Hospital Name',
                Icons.local_hospital,
              ),
              buildField(
                hospitalIdController,
                'Hospital ID',
                Icons.badge,
              ),
              buildField(
                emailController,
                'Email',
                Icons.email,
                email: true,
              ),
              buildField(
                passwordController,
                'Password',
                Icons.lock,
                password: true,
              ),
              buildField(
                phoneController,
                'Emergency Contact Number',
                Icons.phone,
              ),
              buildField(
                addressController,
                'Hospital Address',
                Icons.location_city,
              ),
              buildField(
                ambulanceController,
                'Available Ambulances',
                Icons.local_shipping,
                number: true,
              ),
              buildField(
                bedsController,
                'Available Beds',
                Icons.bed,
                number: true,
              ),
              buildField(
                locationController,
                'Hospital Location',
                Icons.location_on,
              ),

              const SizedBox(height: 4),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                decoration: BoxDecoration(
                  color: Colors.grey.shade900,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.red),
                ),
                child: DropdownButton<String>(
                  value: hospitalType,
                  dropdownColor: Colors.black,
                  isExpanded: true,
                  underline: const SizedBox(),
                  style: const TextStyle(color: Colors.white),
                  items: const [
                    DropdownMenuItem(
                      value: 'Government',
                      child: Text('Government Hospital'),
                    ),
                    DropdownMenuItem(
                      value: 'Private',
                      child: Text('Private Hospital'),
                    ),
                  ],
                  onChanged: isRegistering
                      ? null
                      : (value) {
                          if (value != null) {
                            setState(() => hospitalType = value);
                          }
                        },
                ),
              ),

              const SizedBox(height: 28),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  onPressed:
                      isRegistering ? null : registerHospital,
                  child: isRegistering
                      ? const CircularProgressIndicator(
                          color: Colors.white,
                        )
                      : const Text(
                          'REGISTER',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```
