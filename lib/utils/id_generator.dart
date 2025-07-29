import 'dart:math';

class IdGenerator {
  static final _random = Random();

  static String generateId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = _random.nextInt(999999);
    return '${timestamp}_$random';
  }
}