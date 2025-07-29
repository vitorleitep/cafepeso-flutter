import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import '../services/firebase_auth_service.dart';
import '../utils/hash_utils.dart';
import '../models/admin.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usuarioController = TextEditingController();
  final _senhaController = TextEditingController();
  final _authService = AuthService();
  final _firebaseAuth = FirebaseAuthService();
  bool _carregando = false;
  bool _senhaVisivel = false;

  @override
  void initState() {
    super.initState();
    // Testar usuários ao iniciar
    _testarUsuarios();
  }

  Future<void> _testarUsuarios() async {
    try {
      print('\n🔍 BUSCANDO USUÁRIOS NO FIREBASE...');
      final usuarios = await FirebaseFirestore.instance
          .collection('usuarios')
          .get();

      print('✅ Total de usuários: ${usuarios.docs.length}');

      if (usuarios.docs.isEmpty) {
        print('⚠️ NENHUM USUÁRIO ENCONTRADO!');
        print('Você precisa adicionar os usuários no Firestore');
        return;
      }

      for (var doc in usuarios.docs) {
        final data = doc.data();
        print('\n👤 Usuário encontrado:');
        print('  ID: ${doc.id}');
        print('  Username: ${data['username'] ?? 'FALTA USERNAME'}');
        print('  Email: ${data['email'] ?? 'FALTA EMAIL'}');
        print('  Nome: ${data['nome'] ?? 'FALTA NOME'}');
        print('  PasswordHash: ${data['passwordHash'] != null ? 'TEM' : 'FALTA'}');
        print('  Ativo: ${data['ativo'] ?? 'FALTA'}');
        print('  ClienteId: ${data['clienteId'] ?? 'FALTA'}');
      }

      print('\n🔐 Info importante:');
      print('  Com Firebase Auth, não precisamos mais do passwordHash!');
      print('  As senhas são gerenciadas pelo Firebase Authentication');

    } catch (e) {
      print('❌ ERRO: $e');
    }
  }

  void _login() async {
    if (_usuarioController.text.isEmpty || _senhaController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Preencha todos os campos')),
      );
      return;
    }

    setState(() => _carregando = true);

    // PEGANDO OS VALORES DOS CAMPOS
    final loginInput = _usuarioController.text.trim();
    final senha = _senhaController.text;

    // DEBUG COMPLETO
    print('\n\n🔍 ========== DEBUG FIREBASE ==========');
    print('1. Tentando login com: $loginInput');

    // Verificar usuários no Firestore
    try {
      print('\n2. Buscando TODOS os usuários...');
      final usuarios = await FirebaseFirestore.instance
          .collection('usuarios')
          .get();

      print('✅ Total de usuários encontrados: ${usuarios.docs.length}');

      for (var doc in usuarios.docs) {
        final data = doc.data();
        print('\n👤 Usuário:');
        print('   ID: ${doc.id}');
        print('   Username: ${data['username'] ?? 'SEM USERNAME'}');
        print('   Email: ${data['email'] ?? 'SEM EMAIL'}');
        print('   Nome: ${data['nome'] ?? 'SEM NOME'}');
      }
    } catch (e) {
      print('❌ ERRO ao buscar usuários: $e');
    }

    print('\n3. Continuando com o login...');
    print('=====================================\n');
    // FIM DO DEBUG

    try {
      print('\n========== TENTATIVA DE LOGIN ==========');
      print('🔐 Input: $loginInput');
      print('🔐 Tipo: ${loginInput.contains('@') ? 'Email' : 'Username'}');

      // Login de teste admin/admin
      if (loginInput == 'admin' && senha == 'admin') {
        print('✅ Login de teste admin/admin');
        await _authService.setCurrentUser(
          'teste123',
          'admin',
          'F7Tnzw1sujZFb3MKTSQNyE2dtxI3',
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomeScreen()),
        );
        return;
      }

      // Login com Firebase Auth
      Admin? admin;

      if (loginInput.contains('@')) {
        // Login com email direto
        print('📧 Tentando login com email...');
        admin = await _firebaseAuth.signInWithEmailPassword(loginInput, senha);
      } else {
        // Login com username (busca o email primeiro)
        print('👤 Tentando login com username...');
        admin = await _firebaseAuth.signInWithUsername(loginInput, senha);
      }

      if (admin != null) {
        print('✅ LOGIN FIREBASE BEM-SUCEDIDO!');
        print('   Nome: ${admin.nome}');
        print('   Email: ${admin.email}');
        print('   ClienteId: ${admin.clienteId}');

        // Salvar no AuthService local
        await _authService.setCurrentUser(
          admin.id,
          admin.username,
          admin.clienteId,
        );

        // Navegar para home
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomeScreen()),
        );
      } else {
        print('❌ Login falhou - usuário ou senha incorretos');
        setState(() => _carregando = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Usuário ou senha incorretos'),
            backgroundColor: Colors.red,
          ),
        );
      }

    } catch (e) {
      print('❌ ERRO NO LOGIN: $e');
      setState(() => _carregando = false);

      String mensagemErro = 'Erro ao fazer login';
      if (e.toString().contains('user-not-found')) {
        mensagemErro = 'Usuário não encontrado no Firebase Auth';
      } else if (e.toString().contains('wrong-password')) {
        mensagemErro = 'Senha incorreta';
      } else if (e.toString().contains('invalid-email')) {
        mensagemErro = 'Email inválido';
      } else if (e.toString().contains('network-request-failed')) {
        mensagemErro = 'Erro de conexão';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(mensagemErro),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 5),
        ),
      );
    }

    print('========================================\n');
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
                          labelText: 'Usuário ou E-mail',
                          hintText: 'Digite seu usuário ou e-mail',
                          prefixIcon: Icon(Icons.person),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        keyboardType: TextInputType.emailAddress,
                      ),
                      SizedBox(height: 16),
                      TextField(
                        controller: _senhaController,
                        obscureText: !_senhaVisivel,
                        decoration: InputDecoration(
                          labelText: 'Senha',
                          prefixIcon: Icon(Icons.lock),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _senhaVisivel ? Icons.visibility_off : Icons.visibility,
                            ),
                            onPressed: () {
                              setState(() {
                                _senhaVisivel = !_senhaVisivel;
                              });
                            },
                          ),
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
                      SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          TextButton.icon(
                            onPressed: () async {
                              await _testarUsuarios();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Verifique o console do navegador!'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            },
                            icon: Icon(Icons.bug_report, size: 20),
                            label: Text('Verificar Usuários'),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.blue,
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () {
                              _usuarioController.text = 'admin';
                              _senhaController.text = 'admin';
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Login de teste preenchido!'),
                                  backgroundColor: Colors.orange,
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            },
                            icon: Icon(Icons.person_add, size: 20),
                            label: Text('Preencher Admin'),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.orange,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.info_outline, size: 16, color: Colors.grey[700]),
                                SizedBox(width: 4),
                                Text(
                                  'Informações de Login',
                                  style: TextStyle(
                                    color: Colors.grey[700],
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            Divider(height: 16),
                            Text(
                              'Login de teste (sempre funciona):',
                              style: TextStyle(
                                color: Colors.grey[700],
                                fontSize: 12,
                              ),
                            ),
                            SizedBox(height: 4),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.green[50],
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: Colors.green[200]!),
                              ),
                              child: Text(
                                'admin / admin',
                                style: TextStyle(
                                  color: Colors.green[800],
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ),
                            SizedBox(height: 12),
                            Text(
                              'Usuários Firebase (configurar no console):',
                              style: TextStyle(
                                color: Colors.grey[700],
                                fontSize: 12,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Use o email e senha cadastrados no Firebase Auth',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 11,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16),
              Text(
                'Pressione F12 para ver o console',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
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