import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Class untuk menampung data pesan
class Message {
  final String text;
  final bool isUser;

  Message({required this.text, required this.isUser});
}

class ChatBotPage extends StatelessWidget {
  const ChatBotPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: ChatScreen(),
    );
  }
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final List<Message> _messages = [];
  bool _isLoading = false;
  String _tanggal = "";
  String _firstName = '';
  bool _isLoading_name = true;

  // ⚠️ PENTING: Ganti dengan API Key Anda yang sebenarnya.
  // Sebaiknya gunakan environment variables untuk keamanan.
  static const _apiKey = 'AIzaSyCQbtAb6LVVUkh1Gi-i7CIpfmoWfeGfK5w';

  late final ChatSession _chat;

  @override
  void initState() {
    super.initState();
    _startRealtimeClock();
    _initializeChat();
    _loadUserData();
  }

  void _initializeChat() {
    final model = GenerativeModel(model: 'gemini-2.5-flash', apiKey: _apiKey);
    _chat = model.startChat();
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
      final docRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid);
      try {
        final doc = await docRef.get();
        final data = doc.data();

        if (doc.exists && data != null && data.isNotEmpty) {
          setState(() {
            _firstName = data['firstName'] ?? 'Warga';
          });
        } else {
          String fName = 'Warga';
          await docRef.set({'firstName': fName});
          setState(() {
            _firstName = fName;
          });
        }

        setState(() {
          _messages.insert(
            0,
            Message(
              text: "Halo $_firstName! Ada yang bisa saya bantu hari ini?",
              isUser: false,
            ),
          );
        });
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
      _isLoading_name = false;
    });
  }

  void _handleSubmitted(String text) {
    if (text.isEmpty) return;

    final userMessage = Message(text: text, isUser: true);
    _textController.clear();
    setState(() {
      _messages.insert(0, userMessage);
      _isLoading = true;
    });

    _getResponse(text);
  }

  Future<void> _getResponse(String userText) async {
    try {
      final content = Content.text(userText);
      final response = await _chat.sendMessage(content);

      if (response.text != null) {
        final botMessage = Message(text: response.text!, isUser: false);
        setState(() {
          _messages.insert(0, botMessage);
          _isLoading = false;
        });
      } else {
        _handleError("Menerima respons kosong dari AI.");
      }
    } catch (e) {
      _handleError("Terjadi kesalahan: ${e.toString()}");
    }
  }

  void _handleError(String errorText) {
    final errorMessage = Message(text: errorText, isUser: false);
    setState(() {
      _messages.insert(0, errorMessage);
      _isLoading = false;
    });
  }

  Widget _buildMessageBubble(Message message) {
    // Mendefinisikan widget untuk ikon user dan bot
    final userIcon = Container(
      width: 20,
      height: 20,
      color: Color(0xfff5f5f5), // Warna latar belakang jika gambar tidak ada

      child: Image.asset(
        'assets/icons/user.png', // Ganti dengan path gambar Anda
        fit: BoxFit.contain, // Membuat gambar mengisi penuh lingkaran
      ),
    );

    final botIcon = Container(
      width: 20,
      height: 20,
      color: Color(0xfff5f5f5), // Warna latar belakang jika gambar tidak ada

      child: Image.asset(
        'assets/icons/bot.png', // Ganti dengan path gambar Anda
        fit: BoxFit.contain, // Membuat gambar mengisi penuh lingkaran
      ),
    );

    // Menggunakan Row untuk menyusun ikon dan gelembung pesan
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 16.0),
      child: Row(
        mainAxisAlignment:
            message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children:
            message.isUser
                ? [
                  // Pesan User: Gelembung di kiri, ikon di kanan
                  Flexible(child: _buildBubbleContent(message)),
                  const SizedBox(width: 8),
                  userIcon,
                ]
                : [
                  // Pesan Bot: Ikon di kiri, gelembung di kanan
                  botIcon,
                  const SizedBox(width: 8),
                  Flexible(child: _buildBubbleContent(message)),
                ],
      ),
    );
  }

  // Widget terpisah untuk konten gelembung agar kode lebih rapi
  Widget _buildBubbleContent(Message message) {
    final color = message.isUser ? const Color(0xff052659) : Colors.white;
    final textColor = message.isUser ? Colors.white : Colors.black87;

    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20.0),
      ),
      child: Text(
        message.text,
        style: TextStyle(fontSize: 16.0, color: textColor),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // resizeToAvoidBottomInset: false,
      backgroundColor: const Color(0xFFF5F5F5),
      body: Container(
        padding: const EdgeInsets.only(
          top: 40,
          left: 20,
          right: 20,
          bottom: 20,
        ),
        child: Column(
          children: <Widget>[
            _buildHeader(),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                reverse: true,
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  return _buildMessageBubble(_messages[index]);
                },
              ),
            ),
            _buildTextComposer(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    // Tidak ada perubahan pada widget _buildHeader
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                backgroundImage: AssetImage('assets/icons/user.png'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTextComposer() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: <Widget>[
          Flexible(
            child: TextField(
              controller: _textController,
              onSubmitted: _isLoading ? null : _handleSubmitted,
              style: const TextStyle(
                fontSize: 16.0,
                fontFamily: 'DMSans',
                fontWeight: FontWeight.w400,
              ),
              decoration: InputDecoration.collapsed(
                hintText: 'Tanya Teman Masyarakat . . .',
                hintStyle: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w300,
                  fontFamily: 'DMSans',
                  color: Colors.grey[500],
                ),
              ),
              enabled: !_isLoading,
            ),
          ),
          _isLoading
              ? const SizedBox(
                width: 24,
                height: 24,
                child: Padding(
                  padding: EdgeInsets.all(4.0),
                  child: CircularProgressIndicator(strokeWidth: 2.0),
                ),
              )
              : IconButton(
                icon: const Icon(Icons.send),
                onPressed: () => _handleSubmitted(_textController.text),
                color: const Color(0xff052659),
              ),
        ],
      ),
    );
  }
}
