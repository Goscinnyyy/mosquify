import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'map_detail.dart';
import 'main.dart';

// Kelas untuk memodelkan data lokasi
class StatusArea {
  final String key;
  final String nama;
  final LatLng lokasi;
  final String status;
  final Map<dynamic, dynamic> sensorData;

  StatusArea({
    required this.key,
    required this.nama,
    required this.lokasi,
    required this.status,
    required this.sensorData,
  });
}

// Helper class untuk mengelola tampilan lingkaran dan label di peta
class StatusCircleLayer {
  final List<StatusArea> data;

  StatusCircleLayer(this.data);

  Color _getColor(String status) {
    switch (status.toLowerCase()) {
      case 'tinggi':
        return const Color(0xFFFFE5E5);
      case 'sedang':
        return const Color(0xFFFFF4D1);
      default:
        return const Color(0xFFE0F7FA);
    }
  }

  Color _getFontColor(String status) {
    switch (status.toLowerCase()) {
      case 'tinggi':
        return const Color(0xFFD32F2F);
      case 'sedang':
        return const Color(0xFFC08D3B);
      default:
        return const Color(0xFF00796B);
    }
  }

  CircleLayer buildCircles() {
    return CircleLayer(
      circles:
          data.map((item) {
            return CircleMarker(
              point: item.lokasi,
              color: _getColor(item.status).withOpacity(0.3),
              borderStrokeWidth: 2,
              borderColor: _getColor(item.status),
              radius: 45,
            );
          }).toList(),
    );
  }

  MarkerLayer buildLabels(BuildContext context) {
    return MarkerLayer(
      markers:
          data.map((item) {
            return Marker(
              point: item.lokasi,
              width: 80,
              height: 30,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  backgroundColor: _getColor(item.status),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () {
                  // Kirim kunci unik lokasi ke halaman detail
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => MapDetailPage(locationKey: item.key),
                    ),
                  );
                },
                child: Text(
                  item.status,
                  style: TextStyle(
                    fontSize: 12,
                    color: _getFontColor(item.status),
                  ),
                ),
              ),
            );
          }).toList(),
    );
  }
}

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final _database = FirebaseDatabase.instance.ref();
  late Stream<DatabaseEvent> _dataStream;
  String _tanggal = "";
  String _firstName = '';
  bool _isLoading = true;


  @override
  void initState() {
    super.initState();
    _dataStream = _database.child('lokasi_bencana').onValue;
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
    final center = LatLng(-1.574966, 100.900371);
    final double initialZoom = 8.7;
    final double maxZoom = 25;

    return Scaffold(
      body: Container(
        color: const Color(0xFFF5F5F5),
        child: StreamBuilder(
          stream: _dataStream,
          builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            final Map<dynamic, dynamic>? dataFromFirebase =
                snapshot.data?.snapshot.value as Map<dynamic, dynamic>?;

            if (dataFromFirebase == null || dataFromFirebase.isEmpty) {
              return const Center(
                child: Text('Tidak ada data lokasi yang tersedia.'),
              );
            }

            // =================================================================
            // === PERUBAHAN UTAMA ADA DI BLOK INI (DARI SINI...) ===
            // =================================================================
            final List<StatusArea> dataDaerah =
                dataFromFirebase.entries.map((entry) {
              final locationKey = entry.key;
              final Map<dynamic, dynamic>? item =
                  entry.value as Map<dynamic, dynamic>?;

              // Pengecekan null yang lebih aman
              String nama =
                  item?['nama']?.toString().replaceAll('"', '') ??
                      'Tidak Diketahui';
              
              // 1. Ambil status asli dari Firebase
              String firebaseStatus =
                  item?['potensi_bencana']?['dbd']?['status'] as String? ??
                      'Tidak ada data';
              
              // 2. Terjemahkan status
              String displayStatus;
              switch (firebaseStatus.toUpperCase()) {
                case 'HIGH':
                  displayStatus = 'Tinggi';
                  break;
                case 'MID':
                  displayStatus = 'Sedang';
                  break;
                case 'LOW':
                  displayStatus = 'Rendah';
                  break;
                default:
                  displayStatus = 'Tidak ada data';
              }

              double lat = (item?['lat'] as num?)?.toDouble() ?? 0.0;
              double long = (item?['long'] as num?)?.toDouble() ?? 0.0;
              Map<dynamic, dynamic> sensorData =
                  item?['sensor_data'] as Map<dynamic, dynamic>? ?? {};

              return StatusArea(
                key: locationKey,
                nama: nama,
                lokasi: LatLng(lat, long),
                status: displayStatus, // <-- Gunakan status yang sudah diterjemahkan
                sensorData: sensorData,
              );
            }).toList();
            // =================================================================
            // === (...SAMPAI SINI) ===
            // =================================================================

            final statusCircleLayer = StatusCircleLayer(dataDaerah);
            final int totalTinggi =
                dataDaerah
                    .where((item) => item.status.toLowerCase() == 'tinggi')
                    .length;
            final int totalSedang =
                dataDaerah
                    .where((item) => item.status.toLowerCase() == 'sedang')
                    .length;
            final int totalRendah =
                dataDaerah
                    .where((item) => item.status.toLowerCase() == 'rendah')
                    .length;
            return Container(
              width: double.infinity,
              padding: const EdgeInsets.only(left: 20, right: 20, top: 40),
              color: const Color(0xFFF5F5F5),
              child: Column(
                children: <Widget>[
                  // === HEADER ===
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Column(
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
                            style: TextStyle(
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
                            Expanded(child: Container()),
                            const CircleAvatar(
                              radius: 30,
                              backgroundImage: AssetImage(
                                'assets/icons/user.png',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  // === PETA ===
                  Container(
                    margin: const EdgeInsets.only(top: 20, bottom: 20),
                    height: 400,
                    child: FlutterMap(
                      options: MapOptions(
                        initialCenter: center,
                        initialZoom: initialZoom,
                        minZoom: initialZoom,
                        maxZoom: maxZoom,
                        interactionOptions: const InteractionOptions(
                          flags:
                              InteractiveFlag.pinchZoom |
                              InteractiveFlag.doubleTapZoom,
                        ),
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName:
                              'com.example.mosquify', // This is the correct package name
                        ),
                        statusCircleLayer.buildCircles(),
                        statusCircleLayer.buildLabels(context),
                      ],
                    ),
                  ),
                  Column(
                    children: <Widget>[
                      PotensiCard(
                        title: '$totalTinggi Daerah Berpotensi DBD',
                        status: "Tinggi",
                      ).buildWidget(),
                      PotensiCard(
                        title: '$totalSedang Daerah Berpotensi DBD',
                        status: "Sedang",
                      ).buildWidget(),
                      PotensiCard(
                        title: '$totalRendah Daerah Berpotensi DBD',
                        status: "Rendah",
                      ).buildWidget(),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}