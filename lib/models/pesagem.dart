import 'enums/sync_status.dart';

class Pesagem {
  final String id;
  final String talhaoId;
  final String? fazendaId;
  final String? adminId;
  final String? clienteId;
  final DateTime dataPesagem;
  final double pesoBruto;
  final double tara;
  final double pesoLiquido;
  final String? observacoes;
  final SyncStatus syncStatus;
  final DateTime? lastSync;
  final String? firebaseId;

  String? nomeTalhao;
  String? nomeFazenda;

  Pesagem({
    required this.id,
    required this.talhaoId,
    this.fazendaId,
    this.adminId,
    this.clienteId,
    required this.dataPesagem,
    required this.pesoBruto,
    required this.tara,
    double? pesoLiquido,
    this.observacoes,
    this.syncStatus = SyncStatus.pending,
    this.lastSync,
    this.firebaseId,
  }) : pesoLiquido = pesoLiquido ?? (pesoBruto - tara);

  void setNomeTalhao(String nome) {
    nomeTalhao = nome;
  }

  void setNomeFazenda(String nome) {
    nomeFazenda = nome;
  }

  String get dataFormatada {
    return '${dataPesagem.day.toString().padLeft(2, '0')}/${dataPesagem.month.toString().padLeft(2, '0')}/${dataPesagem.year}';
  }
}