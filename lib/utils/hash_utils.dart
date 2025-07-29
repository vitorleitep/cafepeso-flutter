import 'dart:convert';
import 'package:crypto/crypto.dart' as crypto;

class HashUtils {
  static String sha256(String input) {
    final bytes = utf8.encode(input);
    final digest = crypto.sha256.convert(bytes);
    final result = digest.toString();

    print('HashUtils.sha256:');
    print('  Input: "$input"');
    print('  Output: $result');

    return result;
  }
}