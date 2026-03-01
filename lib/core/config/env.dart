/// Configure com: flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080
class Env {
  static const apiBaseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: 'http://localhost:8080');
}
