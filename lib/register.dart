import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'login.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();
  String? _selectedAddress;

  final List<String> _addressOptions = ['Kambang', 'Tapan'];

  // GANTI FUNGSI _register() ANDA DENGAN YANG INI

  Future<void> _register() async {
    // Tambahkan validasi sederhana sebelum mencoba mendaftar
    if (_emailController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _firstNameController.text.isEmpty ||
        _selectedAddress == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Harap isi semua kolom yang wajib.")),
      );
      return; // Hentikan fungsi jika ada yang kosong
    }

    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          );

      String? userId = userCredential.user?.uid;

      if (userId != null) {
        await FirebaseFirestore.instance.collection('users').doc(userId).set({
          'email': _emailController.text.trim(),
          'firstName': _firstNameController.text.trim(),
          'lastName': _lastNameController.text.trim(),
          'phoneNumber': _phoneNumberController.text.trim(),
          'address': _selectedAddress ?? '',
        });
      }

      // ===============================================
      // === BAGIAN INI YANG DIUBAH (DARI SNACKBAR KE POP-UP) ===
      // ===============================================

      // Pastikan widget masih ada di tree sebelum menampilkan dialog
      if (!mounted) return;

      // Tampilkan pop-up dialog
      showDialog(
        context: context,
        barrierDismissible: false, // User harus menekan tombol untuk menutup
        builder: (BuildContext context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15.0),
            ),
            title: const Text("Pendaftaran Berhasil"),
            content: const Text(
              "Akun Anda telah berhasil dibuat. Silakan masuk untuk melanjutkan.",
            ),
            actions: <Widget>[
              TextButton(
                child: const Text(
                  "Masuk Sekarang",
                  style: TextStyle(
                    color: Color(0xFF052659), // Warna sesuai tombol Anda
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onPressed: () {
                  // Pindahkan navigasi ke sini
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const LoginPage()),
                    (Route<dynamic> route) => false,
                  );
                },
              ),
            ],
          );
        },
      );
    } on FirebaseAuthException catch (e) {
      String message = "Pendaftaran gagal";
      if (e.code == 'weak-password') {
        message = "Kata sandi terlalu lemah.";
      } else if (e.code == 'email-already-in-use') {
        message = "Email ini sudah digunakan.";
      } else if (e.code == 'invalid-email') {
        message = "Format email tidak valid.";
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Terjadi kesalahan.")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            /// Bagian wave logo
            ClipPath(
              clipper: WaveClipper(),
              child: Container(
                height: 0.35 * screenHeight,
                color: const Color(0xFF0A2E63),
                alignment: Alignment.center,
                child: Image.asset(
                  'assets/icons/mosq.png',
                  width: screenWidth * 0.4,
                  height: screenHeight * 0.25,
                ),
              ),
            ),
            const SizedBox(height: 10),

            /// Judul
            Container(
              padding: const EdgeInsets.only(left: 30),
              alignment: Alignment.centerLeft,
              child: const Text(
                "Register",
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'DMSans',
                  color: Colors.black,
                ),
              ),
            ),

            /// Form Email & Password
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Email",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  TextField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      hintText: 'Masukkan Email',
                      hintStyle: const TextStyle(
                        fontSize: 14,
                        fontFamily: 'DMSans',
                      ),
                      filled: true,
                      fillColor: const Color(0x5CD9D9D9),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),

                  const Text(
                    "Nama Depan",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  TextField(
                    controller: _firstNameController,
                    decoration: InputDecoration(
                      hintText: 'Masukkan Nama Depan',
                      hintStyle: const TextStyle(
                        fontSize: 14,
                        fontFamily: 'DMSans',
                      ),
                      filled: true,
                      fillColor: const Color(0x5CD9D9D9),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),

                  const Text(
                    "Nama Belakang",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  TextField(
                    controller: _lastNameController,
                    decoration: InputDecoration(
                      hintText: 'Masukkan Nama Belakang',
                      hintStyle: const TextStyle(
                        fontSize: 14,
                        fontFamily: 'DMSans',
                      ),
                      filled: true,
                      fillColor: const Color(0x5CD9D9D9),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  const Text(
                    "Nomor Handphone",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  TextField(
                    controller: _phoneNumberController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      hintText: 'Masukkan Nomor Handphone',
                      hintStyle: const TextStyle(
                        fontSize: 14,
                        fontFamily: 'DMSans',
                      ),
                      filled: true,
                      fillColor: const Color(0x5CD9D9D9),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  const Text(
                    "Tempat Tinggal",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),

                  // DropdownSearch dengan itemBuilder untuk tampilan yang lebih bagus
                  DropdownSearch<String>(
                    items: _addressOptions,
                    selectedItem: _selectedAddress,
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedAddress = newValue;
                      });
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Silakan pilih tempat tinggal';
                      }
                      return null;
                    },
                    dropdownDecoratorProps: DropDownDecoratorProps(
                      dropdownSearchDecoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 15,
                        ),
                        hintText: "Pilih tempat tinggal...",
                        hintStyle: const TextStyle(
                          fontSize: 14,
                          fontFamily: 'DMSans',
                        ),
                        filled: true,
                        fillColor: const Color(0x5CD9D9D9),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25),
                          borderSide: const BorderSide(
                            color: Color(0xFF0A2E63),
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                    popupProps: PopupProps.menu(
                      fit: FlexFit.loose, // jangan full width
                      constraints: const BoxConstraints(
                        minWidth: 0,
                        maxWidth: 200, // atur sesuai kebutuhan isi
                      ),
                      showSelectedItems: true,
                      menuProps: const MenuProps(
                        elevation: 8,
                        borderRadius: BorderRadius.all(Radius.circular(15)),
                      ),
                      itemBuilder: (context, item, isSelected) {
                        return ListTile(
                          title: Text(item),
                          leading: const Icon(Icons.location_on),
                          selected: isSelected,
                          selectedColor: const Color(0xFF0A2E63),
                          onTap: () {
                            Navigator.pop(context, item);
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 15),
                  const Text(
                    "Password",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      hintText: 'Masukkan kata sandi',
                      hintStyle: const TextStyle(
                        fontSize: 14,
                        fontFamily: 'DMSans',
                      ),
                      filled: true,
                      fillColor: const Color(0x5CD9D9D9),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  /// Button Register
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _register,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF052659),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'DAFTAR',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Center(
                    child: TextButton(
                      onPressed: () {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (context) => const LoginPage(),
                          ),
                        );
                      },
                      child: const Text(
                        "Sudah Punya akun? Masuk Disini",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xff4694FF),
                        ),
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

/// Wave clipper
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
