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
  bool _isLoading = false;

  final List<String> _addressOptions = ['Kambang', 'Tapan'];

  Future<void> _register() async {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
    });

    if (_emailController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _firstNameController.text.isEmpty ||
        _selectedAddress == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Harap isi semua kolom yang wajib.")),
      );
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
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

      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15.0),
            ),
            title: const Text("Pendaftaran Berhasil"),
            content: const Text(
                "Akun Anda telah berhasil dibuat. Silakan masuk untuk melanjutkan."),
            actions: <Widget>[
              TextButton(
                child: const Text(
                  "Masuk Sekarang",
                  style: TextStyle(
                      color: Color(0xFF052659), fontWeight: FontWeight.bold),
                ),
                onPressed: () {
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Terjadi kesalahan.")));
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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
            ClipPath(
              clipper: WaveClipper(),
              child: Container(
                padding: EdgeInsets.only(bottom: screenHeight * 0.05),
                height: screenHeight * 0.35,
                color: const Color(0xFF0A2E63),
                alignment: Alignment.center,
                child: Image.asset(
                  'assets/icons/mosq.png',
                  width: screenWidth * 0.41,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.08),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Register",
                    style: TextStyle(
                      fontSize: screenWidth * 0.09,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'DMSans',
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.02),
                  _buildTextField(
                      controller: _emailController,
                      label: "Email",
                      hint: "Masukkan Email",
                      keyboardType: TextInputType.emailAddress),
                  SizedBox(height: screenHeight * 0.02),
                  _buildTextField(
                      controller: _firstNameController,
                      label: "Nama Depan",
                      hint: "Masukkan Nama Depan"),
                  SizedBox(height: screenHeight * 0.02),
                  _buildTextField(
                      controller: _lastNameController,
                      label: "Nama Belakang",
                      hint: "Masukkan Nama Belakang"),
                  SizedBox(height: screenHeight * 0.02),
                  _buildTextField(
                      controller: _phoneNumberController,
                      label: "Nomor Handphone",
                      hint: "Masukkan Nomor Handphone",
                      keyboardType: TextInputType.phone),
                  SizedBox(height: screenHeight * 0.02),
                  const Text("Tempat Tinggal",
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  SizedBox(height: screenHeight * 0.01),
                  DropdownSearch<String>(
                    items: _addressOptions,
                    selectedItem: _selectedAddress,
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedAddress = newValue;
                      });
                    },
                    validator: (value) =>
                        value == null || value.isEmpty ? 'Pilih tempat tinggal' : null,
                    dropdownDecoratorProps: DropDownDecoratorProps(
                      dropdownSearchDecoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 15),
                        hintText: "Pilih tempat tinggal...",
                        hintStyle: const TextStyle(
                            fontSize: 14, fontFamily: 'DMSans'),
                        filled: true,
                        fillColor: const Color(0x5CD9D9D9),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    popupProps: PopupProps.menu(
                      fit: FlexFit.loose,
                      constraints: BoxConstraints(maxWidth: screenWidth * 0.8),
                      showSelectedItems: true,
                      menuProps: const MenuProps(
                        elevation: 8,
                        borderRadius: BorderRadius.all(Radius.circular(15)),
                      ),
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.02),
                  _buildTextField(
                      controller: _passwordController,
                      label: "Password",
                      hint: "Masukkan kata sandi",
                      isPassword: true),
                  SizedBox(height: screenHeight * 0.03),
                  SizedBox(
                    width: double.infinity,
                    height: screenHeight * 0.06,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _register,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF052659),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              'DAFTAR',
                              style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.01),
                  Center(
                    child: TextButton(
                      onPressed: () {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                              builder: (context) => const LoginPage()),
                        );
                      },
                      child: const Text(
                        "Sudah Punya akun? Masuk Disini",
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xff4694FF)),
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    bool isPassword = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: isPassword,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(fontSize: 14, fontFamily: 'DMSans'),
            filled: true,
            fillColor: const Color(0x5CD9D9D9),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(25),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
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
    path.quadraticBezierTo(firstControlPoint.dx, firstControlPoint.dy,
        firstEndPoint.dx, firstEndPoint.dy);

    var secondControlPoint = Offset(size.width * 3 / 4, size.height);
    var secondEndPoint = Offset(size.width, size.height - 50);
    path.quadraticBezierTo(secondControlPoint.dx, secondControlPoint.dy,
        secondEndPoint.dx, secondEndPoint.dy);

    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}