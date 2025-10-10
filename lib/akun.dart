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
  String _firstName = '';
  String _lastName = '';
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
      final docRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid);
      try {
        final doc = await docRef.get();
        final data = doc.data();

        if (doc.exists && data != null && data.isNotEmpty) {
          setState(() {
            _firstName = data['firstName'] ?? '';
            _lastName = data['lastName'] ?? '';
            _phoneNumber = data['phoneNumber'] ?? '';
            _address = data['address'] ?? '';
            _email = user.email ?? '';
          });
        } else {
          String? displayName = user.displayName;
          String fName = '';
          String lName = '';
          if (displayName != null && displayName.isNotEmpty) {
            final parts = displayName.split(' ');
            fName = parts.isNotEmpty ? parts.first : '';
            lName = parts.length > 1 ? parts.sublist(1).join(' ') : '';
          }

          await docRef.set({
            'firstName': fName,
            'lastName': lName,
            'phoneNumber': '',
            'address': '',
            'email': user.email ?? '',
          });
          setState(() {
            _firstName = fName;
            _lastName = lName;
            _phoneNumber = '';
            _address = '';
            _email = user.email ?? '';
          });
        }
      } catch (e) {
        print('Error loading user data: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Gagal memuat data pengguna.')),
          );
        }
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
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Container(
                color: const Color(0xffF5F5F5),
                padding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.05,
                ).copyWith(top: screenHeight * 0.05),
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
                            width: screenWidth * 0.45,
                            padding: EdgeInsets.only(left: 20),
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
                                Expanded(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Text(
                                        _firstName,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontFamily: 'DMSans',
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                        overflow: TextOverflow.ellipsis,
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
                                ),
                                const SizedBox(width: 8),
                                LayoutBuilder(
                                  builder: (
                                    BuildContext context,
                                    BoxConstraints constraints,
                                  ) {
                                    double radius =
                                        constraints.biggest.shortestSide / 2;

                                    return CircleAvatar(
                                      radius: radius,
                                      backgroundImage: const AssetImage(
                                        'assets/icons/user.png',
                                      ),
                                      onBackgroundImageError: (
                                        exception,
                                        stackTrace,
                                      ) {
                                        print(
                                          'Error loading image: $exception',
                                        );
                                      },
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 0.08 * screenHeight),
                      Container(
                        margin: EdgeInsets.only(
                          top: screenHeight * 0.04,
                        ), 
                        width: screenWidth * 0.4,
                        height: screenWidth * 0.4,
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
                              _firstName.isNotEmpty
                                  ? '$_firstName $_lastName'
                                  : (user?.displayName ?? "Fadiru"),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: screenWidth * 0.095, 
                                fontFamily: 'DMSans',
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF2800FF),
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(
                                vertical: screenHeight * 0.01, 
                                horizontal: screenWidth * 0.05,
                              ), 
                              margin: EdgeInsets.only(
                                top: screenHeight * 0.02,
                              ), 
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
                              child: Text(
                                "Warga Lokal",
                                style: TextStyle(
                                  fontSize: screenWidth * 0.05, 
                                  fontFamily: 'DMSans',
                                  fontWeight: FontWeight.w400,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(20),
                        margin: EdgeInsets.only(
                          top: screenHeight * 0.03,
                        ), 
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
                            _buildNonEditableStatusItem(
                              "Nama",
                              '$_firstName $_lastName',
                            ),
                            _buildNonEditableStatusItem("Email", _email),
                            _buildNonEditableStatusItem("No. Hp", _phoneNumber),
                            _buildNonEditableStatusItem(
                              "Tempat Tinggal",
                              _address,
                            ),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
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
                                    if (mounted) {
                                      Navigator.of(context).pushAndRemoveUntil(
                                        MaterialPageRoute(
                                          builder:
                                              (context) => const LoginPage(),
                                        ),
                                        (Route<dynamic> route) => false,
                                      );
                                    }
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
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w400,
                color: Color(0xff000000),
                fontFamily: 'DMSans',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
