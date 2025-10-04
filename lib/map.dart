import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Pastikan ini di-import
import 'map_detail.dart';
import 'main.dart';

// Class StatusArea tetap sama, sudah memiliki 'jumlahPenderita'
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

// Class StatusCircleLayer tidak perlu diubah sama sekali
class StatusCircleLayer {
  final List<StatusArea> data;
  StatusCircleLayer(this.data);

  Color _getBackgroundColor(String status) {
    switch (status.toLowerCase()) {
      case 'tinggi': return const Color(0xFFFFE5E5);
      case 'sedang': return const Color(0xFFFFF4D1);
      default: return const Color(0xFFE0F7FA);
    }
  }

  Color _getForegroundColor(String status) {
    switch (status.toLowerCase()) {
      case 'tinggi': return const Color(0xFFD32F2F);
      case 'sedang': return const Color(0xFFC08D3B);
      default: return const Color(0xFF00796B);
    }
  }

  MarkerLayer buildMarkers(BuildContext context) {
    return MarkerLayer(
      markers: data.map((item) {
        final backgroundColor = _getBackgroundColor(item.status);
        final foregroundColor = _getForegroundColor(item.status);
        return Marker(
          point: item.lokasi,
          width: 80,
          height: 80,
          child: GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => MapDetailPage(locationKey: item.key)),
              );
            },
            child: Container(
              width: 75,
              height: 75,
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
                        fontSize: 20,
                        height: 1.1,
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(Icons.person, color: foregroundColor, size: 18),
                        const SizedBox(width: 4),
                        Text(
                          item.jumlahPenderita.toString(),
                          style: TextStyle(color: foregroundColor, fontSize: 18),
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

// =========================================================================
// === PERUBAHAN UTAMA ADA DI DALAM CLASS INI (_MapPageState) ===
// =========================================================================
class _MapPageState extends State<MapPage> {
  final _database = FirebaseDatabase.instance.ref();
  late Stream<DatabaseEvent> _dataStream;
  String _tanggal = "";
  String _firstName = '';
  // Hapus _isLoading karena akan ditangani oleh FutureBuilder
  
  @override
  void initState() {
    super.initState();
    _dataStream = _database.child('lokasi_bencana').onValue;
    _startRealtimeClock();
    _loadUserData();
  }

  // Fungsi baru untuk mengambil data lokasi DAN menghitung jumlah laporan dari Firestore
  Future<List<StatusArea>> _fetchDataWithCounts(Map<dynamic, dynamic> rtdbData) async {
    // 1. Ubah data RTDB menjadi list of locations (tanpa jumlah penderita yang benar)
    final initialLocations = rtdbData.entries.map((entry) {
      final item = entry.value as Map<dynamic, dynamic>?;
      String firebaseStatus = item?['potensi_bencana']?['dbd']?['status'] as String? ?? 'Tidak ada data';
      String displayStatus;
      switch (firebaseStatus.toUpperCase()) {
        case 'HIGH': displayStatus = 'Tinggi'; break;
        case 'MID': displayStatus = 'Sedang'; break;
        case 'LOW': displayStatus = 'Rendah'; break;
        default: displayStatus = 'Tidak ada data';
      }
      return StatusArea(
        key: entry.key,
        nama: item?['nama']?.toString().replaceAll('"', '') ?? 'Tidak Diketahui',
        lokasi: LatLng((item?['lat'] as num?)?.toDouble() ?? 0.0, (item?['long'] as num?)?.toDouble() ?? 0.0),
        status: displayStatus,
        jumlahPenderita: 0, // Nilai sementara, akan di-update
        sensorData: item?['sensor_data'] as Map<dynamic, dynamic>? ?? {},
      );
    }).toList();

    // 2. Untuk setiap lokasi, buat query ke Firestore untuk menghitung laporan
    final List<Future<int>> countFutures = initialLocations.map((location) {
      // Query ke koleksi 'pengaduan_dbd' dimana field 'alamat' sama dengan nama lokasi
      return FirebaseFirestore.instance
          .collection('pengaduan_dbd')
          .where('alamat', isEqualTo: location.nama)
          .get()
          .then((snapshot) => snapshot.size); // .size memberikan jumlah dokumen
    }).toList();

    // 3. Tunggu semua query Firestore selesai
    final List<int> counts = await Future.wait(countFutures);

    // 4. Buat list akhir dengan data jumlah penderita yang sudah benar
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
          jumlahPenderita: count, // <-- Gunakan jumlah dari Firestore
      ));
    }

    return finalLocations;
  }
  
  // Fungsi UI dipisahkan agar bisa dipanggil oleh FutureBuilder
  Widget _buildMapUI(List<StatusArea> dataDaerah) {
    final statusCircleLayer = StatusCircleLayer(dataDaerah);
    final int totalTinggi = dataDaerah.where((item) => item.status.toLowerCase() == 'tinggi').length;
    final int totalSedang = dataDaerah.where((item) => item.status.toLowerCase() == 'sedang').length;
    final int totalRendah = dataDaerah.where((item) => item.status.toLowerCase() == 'rendah').length;
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(left: 20, right: 20, top: 40),
      color: const Color(0xFFF5F5F5),
      child: Column(
        children: <Widget>[
          // === HEADER ===
          // (Kode header Anda tidak berubah, saya singkat untuk keringkasan)
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
                         Image.asset('assets/icons/location.png', width: 20, height: 16),
                         const SizedBox(width: 8),
                         const Text('Pesisir Selatan', style: TextStyle(fontSize: 16, fontFamily: 'DMSans', fontWeight: FontWeight.w600, color: Color(0xFF043F89))),
                       ],
                     ),
                   ),
                   Text(_tanggal, style: const TextStyle(fontSize: 16, fontFamily: 'DMSans', fontWeight: FontWeight.w300, color: Color(0xFF011023))),
                 ],
               ),
               Container(
                 height: 60,
                 width: 160,
                 padding: const EdgeInsets.only(left: 20),
                 decoration: BoxDecoration(
                   gradient: const LinearGradient(colors: [Color(0xFF204166), Color(0xFF14438B)], stops: [0.2, 1.0], begin: Alignment.centerLeft, end: Alignment.centerRight),
                   borderRadius: BorderRadius.circular(35),
                 ),
                 child: Row(
                   mainAxisAlignment: MainAxisAlignment.center,
                   children: <Widget>[
                     Column(
                       mainAxisAlignment: MainAxisAlignment.center,
                       crossAxisAlignment: CrossAxisAlignment.start,
                       children: <Widget>[
                         Text(_firstName, style: const TextStyle(fontSize: 16, fontFamily: 'DMSans', fontWeight: FontWeight.w600, color: Colors.white)),
                         const SizedBox(height: 4),
                         const Text("Warga Lokal", style: TextStyle(fontSize: 12, fontFamily: 'DMSans', fontWeight: FontWeight.w200, color: Colors.white)),
                       ],
                     ),
                     Expanded(child: Container()),
                     const CircleAvatar(radius: 30, backgroundImage: AssetImage('assets/icons/user.png')),
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
                initialCenter: LatLng(-1.574966, 100.900371),
                initialZoom: 8.7,
                minZoom: 8.7,
                maxZoom: 25,
                interactionOptions: const InteractionOptions(flags: InteractiveFlag.pinchZoom | InteractiveFlag.doubleTapZoom),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.mosquify',
                ),
                statusCircleLayer.buildMarkers(context),
              ],
            ),
          ),
          // === KARTU POTENSI ===
          // (Kode kartu potensi Anda tidak berubah)
          Column(
             children: <Widget>[
               PotensiCard(title: '$totalTinggi Daerah Berpotensi DBD', status: "Tinggi").buildWidget(),
               PotensiCard(title: '$totalSedang Daerah Berpotensi DBD', status: "Sedang").buildWidget(),
               PotensiCard(title: '$totalRendah Daerah Berpotensi DBD', status: "Rendah").buildWidget(),
             ],
           ),
        ],
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
            final Map<dynamic, dynamic>? dataFromFirebase = snapshot.data?.snapshot.value as Map<dynamic, dynamic>?;
            if (dataFromFirebase == null || dataFromFirebase.isEmpty) {
              return const Center(child: Text('Tidak ada data lokasi yang tersedia.'));
            }

            // Gunakan FutureBuilder untuk mengambil data Firestore
            return FutureBuilder<List<StatusArea>>(
              future: _fetchDataWithCounts(dataFromFirebase),
              builder: (context, AsyncSnapshot<List<StatusArea>> countSnapshot) {
                if (countSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: Text("Menghitung laporan..."));
                }
                if (countSnapshot.hasError) {
                  return Center(child: Text('Gagal menghitung laporan: ${countSnapshot.error}'));
                }
                if (!countSnapshot.hasData || countSnapshot.data!.isEmpty) {
                  return const Center(child: Text('Data lengkap tidak tersedia.'));
                }

                // Jika semua data sudah siap, bangun UI
                final dataDaerahWithCounts = countSnapshot.data!;
                return _buildMapUI(dataDaerahWithCounts);
              },
            );
          },
        ),
      ),
    );
  }

  // Sisa fungsi lain (_startRealtimeClock, _updateDateTime, _getNamaBulan, _loadUserData) tidak perlu diubah
  // ... letakkan sisa fungsi tersebut di sini ...
  void _startRealtimeClock() { _updateDateTime(); }
  void _updateDateTime() {
     final now = DateTime.now();
     setState(() { _tanggal = "${now.day} ${_getNamaBulan(now.month)} ${now.year}"; });
  }
  String _getNamaBulan(int month) {
     const bulan = ["Januari", "Februari", "Maret", "April", "Mei", "Juni", "Juli", "Agustus", "September", "Oktober", "November", "Desember"];
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
           setState(() { _firstName = data['firstName'] ?? ''; });
         } else {
           String? displayName = user.displayName;
           String fName = ''; String lName = '';
           if (displayName != null && displayName.isNotEmpty) {
             final parts = displayName.split(' ');
             fName = parts.isNotEmpty ? parts.first : '';
             lName = parts.length > 1 ? parts.sublist(1).join(' ') : '';
           }
           await docRef.set({ 'firstName': fName, 'lastName': lName, 'phoneNumber': '', 'address': '', 'email': user.email ?? '' });
           setState(() { _firstName = fName; });
         }
       } catch (e) {
         print('Error loading user data: $e');
         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal memuat data pengguna.')));
       }
     }
  }
}