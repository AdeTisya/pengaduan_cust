class NotificationTemplate {
  static String ubahStatus({
    required String kodePengaduan,
    required String namaCustomer,
    required String status,
    String? catatan,
  }) {
    final String labelStatus = _labelStatus(status);
    final String emoji = _emojiStatus(status);
    final String waktu = _formatWaktu(DateTime.now());

    String pesan = '''
$emoji *Notifikasi Pengaduan Internet - Kominfo Gunungkidul*

Halo, *$namaCustomer*!

Status pengaduan internet Anda telah diperbarui.

📋 *Kode Pengaduan:* $kodePengaduan
🔄 *Status Terbaru:* $labelStatus
🕐 *Diperbarui:* $waktu
''';

    if (catatan != null && catatan.isNotEmpty) {
      pesan += '\n📝 *Catatan Teknisi:*\n$catatan\n';
    }

    pesan += '''
Terima kasih telah menggunakan layanan internet Kominfo Kabupaten Gunungkidul.
Hubungi kami jika ada pertanyaan lebih lanjut.

_Pesan ini dikirim otomatis oleh Sistem Pengaduan Kominfo Gunungkidul._''';

    return pesan;
  }

  static String _labelStatus(String status) {
    switch (status.toLowerCase()) {
      case 'diproses': return 'Sedang Diproses';
      case 'selesai':  return 'Selesai / Terselesaikan';
      case 'ditolak':  return 'Ditolak';
      default:         return status;
    }
  }

  static String _emojiStatus(String status) {
    switch (status.toLowerCase()) {
      case 'diproses': return '🔧';
      case 'selesai':  return '✅';
      case 'ditolak':  return '❌';
      default:         return '📢';
    }
  }

  static String _formatWaktu(DateTime dt) {
    const bulan = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
    ];
    return '${dt.day} ${bulan[dt.month]} ${dt.year}, '
        '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}';
  }
}