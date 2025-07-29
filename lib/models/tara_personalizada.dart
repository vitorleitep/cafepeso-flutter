import 'enums/sync_status.dart';

class TaraPersonalizada {
  final String id;
  final String nome;
  final double valorTara;
  final DateTime dataCriacao;
  final DateTime ultimoUso;
  final int quantidadeUsos;
  final bool ativo;
  final String? observacoes;
  final String? clienteId;
  final SyncStatus syncStatus;
  final DateTime? lastSync;
  final String? firebaseId;

  TaraPersonalizada({
    required this.id,
    required this.nome,
    required this.valorTara,
    DateTime? dataCriacao,
    DateTime? ultimoUso,
    this.quantidadeUsos = 1,
    this.ativo = true,
    this.observacoes,
    this.clienteId,
    this.syncStatus = SyncStatus.pending,
    this.lastSync,
    this.firebaseId,
  }) : dataCriacao = dataCriacao ?? DateTime.now(),
        ultimoUso = ultimoUso ?? DateTime.now();

  String get textoCompleto => '${valorTara.toStringAsFixed(3)} kg ($nome)';

  String get pesoFormatado => '${valorTara.toStringAsFixed(3)} kg';

  @override
  String toString() => textoCompleto;
}