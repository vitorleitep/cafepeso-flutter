import '../models/admin.dart';
import '../models/enums/nivel_hierarquia.dart';
import 'database_service.dart';

class ClienteHelper {
  static Future<String?> getClienteIdAtual() async {
    // Por enquanto, retorna um clienteId fixo
    return '1';
  }

  static Future<bool> isSuperAdmin() async {
    return true;
  }
}