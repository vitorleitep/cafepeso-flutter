import 'package:flutter/material.dart';
import '../models/tara_personalizada.dart';
import '../services/database_service.dart';
import 'package:uuid/uuid.dart';

class TarasScreen extends StatefulWidget {
  @override
  _TarasScreenState createState() => _TarasScreenState();
}

class _TarasScreenState extends State<TarasScreen> {
  final DatabaseService _databaseService = DatabaseService();
  List<TaraPersonalizada> _taras = [];
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _carregarTaras();
  }

  Future<void> _carregarTaras() async {
    setState(() => _carregando = true);
    try {
      final taras = await _databaseService.getTarasPersonalizadas();
      setState(() {
        _taras = taras;
        _carregando = false;
      });
    } catch (e) {
      print('Erro ao carregar taras: $e');
      setState(() => _carregando = false);
    }
  }

  void _adicionarTara() {
    final nomeController = TextEditingController();
    final valorController = TextEditingController();
    final observacoesController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Nova Tara Personalizada'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nomeController,
              decoration: InputDecoration(
                labelText: 'Nome da Tara',
                hintText: 'Ex: Saco Grande',
              ),
              autofocus: true,
            ),
            SizedBox(height: 16),
            TextField(
              controller: valorController,
              decoration: InputDecoration(
                labelText: 'Peso (kg)',
                hintText: 'Ex: 0.850',
              ),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
            ),
            SizedBox(height: 16),
            TextField(
              controller: observacoesController,
              decoration: InputDecoration(
                labelText: 'Observações (opcional)',
                hintText: 'Ex: Saco de ráfia padrão',
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final nome = nomeController.text.trim();
              final valorText = valorController.text.trim().replaceAll(',', '.');
              final observacoes = observacoesController.text.trim();

              if (nome.isEmpty || valorText.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Preencha o nome e o peso')),
                );
                return;
              }

              final valor = double.tryParse(valorText);
              if (valor == null || valor <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Peso inválido')),
                );
                return;
              }

              Navigator.pop(context);

              final novaTara = TaraPersonalizada(
                id: Uuid().v4(),
                nome: nome,
                valorTara: valor,
                observacoes: observacoes.isEmpty ? null : observacoes,
                clienteId: 'F7Tnzw1sujZFb3MKTSQNyE2dtxI3',
              );

              await _salvarTara(novaTara);
            },
            child: Text('Salvar'),
          ),
        ],
      ),
    );
  }

  Future<void> _salvarTara(TaraPersonalizada tara) async {
    try {
      await _databaseService.insertTaraPersonalizada(tara);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Tara salva com sucesso!')),
      );
      _carregarTaras();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao salvar tara: $e')),
      );
    }
  }

  void _editarTara(TaraPersonalizada tara) {
    final nomeController = TextEditingController(text: tara.nome);
    final valorController = TextEditingController(text: tara.valorTara.toString());
    final observacoesController = TextEditingController(text: tara.observacoes ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Editar Tara'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nomeController,
              decoration: InputDecoration(labelText: 'Nome da Tara'),
            ),
            SizedBox(height: 16),
            TextField(
              controller: valorController,
              decoration: InputDecoration(labelText: 'Peso (kg)'),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
            ),
            SizedBox(height: 16),
            TextField(
              controller: observacoesController,
              decoration: InputDecoration(labelText: 'Observações'),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final nome = nomeController.text.trim();
              final valorText = valorController.text.trim().replaceAll(',', '.');
              final valor = double.tryParse(valorText);

              if (nome.isEmpty || valor == null || valor <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Dados inválidos')),
                );
                return;
              }

              Navigator.pop(context);

              final taraAtualizada = TaraPersonalizada(
                id: tara.id,
                nome: nome,
                valorTara: valor,
                observacoes: observacoesController.text.trim(),
                dataCriacao: tara.dataCriacao,
                ultimoUso: tara.ultimoUso,
                quantidadeUsos: tara.quantidadeUsos,
                ativo: tara.ativo,
                clienteId: tara.clienteId,
              );

              await _databaseService.updateTaraPersonalizada(taraAtualizada);
              _carregarTaras();
            },
            child: Text('Salvar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Taras Personalizadas'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _carregarTaras,
          ),
        ],
      ),
      body: _carregando
          ? Center(child: CircularProgressIndicator())
          : _taras.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Nenhuma tara cadastrada',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _adicionarTara,
              icon: Icon(Icons.add),
              label: Text('Adicionar Primeira Tara'),
            ),
          ],
        ),
      )
          : ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: _taras.length,
        itemBuilder: (context, index) {
          final tara = _taras[index];
          return Card(
            margin: EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.blue[100],
                child: Text(
                  tara.valorTara.toStringAsFixed(3),
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
              title: Text(tara.nome),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${tara.pesoFormatado} • Usado ${tara.quantidadeUsos}x'),
                  if (tara.observacoes != null)
                    Text(
                      tara.observacoes!,
                      style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                    ),
                ],
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.edit, color: Colors.blue),
                    onPressed: () => _editarTara(tara),
                  ),
                  IconButton(
                    icon: Icon(Icons.delete, color: Colors.red),
                    onPressed: () async {
                      final confirmar = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text('Confirmar exclusão'),
                          content: Text('Deseja excluir a tara "${tara.nome}"?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: Text('Cancelar'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: Text('Excluir', style: TextStyle(color: Colors.red)),
                            ),
                          ],
                        ),
                      );

                      if (confirmar == true) {
                        await _databaseService.deleteTaraPersonalizada(tara.id);
                        _carregarTaras();
                      }
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _adicionarTara,
        icon: Icon(Icons.add),
        label: Text('Nova Tara'),
      ),
    );
  }
}