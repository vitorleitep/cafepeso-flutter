import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../models/pesagem.dart';
import 'fazendas_screen.dart';
import 'talhoes_screen.dart';
import 'pesagens_screen.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DatabaseService _db = DatabaseService();

  int _totalFazendas = 0;
  int _totalTalhoes = 0;
  int _pesagensHoje = 0;
  double _totalMes = 0;
  List<Pesagem> _ultimasPesagens = [];
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    setState(() => _carregando = true);

    final fazendas = await _db.getFazendas();
    final talhoes = await _db.getTalhoes();
    final pesagensHoje = await _db.getPesagensHoje();
    final totalMes = await _db.getTotalMes();
    final todasPesagens = await _db.getPesagens();

    setState(() {
      _totalFazendas = fazendas.length;
      _totalTalhoes = talhoes.length;
      _pesagensHoje = pesagensHoje.length;
      _totalMes = totalMes;
      _ultimasPesagens = todasPesagens.take(3).toList();
      _carregando = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('CafePeso'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _carregarDados,
          ),
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => LoginScreen()),
              );
            },
          ),
        ],
      ),
      drawer: _buildDrawer(context),
      body: _carregando
          ? Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: _carregarDados,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Olá, Admin!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 20),

              // Cards de resumo
              GridView.count(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  _buildCard(
                    'Fazendas',
                    '$_totalFazendas',
                    Icons.landscape,
                    Colors.green,
                  ),
                  _buildCard(
                    'Talhões',
                    '$_totalTalhoes',
                    Icons.grid_on,
                    Colors.blue,
                  ),
                  _buildCard(
                    'Pesagens Hoje',
                    '$_pesagensHoje',
                    Icons.scale,
                    Colors.orange,
                  ),
                  _buildCard(
                    'Total Mês',
                    '${_totalMes.toStringAsFixed(1)} kg',
                    Icons.analytics,
                    Colors.purple,
                  ),
                ],
              ),

              SizedBox(height: 30),

              Text(
                'Últimas Pesagens',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

              SizedBox(height: 10),

              if (_ultimasPesagens.isEmpty)
                Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.brown[100],
                      child: Icon(Icons.coffee, color: Colors.brown[700]),
                    ),
                    title: Text('Nenhuma pesagem'),
                    subtitle: Text('Adicione pesagens no menu'),
                  ),
                )
              else
                ..._ultimasPesagens.map((pesagem) => Card(
                  margin: EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.orange[100],
                      child: Icon(
                        Icons.scale,
                        color: Colors.orange[700],
                      ),
                    ),
                    title: Text(pesagem.nomeTalhao ?? 'Talhão'),
                    subtitle: Text(
                      '${pesagem.pesoLiquido} kg - ${pesagem.nomeFazenda ?? ''}',
                    ),
                    trailing: Text(
                      pesagem.dataFormatada,
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                )).toList(),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => PesagensScreen()),
          ).then((_) => _carregarDados());
        },
        backgroundColor: Colors.brown[700],
        icon: Icon(Icons.add),
        label: Text('Nova Pesagem'),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: Colors.brown[700]),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.coffee, size: 60, color: Colors.white),
                SizedBox(height: 10),
                Text(
                  'CafePeso',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'admin@cafepeso.com',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
          ListTile(
            leading: Icon(Icons.home),
            title: Text('Início'),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: Icon(Icons.landscape),
            title: Text('Fazendas'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => FazendasScreen()),
              ).then((_) => _carregarDados());
            },
          ),
          ListTile(
            leading: Icon(Icons.grid_on),
            title: Text('Talhões'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => TalhoesScreen()),
              ).then((_) => _carregarDados());
            },
          ),
          ListTile(
            leading: Icon(Icons.scale),
            title: Text('Pesagens'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => PesagensScreen()),
              ).then((_) => _carregarDados());
            },
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.exit_to_app, color: Colors.red),
            title: Text('Sair', style: TextStyle(color: Colors.red)),
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => LoginScreen()),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: color),
            SizedBox(height: 10),
            Text(
              title,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 5),
            FittedBox(
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}