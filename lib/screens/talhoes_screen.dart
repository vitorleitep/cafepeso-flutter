import 'package:flutter/material.dart';
import '../models/talhao.dart';
import '../models/fazenda.dart';
import '../services/database_service.dart';
import 'package:uuid/uuid.dart';

class TalhoesScreen extends StatefulWidget {
  @override
  _TalhoesScreenState createState() => _TalhoesScreenState();
}

class _TalhoesScreenState extends State<TalhoesScreen> {
  final DatabaseService _databaseService = DatabaseService();
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
    final talhoes = await _databaseService.getTalhoes();
    final fazendas = await _databaseService.getFazendas();
    setState(() {
      _talhoes = talhoes;
      _fazendas = fazendas;
      _carregando = false;
    });
  }

  Future<void> _mostrarDialogoNovoTalhao() async {
    if (_fazendas.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cadastre uma fazenda primeiro!'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final nomeController = TextEditingController();
    final areaController = TextEditingController();
    String? fazendaSelecionada = _fazendas.first.id;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Novo Talhão'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nomeController,
                decoration: InputDecoration(
                  labelText: 'Nome do Talhão',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: fazendaSelecionada,
                decoration: InputDecoration(
                  labelText: 'Fazenda',
                  border: OutlineInputBorder(),
                ),
                items: _fazendas.map((fazenda) {
                  return DropdownMenuItem(
                    value: fazenda.id,
                    child: Text(fazenda.nome),
                  );
                }).toList(),
                onChanged: (value) {
                  fazendaSelecionada = value;
                },
              ),
              SizedBox(height: 16),
              TextField(
                controller: areaController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Área (hectares)',
                  border: OutlineInputBorder(),
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
              if (nomeController.text.isNotEmpty &&
                  fazendaSelecionada != null) {
                final novoTalhao = Talhao(
                  id: Uuid().v4(),
                  nome: nomeController.text,
                  fazendaId: fazendaSelecionada!,
                  area: double.tryParse(areaController.text),
                );
                await _databaseService.insertTalhao(novoTalhao);
                Navigator.pop(context);
                _carregarDados();

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Talhão adicionado com sucesso!')),
                );
              }
            },
            child: Text('Salvar'),
          ),
        ],
      ),
    );
  }

  Future<void> _deletarTalhao(Talhao talhao) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirmar Exclusão'),
        content: Text('Deseja realmente excluir ${talhao.nome}?'),
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
      await _databaseService.deleteTalhao(talhao.id!);
      _carregarDados();

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('${talhao.nome} foi excluído!')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Talhões', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.brown[700],
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: _carregando
          ? Center(child: CircularProgressIndicator())
          : _talhoes.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.grid_on, size: 100, color: Colors.grey[400]),
                  SizedBox(height: 16),
                  Text(
                    'Nenhum talhão cadastrado',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: _talhoes.length,
              itemBuilder: (context, index) {
                final talhao = _talhoes[index];
                return Card(
                  elevation: 4,
                  margin: EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.blue[100],
                      child: Icon(Icons.grid_on, color: Colors.blue[700]),
                    ),
                    title: Text(
                      talhao.nome,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(talhao.fazendaNome ?? 'Sem fazenda'),
                        if (talhao.area != null)
                          Text('${talhao.area} hectares'),
                      ],
                    ),
                    trailing: IconButton(
                      icon: Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deletarTalhao(talhao),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _mostrarDialogoNovoTalhao,
        backgroundColor: Colors.brown[700],
        child: Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
