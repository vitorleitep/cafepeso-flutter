import 'package:flutter/material.dart';
import '../models/fazenda.dart';
import '../services/database_service.dart';
import 'package:uuid/uuid.dart';

class FazendasScreen extends StatefulWidget {
  @override
  _FazendasScreenState createState() => _FazendasScreenState();
}

class _FazendasScreenState extends State<FazendasScreen> {
  final DatabaseService _databaseService = DatabaseService();
  List<Fazenda> _fazendas = [];
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _carregarFazendas();
  }

  Future<void> _carregarFazendas() async {
    setState(() => _carregando = true);
    final fazendas = await _databaseService.getFazendas();
    setState(() {
      _fazendas = fazendas;
      _carregando = false;
    });
  }

  Future<void> _mostrarDialogoNovaFazenda() async {
    final nomeController = TextEditingController();
    final localizacaoController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Nova Fazenda'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nomeController,
              decoration: InputDecoration(
                labelText: 'Nome da Fazenda',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.words,
            ),
            SizedBox(height: 16),
            TextField(
              controller: localizacaoController,
              decoration: InputDecoration(
                labelText: 'Localização (opcional)',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.words,
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
              if (nomeController.text.trim().isNotEmpty) {
                final novaFazenda = Fazenda(
                  id: Uuid().v4(),
                  nome: nomeController.text.trim(),
                  localizacao: localizacaoController.text.trim().isEmpty
                      ? null
                      : localizacaoController.text.trim(),
                );

                await _databaseService.insertFazenda(novaFazenda);
                Navigator.pop(context);
                _carregarFazendas();

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Fazenda adicionada com sucesso!'),
                    backgroundColor: Colors.green,
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

  Future<void> _deletarFazenda(Fazenda fazenda) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirmar Exclusão'),
        content: Text('Deseja realmente excluir ${fazenda.nome}?\n\n'
            'ATENÇÃO: Todos os talhões desta fazenda também serão excluídos!'),
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
      await _databaseService.deleteFazenda(fazenda.id);
      _carregarFazendas();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${fazenda.nome} foi excluída!'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Fazendas'),
        backgroundColor: Colors.brown[700],
        foregroundColor: Colors.white,
      ),
      body: _carregando
          ? Center(child: CircularProgressIndicator())
          : _fazendas.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.landscape, size: 100, color: Colors.grey[400]),
            SizedBox(height: 16),
            Text(
              'Nenhuma fazenda cadastrada',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _mostrarDialogoNovaFazenda,
              icon: Icon(Icons.add),
              label: Text('Adicionar Fazenda'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.brown[700],
              ),
            ),
          ],
        ),
      )
          : RefreshIndicator(
        onRefresh: _carregarFazendas,
        child: ListView.builder(
          padding: EdgeInsets.all(16),
          itemCount: _fazendas.length,
          itemBuilder: (context, index) {
            final fazenda = _fazendas[index];
            return Card(
              elevation: 4,
              margin: EdgeInsets.only(bottom: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.green[100],
                  child: Icon(Icons.landscape, color: Colors.green[700]),
                ),
                title: Text(
                  fazenda.nome,
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(fazenda.localizacao ?? 'Sem localização'),
                trailing: IconButton(
                  icon: Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _deletarFazenda(fazenda),
                ),
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _mostrarDialogoNovaFazenda,
        backgroundColor: Colors.brown[700],
        child: Icon(Icons.add),
      ),
    );
  }
}