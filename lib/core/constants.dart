class AppConstants {
  AppConstants._();

  /// Emulator Android: 10.0.2.2 = localhost komputer
  /// HP asli: ganti ke IP LAN komputer (cek: `ip -4 addr show`), HP & PC harus 1 WiFi
  static const String baseUrl = 'http://192.168.1.33:3000/api/v1';
}
