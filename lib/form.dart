import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

// Enum untuk merepresentasikan pilihan jenis kelamin
enum Gender { lakiLaki, perempuan }

class formPage extends StatefulWidget {
  const formPage({super.key});

  @override
  State<formPage> createState() => _formPageState();
}

class _formPageState extends State<formPage> {
  final _formKey = GlobalKey<FormState>();

  // Variabel untuk menyimpan data pengguna yang akan ditampilkan
  String _firstName = '';
  String _tanggal = "";
  bool _isLoading = true;

  // Variabel untuk formulir
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
            final parts = displayName.split(' ');
            fName = parts.isNotEmpty ? parts.first : '';
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
              onPrimary: Color.fromARGB(255, 255, 255, 255),
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
                      padding: const EdgeInsets.only(
                        top: 40,
                        left: 20,
                        right: 20,
                        bottom: 30,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
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
                    ),
                    Container(
                      decoration: const BoxDecoration(
                        color: Color(0xff052659),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(50),
                          topRight: Radius.circular(50),
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 30,
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Row(
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
                              ],
                            ),
                            const Text(
                              "Formulir Pengaduan DBD",
                              style: TextStyle(
                                fontSize: 20,
                                fontFamily: 'DMSans',
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 20),
                            _buildFormItem(
                              label: 'Nama Penderita',
                              controller: _namaController,
                              validator:
                                  (value) =>
                                      value!.isEmpty
                                          ? 'Nama tidak boleh kosong.'
                                          : null,
                            ),
                            _buildFormItem(
                              label: 'NIK Penderita',
                              controller: _nikController,
                              validator:
                                  (value) =>
                                      value!.isEmpty
                                          ? 'NIK tidak boleh kosong.'
                                          : null,
                            ),
                            _buildGenderSelector(),
                            _buildFormItem(
                              label: 'Tanggal Lahir',
                              controller: _tanggalLahirController,
                              isDatePicker: true,
                              validator:
                                  (value) =>
                                      value!.isEmpty
                                          ? 'Tanggal lahir tidak boleh kosong.'
                                          : null,
                            ),
                            _buildAlamatDropdown(),
                            _buildFormItem(
                              label: 'Tanggal Mulai Sakit',
                              controller: _tanggalSakitController,
                              isDatePicker: true,
                              validator:
                                  (value) =>
                                      value!.isEmpty
                                          ? 'Tanggal mulai sakit tidak boleh kosong.'
                                          : null,
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
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton(
                              onPressed: _submitFormToFirestore,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: const Color(0xFF052659),
                                minimumSize: const Size(double.infinity, 50),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontFamily: 'DMSans',
                    fontWeight: FontWeight.w400,
                  ),
                ),
                if (label == 'Nama Penderita')
                  const Text(
                    "*Wajib diisi",
                    style: TextStyle(
                      fontSize: 12,
                      fontFamily: 'DMSans',
                      fontWeight: FontWeight.w300,
                      color: Colors.white,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 16),
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

  Widget _buildAlamatDropdown() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Expanded(
            flex: 2,
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
          const SizedBox(width: 16),
          Expanded(
            flex: 3,
            child: // --- PERUBAHAN: Bungkus dengan Theme untuk styling menu ---
                Theme(
              data: Theme.of(context).copyWith(
                // Atur tema untuk menu popup
                popupMenuTheme: PopupMenuThemeData(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      10.0,
                    ), // Atur radius menu di sini
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
                style: const TextStyle(color: Colors.white),

                // --- PERUBAHAN: Modifikasi decoration untuk border radius kolom input ---
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(
                    0xFF204166,
                  ), // Pastikan ada warna latar
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 15,
                  ),
                  // Gunakan OutlineInputBorder untuk mengatur border radius
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(
                      10.0,
                    ), // Atur radius kolom di sini
                    borderSide: BorderSide.none, // Sembunyikan garis border
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
                    ), // Efek saat aktif
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

  Widget _buildGenderSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Jenis Kelamin',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontFamily: 'DMSans',
              fontWeight: FontWeight.w400,
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildGenderRadio(Gender.lakiLaki, 'Laki-laki'),
              _buildGenderRadio(Gender.perempuan, 'Perempuan'),
            ],
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
          ),
        ),
        Text(title, style: const TextStyle(color: Colors.white)),
      ],
    );
  }
}
