class ReportingPeriod {
  static const cutoffHour = 15;

  /// Apotek menutup laporan pada pukul 15.00. Transaksi mulai 15.00
  /// dicatat sebagai laporan hari kalender berikutnya.
  static DateTime businessDate(DateTime timestamp) {
    final date = DateTime(timestamp.year, timestamp.month, timestamp.day);
    return timestamp.hour >= cutoffHour
        ? date.add(const Duration(days: 1))
        : date;
  }

  static String businessDateString(DateTime timestamp) {
    final date = businessDate(timestamp);
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year.toString().padLeft(4, '0')}-$month-$day';
  }

  static String paymentPrefix(String paymentMethod) {
    switch (paymentMethod.trim().toUpperCase()) {
      case 'TUNAI':
        return 'T';
      case 'QRIS':
        return 'Q';
      case 'TRANSFER':
        return 'B';
      default:
        return 'L';
    }
  }
}
