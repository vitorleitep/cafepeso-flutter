import '../models/fazenda.dart';
import '../models/talhao.dart';
import '../models/pesagem.dart';
import '../models/admin.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  Future<bool> syncFazenda(Fazenda fazenda, String action) async {
    print('🔄 [MOCK] Sync fazenda: ${fazenda.nome} - $action');
    return true;
  }

  Future<List<Fazenda>> fetchFazendas() async {
    print('📥 [MOCK] Fetch fazendas');
    return [];
  }

  Future<bool> syncTalhao(Talhao talhao, String action) async {
    print('🔄 [MOCK] Sync talhão: ${talhao.nome} - $action');
    return true;
  }

  Future<List<Talhao>> fetchTalhoes() async {
    print('📥 [MOCK] Fetch talhões');
    return [];
  }

  Future<bool> syncPesagem(Pesagem pesagem, String action) async {
    print('🔄 [MOCK] Sync pesagem: ${pesagem.id} - $action');
    return true;
  }

  Future<List<Pesagem>> fetchPesagens() async {
    print('📥 [MOCK] Fetch pesagens');
    return [];
  }

  Future<bool> syncAdmin(Admin admin, String action) async {
    print('🔄 [MOCK] Sync admin: ${admin.username} - $action');
    return true;
  }
}