import 'package:flutter/material.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _hari = "";
  String _tanggal = "";
  String _jam = "";
  Timer? _timer;

  String _userLocation = "Memuat...";
  String _name = "Pengguna";

  String _suhu = "N/A";
  String _kelembapan = "N/A";
  String _curahHujan = "N/A";
  String _potensiBanjir = "Memuat...";
  String _potensiDBD = "Memuat...";
  String _dangerStatusText = "Memuat...";
  Color _dangerStatusColor = Colors.grey;
  Color _dangerStatusTextColor = Colors.white;
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

  String _getAndTranslateStatus(
    Map<dynamic, dynamic>? potensiBencanaData,
    String key,
  ) {
    final dynamic potensiData = potensiBencanaData?[key];
    String rawStatus = "N/A";

    if (potensiData is String) {
      rawStatus = potensiData;
    } else if (potensiData is Map) {
      rawStatus = potensiData['status'] as String? ?? "N/A";
    }

    switch (rawStatus.toLowerCase()) {
      case 'high':
        return 'Tinggi';
      case 'sedang':
      case 'mid':
        return 'Sedang';
      case 'low':
        return 'Rendah';
      case 'rendah':
        return 'Rendah';
      case 'tinggi':
        return 'Tinggi';
      default:
        return rawStatus;
    }
  }

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
        _initRealtimeDatabase();
      } else {
        setState(() {
          _userLocation = 'Lokasi Tidak Ditemukan';
        });
      }
    }
  }

  void _initRealtimeDatabase() {
    if (_userLocation != "Memuat..." &&
        _userLocation != "Lokasi Tidak Ditemukan") {
      _databaseRef = FirebaseDatabase.instance.ref(
        'lokasi_bencana/$_userLocation',
      );
      _dataSubscription?.cancel();
      _dataSubscription = _databaseRef?.onValue.listen((DatabaseEvent event) {
        final data = event.snapshot.value;
        if (data != null && data is Map) {
          final Map<dynamic, dynamic> locationData = Map.from(data);
          final newPotensiBanjir = _getAndTranslateStatus(
            locationData['potensi_bencana'] as Map<dynamic, dynamic>?,
            'banjir',
          );
          final newPotensiDBD = _getAndTranslateStatus(
            locationData['potensi_bencana'] as Map<dynamic, dynamic>?,
            'dbd',
          );
          setState(() {
            final sensorMap =
                locationData['sensor_data'] as Map<dynamic, dynamic>?;
            if (sensorMap != null) {
              final kelembapanValue =
                  (sensorMap['kelembapan'] as Map?)?['value'] as num?;
              _kelembapan =
                  '${(kelembapanValue?.toDouble() ?? 0.0).toStringAsFixed(1)} %';

              final suhuValue = (sensorMap['suhu'] as Map?)?['value'] as num?;
              _suhu = '${(suhuValue?.toDouble() ?? 0.0).toStringAsFixed(1)} °C';

              final curahHujanValue =
                  (sensorMap['curah_hujan'] as Map?)?['value'] as num?;
              _curahHujan =
                  '${(curahHujanValue?.toDouble() ?? 0.0).toStringAsFixed(1)} mm';
            }
            _potensiBanjir = newPotensiBanjir;
            _potensiDBD = newPotensiDBD;

            if (newPotensiBanjir.toLowerCase() == 'tinggi' ||
                newPotensiDBD.toLowerCase() == 'tinggi') {
              _dangerStatusText = "BAHAYA";
              _dangerStatusColor = const Color(0xffFF4C4C); // Merah
              _dangerStatusTextColor = const Color(0xff052659);
            } else {
              _dangerStatusText = "AMAN";
              _dangerStatusColor = Colors.white; // Putih
              _dangerStatusTextColor = const Color(0xff052659);
            }
          });
        } else {
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
    const hari = [
      "Senin",
      "Selasa",
      "Rabu",
      "Kamis",
      "Jumat",
      "Sabtu",
      "Minggu",
    ];
    return hari[weekday - 1];
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
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: SingleChildScrollView(
        child: Container(
          color: const Color(0xFFF5F5F5),
          padding: EdgeInsets.symmetric(
            horizontal: screenWidth * 0.05,
          ).copyWith(top: screenHeight * 0.05),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
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
                      const SizedBox(height: 4),
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
                                _name,
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
                              onBackgroundImageError: (exception, stackTrace) {
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
                height: screenHeight * 0.28,
                margin: const EdgeInsets.only(top: 5, bottom: 10),
                padding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.05,
                  vertical: screenHeight * 0.02,
                ),
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
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "$_userLocation | $_hari",
                              style: const TextStyle(
                                fontSize: 16,
                                fontFamily: 'DMSans',
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: screenHeight * 0.01),
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
                        Image(
                          image: const AssetImage('assets/images/weather.png'),
                          width: screenWidth * 0.2,
                          height: screenHeight * 0.1,
                        ),
                      ],
                    ),
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
                                color: Colors.white,
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
                        Container(
                          width: screenWidth * 0.25,
                          height: screenHeight * 0.05,
                          decoration: BoxDecoration(
                            color: _dangerStatusColor,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: Text(
                              _dangerStatusText,
                              style: TextStyle(
                                fontSize: 16,
                                fontFamily: 'DMSans',
                                fontWeight: FontWeight.w600,
                                color:_dangerStatusTextColor,
                              ),
                              textAlign: TextAlign.center,
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
              Align(
                alignment: Alignment.centerLeft,
                child: Row(
                  children: <Widget>[
                    Text(
                      "Apa itu",
                      style: TextStyle(
                        fontSize: screenWidth * 0.06,
                        fontFamily: 'DMSans',
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF000000),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    Text(
                      " DBD",
                      style: TextStyle(
                        fontSize: screenWidth * 0.06,
                        fontFamily: 'DMSans',
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF3530A2),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    Text(
                      "?",
                      style: TextStyle(
                        fontSize: screenWidth * 0.06,
                        fontFamily: 'DMSans',
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF000000),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                margin: const EdgeInsets.only(top: 8, bottom: 20),
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
                    const Expanded(
                      flex: 3,
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
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
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
      default:
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
