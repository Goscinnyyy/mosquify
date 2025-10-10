import 'package:bugbusterss/form.dart';
import 'package:flutter/material.dart';

// Import halaman
import 'package:bugbusterss/login.dart';
import 'package:bugbusterss/home.dart';
import 'package:bugbusterss/chat.dart';
import 'package:bugbusterss/akun.dart';
import 'package:bugbusterss/map.dart';

// Firebase
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
// import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      routes: {
        '/main': (context) => const MainPage(),
        '/home': (context) => const HomePage(),
        '/chat': (context) => const ChatPage(),
        '/akun': (context) => const AkunPage(),
        '/map': (context) => const MapPage(),
      },
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          if (snapshot.hasData) {
            return const MainPage(); // user sudah login
          }
          return const LoginPage(); // user belum login
        },
      ),
    );
  }
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const HomePage(),
    const ChatPage(),
    const MapPage(),
    const AkunPage()
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false, // Ditambahkan untuk mengatasi masalah keyboard
      body: _pages[_currentIndex],
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: aksi tombol tengah
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => const FormPage()),
        );
      },
        backgroundColor: const Color(0xFF052659),
        shape: const CircleBorder(),
        elevation: 4,
        child: Image.asset(
          'assets/icons/icon_form.png',
          width: 32,
          height: 32,
          color: const Color(0xFF6E25FF),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        height: 70,
        shape: const CircularNotchedRectangle(),
        color: const Color(0xFF052659),
        notchMargin: 8.0,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavIcon('assets/icons/home.png', 0),
            _buildNavIcon('assets/icons/message.png', 1),
            const SizedBox(width: 60),
            _buildNavIcon('assets/icons/maps.png', 2),
            _buildNavIcon('assets/icons/account.png', 3),
          ],
        ),
      ),
    );
  }

  Widget _buildNavIcon(String assetPath, int index) {
    final isActive = _currentIndex == index;
    return IconButton(
      icon: Image.asset(
        assetPath,
        width: 32,
        height: 32,
        color: isActive ? Colors.white : Colors.white.withOpacity(0.33),
      ),
      onPressed: () {
        setState(() {
          _currentIndex = index;
        });
      },
    );
  }
}

class PotensiCard {
  final String title;
  final String status;

  PotensiCard({required this.title, required this.status});

  Widget buildWidget() {
    Color badgeBgColor;
    Color badgeTextColor;

    switch (status.toLowerCase()) {
      case 'tinggi':
        badgeBgColor = const Color(0xFFFFE5E5);
        badgeTextColor = const Color(0xFFD32F2F);
        break;
      case 'rendah':
        badgeBgColor = const Color(0xFFE0F7FA);
        badgeTextColor = const Color(0xFF00796B);
        break;
      default: // sedang
        badgeBgColor = const Color(0xFFFFF4D1);
        badgeTextColor = const Color(0xFFC08D3B);
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontFamily: 'DMSans',
              fontWeight: FontWeight.w400,
              color: Color(0xFF011023),
            ),
          ),
          Container(
            width: 80,
            alignment: Alignment.center,
            height: 32,
            decoration: BoxDecoration(
              color: badgeBgColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              status,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontFamily: 'DMSans',
                fontWeight: FontWeight.w400,
                color: badgeTextColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}