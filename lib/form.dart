import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

enum Gender { lakiLaki, perempuan }

class FormPage extends StatefulWidget {
  const FormPage({super.key});

  @override
  State<FormPage> createState() => _FormPageState();
}

class _FormPageState extends State<FormPage> {
  final _formKey = GlobalKey<FormState>();

  String _firstName = '';
  String _tanggal = "";
  bool _isLoading = true;

  final _namaController = TextEditingController();
  final _nikController = TextEditingController();
  final _keluhanController = TextEditingController();
  final _tanggalLahirController = TextEditingController();
  final _tanggalSakitController = TextEditingController();
  Gender? _selectedGender = Gender.lakiLaki;

  String? _selectedAlamat;
  final List<String> _alamatOptions = ['Kambang', 'Tapan'];

  @override
  void initState() {
    super.initState();
    _updateDateTime();
    _loadUserData();
  }

  @override
  void dispose() {
    _namaController.dispose();
    _nikController.dispose();
    _keluhanController.dispose();
    _tanggalLahirController.dispose();
    _tanggalSakitController.dispose();
    super.dispose();
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
      final docRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid);
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
          await docRef.set({'firstName': fName});
          setState(() {
            _firstName = fName;
          });
        }
      } catch (e) {
        print('Error loading user data: $e');
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal memuat data pengguna.')),
        );
      }
    }
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _selectDate(
    BuildContext context,
    TextEditingController controller,
  ) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF14438B),
              onPrimary: Colors.white,
              onSurface: Colors.white,
            ),
            dialogBackgroundColor: const Color(0xFF204166),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: Colors.white),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        controller.text = DateFormat('dd MMMM yyyy').format(picked);
      });
    }
  }

  void _resetForm() {
    _namaController.clear();
    _nikController.clear();
    _keluhanController.clear();
    _tanggalLahirController.clear();
    _tanggalSakitController.clear();
    setState(() {
      _selectedGender = Gender.lakiLaki;
      _selectedAlamat = null;
    });
    _formKey.currentState?.reset();
  }

  Future<void> _submitFormToFirestore() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
      try {
        await FirebaseFirestore.instance.collection('pengaduan_dbd').add({
          'nama_penderita': _namaController.text,
          'nik_penderita': _nikController.text,
          'jenis_kelamin':
              _selectedGender == Gender.lakiLaki ? 'Laki-laki' : 'Perempuan',
          'tanggal_lahir': _tanggalLahirController.text,
          'alamat': _selectedAlamat,
          'tanggal_mulai_sakit': _tanggalSakitController.text,
          'keluhan': _keluhanController.text,
          'timestamp': FieldValue.serverTimestamp(),
          'reporter_id': FirebaseAuth.instance.currentUser?.uid,
        });

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Formulir berhasil dikirim!')),
        );
        _resetForm();
      } catch (e) {
        print('Error submitting form: $e');
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal mengirim formulir. Silakan coba lagi.'),
          ),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: const Color(0xffF5F5F5),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                child: Column(
                  children: [
                    Container(
                      color: const Color(0xffF5F5F5),
                      padding: EdgeInsets.symmetric(
                        horizontal: screenWidth * 0.05,
                        vertical: screenHeight * 0.02,
                      ).copyWith(top: screenHeight * 0.05),
                      child: Row(
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Text(
                                        _firstName,
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
                                      onBackgroundImageError: (
                                        exception,
                                        stackTrace,
                                      ) {
                                        print(
                                          'Error loading image: $exception',
                                        );
                                      },
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      decoration: const BoxDecoration(
                        color: Color(0xff052659),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(50),
                          topRight: Radius.circular(50),
                        ),
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal: screenWidth * 0.05,
                        vertical: screenHeight * 0.03,
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Row(
                              children: <Widget>[
                                IconButton(
                                  icon: const Icon(
                                    Icons.arrow_back,
                                    color: Colors.white,
                                  ),
                                  onPressed: () => Navigator.pop(context),
                                ),
                              ],
                            ),
                            Text(
                              "Formulir Pengaduan DBD",
                              style: TextStyle(
                                fontSize: screenWidth * 0.055,
                                fontFamily: 'DMSans',
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: screenHeight * 0.02),
                            _buildFormItem(
                              label: 'Nama Penderita',
                              controller: _namaController,
                              validator:
                                  (value) =>
                                      value!.isEmpty
                                          ? 'Nama tidak boleh kosong.'
                                          : null,
                              screenWidth: screenWidth,
                            ),
                            _buildFormItem(
                              label: 'NIK Penderita',
                              controller: _nikController,
                              validator:
                                  (value) =>
                                      value!.isEmpty
                                          ? 'NIK tidak boleh kosong.'
                                          : null,
                              screenWidth: screenWidth,
                            ),
                            _buildGenderSelector(screenWidth),
                            _buildFormItem(
                              label: 'Tanggal Lahir',
                              controller: _tanggalLahirController,
                              isDatePicker: true,
                              validator:
                                  (value) =>
                                      value!.isEmpty
                                          ? 'Tanggal lahir tidak boleh kosong.'
                                          : null,
                              screenWidth: screenWidth,
                            ),
                            _buildAlamatDropdown(screenWidth),
                            _buildFormItem(
                              label: 'Tanggal Mulai Sakit',
                              controller: _tanggalSakitController,
                              isDatePicker: true,
                              validator:
                                  (value) =>
                                      value!.isEmpty
                                          ? 'Tanggal mulai sakit tidak boleh kosong.'
                                          : null,
                              screenWidth: screenWidth,
                            ),
                            _buildFormItem(
                              label: 'Keluhan',
                              controller: _keluhanController,
                              maxLines: 4,
                              validator:
                                  (value) =>
                                      value!.isEmpty
                                          ? 'Keluhan tidak boleh kosong.'
                                          : null,
                              screenWidth: screenWidth,
                            ),
                            SizedBox(height: screenHeight * 0.03),
                            ElevatedButton(
                              onPressed: _submitFormToFirestore,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: const Color(0xFF052659),
                                minimumSize: Size(
                                  double.infinity,
                                  screenHeight * 0.06,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: const Text(
                                'Kirim',
                                style: TextStyle(fontSize: 18),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
    );
  }

  Widget _buildFormItem({
    required String label,
    required TextEditingController controller,
    required double screenWidth,
    int maxLines = 1,
    bool isDatePicker = false,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontFamily: 'DMSans',
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ),
          SizedBox(width: screenWidth * 0.04),
          Expanded(
            flex: 3,
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF204166),
                borderRadius: BorderRadius.circular(10),
              ),
              child: TextFormField(
                controller: controller,
                maxLines: maxLines,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  suffixIcon:
                      isDatePicker
                          ? const Icon(
                            Icons.calendar_today,
                            color: Colors.white54,
                          )
                          : null,
                ),
                readOnly: isDatePicker,
                onTap:
                    isDatePicker
                        ? () => _selectDate(context, controller)
                        : null,
                validator: validator,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlamatDropdown(double screenWidth) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Expanded(
            flex: 2,
            child: Padding(
              padding: EdgeInsets.only(top: 8.0),
              child: Text(
                'Alamat',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontFamily: 'DMSans',
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ),
          SizedBox(width: screenWidth * 0.04),
          Expanded(
            flex: 3,
            child: Theme(
              data: Theme.of(context).copyWith(
                popupMenuTheme: PopupMenuThemeData(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                ),
              ),
              child: DropdownButtonFormField<String>(
                value: _selectedAlamat,
                isExpanded: true,
                hint: const Text(
                  'Pilih Alamat',
                  style: TextStyle(color: Colors.white54),
                ),
                dropdownColor: const Color(0xFF204166),
                iconEnabledColor: Colors.white54,
                style: const TextStyle(color: Colors.white, fontSize: 16),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFF204166),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 15,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                    borderSide: const BorderSide(
                      color: Color(0xff4694FF),
                      width: 2,
                    ),
                  ),
                ),
                items:
                    _alamatOptions.map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedAlamat = newValue;
                  });
                },
                validator:
                    (value) =>
                        value == null ? 'Alamat tidak boleh kosong.' : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGenderSelector(double screenWidth) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Expanded(
            flex: 2,
            child: Text(
              'Jenis Kelamin',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontFamily: 'DMSans',
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          SizedBox(width: screenWidth * 0.04),
          Expanded(
            flex: 3,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                _buildGenderRadio(Gender.lakiLaki, 'Laki-laki'),
                const SizedBox(width: 2),
                _buildGenderRadio(Gender.perempuan, 'Perempuan'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGenderRadio(Gender value, String title) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Theme(
          data: Theme.of(context).copyWith(unselectedWidgetColor: Colors.white),
          child: Radio<Gender>(
            value: value,
            groupValue: _selectedGender,
            onChanged: (Gender? newValue) {
              setState(() {
                _selectedGender = newValue;
              });
            },
            activeColor: Colors.white,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
        Text(title, style: const TextStyle(color: Colors.white)),
      ],
    );
  }
}
