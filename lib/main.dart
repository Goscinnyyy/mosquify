import 'package:flutter/material.dart';
import 'package:bugbusterss/home.dart';
import 'package:bugbusterss/chat/chat.dart';
import 'package:bugbusterss/akun.dart';
import 'package:bugbusterss/map/map.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MainPage(),
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

  final List<Widget> _pages = [HomePage(), ChatPage(), MapPage(), AkunPage()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Aksi saat tombol tengah ditekan
        },
        backgroundColor: Color(0xFF052659),
        shape: const CircleBorder(),
        elevation: 4,
        child: Image.asset(
          'assets/icons/icon_form.png', // path gambar kamu
          width: 32,
          height: 32,
          color: const Color(
            0xFF6E25FF,
          ), // kalau PNG transparan, warna bisa diubah
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        height: 70,
        // padding: EdgeInsets.only(bottom: ),
        shape: const CircularNotchedRectangle(),
        color: const Color(0xFF052659),
        notchMargin: 8.0,
        child: SizedBox(
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
    // Tentukan warna berdasarkan status
    Color badgeBgColor;
    Color badgeTextColor;

    switch (status.toLowerCase()) {
      case 'tinggi':
        badgeBgColor = const Color(0xFFFFE5E5); // Merah muda (background)
        badgeTextColor = const Color(0xFFD32F2F); // Merah teks
        break;
      case 'rendah':
        badgeBgColor = const Color(0xFFE0F7FA); // Biru muda (background)
        badgeTextColor = const Color(0xFF00796B); // Biru teks
        break;
      default: // sedang
        badgeBgColor = const Color(0xFFFFF4D1); // Kuning (background)
        badgeTextColor = const Color(0xFFC08D3B); // Kuning teks
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
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: badgeBgColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              status,
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
