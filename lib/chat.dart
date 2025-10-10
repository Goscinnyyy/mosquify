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
  String _firstName = '';
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
          });
        } else {
          String? displayName = user.displayName;
          String fName = '';
          if (displayName != null && displayName.isNotEmpty) {
            fName = displayName.split(' ').first;
          }
          await docRef.set({'firstName': fName});
          setState(() {
            _firstName = fName;
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
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Container(
                height: screenHeight,
                color: const Color(0xFFF5f5f5),
                padding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.05,
                ).copyWith(top: screenHeight * 0.05),
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
                                  const Text(
                                    "Pesisir Selatan",
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
                            children: <Widget>[
                              Expanded(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Text(
                                      _firstName,
                                      overflow: TextOverflow.ellipsis,
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
                              ),
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
                                      print('Error loading image: $exception');
                                    },
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Container(
                      width: screenWidth,
                      margin: EdgeInsets.only(top: screenHeight * 0.05),
                      padding: const EdgeInsets.only(left: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            "Hello,",
                            style: TextStyle(
                              fontFamily: 'OpenSans',
                              fontSize: screenWidth * 0.08,
                              fontWeight: FontWeight.w400,
                              color: const Color(0xff000000),
                            ),
                          ),
                          Text(
                            _firstName.isNotEmpty ? _firstName : "User",
                            style: TextStyle(
                              fontFamily: 'OpenSans',
                              fontSize: screenWidth * 0.1,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xff553AE3),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(), 
                    Container(
                      padding: const EdgeInsets.only(left: 10),
                      width: screenWidth,
                      child: const Text(
                        "Silahkan pilih topik yang kamu mau!",
                        style: TextStyle(
                          fontFamily: 'OpenSans',
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.only(top: 20, bottom: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          SizedBox(
                            width: screenWidth * 0.4,
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const ChatBotPage(),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: const Color(0xFF000000),
                                padding: EdgeInsets.symmetric(
                                  vertical: screenHeight * 0.02,
                                ),
                                elevation: 8,
                                shadowColor: Colors.black.withOpacity(0.05),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(50),
                                ),
                              ),
                              child: Column(
                                children: <Widget>[
                                  Image.asset(
                                    'assets/images/bot_big.png',
                                    width: screenWidth * 0.15,
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    "Chat dengan",
                                    style: TextStyle(
                                      fontFamily: 'OpenSans',
                                      fontSize: 12,
                                      fontWeight: FontWeight.w400,
                                      color: Color(0xFF000000),
                                    ),
                                  ),
                                  Text(
                                    "Chatbot",
                                    style: TextStyle(
                                      fontFamily: 'OpenSans',
                                      fontSize: screenWidth * 0.05,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xff052659),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(
                            width: screenWidth * 0.4,
                            child: ElevatedButton(
                              onPressed: () {},
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: const Color(0xFF000000),
                                padding: EdgeInsets.symmetric(
                                  vertical: screenHeight * 0.02,
                                ),
                                elevation: 8,
                                shadowColor: Colors.black.withOpacity(0.05),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(50),
                                ),
                              ),
                              child: Column(
                                children: <Widget>[
                                  Image.asset(
                                    'assets/images/nakes.png',
                                    width: screenWidth * 0.15,
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    "Chat dengan",
                                    style: TextStyle(
                                      fontFamily: 'OpenSans',
                                      fontSize: 12,
                                      fontWeight: FontWeight.w400,
                                      color: Color(0xFF000000),
                                    ),
                                  ),
                                  Text(
                                    "Nakes",
                                    style: TextStyle(
                                      fontFamily: 'OpenSans',
                                      fontSize: screenWidth * 0.05,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xff052659),
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
