import 'package:flutter/material.dart';
import 'package:bugbusterss/main.dart';

// const Color primaryColor = Color(0xFF42A5F5);

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Color(0xFFF5F5F5), // Warna latar belakang
        padding: EdgeInsets.only(top: 40, left: 20, right: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Column(
                  children: <Widget>[
                    SizedBox(
                      height: 30,
                      // color: Colors.black12,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: <Widget>[
                          Image.asset(
                            'assets/icons/location.png',
                            width: 20,
                            height: 16,
                          ),
                          SizedBox(width: 8),
                          Text(
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
                  // margin: EdgeInsets.only(right: 20),
                  height: 60,
                  width: 160,
                  padding: EdgeInsets.only(left: 20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
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
                      CircleAvatar(
                        radius: 30,
                        backgroundImage: AssetImage('assets/icons/user.png'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(
              height: 20,
              child: Row(
                children: <Widget>[
                  Text(
                    "Welcome Back",
                    style: TextStyle(
                      fontSize: 16,
                      fontFamily: 'DMSans',
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF011023),
                    ),
                  ),
                  Text(
                    " Fadiru,",
                    style: TextStyle(
                      fontSize: 16,
                      fontFamily: 'DMSans',
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0B39BF),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              height: 220,
              margin: EdgeInsets.only(top: 5, bottom: 10),
              padding: EdgeInsets.only(left: 20, right: 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF13438C), Color(0xFF204164)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.5),
                    spreadRadius: 2,
                    blurRadius: 6,
                    offset: Offset(3, 3), // posisi bayangan (x, y)
                  ),
                ],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: <Widget>[
                  Container(
                    margin: EdgeInsets.only(top: 20),
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Pasaman | Zone A",
                      style: TextStyle(
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
                            "Suhu             :  20°C",
                            style: TextStyle(
                              fontSize: 14,
                              fontFamily: 'DMSans',
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            "Kelembapan :  88%",
                            style: TextStyle(
                              fontSize: 14,
                              fontFamily: 'DMSans',
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            "Curah Hujan :  500mm",
                            style: TextStyle(
                              fontSize: 14,
                              fontFamily: 'DMSans',
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        margin: EdgeInsets.only(left: 43),
                        child: Image.asset(
                          'assets/images/weather.png',
                          width: 100,
                          height: 100,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    margin: EdgeInsets.only(top: 10),
                    padding: EdgeInsets.only(
                      left: 10,
                      right: 10,
                      top: 10,
                      bottom: 5,
                    ),
                    alignment: Alignment.centerLeft,
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(color: Color(0xFF5381B3), width: 1),
                      ),
                    ),
                    child: Row(
                      children: <Widget>[
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              "22:39 WIB",
                              style: TextStyle(
                                fontSize: 14,
                                fontFamily: 'DMSans',
                                fontWeight: FontWeight.w300,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              "PASAMAN ZONA A",
                              style: TextStyle(
                                fontSize: 14,
                                fontFamily: 'DMSans',
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          margin: EdgeInsets.only(left: 45),
                          alignment: Alignment.center,
                          height: 45,
                          width: 100,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            "SAVE",
                            style: TextStyle(
                              fontSize: 16,
                              fontFamily: 'DMSans',
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1D416C),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Column(
              children: [
                PotensiCard(
                  title: 'Potensi Terjadi Banjir',
                  status: 'Sedang',
                ).buildWidget(),
                PotensiCard(
                  title: 'Potensi Terjadi DBD',
                  status: 'Sedang',
                ).buildWidget(),
              ],
            ),
            SizedBox(height: 7),
            Container(
              margin: EdgeInsets.only(left: 20, right: 20, bottom: 5),
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
              padding: EdgeInsets.all(15),
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
                  SizedBox(
                    // color: Colors.black,
                    width: 180,
                    child: Text(
                      "DBD (Dengue Berdarah) atau demam berdarah dengue adalah penyakit yang disebabkan oleh virus dengue yang ditularkan melalui gigitan nyamuk Aedes aegypti atau Aedes albopictus yang terinfeksi.",
                      style: TextStyle(
                        fontSize: 13,
                        fontFamily: 'DMSans',
                        fontWeight: FontWeight.w200,
                        color: Color(0xff000000),
                      ),
                      // textAlign: TextAlign.justify,
                    ),
                  ),
                  Expanded(
                    child: Transform.rotate(
                      angle: 25 * 3.1416 / 180, // 45 derajat
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

