import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/fazenda.dart';
import '../models/talhao.dart';
import '../models/pesagem.dart';
import '../models/tara_personalizada.dart';
import '../models/admin.dart';
import '../models/enums/sync_status.dart';
import '../models/enums/tipo_usuario.dart';
import '../models/enums/nivel_hierarquia.dart';
import 'package:uuid/uuid.dart';

class DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Cache local
  List<Fazenda>? _fazendasCache;
  List<Talhao>? _talhoesCache;
  List<TaraPersonalizada>? _tarasCache;
  DateTime? _lastCacheUpdate;

  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  bool get _isCacheValid =>
      _lastCacheUpdate != null &&
          DateTime.now().difference(_lastCacheUpdate!).inMinutes < 5;

  void clearCache() {
    _fazendasCache = null;
    _talhoesCache = null;
    _tarasCache = null;
    _lastCacheUpdate = null;
  }

  // Cliente padrão para teste
  String get _defaultClienteId => 'F7Tnzw1sujZFb3MKTSQNyE2dtxI3';

  // ===== FAZENDAS =====
  Future<List<Fazenda>> getFazendas({String? clienteId}) async {
    try {
      if (_isCacheValid && _fazendasCache != null) {
        return _fazendasCache!;
      }

      print('🔍 Buscando fazendas do Firebase...');

      final userClienteId = clienteId ?? _defaultClienteId;

      // Tente primeiro sem o filtro clienteId para teste
      QuerySnapshot snapshot;
      try {
        snapshot = await _firestore
            .collection('fazendas')
            .where('clienteId', isEqualTo: userClienteId)
            .orderBy('nome')
            .get();
      } catch (e) {
        print('⚠️ Erro com filtro, tentando sem filtro...');
        // Se falhar, tenta sem filtro
        snapshot = await _firestore
            .collection('fazendas')
            .get();
      }

      List<Fazenda> fazendas = snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

        return Fazenda(
          id: doc.id,
          nome: data['nome'] ?? '',
          localizacao: data['localizacao'],
          adminId: data['adminId'],
          clienteId: data['clienteId'],
          dataCriacao: (data['dataCriacao'] as Timestamp?)?.toDate() ?? DateTime.now(),
          dataUltimaModificacao: (data['dataUltimaModificacao'] as Timestamp?)?.toDate() ?? DateTime.now(),
          syncStatus: SyncStatus.synced,
          firebaseId: doc.id,
        );
      }).toList();

      _fazendasCache = fazendas;
      _lastCacheUpdate = DateTime.now();

      print('✅ ${fazendas.length} fazendas encontradas');
      return fazendas;

    } catch (e) {
      print('❌ Erro ao buscar fazendas: $e');
      return _fazendasCache ?? [];
    }
  }

  // ===== TALHÕES =====
  Future<List<Talhao>> getTalhoes({String? clienteId}) async {
    try {
      if (_isCacheValid && _talhoesCache != null) {
        return _talhoesCache!;
      }

      print('🔍 Buscando talhões do Firebase...');

      QuerySnapshot snapshot = await _firestore
          .collection('talhoes')
          .get();

      List<Fazenda> fazendas = await getFazendas();
      Map<String, String> nomeFazendas = {};
      for (var fazenda in fazendas) {
        nomeFazendas[fazenda.id] = fazenda.nome;
      }

      List<Talhao> talhoes = snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

        Talhao talhao = Talhao(
          id: doc.id,
          fazendaId: data['fazendaId'] ?? '',
          nome: data['nome'] ?? '',
          area: data['area']?.toDouble(),
          localizacao: data['localizacao'],
          adminId: data['adminId'],
          clienteId: data['clienteId'],
          dataCriacao: (data['dataCriacao'] as Timestamp?)?.toDate() ?? DateTime.now(),
          dataUltimaModificacao: (data['dataUltimaModificacao'] as Timestamp?)?.toDate() ?? DateTime.now(),
          syncStatus: SyncStatus.synced,
          firebaseId: doc.id,
        );

        talhao.setNomeFazenda(nomeFazendas[talhao.fazendaId] ?? 'Desconhecida');

        return talhao;
      }).toList();

      _talhoesCache = talhoes;
      _lastCacheUpdate = DateTime.now();

      print('✅ ${talhoes.length} talhões encontrados');
      return talhoes;

    } catch (e) {
      print('❌ Erro ao buscar talhões: $e');
      return _talhoesCache ?? [];
    }
  }

  // ===== TARAS =====
  Future<List<TaraPersonalizada>> getTarasPersonalizadas({String? clienteId}) async {
    try {
      if (_isCacheValid && _tarasCache != null) {
        return _tarasCache!;
      }

      print('🔍 Buscando taras personalizadas do Firebase...');

      // Simplificar a query para evitar erro de índice
      QuerySnapshot snapshot;
      try {
        snapshot = await _firestore
            .collection('taras_personalizadas')
            .where('ativo', isEqualTo: true)
            .get();
      } catch (e) {
        print('⚠️ Erro com filtro ativo, buscando todas...');
        // Se falhar, busca todas
        snapshot = await _firestore
            .collection('taras_personalizadas')
            .get();
      }

      List<TaraPersonalizada> taras = snapshot.docs
          .where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return data['ativo'] == true; // Filtrar apenas ativas
      })
          .map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

        return TaraPersonalizada(
          id: doc.id,
          nome: data['nome'] ?? '',
          valorTara: (data['valorTara'] ?? 0.0).toDouble(),
          dataCriacao: (data['dataCriacao'] as Timestamp?)?.toDate() ?? DateTime.now(),
          ultimoUso: (data['ultimoUso'] as Timestamp?)?.toDate() ?? DateTime.now(),
          quantidadeUsos: data['quantidadeUsos'] ?? 1,
          ativo: data['ativo'] ?? true,
          observacoes: data['observacoes'],
          clienteId: data['clienteId'],
          syncStatus: SyncStatus.synced,
          firebaseId: doc.id,
        );
      })
          .toList();

      // Ordenar manualmente se necessário
      taras.sort((a, b) => b.ultimoUso.compareTo(a.ultimoUso));

      _tarasCache = taras;
      _lastCacheUpdate = DateTime.now();

      print('✅ ${taras.length} taras personalizadas encontradas');
      return taras;

    } catch (e) {
      print('❌ Erro ao buscar taras: $e');
      return _tarasCache ?? [];
    }
  }

  // ===== PESAGENS =====
  Future<List<Pesagem>> getPesagens({String? clienteId}) async {
    try {
      print('🔍 Buscando pesagens do Firebase...');

      final dataLimite = DateTime.now().subtract(Duration(days: 30));

      QuerySnapshot snapshot = await _firestore
          .collection('pesagens')
          .where('dataPesagem', isGreaterThan: Timestamp.fromDate(dataLimite))
          .orderBy('dataPesagem', descending: true)
          .limit(100)
          .get();

      List<Talhao> talhoes = await getTalhoes();
      List<Fazenda> fazendas = await getFazendas();

      Map<String, Talhao> talhoesMap = {};
      Map<String, Fazenda> fazendasMap = {};

      for (var talhao in talhoes) {
        talhoesMap[talhao.id] = talhao;
      }

      for (var fazenda in fazendas) {
        fazendasMap[fazenda.id] = fazenda;
      }

      List<Pesagem> pesagens = snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

        Pesagem pesagem = Pesagem(
          id: doc.id,
          talhaoId: data['talhaoId'] ?? '',
          fazendaId: data['fazendaId'],
          adminId: data['adminId'],
          clienteId: data['clienteId'],
          dataPesagem: (data['dataPesagem'] as Timestamp?)?.toDate() ?? DateTime.now(),
          pesoBruto: (data['pesoBruto'] ?? 0.0).toDouble(),
          tara: (data['tara'] ?? 0.0).toDouble(),
          pesoLiquido: (data['pesoLiquido'] ?? 0.0).toDouble(),
          observacoes: data['observacoes'],
          syncStatus: SyncStatus.synced,
          firebaseId: doc.id,
        );

        Talhao? talhao = talhoesMap[pesagem.talhaoId];
        if (talhao != null) {
          pesagem.setNomeTalhao(talhao.nome);
          pesagem.setNomeFazenda(fazendasMap[talhao.fazendaId]?.nome ?? 'Desconhecida');
        }

        return pesagem;
      }).toList();

      print('✅ ${pesagens.length} pesagens encontradas');
      return pesagens;

    } catch (e) {
      print('❌ Erro ao buscar pesagens: $e');
      return [];
    }
  }

  Future<List<Pesagem>> getPesagensHoje({String? clienteId}) async {
    final hoje = DateTime.now();
    final pesagens = await getPesagens(clienteId: clienteId);

    return pesagens.where((p) =>
    p.dataPesagem.day == hoje.day &&
        p.dataPesagem.month == hoje.month &&
        p.dataPesagem.year == hoje.year
    ).toList();
  }

  Future<double> getTotalMes({String? clienteId}) async {
    final hoje = DateTime.now();
    final pesagens = await getPesagens(clienteId: clienteId);

    final pesagensMes = pesagens.where((p) =>
    p.dataPesagem.month == hoje.month &&
        p.dataPesagem.year == hoje.year
    );

    return pesagensMes.fold<double>(0.0, (total, p) => total + p.pesoLiquido);
  }

  // ===== CRUD PESAGENS =====
  Future<void> insertPesagem(Pesagem pesagem) async {
    try {
      final clienteId = _defaultClienteId;

      DocumentSnapshot talhaoDoc = await _firestore
          .collection('talhoes')
          .doc(pesagem.talhaoId)
          .get();

      String? fazendaId;
      if (talhaoDoc.exists) {
        fazendaId = (talhaoDoc.data() as Map<String, dynamic>)['fazendaId'];
      }

      Map<String, dynamic> data = {
        'id': pesagem.id,
        'talhaoId': pesagem.talhaoId,
        'fazendaId': fazendaId,
        'dataPesagem': Timestamp.fromDate(pesagem.dataPesagem),
        'pesoBruto': pesagem.pesoBruto,
        'tara': pesagem.tara,
        'pesoLiquido': pesagem.pesoLiquido,
        'observacoes': pesagem.observacoes,
        'clienteId': clienteId,
        'dataCriacao': Timestamp.fromDate(DateTime.now()),
        'dataUltimaModificacao': Timestamp.fromDate(DateTime.now()),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await _firestore.collection('pesagens').doc(pesagem.id).set(data);
      print('✅ Pesagem inserida no Firebase: ${pesagem.id}');

    } catch (e) {
      print('❌ Erro ao inserir pesagem: $e');
      throw e;
    }
  }

  Future<void> updatePesagem(Pesagem pesagem) async {
    try {
      await _firestore.collection('pesagens').doc(pesagem.id).update({
        'pesoBruto': pesagem.pesoBruto,
        'tara': pesagem.tara,
        'pesoLiquido': pesagem.pesoLiquido,
        'observacoes': pesagem.observacoes,
        'dataUltimaModificacao': Timestamp.fromDate(DateTime.now()),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('✅ Pesagem atualizada no Firebase: ${pesagem.id}');
    } catch (e) {
      print('❌ Erro ao atualizar pesagem: $e');
      throw e;
    }
  }

  Future<void> deletePesagem(String id) async {
    try {
      await _firestore.collection('pesagens').doc(id).delete();
      print('✅ Pesagem deletada do Firebase: $id');
    } catch (e) {
      print('❌ Erro ao deletar pesagem: $e');
      throw e;
    }
  }

  // ===== CRUD FAZENDAS =====
  Future<void> insertFazenda(Fazenda fazenda) async {
    try {
      Map<String, dynamic> data = {
        'id': fazenda.id,
        'nome': fazenda.nome,
        'localizacao': fazenda.localizacao,
        'adminId': fazenda.adminId,
        'clienteId': fazenda.clienteId ?? _defaultClienteId,
        'dataCriacao': Timestamp.fromDate(fazenda.dataCriacao),
        'dataUltimaModificacao': Timestamp.fromDate(fazenda.dataUltimaModificacao),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await _firestore.collection('fazendas').doc(fazenda.id).set(data);
      clearCache();
      print('✅ Fazenda inserida: ${fazenda.nome}');
    } catch (e) {
      print('❌ Erro ao inserir fazenda: $e');
      throw e;
    }
  }

  Future<void> updateFazenda(Fazenda fazenda) async {
    try {
      await _firestore.collection('fazendas').doc(fazenda.id).update({
        'nome': fazenda.nome,
        'localizacao': fazenda.localizacao,
        'dataUltimaModificacao': Timestamp.fromDate(DateTime.now()),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      clearCache();
      print('✅ Fazenda atualizada: ${fazenda.nome}');
    } catch (e) {
      print('❌ Erro ao atualizar fazenda: $e');
      throw e;
    }
  }

  Future<void> deleteFazenda(String id) async {
    try {
      await _firestore.collection('fazendas').doc(id).delete();
      clearCache();
      print('✅ Fazenda deletada: $id');
    } catch (e) {
      print('❌ Erro ao deletar fazenda: $e');
      throw e;
    }
  }

  // ===== CRUD TALHÕES =====
  Future<void> insertTalhao(Talhao talhao) async {
    try {
      Map<String, dynamic> data = {
        'id': talhao.id,
        'fazendaId': talhao.fazendaId,
        'nome': talhao.nome,
        'area': talhao.area,
        'localizacao': talhao.localizacao,
        'adminId': talhao.adminId,
        'clienteId': talhao.clienteId ?? _defaultClienteId,
        'dataCriacao': Timestamp.fromDate(talhao.dataCriacao),
        'dataUltimaModificacao': Timestamp.fromDate(talhao.dataUltimaModificacao),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await _firestore.collection('talhoes').doc(talhao.id).set(data);
      clearCache();
      print('✅ Talhão inserido: ${talhao.nome}');
    } catch (e) {
      print('❌ Erro ao inserir talhão: $e');
      throw e;
    }
  }

  Future<void> updateTalhao(Talhao talhao) async {
    try {
      await _firestore.collection('talhoes').doc(talhao.id).update({
        'nome': talhao.nome,
        'area': talhao.area,
        'localizacao': talhao.localizacao,
        'dataUltimaModificacao': Timestamp.fromDate(DateTime.now()),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      clearCache();
      print('✅ Talhão atualizado: ${talhao.nome}');
    } catch (e) {
      print('❌ Erro ao atualizar talhão: $e');
      throw e;
    }
  }

  Future<void> deleteTalhao(String id) async {
    try {
      await _firestore.collection('talhoes').doc(id).delete();
      clearCache();
      print('✅ Talhão deletado: $id');
    } catch (e) {
      print('❌ Erro ao deletar talhão: $e');
      throw e;
    }
  }

  // ===== CRUD TARAS =====
  Future<void> insertTaraPersonalizada(TaraPersonalizada tara) async {
    try {
      Map<String, dynamic> data = {
        'id': tara.id,
        'nome': tara.nome,
        'valorTara': tara.valorTara,
        'dataCriacao': Timestamp.fromDate(tara.dataCriacao),
        'ultimoUso': Timestamp.fromDate(tara.ultimoUso),
        'quantidadeUsos': tara.quantidadeUsos,
        'ativo': tara.ativo,
        'observacoes': tara.observacoes,
        'clienteId': tara.clienteId ?? _defaultClienteId,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await _firestore.collection('taras_personalizadas').doc(tara.id).set(data);
      clearCache();
      print('✅ Tara inserida: ${tara.nome}');
    } catch (e) {
      print('❌ Erro ao inserir tara: $e');
      throw e;
    }
  }

  Future<void> updateTaraPersonalizada(TaraPersonalizada tara) async {
    try {
      await _firestore.collection('taras_personalizadas').doc(tara.id).update({
        'nome': tara.nome,
        'valorTara': tara.valorTara,
        'observacoes': tara.observacoes,
        'ultimoUso': Timestamp.fromDate(DateTime.now()),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      clearCache();
      print('✅ Tara atualizada: ${tara.nome}');
    } catch (e) {
      print('❌ Erro ao atualizar tara: $e');
      throw e;
    }
  }

  Future<void> deleteTaraPersonalizada(String id) async {
    try {
      await _firestore.collection('taras_personalizadas').doc(id).update({
        'ativo': false,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      clearCache();
      print('✅ Tara desativada: $id');
    } catch (e) {
      print('❌ Erro ao deletar tara: $e');
      throw e;
    }
  }

  // ===== ADMIN =====
  Future<Admin?> getAdminById(String id) async {
    return null;
  }

  Future<Admin?> getAdminByUsername(String username) async {
    return null;
  }

  Future<void> insertAdmin(Admin admin) async {
    print('✅ Admin mock inserido: ${admin.username}');
  }

  Future<void> updateAdmin(Admin admin) async {
    print('✅ Admin mock atualizado: ${admin.username}');
  }
}