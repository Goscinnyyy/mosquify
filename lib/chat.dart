import 'package:bugbusterss/chatbot.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  // Variabel untuk menyimpan data pengguna yang akan ditampilkan
  String _firstName = ''; // Changed: First name variable

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
            _firstName =
                data['firstName'] ??
                ''; // Changed: Get first name from Firestore
          });
        } else {
          // Jika dokumen tidak ada, buat dokumen baru dengan data awal.
          // Split user's displayName into first and last names if available.
          String? displayName = user.displayName;
          String fName = '';
          await docRef.set({
            'firstName': fName, // Changed: Save first name
          });
          setState(() {
            _firstName = fName; // Changed: Set first name
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
      body: Container(
        color: Color(0xFFF5f5f5),
        padding: const EdgeInsets.only(top: 40, left: 20, right: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
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
                          Text(
                            "Pesisir Selatan", // Menggunakan _userLocation
                            style: const TextStyle(
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
                      const Expanded(child: SizedBox()),
                      const CircleAvatar(
                        radius: 30,
                        backgroundImage: AssetImage('assets/icons/user.png'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Container(
              width: screenWidth,
              margin: EdgeInsets.only(top: 70),
              padding: EdgeInsets.only(left: 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    "Hello,",
                    style: TextStyle(
                      fontFamily: 'OpenSans',
                      fontSize: 32,
                      fontWeight: FontWeight.w400,
                      color: Color(0xff000000),
                    ),
                  ),
                  Text(
                    _firstName,
                    style: TextStyle(
                      fontFamily: 'OpenSans',
                      fontSize: 40,
                      fontWeight: FontWeight.w700,
                      color: Color(0xff553AE3),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 240),
            Container(
              padding: EdgeInsets.only(left: 10),
              width: screenWidth,
              child: Text(
                "Silahkan pilih topik yang kamu mau!",
                style: TextStyle(
                  fontFamily: 'OpenSans',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Container(
              margin: EdgeInsets.only(top: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  SizedBox(
                    // Kita gunakan SizedBox untuk mengatur lebar tombol
                    width: 0.43 * screenWidth,
                    child: ElevatedButton(
                      // Aksi yang dijalankan ketika tombol ditekan. WAJIB ADA.
                      onPressed: () {
                        // Tambahkan logika Anda di sini, misalnya:
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChatBotPage(),
                          ),
                        );
                      },

                      // Properti 'style' digunakan untuk menggantikan 'decoration' pada Container
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white, // Menggantikan color
                        foregroundColor: Color(
                          0xFF000000,
                        ), // Warna untuk splash effect & teks default
                        padding: EdgeInsets.all(20), // Menggantikan padding
                        elevation:
                            8, // Menggantikan BoxShadow untuk efek terangkat
                        shadowColor: Colors.black.withOpacity(
                          0.05,
                        ), // Warna bayangan
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            50,
                          ), // Menggantikan borderRadius
                        ),
                      ),

                      // 'child' dari Container dipindahkan langsung ke sini
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Center(
                            child: Image.asset(
                              'assets/images/bot_big.png',
                              width: 60,
                            ),
                          ),
                          SizedBox(height: 8), // Memberi sedikit jarak
                          Text(
                            "Chat dengan",
                            style: TextStyle(
                              fontFamily: 'OpenSans',
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              color: Color(0xFF000000),
                            ),
                          ),
                          Center(
                            child: Text(
                              "Chatbot",
                              style: TextStyle(
                                fontFamily: 'OpenSans',
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                color: Color(0xff052659),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(
                    // Kita gunakan SizedBox untuk mengatur lebar tombol
                    width: 0.43 * screenWidth,
                    child: ElevatedButton(
                      // Aksi yang dijalankan ketika tombol ditekan. WAJIB ADA.
                      onPressed: () {
                        // Tambahkan logika Anda di sini, misalnya:
                      },

                      // Properti 'style' digunakan untuk menggantikan 'decoration' pada Container
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white, // Menggantikan color
                        foregroundColor: Color(
                          0xFF000000,
                        ), // Warna untuk splash effect & teks default
                        padding: EdgeInsets.all(20), // Menggantikan padding
                        elevation:
                            8, // Menggantikan BoxShadow untuk efek terangkat
                        shadowColor: Colors.black.withOpacity(
                          0.05,
                        ), // Warna bayangan
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            50,
                          ), // Menggantikan borderRadius
                        ),
                      ),

                      // 'child' dari Container dipindahkan langsung ke sini
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Center(
                            child: Image.asset(
                              'assets/images/nakes.png',
                              width: 60,
                            ),
                          ),
                          SizedBox(height: 8), // Memberi sedikit jarak
                          Text(
                            "Chat dengan",
                            style: TextStyle(
                              fontFamily: 'OpenSans',
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              color: Color(0xFF000000),
                            ),
                          ),
                          Center(
                            child: Text(
                              "Nakes",
                              style: TextStyle(
                                fontFamily: 'OpenSans',
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                color: Color(0xff052659),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
