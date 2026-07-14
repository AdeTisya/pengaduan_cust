import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/api_config.dart';

// ─── Model ────────────────────────────────────────────────────────────────────

class ChatMessage {
  final String role; // 'user' | 'assistant'
  final String text;
  final MessageType type;
  final DateTime timestamp; // ← BARU

  ChatMessage({
    required this.role,
    required this.text,
    this.type = MessageType.text,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'role': role,
        'text': text,
        'type': type.index,
        'timestamp': timestamp.toIso8601String(),
      };

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
        role: json['role'] as String,
        text: json['text'] as String,
        type: MessageType.values[json['type'] as int? ?? 0],
        timestamp: DateTime.tryParse(json['timestamp'] as String? ?? '') ??
            DateTime.now(),
      );
}

enum MessageType { text, quickReply }

// ─── Data Template Troubleshooting ───────────────────────────────────────────

class TroubleshootingStep {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final List<String> steps;
  final String? nextQuestion;
  final List<QuickReplyOption> options;

  const TroubleshootingStep({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.steps,
    this.nextQuestion,
    this.options = const [],
  });
}

class QuickReplyOption {
  final String label;
  final String emoji;
  final String? flowId;
  final String userMessage;

  const QuickReplyOption({
    required this.label,
    required this.emoji,
    this.flowId,
    required this.userMessage,
  });
}

final List<QuickReplyOption> _mainMenuOptions = [
  QuickReplyOption(
    label: 'Internet mati total',
    emoji: '🔴',
    flowId: 'no_internet',
    userMessage: 'Internet saya mati total, tidak ada koneksi sama sekali',
  ),
  QuickReplyOption(
    label: 'Koneksi lambat',
    emoji: '🐌',
    flowId: 'slow_internet',
    userMessage: 'Koneksi internet saya sangat lambat',
  ),
  QuickReplyOption(
    label: 'WiFi tidak muncul',
    emoji: '📶',
    flowId: 'wifi_missing',
    userMessage: 'Jaringan WiFi saya tidak muncul di daftar perangkat',
  ),
  QuickReplyOption(
    label: 'Sering putus-putus',
    emoji: '⚡',
    flowId: 'intermittent',
    userMessage: 'Koneksi internet saya sering putus-putus',
  ),
  QuickReplyOption(
    label: 'Lainnya / Tanya AI',
    emoji: '💬',
    flowId: null,
    userMessage: '',
  ),
];

final Map<String, TroubleshootingStep> _troubleshootingFlows = {
  'no_internet': TroubleshootingStep(
    id: 'no_internet',
    title: 'Internet Mati Total',
    description:
        'Baik, mari kita coba beberapa langkah dasar dulu. Silakan coba satu per satu:',
    icon: Icons.wifi_off_rounded,
    steps: [
      '1️⃣ Periksa lampu indikator modem/router — apakah ada lampu yang berkedip merah atau mati?',
      '2️⃣ Cabut kabel power modem, tunggu 30 detik, lalu pasang kembali',
      '3️⃣ Tunggu ±2 menit hingga modem restart sepenuhnya',
      '4️⃣ Cek apakah kabel LAN/fiber terpasang dengan benar di modem',
    ],
    nextQuestion:
        'Setelah mencoba langkah di atas, apakah koneksi sudah pulih?',
    options: [
      QuickReplyOption(
        label: 'Sudah pulih ✅',
        emoji: '✅',
        flowId: 'resolved',
        userMessage: 'Koneksi sudah pulih setelah restart modem, terima kasih!',
      ),
      QuickReplyOption(
        label: 'Belum pulih, lampu merah',
        emoji: '🔴',
        flowId: 'still_red_light',
        userMessage:
            'Belum pulih, masih ada lampu merah di modem setelah restart',
      ),
      QuickReplyOption(
        label: 'Belum pulih, lampu normal',
        emoji: '🟡',
        flowId: 'light_ok_no_net',
        userMessage:
            'Lampu modem terlihat normal tapi internet masih tidak bisa',
      ),
    ],
  ),
  'slow_internet': TroubleshootingStep(
    id: 'slow_internet',
    title: 'Koneksi Lambat',
    description: 'Koneksi lambat bisa disebabkan beberapa hal. Mari kita cek:',
    icon: Icons.speed_rounded,
    steps: [
      '1️⃣ Lakukan speed test di fast.com atau speedtest.net — catat hasilnya',
      '2️⃣ Periksa berapa perangkat yang terhubung ke WiFi saat ini',
      '3️⃣ Coba restart modem/router (cabut power 30 detik)',
      '4️⃣ Dekatkan perangkat ke router, atau gunakan kabel LAN jika memungkinkan',
      '5️⃣ Matikan perangkat lain yang tidak digunakan untuk sementara',
    ],
    nextQuestion: 'Berapa kecepatan yang kamu dapatkan dari speed test?',
    options: [
      QuickReplyOption(
        label: 'Sudah normal setelah restart',
        emoji: '✅',
        userMessage: 'Kecepatan sudah normal setelah restart modem',
        flowId: 'resolved',
      ),
      QuickReplyOption(
        label: '< 1 Mbps (sangat lambat)',
        emoji: '🐢',
        userMessage:
            'Kecepatan speed test kurang dari 1 Mbps, sangat lambat sekali',
        flowId: null,
      ),
      QuickReplyOption(
        label: 'Masih lambat, perlu lapor',
        emoji: '📋',
        userMessage:
            'Sudah coba semua langkah tapi koneksi masih lambat, ingin melaporkan ke teknisi',
        flowId: 'suggest_report',
      ),
    ],
  ),
  'wifi_missing': TroubleshootingStep(
    id: 'wifi_missing',
    title: 'WiFi Tidak Muncul',
    description: 'Jaringan WiFi tidak terdeteksi? Coba langkah ini:',
    icon: Icons.wifi_find_rounded,
    steps: [
      '1️⃣ Pastikan WiFi di perangkatmu sudah aktif (toggle WiFi on/off)',
      '2️⃣ Restart modem/router (cabut power 30 detik lalu nyalakan)',
      '3️⃣ Periksa lampu WiFi di modem — apakah menyala?',
      '4️⃣ Coba scan jaringan dari perangkat lain (HP lain atau laptop)',
      '5️⃣ Pastikan tidak ada tombol WiFi fisik di router yang tidak sengaja dinonaktifkan',
    ],
    nextQuestion: 'Setelah dicoba, bagaimana hasilnya?',
    options: [
      QuickReplyOption(
        label: 'WiFi sudah muncul ✅',
        emoji: '✅',
        userMessage: 'WiFi sudah muncul kembali setelah restart, terima kasih!',
        flowId: 'resolved',
      ),
      QuickReplyOption(
        label: 'Masih tidak muncul',
        emoji: '❌',
        userMessage:
            'WiFi masih tidak muncul di semua perangkat setelah dicoba semua langkah',
        flowId: 'suggest_report',
      ),
      QuickReplyOption(
        label: 'Lampu WiFi mati di router',
        emoji: '💡',
        userMessage:
            'Lampu indikator WiFi di router/modem terlihat mati atau tidak menyala',
        flowId: null,
      ),
    ],
  ),
  'intermittent': TroubleshootingStep(
    id: 'intermittent',
    title: 'Koneksi Sering Putus',
    description:
        'Koneksi putus-putus biasanya disebabkan gangguan sinyal atau kabel. Coba ini:',
    icon: Icons.signal_wifi_statusbar_connected_no_internet_4_rounded,
    steps: [
      '1️⃣ Periksa fisik kabel yang terhubung ke modem — pastikan tidak ada yang longgar',
      '2️⃣ Jauhkan modem dari perangkat elektronik lain (TV, microwave, AC)',
      '3️⃣ Perhatikan kapan koneksi putus — apakah saat jam tertentu atau acak?',
      '4️⃣ Restart modem dan biarkan menyala minimal 10 menit',
      '5️⃣ Cek apakah kabel di luar rumah (jika ada) dalam kondisi baik',
    ],
    nextQuestion: 'Apakah kamu tahu kapan biasanya koneksi putus?',
    options: [
      QuickReplyOption(
        label: 'Sudah stabil setelah restart',
        emoji: '✅',
        userMessage: 'Koneksi sudah stabil setelah restart modem',
        flowId: 'resolved',
      ),
      QuickReplyOption(
        label: 'Putus di jam tertentu (sibuk)',
        emoji: '🕐',
        userMessage:
            'Koneksi sering putus di jam-jam ramai seperti malam hari atau siang',
        flowId: null,
      ),
      QuickReplyOption(
        label: 'Putus acak tidak menentu',
        emoji: '🎲',
        userMessage:
            'Koneksi putus secara acak tidak ada pola, sudah coba semua langkah tapi masih sama',
        flowId: 'suggest_report',
      ),
    ],
  ),
  'resolved': TroubleshootingStep(
    id: 'resolved',
    title: 'Masalah Teratasi',
    description: '',
    icon: Icons.check_circle_rounded,
    steps: [],
    options: [
      QuickReplyOption(
        label: 'Ada masalah lain',
        emoji: '🔧',
        userMessage: 'Saya masih punya masalah lain',
        flowId: 'main_menu',
      ),
      QuickReplyOption(
        label: 'Selesai, terima kasih!',
        emoji: '👋',
        userMessage: 'Selesai, terima kasih atas bantuannya!',
        flowId: null,
      ),
    ],
  ),
  'still_red_light': TroubleshootingStep(
    id: 'still_red_light',
    title: 'Lampu Merah Setelah Restart',
    description:
        'Lampu merah setelah restart menandakan kemungkinan gangguan dari sisi jaringan ISP atau kerusakan perangkat. Langkah berikutnya:',
    icon: Icons.warning_amber_rounded,
    steps: [
      '⚠️ Pastikan tagihan internet sudah dibayar dan tidak ada tunggakan',
      '📞 Coba hubungi Kominfo Gunungkidul untuk laporan gangguan jaringan',
      '📋 Siapkan informasi: nomor pelanggan, lokasi, dan deskripsi lampu yang menyala',
    ],
    nextQuestion: 'Apakah kamu ingin membuat pengaduan resmi?',
    options: [
      QuickReplyOption(
        label: 'Ya, buat pengaduan',
        emoji: '📋',
        userMessage:
            'Saya ingin membuat pengaduan resmi ke Kominfo Gunungkidul',
        flowId: 'suggest_report',
      ),
      QuickReplyOption(
        label: 'Tanya dulu ke AI',
        emoji: '💬',
        userMessage:
            'Saya ingin bertanya lebih lanjut tentang lampu merah di modem',
        flowId: null,
      ),
    ],
  ),
  'light_ok_no_net': TroubleshootingStep(
    id: 'light_ok_no_net',
    title: 'Lampu Normal, Internet Tidak Bisa',
    description:
        'Lampu normal tapi internet tidak jalan? Kemungkinan masalah konfigurasi atau DNS. Coba:',
    icon: Icons.settings_ethernet_rounded,
    steps: [
      '1️⃣ Lupakan jaringan WiFi di HP/laptop lalu sambungkan ulang',
      '2️⃣ Coba ganti DNS ke 8.8.8.8 (Google) atau 1.1.1.1 (Cloudflare)',
      '3️⃣ Pastikan tidak ada VPN yang aktif di perangkatmu',
      '4️⃣ Coba akses internet dari perangkat lain di jaringan yang sama',
    ],
    nextQuestion: 'Apakah perangkat lain di rumah juga tidak bisa internet?',
    options: [
      QuickReplyOption(
        label: 'Semua perangkat bermasalah',
        emoji: '📱',
        userMessage:
            'Semua perangkat di rumah tidak bisa internet, bukan hanya satu',
        flowId: 'suggest_report',
      ),
      QuickReplyOption(
        label: 'Hanya perangkat ini saja',
        emoji: '💻',
        userMessage:
            'Hanya perangkat saya yang bermasalah, perangkat lain normal',
        flowId: null,
      ),
      QuickReplyOption(
        label: 'Sudah bisa setelah dicoba',
        emoji: '✅',
        userMessage:
            'Internet sudah bisa setelah mengikuti langkah-langkah tadi',
        flowId: 'resolved',
      ),
    ],
  ),
  'suggest_report': TroubleshootingStep(
    id: 'suggest_report',
    title: 'Perlu Laporan Teknisi',
    description: '',
    icon: Icons.report_problem_rounded,
    steps: [],
    options: [
      QuickReplyOption(
        label: 'Mulai dari awal',
        emoji: '🔄',
        userMessage: 'Saya ingin mencoba troubleshooting dari awal lagi',
        flowId: 'main_menu',
      ),
      QuickReplyOption(
        label: 'Tanya AI dulu',
        emoji: '🤖',
        userMessage: 'Saya ingin bertanya ke asisten AI dulu sebelum laporan',
        flowId: null,
      ),
    ],
  ),
};

// ─── Key SharedPreferences ────────────────────────────────────────────────────

const _kChatHistoryKey = 'chatbot_history';

// ─── Helper: Format tanggal ───────────────────────────────────────────────────

String _formatDateLabel(DateTime dt) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final yesterday = today.subtract(const Duration(days: 1));
  final msgDay = DateTime(dt.year, dt.month, dt.day);

  if (msgDay == today) return 'Hari ini';
  if (msgDay == yesterday) return 'Kemarin';

  const months = [
    '', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
    'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
  ];
  return '${dt.day} ${months[dt.month]} ${dt.year}';
}

String _formatTime(DateTime dt) {
  final h = dt.hour.toString().padLeft(2, '0');
  final m = dt.minute.toString().padLeft(2, '0');
  return '$h:$m';
}

// ─── Helper class untuk separator tanggal ────────────────────────────────────

class _DateSeparator {
  final String label;
  const _DateSeparator(this.label);
}

// ─── Page ─────────────────────────────────────────────────────────────────────

class ChatbotPage extends StatefulWidget {
  const ChatbotPage({super.key});

  @override
  State<ChatbotPage> createState() => _ChatbotPageState();
}

class _ChatbotPageState extends State<ChatbotPage>
    with TickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  bool _isLoadingHistory = true;
  List<QuickReplyOption>? _currentOptions;
  late AnimationController _typingAnimController;

  static const Color _navy = Color(0xFF1E2A5E);
  static const Color _accent = Color(0xFF4F80FF);
  static const Color _bgColor = Color(0xFFF7F8FC);

  @override
  void initState() {
    super.initState();
    _typingAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();

    _loadHistory();
  }

  // ─── Persistence ───────────────────────────────────────────────────────────

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kChatHistoryKey);

    if (raw != null && raw.isNotEmpty) {
      try {
        final List decoded = jsonDecode(raw) as List;
        final loaded = decoded
            .map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
            .toList();

        setState(() {
          _messages.addAll(loaded);
          _isLoadingHistory = false;
          _currentOptions = _mainMenuOptions;
        });
        _scrollToBottom();
        return;
      } catch (_) {
        await prefs.remove(_kChatHistoryKey);
      }
    }

    setState(() => _isLoadingHistory = false);
    _addWelcomeMessage();
  }

  Future<void> _saveHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(_messages.map((m) => m.toJson()).toList());
    await prefs.setString(_kChatHistoryKey, encoded);
  }

  Future<void> _clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kChatHistoryKey);
    setState(() {
      _messages.clear();
      _currentOptions = null;
    });
    _addWelcomeMessage();
    _scrollToBottom();
  }

  // ─── Welcome ───────────────────────────────────────────────────────────────

  void _addWelcomeMessage() {
    setState(() {
      _messages.add(
        ChatMessage(
          role: 'assistant',
          text:
              'Halo! Saya asisten virtual Kominfo Gunungkidul 👋\n\nSebelum menghubungi teknisi, yuk coba selesaikan gangguan jaringanmu sendiri dulu. Pilih masalah yang kamu alami:',
        ),
      );
      _currentOptions = _mainMenuOptions;
    });
    _saveHistory();
  }

  // ─── Scroll ────────────────────────────────────────────────────────────────

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 150), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ─── Quick reply ───────────────────────────────────────────────────────────

  void _handleQuickReply(QuickReplyOption option) {
    if (_isLoading) return;

    if (option.flowId == null && option.userMessage.isEmpty) {
      setState(() => _currentOptions = null);
      return;
    }

    if (option.userMessage.isNotEmpty) {
      setState(() {
        _messages.add(ChatMessage(role: 'user', text: option.userMessage));
        _currentOptions = null;
      });
      _saveHistory();
      _scrollToBottom();
    }

    if (option.flowId != null) {
      _processFlow(option.flowId!);
    } else {
      _sendToAI(option.userMessage);
    }
  }

  void _processFlow(String flowId) {
    if (flowId == 'main_menu') {
      Future.delayed(const Duration(milliseconds: 400), () {
        setState(() {
          _messages.add(
            ChatMessage(
              role: 'assistant',
              text: 'Pilih masalah yang kamu alami:',
            ),
          );
          _currentOptions = _mainMenuOptions;
        });
        _saveHistory();
        _scrollToBottom();
      });
      return;
    }

    final flow = _troubleshootingFlows[flowId];
    if (flow == null) return;

    setState(() => _isLoading = true);

    Future.delayed(const Duration(milliseconds: 700), () {
      if (!mounted) return;

      String replyText = '';

      if (flowId == 'resolved') {
        replyText =
            '🎉 Senang mendengarnya! Masalah berhasil diatasi dengan langkah mandiri.\n\nJika di kemudian hari gangguan terjadi lagi dan langkah di atas tidak berhasil, jangan ragu untuk membuat pengaduan resmi.';
      } else if (flowId == 'suggest_report') {
        replyText =
            '📋 Berdasarkan informasi yang kamu berikan, sepertinya masalah ini perlu ditangani oleh teknisi kami.\n\n'
            'Silakan buat pengaduan resmi melalui menu **Pengaduan** agar tim kami dapat segera menindaklanjuti. Pastikan menyertakan:\n'
            '• Deskripsi masalah lengkap\n'
            '• Foto bukti (jika ada, seperti lampu modem)\n'
            '• Lokasi kecamatan kamu';
      } else {
        replyText = '${flow.description}\n\n';
        replyText += flow.steps.join('\n\n');
        if (flow.nextQuestion != null) {
          replyText += '\n\n${flow.nextQuestion}';
        }
      }

      setState(() {
        _messages.add(ChatMessage(role: 'assistant', text: replyText));
        _currentOptions = flow.options.isNotEmpty ? flow.options : null;
        _isLoading = false;
      });
      _saveHistory();
      _scrollToBottom();
    });
  }

  // ─── AI ────────────────────────────────────────────────────────────────────

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isLoading) return;

    setState(() {
      _messages.add(ChatMessage(role: 'user', text: text));
      _currentOptions = null;
      _isLoading = true;
    });
    _controller.clear();
    _saveHistory();
    _scrollToBottom();

    await _sendToAI(text);
  }

  Future<void> _sendToAI(String text) async {
    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      final historyToSend = _messages
          .sublist(1, _messages.length - 1)
          .map((m) => {'role': m.role, 'text': m.text})
          .toList();

      final response = await http.post(
        Uri.parse(ApiConfig.customerChatbot),
        headers: ApiConfig.headers(token: token),
        body: jsonEncode({'message': text, 'history': historyToSend}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final reply = data['data']['reply'] ?? 'Maaf, tidak ada respons.';
        setState(() {
          _messages.add(ChatMessage(role: 'assistant', text: reply));
          _currentOptions = [
            QuickReplyOption(
              label: 'Kembali ke menu utama',
              emoji: '🏠',
              userMessage: 'Kembali ke menu troubleshooting utama',
              flowId: 'main_menu',
            ),
          ];
        });
      } else if (response.statusCode == 429) {
        setState(() {
          _messages.add(
            ChatMessage(
              role: 'assistant',
              text: '⚠️ Terlalu banyak permintaan. Coba lagi beberapa saat.',
            ),
          );
        });
      } else {
        setState(() {
          _messages.add(
            ChatMessage(
              role: 'assistant',
              text: '⚠️ Gagal menghubungi asisten. (${response.statusCode})',
            ),
          );
        });
      }
    } catch (e) {
      setState(() {
        _messages.add(
          ChatMessage(
            role: 'assistant',
            text: '⚠️ Terjadi kesalahan koneksi. Periksa jaringan kamu.',
          ),
        );
      });
    } finally {
      setState(() => _isLoading = false);
      _saveHistory();
      _scrollToBottom();
    }
  }

  // ─── Build item list (pesan + separator tanggal) ──────────────────────────

  List<Object> _buildItemList() {
    final items = <Object>[];
    DateTime? lastDate;

    for (final msg in _messages) {
      final msgDay = DateTime(msg.timestamp.year, msg.timestamp.month, msg.timestamp.day);

      if (lastDate == null || msgDay != lastDate) {
        items.add(_DateSeparator(_formatDateLabel(msg.timestamp)));
        lastDate = msgDay;
      }
      items.add(msg);
    }

    return items;
  }

  // ─── Build UI ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      appBar: _buildAppBar(),
      body: _isLoadingHistory
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(14, 16, 14, 8),
                    itemCount: _buildItemList().length,
                    itemBuilder: (ctx, i) {
                      final item = _buildItemList()[i];
                      if (item is _DateSeparator) {
                        return _buildDateSeparator(item.label);
                      } else if (item is ChatMessage) {
                        return _buildBubble(item);
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ),
                if (_isLoading) _buildTypingIndicator(),
                if (_currentOptions != null && !_isLoading)
                  _buildQuickReplySection(_currentOptions!),
                _buildInputBar(),
              ],
            ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: _navy,
      foregroundColor: Colors.white,
      elevation: 0,
      titleSpacing: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.support_agent_rounded, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Asisten Kominfo',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: -0.2),
              ),
              Row(
                children: [
                  Container(
                    width: 6, height: 6,
                    decoration: const BoxDecoration(color: Color(0xFF4ADE80), shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 4),
                  const Text('Online', style: TextStyle(fontSize: 11, color: Colors.white70)),
                ],
              ),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.delete_outline_rounded, size: 20),
          tooltip: 'Hapus riwayat chat',
          onPressed: _showClearHistoryDialog,
        ),
      ],
    );
  }

  void _showClearHistoryDialog() {
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hapus Riwayat Chat'),
        content: const Text('Semua riwayat percakapan akan dihapus permanen. Lanjutkan?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _navy),
            onPressed: () {
              Navigator.pop(ctx);
              _clearHistory();
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildDateSeparator(String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          const Expanded(child: Divider(color: Color(0xFFDDE1EA), thickness: 1)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFE8EAF2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF6B7280),
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ),
          const Expanded(child: Divider(color: Color(0xFFDDE1EA), thickness: 1)),
        ],
      ),
    );
  }

  Widget _buildBubble(ChatMessage msg) {
    final isUser = msg.role == 'user';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            Container(
              width: 30, height: 30,
              decoration: BoxDecoration(color: _navy, shape: BoxShape.circle),
              child: const Icon(Icons.support_agent_rounded, color: Colors.white, size: 16),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                  decoration: BoxDecoration(
                    color: isUser ? _navy : Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: Radius.circular(isUser ? 18 : 4),
                      bottomRight: Radius.circular(isUser ? 4 : 18),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    msg.text,
                    style: TextStyle(
                      color: isUser ? Colors.white : const Color(0xFF1A1A2E),
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                ),
                // Timestamp di bawah bubble
                const SizedBox(height: 3),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    _formatTime(msg.timestamp),
                    style: const TextStyle(fontSize: 10, color: Color(0xFFADB5BD)),
                  ),
                ),
              ],
            ),
          ),
          if (isUser) const SizedBox(width: 4),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 4),
      child: Row(
        children: [
          Container(
            width: 30, height: 30,
            decoration: BoxDecoration(color: _navy, shape: BoxShape.circle),
            child: const Icon(Icons.support_agent_rounded, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(18),
              ),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, 2)),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (i) => _buildDot(i)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDot(int index) {
    return AnimatedBuilder(
      animation: _typingAnimController,
      builder: (_, __) {
        final phase = (_typingAnimController.value + index * 0.2) % 1.0;
        final opacity = (phase < 0.5) ? (phase * 2) : (1 - (phase - 0.5) * 2);
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 2.5),
          width: 7, height: 7,
          decoration: BoxDecoration(
            color: _navy.withValues(alpha: 0.3 + opacity * 0.7),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }

  Widget _buildQuickReplySection(List<QuickReplyOption> options) {
    return Container(
      color: _bgColor,
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 4),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: options.map((opt) => _buildChip(opt)).toList(),
      ),
    );
  }

  Widget _buildChip(QuickReplyOption opt) {
    final isPositive = opt.label.contains('✅') || opt.label.contains('Sudah');
    final isNegative = opt.label.contains('❌') || opt.label.contains('Lapor') || opt.label.contains('pengaduan');
    final isNeutral = opt.flowId == null && opt.userMessage.isEmpty;

    Color chipBg, chipText, chipBorder;

    if (isNeutral) {
      chipBg = Colors.white;
      chipText = const Color(0xFF6B7280);
      chipBorder = const Color(0xFFD1D5DB);
    } else if (isPositive) {
      chipBg = const Color(0xFFECFDF5);
      chipText = const Color(0xFF065F46);
      chipBorder = const Color(0xFFA7F3D0);
    } else if (isNegative) {
      chipBg = const Color(0xFFFFF7ED);
      chipText = const Color(0xFF92400E);
      chipBorder = const Color(0xFFFCD34D);
    } else {
      chipBg = const Color(0xFFEEF2FF);
      chipText = _navy;
      chipBorder = const Color(0xFFC7D2FE);
    }

    return GestureDetector(
      onTap: () => _handleQuickReply(opt),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: chipBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: chipBorder, width: 1.2),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 4, offset: const Offset(0, 1)),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(opt.emoji, style: const TextStyle(fontSize: 15)),
            const SizedBox(width: 6),
            Text(opt.label, style: TextStyle(color: chipText, fontSize: 13, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.07), blurRadius: 10, offset: const Offset(0, -3)),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: _bgColor,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
                ),
                child: TextField(
                  controller: _controller,
                  maxLines: null,
                  textCapitalization: TextCapitalization.sentences,
                  style: const TextStyle(fontSize: 14),
                  decoration: const InputDecoration(
                    hintText: 'Ketik pertanyaan...',
                    hintStyle: TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _sendMessage,
              child: Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_accent, _navy],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: _accent.withValues(alpha: 0.35), blurRadius: 8, offset: const Offset(0, 3)),
                  ],
                ),
                child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _typingAnimController.dispose();
    super.dispose();
  }
}