import 'package:flutter/material.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

// CATATAN: Pastikan Anda telah menambahkan semua paket ini di pubspec.yaml.

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Variabel state untuk menyimpan waktu saat ini
  String _hari = "";
  String _tanggal = "";
  String _jam = "";
  Timer? _timer;

  // Variabel state baru untuk data pengguna dari Firestore
  String _userLocation = "Memuat...";
  String _name = "Pengguna";

  // Variabel state untuk data Suhu dan Kelembapan dari Realtime Database
  String _suhu = "N/A";
  String _kelembapan = "N/A";
  String _curahHujan = "N/A";
  String _potensiBanjir = "Memuat...";
  String _potensiDBD = "Memuat...";

  // Variabel referensi database
  DatabaseReference? _databaseRef;
  StreamSubscription? _dataSubscription;

  @override
  void initState() {
    super.initState();
    _startRealtimeClock();
    _fetchUserData();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _dataSubscription?.cancel();
    super.dispose();
  }

  void _startRealtimeClock() {
    _updateDateTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateDateTime();
    });
  }

  void _updateDateTime() {
    final now = DateTime.now();
    setState(() {
      _hari = _getNamaHari(now.weekday);
      _tanggal = "${now.day} ${_getNamaBulan(now.month)} ${now.year}";
      _jam =
          "${now.hour.toString().padLeft(2, '0')}:"
          "${now.minute.toString().padLeft(2, '0')}:"
          "${now.second.toString().padLeft(2, '0')} WIB";
    });
  }
  // Fungsi untuk membaca dan menerjemahkan status potensi bencana
  String _getAndTranslateStatus(Map<dynamic, dynamic>? potensiBencanaData, String key) {
    final dynamic potensiData = potensiBencanaData?[key];
    String rawStatus = "N/A"; // Nilai default

    if (potensiData is String) {
      // Menangani kasus seperti: "dbd": "HIGH"
      rawStatus = potensiData;
    } else if (potensiData is Map) {
      // Menangani kasus seperti: "banjir": { "status": "Tinggi" }
      rawStatus = potensiData['status'] as String? ?? "N/A";
    }

    // Menerjemahkan status mentah ke format tampilan
    switch (rawStatus.toLowerCase()) {
      case 'high':
        return 'Tinggi';
      case 'sedang':
        return 'Sedang';
      case 'mid':
        return 'Sedang';
      case 'low':
        return 'Rendah';
      // Menjaga nilai yang sudah benar
      case 'rendah':
        return 'Rendah';
      case 'tinggi':
        return 'Tinggi';
      default:
        return rawStatus; // Kembalikan nilai asli jika tidak dikenali (misal: "N/A")
    }
  }
  // Fungsi untuk mengambil data pengguna dari Firestore
  Future<void> _fetchUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final docRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid);
      final docSnapshot = await docRef.get();

      if (docSnapshot.exists) {
        final data = docSnapshot.data()!;
        setState(() {
          _userLocation = data['address'] ?? 'Lokasi Tidak Ditemukan';
          _name = data['firstName'] ?? 'Pengguna';
        });

        // Panggil _initRealtimeDatabase() di sini, setelah lokasi tersedia.
        _initRealtimeDatabase();
      } else {
        setState(() {
          _userLocation = 'Lokasi Tidak Ditemukan';
        });
      }
    }
  }

  // Fungsi untuk inisialisasi dan mendengarkan data dari Realtime Database
  void _initRealtimeDatabase() {
  if (_userLocation != "Memuat..." && _userLocation != "Lokasi Tidak Ditemukan") {
    _databaseRef = FirebaseDatabase.instance.ref('lokasi_bencana/$_userLocation');

    _dataSubscription?.cancel();

    _dataSubscription = _databaseRef?.onValue.listen((DatabaseEvent event) {
      final data = event.snapshot.value;
      
      if (data != null && data is Map) {
        final Map<dynamic, dynamic> locationData = Map.from(data);
        
        setState(() {
          // Akses data sensor
          final sensorMap = locationData['sensor_data'] as Map<dynamic, dynamic>?;
          if (sensorMap != null) {
            final kelembapanValue = (sensorMap['kelembapan'] as Map?)?['value'] as num?;
            _kelembapan = '${(kelembapanValue?.toDouble() ?? 0.0).toStringAsFixed(1)} %';
            
            final suhuValue = (sensorMap['suhu'] as Map?)?['value'] as num?;
            _suhu = '${(suhuValue?.toDouble() ?? 0.0).toStringAsFixed(1)} °C';
            
            final curahHujanValue = (sensorMap['curah_hujan'] as Map?)?['value'] as num?;
            _curahHujan = '${(curahHujanValue?.toDouble() ?? 0.0).toStringAsFixed(1)} mm';
          }
          
          // Akses data potensi bencana
          // Akses data potensi bencana dengan fungsi baru
          final potensiMap = locationData['potensi_bencana'] as Map<dynamic, dynamic>?;
          _potensiBanjir = _getAndTranslateStatus(potensiMap, 'banjir');
          _potensiDBD = _getAndTranslateStatus(potensiMap, 'dbd');
        });
      } else {
        // Handle case where data is null
        setState(() {
          _suhu = "N/A";
          _kelembapan = "N/A";
          _curahHujan = "N/A";
          _potensiBanjir = "N/A";
          _potensiDBD = "N/A";
        });
      }
    });
  }
}

  String _getNamaHari(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return "Senin";
      case DateTime.tuesday:
        return "Selasa";
      case DateTime.wednesday:
        return "Rabu";
      case DateTime.thursday:
        return "Kamis";
      case DateTime.friday:
        return "Jumat";
      case DateTime.saturday:
        return "Sabtu";
      case DateTime.sunday:
        return "Minggu";
      default:
        return "";
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: const Color(0xFFF5F5F5),
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
                            _name,
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
            const SizedBox(height: 20),
            Row(
              children: <Widget>[
                const Text(
                  "Selamat Datang Kembali, ",
                  style: TextStyle(
                    fontSize: 16,
                    fontFamily: 'DMSans',
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF011023),
                  ),
                ),
                Text(
                  _name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontFamily: 'DMSans',
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0B39BF),
                  ),
                ),
              ],
            ),
            Container(
              height: 220,
              margin: const EdgeInsets.only(top: 5, bottom: 10),
              padding: const EdgeInsets.only(left: 20, right: 20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF13438C), Color(0xFF204164)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.5),
                    spreadRadius: 2,
                    blurRadius: 6,
                    offset: const Offset(3, 3),
                  ),
                ],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: <Widget>[
                  const SizedBox(height: 20),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "$_userLocation | $_hari",
                      style: const TextStyle(
                        fontSize: 16,
                        fontFamily: 'DMSans',
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Row(
                    children: <Widget>[
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            "Suhu             : $_suhu",
                            style: const TextStyle(
                              fontSize: 14,
                              fontFamily: 'DMSans',
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            "Kelembapan : $_kelembapan",
                            style: const TextStyle(
                              fontSize: 14,
                              fontFamily: 'DMSans',
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            "Curah Hujan : $_curahHujan",
                            style: const TextStyle(
                              fontSize: 14,
                              fontFamily: 'DMSans',
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 43),
                      const Image(
                        image: AssetImage('assets/images/weather.png'),
                        width: 100,
                        height: 100,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Divider(color: Color(0xFF5381B3), thickness: 1),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            _jam,
                            style: const TextStyle(
                              fontSize: 14,
                              fontFamily: 'DMSans',
                              fontWeight: FontWeight.w700,
                              color: Color.fromARGB(255, 255, 255, 255),
                            ),
                          ),
                          Text(
                            _hari,
                            style: const TextStyle(
                              fontSize: 14,
                              fontFamily: 'DMSans',
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 45),
                      const SizedBox(
                        height: 45,
                        width: 100,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.all(Radius.circular(10)),
                          ),
                          child: Center(
                            child: Text(
                              "AMAN",
                              style: TextStyle(
                                fontSize: 16,
                                fontFamily: 'DMSans',
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1D416C),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            PotensiCard(
              title: 'Potensi Terjadi Banjir',
              status: _potensiBanjir,
            ),
            PotensiCard(title: 'Potensi Terjadi DBD', status: _potensiDBD),
            const SizedBox(height: 7),
            const Align(
              alignment: Alignment.centerLeft,
              child: Row(
                children: <Widget>[
                  Text(
                    "Apa itu",
                    style: TextStyle(
                      fontSize: 24,
                      fontFamily: 'DMSans',
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF000000),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  Text(
                    " DBD",
                    style: TextStyle(
                      fontSize: 24,
                      fontFamily: 'DMSans',
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF3530A2),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  Text(
                    "?",
                    style: TextStyle(
                      fontSize: 24,
                      fontFamily: 'DMSans',
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF000000),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(15),
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
                children: <Widget>[
                  const SizedBox(
                    width: 180,
                    child: Text(
                      "DBD (Dengue Berdarah) atau demam berdarah dengue adalah penyakit yang disebabkan oleh virus dengue yang ditularkan melalui gigitan nyamuk Aedes aegypti atau Aedes albopictus yang terinfeksi.",
                      style: TextStyle(
                        fontSize: 13,
                        fontFamily: 'DMSans',
                        fontWeight: FontWeight.w200,
                        color: Color(0xff000000),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Transform.rotate(
                      angle: 25 * 3.1416 / 180,
                      child: Image.asset(
                        'assets/images/mosquito.png',
                        fit: BoxFit.contain,
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

class PotensiCard extends StatelessWidget {
  final String title;
  final String status;

  const PotensiCard({super.key, required this.title, required this.status});

  @override
  Widget build(BuildContext context) {
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
      case 'sedang':
        badgeBgColor = const Color(0xFFFFF4D1);
        badgeTextColor = const Color(0xFFC08D3B);
        break;
      default: // N/A, Memuat..., etc.
        badgeBgColor = Colors.grey[200]!;
        badgeTextColor = Colors.grey[700]!;
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

// Tambahkan WaveClipper di luar class _HomePageState
class WaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    path.lineTo(0, size.height - 50);
    var firstControlPoint = Offset(size.width / 4, size.height - 100);
    var firstEndPoint = Offset(size.width / 2, size.height - 50);
    path.quadraticBezierTo(
      firstControlPoint.dx,
      firstControlPoint.dy,
      firstEndPoint.dx,
      firstEndPoint.dy,
    );

    var secondControlPoint = Offset(size.width * 3 / 4, size.height);
    var secondEndPoint = Offset(size.width, size.height - 50);
    path.quadraticBezierTo(
      secondControlPoint.dx,
      secondControlPoint.dy,
      secondEndPoint.dx,
      secondEndPoint.dy,
    );

    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}