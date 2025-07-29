import 'enums/sync_status.dart';

class Talhao {
  final String id;
  final String fazendaId;
  final String nome;
  final double? area;
  final String? localizacao;
  final String? adminId;
  final String? clienteId;
  final DateTime dataCriacao;
  final DateTime dataUltimaModificacao;
  final SyncStatus syncStatus;
  final DateTime? lastSync;
  final String? firebaseId;

  String? fazendaNome;

  Talhao({
    required this.id,
    required this.fazendaId,
    required this.nome,
    this.area,
    this.localizacao,
    this.adminId,
    this.clienteId,
    DateTime? dataCriacao,
    DateTime? dataUltimaModificacao,
    this.syncStatus = SyncStatus.pending,
    this.lastSync,
    this.firebaseId,
  }) : dataCriacao = dataCriacao ?? DateTime.now(),
        dataUltimaModificacao = dataUltimaModificacao ?? DateTime.now();

  void setNomeFazenda(String nome) {
    fazendaNome = nome;
  }

  @override
  String toString() => nome;
}