class NotificationTemplate {
  /// Pesan WA ketika teknisi mengubah status pengaduan.
  ///
  /// [fotoPenyelesaianUrl] — URL publik foto bukti penyelesaian.
  /// Hanya disertakan ke pesan jika status == 'selesai' dan URL tidak kosong.
  static String ubahStatus({
    required String kodePengaduan,
    required String namaCustomer,
    required String status,
    String? catatan,
    String? fotoPenyelesaianUrl,
  }) {
    final String labelStatus = _labelStatus(status);

    final StringBuffer sb = StringBuffer();

    sb.writeln('Halo, *$namaCustomer*! 👋');
    sb.writeln();
    sb.writeln('Pengaduan Anda dengan kode *$kodePengaduan* '
        'telah diperbarui statusnya menjadi:');
    sb.writeln();
    sb.writeln('📌 Status: *$labelStatus*');

    if (catatan != null && catatan.isNotEmpty) {
      sb.writeln();
      sb.writeln('📝 Catatan Teknisi:');
      sb.writeln(catatan);
    }

    // Sertakan link foto bukti penyelesaian hanya jika status selesai
    if (status.toLowerCase() == 'selesai' &&
        fotoPenyelesaianUrl != null &&
        fotoPenyelesaianUrl.isNotEmpty) {
      sb.writeln();
      sb.writeln('📷 Foto Bukti Penyelesaian:');
      sb.writeln(fotoPenyelesaianUrl);
    }

    sb.writeln();
    sb.writeln('Terima kasih. '
        'Jika ada pertanyaan, jangan ragu menghubungi kami kembali. 🙏');

    return sb.toString().trim();
  }

  static String _labelStatus(String status) {
    switch (status.toLowerCase()) {
      case 'menunggu':
        return 'Menunggu';
      case 'diterima':
        return 'Diterima';
      case 'diproses':
        return 'Diproses';
      case 'selesai':
        return 'Selesai ✅';
      case 'ditolak':
        return 'Ditolak ❌';
      default:
        return status;
    }
  }
}