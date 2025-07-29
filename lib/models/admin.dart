import '../utils/id_generator.dart';
import 'enums/sync_status.dart';
import 'enums/tipo_usuario.dart';
import 'enums/nivel_hierarquia.dart';

class Admin {
  final String id;
  final String username;
  final String? email;
  final String passwordHash;
  final String nome;
  final TipoUsuario tipoUsuario;
  final NivelHierarquia nivelHierarquia;
  final String? clienteId;
  final String? adminResponsavelId;
  final String? fazendaId;
  final String? criadoPor;
  final bool ativo;
  final List<String> permissoes;
  final int tentativasLogin;
  final DateTime? bloqueadoAte;
  final String? firebaseId;
  final bool sincronizado;
  final SyncStatus syncStatus;
  final DateTime dataCriacao;
  final DateTime dataUltimaAlteracao;
  final DateTime? ultimoLogin;

  Admin({
    String? id,
    required this.username,
    this.email,
    required this.passwordHash,
    required this.nome,
    required this.tipoUsuario,
    required this.nivelHierarquia,
    this.clienteId,
    this.adminResponsavelId,
    this.fazendaId,
    this.criadoPor,
    this.ativo = true,
    this.permissoes = const [],
    this.tentativasLogin = 0,
    this.bloqueadoAte,
    this.firebaseId,
    this.sincronizado = false,
    this.syncStatus = SyncStatus.pending,
    DateTime? dataCriacao,
    DateTime? dataUltimaAlteracao,
    this.ultimoLogin,
  }) :
        this.id = id ?? IdGenerator.generateId(),
        this.dataCriacao = dataCriacao ?? DateTime.now(),
        this.dataUltimaAlteracao = dataUltimaAlteracao ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'passwordHash': passwordHash,
      'nome': nome,
      'tipoUsuario': tipoUsuario.name,
      'nivelHierarquia': nivelHierarquia.name,
      'clienteId': clienteId,
      'adminResponsavelId': adminResponsavelId,
      'fazendaId': fazendaId,
      'criadoPor': criadoPor,
      'ativo': ativo ? 1 : 0,
      'permissoes': permissoes.join(','),
      'tentativasLogin': tentativasLogin,
      'bloqueadoAte': bloqueadoAte?.toIso8601String(),
      'firebaseId': firebaseId,
      'sincronizado': sincronizado ? 1 : 0,
      'syncStatus': syncStatus.name,
      'dataCriacao': dataCriacao.toIso8601String(),
      'dataUltimaAlteracao': dataUltimaAlteracao.toIso8601String(),
      'ultimoLogin': ultimoLogin?.toIso8601String(),
    };
  }

  factory Admin.fromMap(Map<String, dynamic> map) {
    return Admin(
      id: map['id'] as String,
      username: map['username'] as String,
      email: map['email'] as String?,
      passwordHash: map['passwordHash'] as String,
      nome: map['nome'] as String,
      tipoUsuario: TipoUsuario.values.firstWhere(
            (e) => e.name == map['tipoUsuario'],
        orElse: () => TipoUsuario.OPERACIONAL,
      ),
      nivelHierarquia: NivelHierarquia.values.firstWhere(
            (e) => e.name == map['nivelHierarquia'],
        orElse: () => NivelHierarquia.OPERACIONAL,
      ),
      clienteId: map['clienteId'] as String?,
      adminResponsavelId: map['adminResponsavelId'] as String?,
      fazendaId: map['fazendaId'] as String?,
      criadoPor: map['criadoPor'] as String?,
      ativo: map['ativo'] == 1,
      permissoes: (map['permissoes'] as String?)?.split(',') ?? [],
      tentativasLogin: map['tentativasLogin'] as int? ?? 0,
      bloqueadoAte: map['bloqueadoAte'] != null
          ? DateTime.parse(map['bloqueadoAte'] as String)
          : null,
      firebaseId: map['firebaseId'] as String?,
      sincronizado: map['sincronizado'] == 1,
      syncStatus: SyncStatusExtension.fromString(
          map['syncStatus'] as String? ?? 'PENDING'
      ),
      dataCriacao: DateTime.parse(map['dataCriacao'] as String),
      dataUltimaAlteracao: DateTime.parse(map['dataUltimaAlteracao'] as String),
      ultimoLogin: map['ultimoLogin'] != null
          ? DateTime.parse(map['ultimoLogin'] as String)
          : null,
    );
  }

  static Admin fromFirestore(Map<String, dynamic> data, String id) {
    return Admin(
      id: id,
      username: data['username'] ?? '',
      email: data['email'],
      passwordHash: data['passwordHash'] ?? '',
      nome: data['nome'] ?? '',
      tipoUsuario: TipoUsuario.values.firstWhere(
            (e) => e.name == (data['tipoUsuario'] ?? 'PESADOR'),
        orElse: () => TipoUsuario.PESADOR,
      ),
      nivelHierarquia: NivelHierarquia.values.firstWhere(
            (e) => e.name == (data['nivelHierarquia'] ?? 'OPERACIONAL'),
        orElse: () => NivelHierarquia.OPERACIONAL,
      ),
      clienteId: data['clienteId'],
      adminResponsavelId: data['adminResponsavelId'],
      fazendaId: data['fazendaId'],
      criadoPor: data['criadoPor'],
      ativo: data['ativo'] ?? true,
      permissoes: List<String>.from(data['permissoes'] ?? []),
      firebaseId: id,
      sincronizado: true,
      syncStatus: SyncStatus.synced,
    );
  }

  Admin copyWith({
    String? username,
    String? email,
    String? passwordHash,
    String? nome,
    TipoUsuario? tipoUsuario,
    NivelHierarquia? nivelHierarquia,
    String? clienteId,
    String? adminResponsavelId,
    String? fazendaId,
    String? criadoPor,
    bool? ativo,
    List<String>? permissoes,
    int? tentativasLogin,
    DateTime? bloqueadoAte,
    String? firebaseId,
    bool? sincronizado,
    SyncStatus? syncStatus,
    DateTime? dataUltimaAlteracao,
    DateTime? ultimoLogin,
  }) {
    return Admin(
      id: this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      passwordHash: passwordHash ?? this.passwordHash,
      nome: nome ?? this.nome,
      tipoUsuario: tipoUsuario ?? this.tipoUsuario,
      nivelHierarquia: nivelHierarquia ?? this.nivelHierarquia,
      clienteId: clienteId ?? this.clienteId,
      adminResponsavelId: adminResponsavelId ?? this.adminResponsavelId,
      fazendaId: fazendaId ?? this.fazendaId,
      criadoPor: criadoPor ?? this.criadoPor,
      ativo: ativo ?? this.ativo,
      permissoes: permissoes ?? this.permissoes,
      tentativasLogin: tentativasLogin ?? this.tentativasLogin,
      bloqueadoAte: bloqueadoAte ?? this.bloqueadoAte,
      firebaseId: firebaseId ?? this.firebaseId,
      sincronizado: sincronizado ?? this.sincronizado,
      syncStatus: syncStatus ?? this.syncStatus,
      dataCriacao: this.dataCriacao,
      dataUltimaAlteracao: dataUltimaAlteracao ?? DateTime.now(),
      ultimoLogin: ultimoLogin ?? this.ultimoLogin,
    );
  }

  bool get isSuperAdmin => nivelHierarquia == NivelHierarquia.SUPER_ADMIN;

  bool get isAdminCliente => nivelHierarquia == NivelHierarquia.ADMIN_CLIENTE;

  bool get canManageFazendas =>
      isSuperAdmin ||
          isAdminCliente ||
          permissoes.contains('GERENCIAR_FAZENDAS');
}