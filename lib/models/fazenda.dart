import 'enums/sync_status.dart';

class Fazenda {
  final String id;
  final String nome;
  final String? localizacao;
  final String? adminId;
  final String? clienteId;
  final DateTime dataCriacao;
  final DateTime dataUltimaModificacao;
  final SyncStatus syncStatus;
  final DateTime? lastSync;
  final String? firebaseId;

  Fazenda({
    required this.id,
    required this.nome,
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

  @override
  String toString() => nome;
}