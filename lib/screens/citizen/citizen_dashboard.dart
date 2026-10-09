After copying the Citizen Dashboard code, follow these steps in order. We will update all the code first and test later.

Step 1: Save the file

Press Ctrl + S in VS Code.

Check that the file is saved as:

lib/screens/citizen_dashboard.dart

Step 2: Update Android permissions

Open this file in VS Code:

android/app/src/main/AndroidManifest.xml

This file is needed for the Citizen Dashboard to request GPS location permission.

Step 3: Send me the current code

Copy everything inside AndroidManifest.xml and paste it here. I’ll give you the correct updated code while preserving your existing settings.

Don't run the app yet. We'll finish the remaining code updates first, then test GuardianX step by step.

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HospitalDashboardScreen extends StatefulWidget {
  const HospitalDashboardScreen({super.key});

  @override
  State<HospitalDashboardScreen> createState() =>
      _HospitalDashboardScreenState();
}

class _HospitalDashboardScreenState
    extends State<HospitalDashboardScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String get _uid =>
      FirebaseAuth.instance.currentUser?.uid ?? '';

  Stream<DocumentSnapshot<Map<String, dynamic>>> get hospitalStream =>
      _db.collection('hospitals').doc(_uid).snapshots();

  Stream<QuerySnapshot<Map<String, dynamic>>> get emergencyStream =>
      _db
          .collection('emergencies')
          .where('status', isEqualTo: 'active')
          .snapshots();

  @override
  Widget build(BuildContext context) {
    if (_uid.isEmpty) {
      return const Scaffold(
        backgroundColor: Color(0xFF101010),
        body: Center(
          child: Text(
            'Please sign in to continue.',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF101010),
      appBar: AppBar(
        backgroundColor: const Color(0xFF171717),
        foregroundColor: Colors.white,
        title: const Text(
          'GuardianX Hospital',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();

              if (!context.mounted) return;

              Navigator.of(context).pushNamedAndRemoveUntil(
                '/',
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: hospitalStream,
        builder: (context, hospitalSnapshot) {
          if (hospitalSnapshot.hasError) {
            return _message(
              'Unable to load hospital details. Check Firebase permissions.',
            );
          }

          if (hospitalSnapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: Colors.redAccent,
              ),
            );
          }

          final hospitalData =
              hospitalSnapshot.data?.data() ?? {};

          final hospitalName =
              hospitalData['hospitalName']?.toString() ??
              hospitalData['name']?.toString() ??
              'Hospital';

          final beds = hospitalData['availableBeds'] ??
              hospitalData['beds'] ??
              0;

          final ambulanceCount =
              hospitalData['numberOfAmbulances'] ?? 0;

          return StreamBuilder<
              QuerySnapshot<Map<String, dynamic>>>(
            stream: emergencyStream,
            builder: (context, emergencySnapshot) {
              if (emergencySnapshot.hasError) {
                return _message(
                  'Unable to load emergency cases. Check Firestore rules.',
                );
              }

              final emergencyDocs =
                  emergencySnapshot.data?.docs ?? [];

              emergencyDocs.sort((a, b) {
                final aTime = a.data()['createdAt'];
                final bTime = b.data()['createdAt'];

                final aDate = aTime is Timestamp
                    ? aTime.toDate()
                    : DateTime.fromMillisecondsSinceEpoch(0);

                final bDate = bTime is Timestamp
                    ? bTime.toDate()
                    : DateTime.fromMillisecondsSinceEpoch(0);

                return bDate.compareTo(aDate);
              });

              return SingleChildScrollView(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome, $hospitalName',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 23,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Hospital Emergency Management',
                      style: TextStyle(
                        color: Colors.white60,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 22),

                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics:
                          const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.2,
                      children: [
                        _statCard(
                          'Active Emergencies',
                          emergencySnapshot.hasData
                              ? '${emergencyDocs.length}'
                              : '...',
                          Icons.emergency,
                          Colors.redAccent,
                        ),
                        _statCard(
                          'Bed Capacity',
                          '$beds',
                          Icons.bed,
                          Colors.lightBlueAccent,
                        ),
                        _statCard(
                          'Registered Ambulances',
                          '$ambulanceCount',
                          Icons.local_hospital,
                          Colors.orangeAccent,
                        ),
                        _statCard(
                          'Hospital Status',
                          'Online',
                          Icons.check_circle,
                          Colors.greenAccent,
                        ),
                      ],
                    ),

                    const SizedBox(height: 28),
                    const Text(
                      'Active Emergency Cases',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),

                    if (emergencySnapshot.connectionState ==
                            ConnectionState.waiting &&
                        !emergencySnapshot.hasData)
                      const Center(
                        child: CircularProgressIndicator(
                          color: Colors.redAccent,
                        ),
                      )
                    else if (emergencyDocs.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1B1B1B),
                          borderRadius:
                              BorderRadius.circular(14),
                        ),
                        child: const Column(
                          children: [
                            Icon(
                              Icons.check_circle_outline,
                              color: Colors.greenAccent,
                              size: 36,
                            ),
                            SizedBox(height: 10),
                            Text(
                              'No active emergencies',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      ...emergencyDocs.map((doc) {
                        final data = doc.data();

                        final citizenName =
                            data['citizenName']?.toString() ??
                            'Unknown Citizen';

                        final phone =
                            data['phone']?.toString() ?? '';

                        final address =
                            data['address']?.toString() ??
                            'Address unavailable';

                        final type =
                            data['type']?.toString() ?? 'SOS';

                        final latitude = data['latitude'];
                        final longitude = data['longitude'];

                        final hasLocation =
                            latitude is num &&
                            longitude is num;

                        return Container(
                          margin:
                              const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1B1B1B),
                            borderRadius:
                                BorderRadius.circular(14),
                            border: Border.all(
                              color: Colors.redAccent
                                  .withValues(alpha: 0.5),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.warning_amber_rounded,
                                    color: Colors.redAccent,
                                    size: 28,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      type,
                                      style: const TextStyle(
                                        color: Colors.redAccent,
                                        fontWeight:
                                            FontWeight.bold,
                                        fontSize: 17,
                                      ),
                                    ),
                                  ),
                                  const Text(
                                    'ACTIVE',
                                    style: TextStyle(
                                      color: Colors.orangeAccent,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              _detail('Citizen', citizenName),
                              _detail('Phone', phone),
                              _detail('Address', address),
                              if (hasLocation)
                                _detail(
                                  'GPS',
                                  '${latitude.toString()}, '
                                  '${longitude.toString()}',
                                )
                              else
                                _detail(
                                  'GPS',
                                  'Location unavailable',
                                ),
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        Colors.green.shade800,
                                    foregroundColor: Colors.white,
                                  ),
                                  icon: const Icon(
                                    Icons.check_circle_outline,
                                  ),
                                  label: const Text(
                                    'Mark as Resolved',
                                  ),
                                  onPressed: () =>
                                      _resolveEmergency(
                                    doc.reference,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _resolveEmergency(
    DocumentReference<Map<String, dynamic>> reference,
  ) async {
    try {
      await reference.update({
        'status': 'resolved',
        'resolvedAt': FieldValue.serverTimestamp(),
        'resolvedBy': _uid,
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Emergency marked as resolved.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      debugPrint('Resolve emergency error: $e');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Could not update the emergency. Check Firebase rules.',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _statCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFF1B1B1B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 30),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 23,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _detail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Text(
        '$label: ${value.isEmpty ? "Not provided" : value}',
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _message(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 15,
          ),
        ),
      ),
    );
  }
}


This code is for the Hospital Dashboard, not the Citizen Dashboard. It looks mostly correct, so you don't need to copy it again.

What to do next

Save this code as lib/screens/hospital_dashboard_screen.dart using Ctrl + S.

Keep your Citizen Dashboard in its separate file: lib/screens/citizen_dashboard.dart.

Next, we need to connect the hospital registration and login flow to this dashboard.

Please send me your hospital registration code file (the file that contains HospitalRegisterScreen). I’ll update that code to match this dashboard and your Firebase structure.

give citizen code

Here is the complete Citizen Dashboard code for GuardianX. It includes the black-and-red UI, citizen information, emergency contacts, GPS location, and SOS activation by triple-tapping.

Open lib/screens/citizen_dashboard.dart, delete the old code, and paste this entire code.


import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';

class CitizenDashboard extends StatefulWidget {
  const CitizenDashboard({super.key});

  @override
  State<CitizenDashboard> createState() =>
      _CitizenDashboardState();
}

class _CitizenDashboardState extends State<CitizenDashboard> {
  Map<String, dynamic> citizenData = {};

  bool isLoading = true;
  bool isSendingSOS = false;

  int tapCount = 0;
  DateTime? lastTapTime;

  @override
  void initState() {
    super.initState();
    loadCitizenData();
  }

  Future<void> loadCitizenData() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      if (mounted) setState(() => isLoading = false);
      return;
    }

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (snapshot.exists) {
        final data = snapshot.data() ?? {};

        if (data['role']?.toString().toLowerCase() ==
            'citizen') {
          citizenData = data;
        }
      }
    } catch (e) {
      debugPrint('Citizen profile error: $e');
    }

    if (mounted) {
      setState(() => isLoading = false);
    }
  }

  void handleSOSTap() {
    if (isSendingSOS) return;

    final now = DateTime.now();

    if (lastTapTime == null ||
        now.difference(lastTapTime!) >
            const Duration(milliseconds: 1500)) {
      tapCount = 0;
    }

    lastTapTime = now;
    tapCount++;

    if (tapCount >= 3) {
      tapCount = 0;
      lastTapTime = null;
      sendEmergencySOS();
    }
  }

  Future<Position?> getCitizenLocation() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        return null;
      }

      LocationPermission permission =
          await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }

      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
    } catch (e) {
      debugPrint('GPS error: $e');
      return null;
    }
  }

  Future<void> sendEmergencySOS() async {
    if (isSendingSOS) return;

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      showMessage('Please log in first.');
      return;
    }

    if (citizenData['role']?.toString().toLowerCase() !=
        'citizen') {
      showMessage('Citizen profile not found. Check registration.');
      return;
    }

    setState(() => isSendingSOS = true);

    try {
      final position = await getCitizenLocation();

      await FirebaseFirestore.instance
          .collection('emergencies')
          .add({
        'citizenId': user.uid,
        'citizenName':
            citizenData['fullName'] ?? 'Unknown Citizen',
        'phone': citizenData['phone'] ?? '',
        'email': citizenData['email'] ?? user.email ?? '',
        'address': citizenData['address'] ?? '',
        'bloodGroup': citizenData['bloodGroup'] ?? '',
        'emergencyContact1':
            citizenData['emergencyContact1'] ?? '',
        'emergencyContact2':
            citizenData['emergencyContact2'] ?? '',
        'type': 'SOS',
        'status': 'active',
        'createdAt': FieldValue.serverTimestamp(),
        'latitude': position?.latitude,
        'longitude': position?.longitude,
        'locationStatus':
            position == null ? 'unavailable' : 'available',
        'source': 'citizen_triple_tap',
      });

      if (!mounted) return;

      showMessage(
        position == null
            ? 'SOS saved. GPS location is unavailable.'
            : 'Emergency SOS sent with GPS location.',
      );
    } catch (e) {
      debugPrint('SOS error: $e');

      if (mounted) {
        showMessage('Unable to send SOS. Please try again.');
      }
    } finally {
      if (mounted) {
        setState(() => isSendingSOS = false);
      }
    }
  }

  void showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade800,
      ),
    );
  }

  Widget infoCard(
    String title,
    String value,
    IconData icon,
  ) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1B1B1B),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.redAccent, size: 26),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  value.isEmpty ? 'Not provided' : value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF101010),
      appBar: AppBar(
        backgroundColor: const Color(0xFF171717),
        foregroundColor: Colors.white,
        title: const Text(
          'GuardianX',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();

              if (!context.mounted) return;

              Navigator.of(context).pushNamedAndRemoveUntil(
                '/',
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Colors.redAccent,
              ),
            )
          : citizenData.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'Citizen profile not found.\n'
                      'Please check your registration and role.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Welcome back,',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        citizenData['fullName']?.toString() ??
                            'Citizen',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Triple-tap SOS area.
                      GestureDetector(
                        onTap: handleSOSTap,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            vertical: 28,
                            horizontal: 20,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red.shade900,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.redAccent,
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.red.withValues(
                                  alpha: 0.2,
                                ),
                                blurRadius: 18,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Icon(
                                isSendingSOS
                                    ? Icons.hourglass_top
                                    : Icons.sos,
                                color: Colors.white,
                                size: 58,
                              ),
                              const SizedBox(height: 10),
                              Text(
                                isSendingSOS
                                    ? 'SENDING SOS...'
                                    : 'TRIPLE-TAP FOR SOS',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 21,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Tap this area 3 times quickly',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 28),
                      const Text(
                        'My Information',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 14),

                      infoCard(
                        'Full Name',
                        citizenData['fullName']?.toString() ?? '',
                        Icons.person,
                      ),
                      infoCard(
                        'Phone Number',
                        citizenData['phone']?.toString() ?? '',
                        Icons.phone,
                      ),
                      infoCard(
                        'Email',
                        citizenData['email']?.toString() ??
                            FirebaseAuth.instance.currentUser?.email ??
                            '',
                        Icons.email,
                      ),
                      infoCard(
                        'Address',
                        citizenData['address']?.toString() ?? '',
                        Icons.location_on,
                      ),
                      infoCard(
                        'Blood Group',
                        citizenData['bloodGroup']?.toString() ?? '',
                        Icons.bloodtype,
                      ),

                      const SizedBox(height: 16),
                      const Text(
                        'Emergency Contacts',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 14),

                      infoCard(
                        'Emergency Contact 1',
                        citizenData['emergencyContact1']
                                ?.toString() ??
                            '',
                        Icons.contact_phone,
                      ),
                      infoCard(
                        'Emergency Contact 2',
                        citizenData['emergencyContact2']
                                ?.toString() ??
                            '',
                        Icons.contact_phone,
                      ),
                    ],
                  ),
                ),
    );
  }
}
After copying

Save the file using Ctrl + S.

Keep the Hospital Dashboard code in its own separate file.

Next, send me the contents of android/app/src/main/AndroidManifest.xml so I can check the GPS permissions.

Note: This code writes SOS records to Firebase and requests GPS access. It does not itself place phone calls or send push notifications to police or hospitals. We’ll connect and verify those parts separately.
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';

class CitizenDashboard extends StatefulWidget {
  const CitizenDashboard({super.key});

  @override
  State<CitizenDashboard> createState() =>
      _CitizenDashboardState();
}

class _CitizenDashboardState extends State<CitizenDashboard> {
  Map<String, dynamic> citizenData = {};

  bool isLoading = true;
  bool isSendingSOS = false;

  int tapCount = 0;
  DateTime? lastTapTime;

  @override
  void initState() {
    super.initState();
    loadCitizenData();
  }

  Future<void> loadCitizenData() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      if (mounted) setState(() => isLoading = false);
      return;
    }

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (snapshot.exists) {
        final data = snapshot.data() ?? {};

        if (data['role']?.toString().toLowerCase() ==
            'citizen') {
          citizenData = data;
        }
      }
    } catch (e) {
      debugPrint('Citizen profile error: $e');
    }

    if (mounted) {
      setState(() => isLoading = false);
    }
  }

  void handleSOSTap() {
    if (isSendingSOS) return;

    final now = DateTime.now();

    if (lastTapTime == null ||
        now.difference(lastTapTime!) >
            const Duration(milliseconds: 1500)) {
      tapCount = 0;
    }

    lastTapTime = now;
    tapCount++;

    if (tapCount >= 3) {
      tapCount = 0;
      lastTapTime = null;
      sendEmergencySOS();
    }
  }

  Future<Position?> getCitizenLocation() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        return null;
      }

      LocationPermission permission =
          await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }

      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
    } catch (e) {
      debugPrint('GPS error: $e');
      return null;
    }
  }

  Future<void> sendEmergencySOS() async {
    if (isSendingSOS) return;

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      showMessage('Please log in first.');
      return;
    }

    if (citizenData['role']?.toString().toLowerCase() !=
        'citizen') {
      showMessage('Citizen profile not found. Check registration.');
      return;
    }

    setState(() => isSendingSOS = true);

    try {
      final position = await getCitizenLocation();

      await FirebaseFirestore.instance
          .collection('emergencies')
          .add({
        'citizenId': user.uid,
        'citizenName':
            citizenData['fullName'] ?? 'Unknown Citizen',
        'phone': citizenData['phone'] ?? '',
        'email': citizenData['email'] ?? user.email ?? '',
        'address': citizenData['address'] ?? '',
        'bloodGroup': citizenData['bloodGroup'] ?? '',
        'emergencyContact1':
            citizenData['emergencyContact1'] ?? '',
        'emergencyContact2':
            citizenData['emergencyContact2'] ?? '',
        'type': 'SOS',
        'status': 'active',
        'createdAt': FieldValue.serverTimestamp(),
        'latitude': position?.latitude,
        'longitude': position?.longitude,
        'locationStatus':
            position == null ? 'unavailable' : 'available',
        'source': 'citizen_triple_tap',
      });

      if (!mounted) return;

      showMessage(
        position == null
            ? 'SOS saved. GPS location is unavailable.'
            : 'Emergency SOS sent with GPS location.',
      );
    } catch (e) {
      debugPrint('SOS error: $e');

      if (mounted) {
        showMessage('Unable to send SOS. Please try again.');
      }
    } finally {
      if (mounted) {
        setState(() => isSendingSOS = false);
      }
    }
  }

  void showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade800,
      ),
    );
  }

  Widget infoCard(
    String title,
    String value,
    IconData icon,
  ) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1B1B1B),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.redAccent, size: 26),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  value.isEmpty ? 'Not provided' : value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF101010),
      appBar: AppBar(
        backgroundColor: const Color(0xFF171717),
        foregroundColor: Colors.white,
        title: const Text(
          'GuardianX',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();

              if (!context.mounted) return;

              Navigator.of(context).pushNamedAndRemoveUntil(
                '/',
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Colors.redAccent,
              ),
            )
          : citizenData.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'Citizen profile not found.\n'
                      'Please check your registration and role.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Welcome back,',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        citizenData['fullName']?.toString() ??
                            'Citizen',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Triple-tap SOS area.
                      GestureDetector(
                        onTap: handleSOSTap,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            vertical: 28,
                            horizontal: 20,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red.shade900,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.redAccent,
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.red.withValues(
                                  alpha: 0.2,
                                ),
                                blurRadius: 18,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Icon(
                                isSendingSOS
                                    ? Icons.hourglass_top
                                    : Icons.sos,
                                color: Colors.white,
                                size: 58,
                              ),
                              const SizedBox(height: 10),
                              Text(
                                isSendingSOS
                                    ? 'SENDING SOS...'
                                    : 'TRIPLE-TAP FOR SOS',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 21,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Tap this area 3 times quickly',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 28),
                      const Text(
                        'My Information',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 14),

                      infoCard(
                        'Full Name',
                        citizenData['fullName']?.toString() ?? '',
                        Icons.person,
                      ),
                      infoCard(
                        'Phone Number',
                        citizenData['phone']?.toString() ?? '',
                        Icons.phone,
                      ),
                      infoCard(
                        'Email',
                        citizenData['email']?.toString() ??
                            FirebaseAuth.instance.currentUser?.email ??
                            '',
                        Icons.email,
                      ),
                      infoCard(
                        'Address',
                        citizenData['address']?.toString() ?? '',
                        Icons.location_on,
                      ),
                      infoCard(
                        'Blood Group',
                        citizenData['bloodGroup']?.toString() ?? '',
                        Icons.bloodtype,
                      ),

                      const SizedBox(height: 16),
                      const Text(
                        'Emergency Contacts',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 14),

                      infoCard(
                        'Emergency Contact 1',
                        citizenData['emergencyContact1']
                                ?.toString() ??
                            '',
                        Icons.contact_phone,
                      ),
                      infoCard(
                        'Emergency Contact 2',
                        citizenData['emergencyContact2']
                                ?.toString() ??
                            '',
                        Icons.contact_phone,
                      ),
                    ],
                  ),
                ),
    );
  }
}