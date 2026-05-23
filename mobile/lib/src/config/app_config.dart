class AppConfig {
  // Override with --dart-define=BASE_URL=http://your_pc_ip:8000/api
  static const String baseUrl = String.fromEnvironment(
    'BASE_URL',
    defaultValue: 'http://192.168.1.88:8000/api', // PC Wi-Fi for physical phone
  );
}
