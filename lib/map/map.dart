import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:bugbusterss/main.dart';

class MapPage extends StatelessWidget {
  const MapPage({super.key});

  @override
  Widget build(BuildContext context) {
    final center = LatLng(-1.574966, 100.900371); // Koordinat Pesisir Selatan
    final double initialZoom = 8.7;
    final double maxZoom = 25;

    // Data lokasi daerah
    final List<StatusArea> dataDaerah = [
      StatusArea(
        nama: "Kambang",
        lokasi: LatLng(-1.493, 100.576),
        status: "Sedang",
      ),
      StatusArea(
        nama: "Tapan",
        lokasi: LatLng(-1.801, 101.203),
        status: "Tinggi",
      ),
      // Bisa tambah data lagi di sini...
    ];

    final statusCircleLayer = StatusCircleLayer(dataDaerah);

    return Scaffold(
      body: Container(
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
                    const Text(
                      "29 Juli 2025",
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
                        children: const <Widget>[
                          Text(
                            "Fadiru",
                            style: TextStyle(
                              fontSize: 16,
                              fontFamily: 'DMSans',
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
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
                        backgroundImage: AssetImage('assets/icons/user.png'),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // === PETA ===
            Container(
              margin: const EdgeInsets.only(top: 20, bottom: 20),
              height: 460,
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
                    userAgentPackageName: 'com.example.app',
                  ),
                  statusCircleLayer.buildCircles(),
                  statusCircleLayer.buildLabels(context),
                ],
              ),
            ),

            Column(
              children:
                  dataDaerah.map((item) {
                    return PotensiCard(
                      title: '1 Daerah Berpotensi DBD',
                      status: item.status,
                    ).buildWidget();
                  }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class StatusArea {
  final String nama;
  final LatLng lokasi;
  final String status; // "Sedang" atau "Tinggi"

  StatusArea({required this.nama, required this.lokasi, required this.status});
}

class StatusCircleLayer {
  final List<StatusArea> data;

  StatusCircleLayer(this.data);

  Color _getColor(String status) {
    switch (status.toLowerCase()) {
      case 'tinggi':
        return Color(0xffFF8585);
      case 'sedang':
        return Color(0xffFFECC9);
      default:
        return Colors.grey;
    }
  }

  Color _getFontColor(String status) {
    switch (status.toLowerCase()) {
      case 'tinggi':
        return Color(0xff681010);
      case 'sedang':
        return Color(0xff735C10);
      default:
        return Colors.grey;
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
              radius: 45, // pixel
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
              width: 80, // sedikit lebih lebar biar muat teks + button style
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
                  // Navigator.push(
                  //   // context,
                  //   // MaterialPageRoute(
                  //   //   // builder: (context) => DetailPage(area: item),
                  //   // ),
                  // );
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
