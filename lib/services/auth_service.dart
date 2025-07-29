import '../models/admin.dart';
import '../models/enums/tipo_usuario.dart';
import '../models/enums/nivel_hierarquia.dart';
import '../utils/hash_utils.dart';
import 'database_service.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final DatabaseService _db = DatabaseService();
  Admin? _currentAdmin;

  Admin? get currentAdmin => _currentAdmin;
  String? get currentUserId => _currentAdmin?.id;
  String? get currentClienteId => _currentAdmin?.clienteId;
  bool get isLoggedIn => _currentAdmin != null;

  // Método para definir o usuário atual após login bem-sucedido
  Future<void> setCurrentUser(String userId, String username, String? clienteId) async {
    _currentAdmin = Admin(
      id: userId,
      username: username,
      email: '$username@cafepeso.com', // email fictício
      passwordHash: '', // não precisamos armazenar
      nome: username,
      tipoUsuario: TipoUsuario.ADMIN,
      nivelHierarquia: NivelHierarquia.OPERACIONAL,
      clienteId: clienteId,
    );
    print('✅ Usuário logado definido: $username (clienteId: $clienteId)');
  }

  Future<void> logout() async {
    _currentAdmin = null;
    print('👋 Logout realizado');
  }
}