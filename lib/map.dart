import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'map_detail.dart';
import 'main.dart';

class StatusArea {
  final String key;
  final String nama;
  final LatLng lokasi;
  final String status;
  final int jumlahPenderita;
  final Map<dynamic, dynamic> sensorData;

  StatusArea({
    required this.key,
    required this.nama,
    required this.lokasi,
    required this.status,
    required this.jumlahPenderita,
    required this.sensorData,
  });
}

class StatusCircleLayer {
  final List<StatusArea> data;
  StatusCircleLayer(this.data);

  Color _getBackgroundColor(String status) {
    switch (status.toLowerCase()) {
      case 'tinggi':
        return const Color(0xFFFFE5E5);
      case 'sedang':
        return const Color(0xFFFFF4D1);
      default:
        return const Color(0xFFE0F7FA);
    }
  }

  Color _getForegroundColor(String status) {
    switch (status.toLowerCase()) {
      case 'tinggi':
        return const Color(0xFFD32F2F);
      case 'sedang':
        return const Color(0xFFC08D3B);
      default:
        return const Color(0xFF00796B);
    }
  }

  MarkerLayer buildMarkers(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final markerSize = screenWidth * 0.2;

    return MarkerLayer(
      markers: data.map((item) {
        final backgroundColor = _getBackgroundColor(item.status);
        final foregroundColor = _getForegroundColor(item.status);
        return Marker(
          point: item.lokasi,
          width: markerSize,
          height: markerSize,
          child: GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => MapDetailPage(locationKey: item.key)),
              );
            },
            child: Container(
              decoration: BoxDecoration(
                  color: backgroundColor.withOpacity(0.9),
                  shape: BoxShape.circle,
                  border: Border.all(color: foregroundColor, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 3,
                    )
                  ]),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      item.status,
                      style: TextStyle(
                        color: foregroundColor,
                        fontWeight: FontWeight.bold,
                        fontSize: markerSize * 0.25,
                        height: 1.1,
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(Icons.person,
                            color: foregroundColor, size: markerSize * 0.22),
                        const SizedBox(width: 4),
                        Text(
                          item.jumlahPenderita.toString(),
                          style: TextStyle(
                              color: foregroundColor,
                              fontSize: markerSize * 0.22),
                        ),
                      ],
                    )
                  ],
                ),
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

  @override
  void initState() {
    super.initState();
    _dataStream = _database.child('lokasi_bencana').onValue;
    _startRealtimeClock();
    _loadUserData();
  }

  Future<List<StatusArea>> _fetchDataWithCounts(
      Map<dynamic, dynamic> rtdbData) async {
    final initialLocations = rtdbData.entries.map((entry) {
      final item = entry.value as Map<dynamic, dynamic>?;
      String firebaseStatus =
          item?['potensi_bencana']?['dbd']?['status'] as String? ??
              'Tidak ada data';
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
      return StatusArea(
        key: entry.key,
        nama: item?['nama']?.toString().replaceAll('"', '') ?? 'Tidak Diketahui',
        lokasi: LatLng((item?['lat'] as num?)?.toDouble() ?? 0.0,
            (item?['long'] as num?)?.toDouble() ?? 0.0),
        status: displayStatus,
        jumlahPenderita: 0,
        sensorData: item?['sensor_data'] as Map<dynamic, dynamic>? ?? {},
      );
    }).toList();

    final List<Future<int>> countFutures = initialLocations.map((location) {
      return FirebaseFirestore.instance
          .collection('pengaduan_dbd')
          .where('alamat', isEqualTo: location.nama)
          .get()
          .then((snapshot) => snapshot.size);
    }).toList();

    final List<int> counts = await Future.wait(countFutures);

    final List<StatusArea> finalLocations = [];
    for (int i = 0; i < initialLocations.length; i++) {
      final location = initialLocations[i];
      final count = counts[i];
      finalLocations.add(StatusArea(
        key: location.key,
        nama: location.nama,
        lokasi: location.lokasi,
        status: location.status,
        sensorData: location.sensorData,
        jumlahPenderita: count,
      ));
    }

    return finalLocations;
  }

  Widget _buildMapUI(List<StatusArea> dataDaerah) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final statusCircleLayer = StatusCircleLayer(dataDaerah);
    final int totalTinggi = dataDaerah.where((item) => item.status.toLowerCase() == 'tinggi').length;
    final int totalSedang = dataDaerah.where((item) => item.status.toLowerCase() == 'sedang').length;
    final int totalRendah = dataDaerah.where((item) => item.status.toLowerCase() == 'rendah').length;

    return SingleChildScrollView(
      child: Container(
        height: screenHeight,
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05)
            .copyWith(top: screenHeight * 0.05),
        color: const Color(0xFFF5F5F5),
        child: Column(
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
                        Image.asset('assets/icons/location.png',
                            width: 20, height: 16),
                        const SizedBox(width: 8),
                        const Text('Pesisir Selatan',
                            style: TextStyle(
                                fontSize: 16,
                                fontFamily: 'DMSans',
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF043F89))),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(_tanggal,
                        style: const TextStyle(
                            fontSize: 16,
                            fontFamily: 'DMSans',
                            fontWeight: FontWeight.w300,
                            color: Color(0xFF011023))),
                  ],
                ),
                Container(
                  height: 60,
                  width: screenWidth * 0.45,
                  padding: const EdgeInsets.only(left: 20, right: 8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [Color(0xFF204166), Color(0xFF14438B)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight),
                    borderRadius: BorderRadius.circular(35),
                  ),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(_firstName,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontSize: 16,
                                    fontFamily: 'DMSans',
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white)),
                            const SizedBox(height: 4),
                            const Text("Warga Lokal",
                                style: TextStyle(
                                    fontSize: 12,
                                    fontFamily: 'DMSans',
                                    fontWeight: FontWeight.w200,
                                    color: Colors.white)),
                          ],
                        ),
                      ),
                      const CircleAvatar(
                          radius: 22,
                          backgroundImage: AssetImage('assets/icons/user.png')),
                    ],
                  ),
                ),
              ],
            ),
            Container(
              margin: EdgeInsets.symmetric(vertical: screenHeight * 0.025),
              height: screenHeight * 0.45,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: FlutterMap(
                  options: const MapOptions(
                    initialCenter: LatLng(-1.574966, 100.900371),
                    initialZoom: 8.7,
                    minZoom: 8.7,
                    maxZoom: 25,
                    interactionOptions: InteractionOptions(
                        flags: InteractiveFlag.pinchZoom |
                            InteractiveFlag.doubleTapZoom),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.mosquify',
                    ),
                    statusCircleLayer.buildMarkers(context),
                  ],
                ),
              ),
            ),
            Column(
              children: <Widget>[
                PotensiCard(
                        title: '$totalTinggi Daerah Berpotensi DBD',
                        status: "Tinggi")
                    .buildWidget(),
                PotensiCard(
                        title: '$totalSedang Daerah Berpotensi DBD',
                        status: "Sedang")
                    .buildWidget(),
                PotensiCard(
                        title: '$totalRendah Daerah Berpotensi DBD',
                        status: "Rendah")
                    .buildWidget(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                  child: Text('Tidak ada data lokasi yang tersedia.'));
            }

            return FutureBuilder<List<StatusArea>>(
              future: _fetchDataWithCounts(dataFromFirebase),
              builder:
                  (context, AsyncSnapshot<List<StatusArea>> countSnapshot) {
                if (countSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: Text("Menghitung laporan..."));
                }
                if (countSnapshot.hasError) {
                  return Center(
                      child: Text(
                          'Gagal menghitung laporan: ${countSnapshot.error}'));
                }
                if (!countSnapshot.hasData || countSnapshot.data!.isEmpty) {
                  return const Center(child: Text('Data lengkap tidak tersedia.'));
                }
                final dataDaerahWithCounts = countSnapshot.data!;
                return _buildMapUI(dataDaerahWithCounts);
              },
            );
          },
        ),
      ),
    );
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
      "Januari", "Februari", "Maret", "April", "Mei", "Juni", "Juli",
      "Agustus", "September", "Oktober", "November", "Desember"
    ];
    return bulan[month - 1];
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final docRef =
          FirebaseFirestore.instance.collection('users').doc(user.uid);
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
          await docRef.set({
            'firstName': fName,
            'lastName': '',
            'phoneNumber': '',
            'address': '',
            'email': user.email ?? ''
          });
          setState(() {
            _firstName = fName;
          });
        }
      } catch (e) {
        if (mounted) {
          print('Error loading user data: $e');
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Gagal memuat data pengguna.')));
        }
      }
    }
  }
}