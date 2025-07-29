import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/fazendas_screen.dart';
import 'screens/talhoes_screen.dart';
import 'screens/pesagens_screen.dart';
import 'services/database_service.dart';
import 'services/auth_service.dart';
import 'models/pesagem.dart';
import 'screens/taras_screen.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyBwUxE4LVBBN03hzkPBo44eNJ-HBfUn-sI",
        authDomain: "cafepeso-c9541.firebaseapp.com",
        projectId: "cafepeso-c9541",
        storageBucket: "cafepeso-c9541.firebasestorage.app",
        messagingSenderId: "216060882166",
        appId: "1:216060882166:web:cafepesoweb2024",
      ),
    );
    print('✅ Firebase inicializado com sucesso!');

    // ADICIONE ESTAS LINHAS
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      print('✅ Usuário já logado: ${user.email}');
    } else {
      print('📍 Nenhum usuário logado');
    }

  } catch (e) {
    print('❌ Erro ao inicializar Firebase: $e');
  }

  runApp(CafePesoApp());
}

class CafePesoApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CafePeso',
      theme: ThemeData(
        primarySwatch: Colors.brown,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.brown[700],
          foregroundColor: Colors.white,
          elevation: 4,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.brown[700],
            foregroundColor: Colors.white,
          ),
        ),
      ),
      home: LoginScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usuarioController = TextEditingController();
  final _senhaController = TextEditingController();
  bool _carregando = false;

  void _login() async {
    if (_usuarioController.text.isEmpty || _senhaController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Preencha todos os campos')),
      );
      return;
    }

    setState(() => _carregando = true);

    await Future.delayed(Duration(seconds: 1));

    if (_usuarioController.text == 'admin' && _senhaController.text == 'admin') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomeScreen()),
      );
    } else {
      setState(() => _carregando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Usuário ou senha incorretos')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.brown[50],
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.coffee,
                size: 100,
                color: Colors.brown[700],
              ),
              SizedBox(height: 20),
              Text(
                'CafePeso',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.brown[800],
                ),
              ),
              SizedBox(height: 40),
              Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: _usuarioController,
                        decoration: InputDecoration(
                          labelText: 'Usuário',
                          prefixIcon: Icon(Icons.person),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      SizedBox(height: 16),
                      TextField(
                        controller: _senhaController,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: 'Senha',
                          prefixIcon: Icon(Icons.lock),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onSubmitted: (_) => _login(),
                      ),
                      SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _carregando ? null : _login,
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _carregando
                              ? CircularProgressIndicator(color: Colors.white)
                              : Text(
                            'Entrar',
                            style: TextStyle(fontSize: 18),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _usuarioController.dispose();
    _senhaController.dispose();
    super.dispose();
  }
}

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DatabaseService _databaseService = DatabaseService();

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

    try {
      final fazendas = await _databaseService.getFazendas();
      final talhoes = await _databaseService.getTalhoes();
      final pesagensHoje = await _databaseService.getPesagensHoje();
      final totalMes = await _databaseService.getTotalMes();
      final todasPesagens = await _databaseService.getPesagens();

      setState(() {
        _totalFazendas = fazendas.length;
        _totalTalhoes = talhoes.length;
        _pesagensHoje = pesagensHoje.length;
        _totalMes = totalMes;
        _ultimasPesagens = todasPesagens.take(3).toList();
        _carregando = false;
      });
    } catch (e) {
      print('Erro ao carregar dados: $e');
      setState(() => _carregando = false);
    }
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
                      '${pesagem.pesoLiquido.toStringAsFixed(1)} kg - ${pesagem.nomeFazenda ?? ''}',
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
          ListTile(
            leading: Icon(Icons.inventory_2),
            title: Text('Taras'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => TarasScreen()),
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