/// Abstração para obter token (facilita teste + interceptor).
abstract class TokenProvider {
  Future<String?> getToken();
}
