import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login.dart';

class AkunPage extends StatefulWidget {
  const AkunPage({super.key});

  @override
  State<AkunPage> createState() => _AkunPageState();
}

class _AkunPageState extends State<AkunPage> {
  // Variabel untuk menyimpan data pengguna yang akan ditampilkan
  String _firstName = ''; // Changed: First name variable
  String _lastName = '';  // Added: Last name variable
  String _phoneNumber = '';
  String _address = '';
  String _email = '';

  String _tanggal = "";

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _startRealtimeClock();
    _loadUserData();
  }

  void _startRealtimeClock() {
    _updateDateTime();
  }

  void _updateDateTime() {
    final now = DateTime.now();
    setState(() {
      _tanggal = "${now.day} ${_getNamaBulan(now.month)} ${now.year}";
    });
  }

  String _getNamaBulan(int month) {
    const bulan = [
      "Januari",
      "Februari",
      "Maret",
      "April",
      "Mei",
      "Juni",
      "Juli",
      "Agustus",
      "September",
      "Oktober",
      "November",
      "Desember",
    ];
    return bulan[month - 1];
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final docRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
      
      try {
        final doc = await docRef.get();
        final data = doc.data();

        if (doc.exists && data != null && data.isNotEmpty) {
          setState(() {
            _firstName = data['firstName'] ?? ''; // Changed: Get first name from Firestore
            _lastName = data['lastName'] ?? ''; // Added: Get last name from Firestore
            _phoneNumber = data['phoneNumber'] ?? '';
            _address = data['address'] ?? '';
            _email = user.email ?? '';
          });
        } else {
          // Jika dokumen tidak ada, buat dokumen baru dengan data awal.
          // Split user's displayName into first and last names if available.
          String? displayName = user.displayName;
          String fName = '';
          String lName = '';
          if (displayName != null && displayName.isNotEmpty) {
            final parts = displayName.split(' ');
            fName = parts.isNotEmpty ? parts.first : '';
            lName = parts.length > 1 ? parts.sublist(1).join(' ') : '';
          }

          await docRef.set({
            'firstName': fName, // Changed: Save first name
            'lastName': lName, // Added: Save last name
            'phoneNumber': '',
            'address': '',
            'email': user.email ?? '',
          });
          setState(() {
            _firstName = fName; // Changed: Set first name
            _lastName = lName; // Added: Set last name
            _phoneNumber = '';
            _address = '';
            _email = user.email ?? '';
          });
        }
      } catch (e) {
        print('Error loading user data: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal memuat data pengguna.')),
        );
      }
    }
    
    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Container(
              color: const Color(0xffF5F5F5),
              padding: const EdgeInsets.only(top: 40, left: 20, right: 20),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            SizedBox(
                              height: 30,
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: <Widget>[
                                  Image.asset(
                                    'assets/icons/location.png',
                                    width: 20,
                                    height: 16,
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Pesisir Selatan',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontFamily: 'DMSans',
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF043F89),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              _tanggal,
                              style: const TextStyle(
                                fontSize: 16,
                                fontFamily: 'DMSans',
                                fontWeight: FontWeight.w300,
                                color: Color(0xFF011023),
                              ),
                            ),
                          ],
                        ),
                        Container(
                          height: 60,
                          width: 160,
                          padding: const EdgeInsets.only(left: 20),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF204166), Color(0xFF14438B)],
                              stops: [0.2, 1.0],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            borderRadius: BorderRadius.circular(35),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    // Combine first and last names for display
                                    _firstName,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontFamily: 'DMSans',
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    "Warga Lokal",
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontFamily: 'DMSans',
                                      fontWeight: FontWeight.w200,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                              Expanded(child: Container()),
                              CircleAvatar(
                                radius: 30,
                                backgroundImage: const AssetImage(
                                  'assets/icons/user.png',
                                ),
                                onBackgroundImageError: (exception, stackTrace) {
                                  print('Error loading image: $exception');
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Container(
                      margin: const EdgeInsets.only(top: 60),
                      width: 0.4 * screenWidth,
                      height: 0.4 * screenWidth,
                      child: Stack(
                        children: <Widget>[
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xff0A4EB7),
                                width: 4,
                              ),
                            ),
                            child: ClipOval(
                              child: Image.asset(
                                'assets/icons/user.png',
                                width: 120,
                                height: 120,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.only(top: 10),
                      child: Column(
                        children: <Widget>[
                          Text(
                            // Combine first and last names for the main display
                            _firstName.isNotEmpty ? '$_firstName $_lastName' : (user?.displayName ?? "Fadiru"),
                            style: const TextStyle(
                              fontSize: 40,
                              fontFamily: 'DMSans',
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF2800FF),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                vertical: 10, horizontal: 20),
                            margin: const EdgeInsets.only(top: 15),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              gradient: const LinearGradient(
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                                colors: [
                                  Color(0xFF6E25FF),
                                  Color(0xFF043F89),
                                ],
                              ),
                            ),
                            child: const Text(
                              "Warga Lokal",
                              style: TextStyle(
                                fontSize: 20,
                                fontFamily: 'DMSans',
                                fontWeight: FontWeight.w400,
                                color: Color.fromARGB(255, 255, 255, 255),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(20),
                      margin: const EdgeInsets.only(top: 30),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0xffffffff),
                            blurRadius: 6,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        children: <Widget>[
                          // Display first and last name separately or combined.
                          _buildNonEditableStatusItem("Nama", '$_firstName $_lastName'),
                          _buildNonEditableStatusItem("Email", _email),
                          _buildNonEditableStatusItem("No. Hp", _phoneNumber),
                          _buildNonEditableStatusItem("Tempat Tinggal", _address),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: <Widget>[
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 10,
                                    horizontal: 20,
                                  ),
                                  backgroundColor: const Color(0xff052659),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                onPressed: () async {
                                  await FirebaseAuth.instance.signOut();
                                  Navigator.of(context).pushAndRemoveUntil(
                                    MaterialPageRoute(
                                        builder: (context) => const LoginPage()),
                                    (Route<dynamic> route) => false,
                                  );
                                },
                                child: const Text(
                                  "LOG OUT",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontFamily: 'DMSans',
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  // Widget untuk menampilkan item data yang tidak dapat diedit
  Widget _buildNonEditableStatusItem(String title, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade300, width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w300,
              color: Color(0xff000000),
              fontFamily: 'DMSans',
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w400,
              color: Color(0xff000000),
              fontFamily: 'DMSans',
            ),
          ),
        ],
      ),
    );
  }
}