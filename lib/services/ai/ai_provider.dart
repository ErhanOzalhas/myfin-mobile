abstract class AIProvider {
  Future<String> ask({
    required String context,
    required String question,
  });
}