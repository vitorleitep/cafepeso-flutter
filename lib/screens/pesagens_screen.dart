import 'package:flutter/material.dart';
import '../models/pesagem.dart';
import '../models/talhao.dart';
import '../models/fazenda.dart';
import '../services/database_service.dart';
import 'package:uuid/uuid.dart';

class PesagensScreen extends StatefulWidget {
  @override
  _PesagensScreenState createState() => _PesagensScreenState();
}

class _PesagensScreenState extends State<PesagensScreen> {
  final DatabaseService _databaseService = DatabaseService();
  List<Pesagem> _pesagens = [];
  List<Talhao> _talhoes = [];
  List<Fazenda> _fazendas = [];
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    setState(() => _carregando = true);

    final pesagens = await _databaseService.getPesagens();
    final talhoes = await _databaseService.getTalhoes();
    final fazendas = await _databaseService.getFazendas();

    setState(() {
      _pesagens = pesagens;
      _talhoes = talhoes;
      _fazendas = fazendas;
      _carregando = false;
    });
  }

  Future<void> _mostrarDialogoNovaPesagem() async {
    if (_talhoes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cadastre um talhão primeiro!'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final pesoBrutoController = TextEditingController();
    final taraController = TextEditingController();
    final observacoesController = TextEditingController();
    String? talhaoSelecionado = _talhoes.first.id;
    DateTime dataSelecionada = DateTime.now();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Nova Pesagem'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Seleção de Talhão
              DropdownButtonFormField<String>(
                value: talhaoSelecionado,
                decoration: InputDecoration(
                  labelText: 'Talhão',
                  border: OutlineInputBorder(),
                ),
                items: _talhoes.map((talhao) {
                  final fazenda = _fazendas.firstWhere(
                        (f) => f.id == talhao.fazendaId,
                    orElse: () => Fazenda(nome: 'Sem fazenda', id: ''),
                  );
                  return DropdownMenuItem(
                    value: talhao.id,
                    child: Text('${talhao.nome} - ${fazenda.nome}'),
                  );
                }).toList(),
                onChanged: (value) {
                  talhaoSelecionado = value;
                },
              ),
              SizedBox(height: 16),

              // Peso Bruto
              TextField(
                controller: pesoBrutoController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Peso Bruto (kg)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.scale),
                ),
              ),
              SizedBox(height: 16),

              // Tara
              TextField(
                controller: taraController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Tara (kg)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.remove_circle_outline),
                ),
              ),
              SizedBox(height: 16),

              // Data da Pesagem
              ListTile(
                title: Text('Data da Pesagem'),
                subtitle: Text(
                  '${dataSelecionada.day}/${dataSelecionada.month}/${dataSelecionada.year}',
                ),
                trailing: Icon(Icons.calendar_today),
                onTap: () async {
                  final data = await showDatePicker(
                    context: context,
                    initialDate: dataSelecionada,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (data != null) {
                    setState(() {
                      dataSelecionada = data;
                    });
                  }
                },
              ),
              SizedBox(height: 16),

              // Observações
              TextField(
                controller: observacoesController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Observações (opcional)',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final pesoBruto = double.tryParse(pesoBrutoController.text) ?? 0;
              final tara = double.tryParse(taraController.text) ?? 0;

              if (pesoBruto > 0 && tara >= 0 && talhaoSelecionado != null) {
                // Buscar fazendaId do talhão
                final talhao = _talhoes.firstWhere((t) => t.id == talhaoSelecionado);

                final novaPesagem = Pesagem(
                  id: Uuid().v4(),
                  talhaoId: talhaoSelecionado!,
                  fazendaId: talhao.fazendaId,
                  pesoBruto: pesoBruto,
                  tara: tara,
                  dataPesagem: dataSelecionada,
                  observacoes: observacoesController.text.isEmpty
                      ? null
                      : observacoesController.text,
                );

                await _databaseService.insertPesagem(novaPesagem);
                Navigator.pop(context);
                _carregarDados();

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Pesagem adicionada! Peso líquido: ${(pesoBruto - tara).toStringAsFixed(2)} kg'),
                    backgroundColor: Colors.green,
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Preencha os campos corretamente!'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.brown[700],
            ),
            child: Text('Salvar'),
          ),
        ],
      ),
    );
  }

  Future<void> _deletarPesagem(Pesagem pesagem) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirmar Exclusão'),
        content: Text('Deseja realmente excluir esta pesagem?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      await _databaseService.deletePesagem(pesagem.id);
      _carregarDados();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Pesagem excluída!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Pesagens'),
        backgroundColor: Colors.brown[700],
        foregroundColor: Colors.white,
      ),
      body: _carregando
          ? Center(child: CircularProgressIndicator())
          : _pesagens.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.scale, size: 100, color: Colors.grey[400]),
            SizedBox(height: 16),
            Text(
              'Nenhuma pesagem cadastrada',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _mostrarDialogoNovaPesagem,
              icon: Icon(Icons.add),
              label: Text('Adicionar Pesagem'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.brown[700],
              ),
            ),
          ],
        ),
      )
          : RefreshIndicator(
        onRefresh: _carregarDados,
        child: ListView.builder(
          padding: EdgeInsets.all(16),
          itemCount: _pesagens.length,
          itemBuilder: (context, index) {
            final pesagem = _pesagens[index];
            return Card(
              elevation: 4,
              margin: EdgeInsets.only(bottom: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  // Mostrar detalhes da pesagem
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text('Detalhes da Pesagem'),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildDetailRow('Talhão', pesagem.nomeTalhao ?? 'Desconhecido'),
                          _buildDetailRow('Fazenda', pesagem.nomeFazenda ?? 'Desconhecida'),
                          _buildDetailRow('Data', pesagem.dataFormatada),
                          Divider(height: 20),
                          _buildDetailRow('Peso Bruto', '${pesagem.pesoBruto.toStringAsFixed(2)} kg'),
                          _buildDetailRow('Tara', '${pesagem.tara.toStringAsFixed(2)} kg'),
                          _buildDetailRow('Peso Líquido', '${pesagem.pesoLiquido.toStringAsFixed(2)} kg',
                              isHighlight: true),
                          if (pesagem.observacoes != null) ...[
                            Divider(height: 20),
                            Text('Observações:', style: TextStyle(fontWeight: FontWeight.bold)),
                            SizedBox(height: 4),
                            Text(pesagem.observacoes!),
                          ],
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text('Fechar'),
                        ),
                      ],
                    ),
                  );
                },
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  pesagem.nomeTalhao ?? 'Talhão',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  pesagem.nomeFazenda ?? 'Fazenda',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deletarPesagem(pesagem),
                          ),
                        ],
                      ),
                      SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${pesagem.pesoLiquido.toStringAsFixed(2)} kg',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.brown[700],
                                ),
                              ),
                              Text(
                                'Peso Líquido',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                pesagem.dataFormatada,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                _getHorario(pesagem.dataPesagem),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      if (pesagem.observacoes != null) ...[
                        SizedBox(height: 8),
                        Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.note, size: 16, color: Colors.grey[600]),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  pesagem.observacoes!,
                                  style: TextStyle(fontSize: 12),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _mostrarDialogoNovaPesagem,
        backgroundColor: Colors.brown[700],
        child: Icon(Icons.add),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isHighlight = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label + ':', style: TextStyle(color: Colors.grey[600])),
          Text(
            value,
            style: TextStyle(
              fontWeight: isHighlight ? FontWeight.bold : FontWeight.normal,
              color: isHighlight ? Colors.brown[700] : null,
              fontSize: isHighlight ? 16 : 14,
            ),
          ),
        ],
      ),
    );
  }

  String _getHorario(DateTime data) {
    return '${data.hour.toString().padLeft(2, '0')}:${data.minute.toString().padLeft(2, '0')}';
  }
}