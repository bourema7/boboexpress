class AppConfig {
  // Override with --dart-define=BASE_URL=http://your_pc_ip:8000/api for local tests.
  static const String baseUrl = String.fromEnvironment(
    'BASE_URL',
    defaultValue: 'https://boboexpress.onrender.com/api',
  );
}
