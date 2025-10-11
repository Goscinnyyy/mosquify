import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'main.dart';

class MapDetailPage extends StatefulWidget {
  final String locationKey;

  const MapDetailPage({super.key, required this.locationKey});

  @override
  State<MapDetailPage> createState() => _MapDetailPageState();
}

class _MapDetailPageState extends State<MapDetailPage> {
  late final DatabaseReference _databaseRef;
  StreamSubscription<DatabaseEvent>? _dataSubscription;

  double _kekeruhanAir = 0.0;
  double _suhuAir = 0.0;
  double _kelembapan = 0.0;
  double _curahHujan = 0.0;
  double _ph = 0.0;
  double _suhu = 0.0;
  String _potensiBanjir = "Memuat...";
  String _potensiDBD = "Memuat...";
  String _jumlahPenderitaDBD = "Memuat...";
  String _lokasiNama = "Memuat...";

  String _firstName = '';
  String _hari = "";
  String _tanggal = "";
  String _jam = "";
  bool _isLoading = true;

  String _dangerStatusText = "Memuat...";
  Color _dangerStatusColor = Colors.grey;
  Color _dangerStatusTextColor = Colors.white;

  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _databaseRef = FirebaseDatabase.instance.ref(
      'lokasi_bencana/${widget.locationKey}',
    );
    _startListeningToData();
    _startRealtimeClock();
    _loadUserData();
  }

  @override
  void dispose() {
    _dataSubscription?.cancel();
    _timer?.cancel();
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
          "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')} WIB";
    });
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
      "Januari", "Februari", "Maret", "April", "Mei", "Juni", "Juli",
      "Agustus", "September", "Oktober", "November", "Desember",
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
            _firstName = data['firstName'] ?? '';
          });
        } else {
          String fName = '';
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

  String _getAndTranslateStatus(
      Map<dynamic, dynamic>? potensiBencanaData, String key) {
    final dynamic potensiData = potensiBencanaData?[key];
    String rawStatus = "Tidak ada data";

    if (potensiData is String) {
      rawStatus = potensiData;
    } else if (potensiData is Map) {
      rawStatus = potensiData['status'] as String? ?? "Tidak ada data";
    }

    switch (rawStatus.toLowerCase()) {
      case 'high':
      case 'tinggi':
        return 'Tinggi';
      case 'sedang':
      case 'mid':
        return 'Sedang';
      case 'low':
      case 'rendah':
        return 'Rendah';
      default:
        return rawStatus;
    }
  }

  Future<void> _fetchDbdCount(String lokasiNama) async {
    if (lokasiNama == "Lokasi" || lokasiNama == "Memuat...") {
      setState(() {
        _jumlahPenderitaDBD = "0";
      });
      return;
    }

    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('pengaduan_dbd')
          .where('alamat', isEqualTo: lokasiNama)
          .get();

      final count = querySnapshot.size;

      if (mounted) {
        setState(() {
          _jumlahPenderitaDBD = count.toString();
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error fetching DBD count from Firestore: $e");
      }
      if (mounted) {
        setState(() {
          _jumlahPenderitaDBD = "Error";
        });
      }
    }
  }

  void _startListeningToData() {
    _dataSubscription = _databaseRef.onValue.listen(
      (DatabaseEvent event) {
        final data = event.snapshot.value;
        if (data != null && data is Map) {
          final Map<dynamic, dynamic> locationData = Map.from(data).cast<dynamic, dynamic>();
          final sensorData = locationData['sensor_data'] as Map<dynamic, dynamic>?;
          final potensiBencanaData = locationData['potensi_bencana'] as Map<dynamic, dynamic>?;

          final newLokasiNama = locationData['nama']?.toString().replaceAll('"', '') ?? "Lokasi";
          final newPotensiBanjir =
              _getAndTranslateStatus(potensiBencanaData, 'banjir');
          final newPotensiDBD =
              _getAndTranslateStatus(potensiBencanaData, 'dbd');


          setState(() {
            _lokasiNama = newLokasiNama;
            _kekeruhanAir = (sensorData?['kekeruhan_air']?['value'] as num?)?.toDouble() ?? 0.0;
            _suhuAir = ((sensorData?['suhu_air']?['value'] as num?)?.toDouble() ?? 0.0) / 10.0;
            _ph = (sensorData?['ph']?['value'] as num?)?.toDouble() ?? 0.0;
            _curahHujan = (sensorData?['curah_hujan']?['value'] as num?)?.toDouble() ?? 0.0;
            _kelembapan = (sensorData?['kelembapan']?['value'] as num?)?.toDouble() ?? 0.0;
            _suhu = (sensorData?['suhu']?['value'] as num?)?.toDouble() ?? 0.0;
            _potensiBanjir = newPotensiBanjir;
            _potensiDBD = newPotensiDBD;

            if (newPotensiBanjir.toLowerCase() == 'tinggi' || newPotensiDBD.toLowerCase() == 'tinggi') {
              _dangerStatusText = "BAHAYA";
              _dangerStatusColor = const Color(0xffFF4C4C); // Merah
              _dangerStatusTextColor = const Color(0xff052659);
            } else {
              _dangerStatusText = "AMAN";
              _dangerStatusColor = Colors.white; // Putih
              _dangerStatusTextColor = const Color(0xff052659);
            }
          });
          _fetchDbdCount(newLokasiNama);
        }
      },
      onError: (error) {
        if (kDebugMode) {
          print("Gagal mengambil data dari Firebase: $error");
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: const Color(0xFF052659),
        padding: const EdgeInsets.only(top: 40, left: 20, right: 20),
        child: SingleChildScrollView(
          child: Column(
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: EdgeInsets.zero,
                      elevation: 0,
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: Image.asset(
                      'assets/icons/back.png',
                      width: 40,
                      height: 40,
                      color: Colors.white,
                    ),
                  ),
                  Container(
                    height: 60,
                    width: 160,
                    padding: const EdgeInsets.only(left: 20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFFFF),
                      borderRadius: BorderRadius.circular(35),
                    ),
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            "$_firstName \nWarga Lokal",
                            style: const TextStyle(
                              fontSize: 14,
                              fontFamily: 'DMSans',
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF052659),
                            ),
                          ),
                        ),
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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Text(
                        "Kabupaten Pesisir Selatan",
                        style: TextStyle(
                          fontSize: 15,
                          fontFamily: 'DMSans',
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      Row(
                        children: <Widget>[
                          Text(
                            _lokasiNama,
                            style: const TextStyle(
                              fontSize: 15,
                              fontFamily: 'DMSans',
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                          const Text(
                            " | ",
                            style: TextStyle(color: Colors.white),
                          ),
                          Text(
                            _hari,
                            style: const TextStyle(
                              fontSize: 15,
                              color: Colors.white,
                              fontFamily: 'DMSans',
                              fontWeight: FontWeight.w200,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: <Widget>[
                          Text(
                            _tanggal,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.white,
                              fontFamily: 'DMSans',
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          const Text(
                            " | ",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white,
                              fontFamily: 'DMSans',
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          Text(
                            _jam,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.white,
                              fontFamily: 'DMSans',
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _dangerStatusColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      _dangerStatusText,
                      style: TextStyle(
                        color: _dangerStatusTextColor,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'DMSans',
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  SensorCard(
                    title: "Kekeruhan Air",
                    unit: "NTU",
                    value: _kekeruhanAir,
                    imagePath: "assets/icons/kekeruhan_air.png",
                  ).buildWidget(),
                  SensorCard(
                    title: "Suhu Air",
                    unit: "°C",
                    value: _suhuAir,
                    imagePath: "assets/icons/kerapatan_air.png",
                  ).buildWidget(),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  SensorCard(
                    title: "pH Air",
                    unit: "",
                    value: _ph,
                    imagePath: "assets/icons/ph.png",
                  ).buildWidget(),
                  SensorCard(
                    title: "Curah Hujan",
                    unit: "mm",
                    value: _curahHujan,
                    imagePath: "assets/icons/curah_hujan.png",
                  ).buildWidget(),
                ],
              ),
              _buildDualSensorCard(
                label1: 'Suhu',
                value1: _suhu,
                unit1: '°C',
                label2: 'Kelembaban',
                value2: _kelembapan,
                unit2: '%',
              ),
              Column(
                children: [
                  PotensiCard(
                    title: 'Potensi Terjadi Banjir',
                    status: _potensiBanjir,
                  ).buildWidget(),
                  const SizedBox(height: 10),
                  PotensiCard(
                    title: 'Potensi Terjadi DBD',
                    status: _potensiDBD,
                  ).buildWidget(),
                  const SizedBox(height: 10),
                  PotensiCard(
                    title: 'Jumlah Penderita DBD',
                    status: _jumlahPenderitaDBD,
                  ).buildWidget(),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDualSensorCard({
    required String label1,
    required double value1,
    required String unit1,
    required String label2,
    required double value2,
    required String unit2,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 20),
      padding: const EdgeInsets.all(16),
      width: double.infinity,
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
        children: [
          _buildSensorInfoBlock(label1, value1, unit1),
          const SizedBox(width: 20),
          _buildSensorInfoBlock(label2, value2, unit2),
        ],
      ),
    );
  }
}

class SensorCard {
  final String title;
  final String unit;
  final double value;
  final String imagePath;

  SensorCard({
    required this.title,
    required this.unit,
    required this.value,
    required this.imagePath,
  });

  Widget buildWidget() {
    return Container(
      height: 110,
      width: 155,
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.only(top: 12, left: 12, right: 12),
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
      child: Stack(
        children: <Widget>[
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontFamily: 'DMSans',
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF052659),
                ),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    value.toStringAsFixed(1),
                    style: const TextStyle(
                      fontSize: 52,
                      fontFamily: "DMSans",
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF052659),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      unit,
                      style: const TextStyle(
                        fontSize: 14,
                        fontFamily: 'DMSans',
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF052659),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          Positioned(
            top: 0,
            left: 95,
            child: SizedBox(
              width: 25,
              height: 25,
              child: Image.asset(imagePath, fit: BoxFit.contain),
            ),
          ),
        ],
      ),
    );
  }
}

Widget _buildSensorInfoBlock(String label, double value, String unit) {
  return Expanded(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
              fontSize: 14,
              fontFamily: 'DMSans',
              color: Color(0xFF052659),
              fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              value.toStringAsFixed(1),
              style: const TextStyle(
                fontSize: 52,
                fontWeight: FontWeight.w600,
                fontFamily: 'DMSans',
                color: Color(0xFF052659),
              ),
            ),
            const SizedBox(width: 4),
            Text(
              unit,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                fontFamily: 'DMSans',
                color: Color(0xFF052659),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}