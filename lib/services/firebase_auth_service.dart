import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/admin.dart';
import '../models/enums/tipo_usuario.dart';
import '../models/enums/nivel_hierarquia.dart';

class FirebaseAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static final FirebaseAuthService _instance = FirebaseAuthService._internal();
  factory FirebaseAuthService() => _instance;
  FirebaseAuthService._internal();

  User? get currentUser => _auth.currentUser;
  String? get currentUserId => _auth.currentUser?.uid;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Login com email e senha (IGUAL AO ANDROID)
  Future<Admin?> signInWithEmailPassword(String email, String password) async {
    try {
      print('🔐 Tentando login no Firebase Auth...');
      print('   Email: $email');

      // Fazer login no Firebase Auth
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        print('✅ Login bem-sucedido no Firebase Auth!');
        print('   UID: ${credential.user!.uid}');

        // Buscar dados adicionais do Firestore
        final userData = await _firestore
            .collection('usuarios')
            .doc(credential.user!.uid)
            .get();

        if (userData.exists) {
          final data = userData.data()!;
          print('✅ Dados do usuário encontrados no Firestore');

          // Criar objeto Admin com os dados
          return Admin(
            id: credential.user!.uid,
            username: data['username'] ?? email.split('@')[0],
            email: email,
            passwordHash: '', // Não precisamos mais
            nome: data['nome'] ?? 'Usuário',
            tipoUsuario: _getTipoUsuario(data['tipoUsuario']),
            nivelHierarquia: _getNivelHierarquia(data['nivelHierarquia']),
            clienteId: data['clienteId'],
            ativo: data['ativo'] ?? true,
          );
        } else {
          print('⚠️ Usuário não encontrado no Firestore, criando dados básicos...');
          return Admin(
            id: credential.user!.uid,
            username: email.split('@')[0],
            email: email,
            passwordHash: '',
            nome: email.split('@')[0],
            tipoUsuario: TipoUsuario.OPERACIONAL,
            nivelHierarquia: NivelHierarquia.OPERACIONAL,
            clienteId: credential.user!.uid,
          );
        }
      }

      return null;
    } on FirebaseAuthException catch (e) {
      print('❌ Erro Firebase Auth: ${e.code} - ${e.message}');
      if (e.code == 'user-not-found') {
        print('   Usuário não encontrado no Firebase Auth');
      } else if (e.code == 'wrong-password') {
        print('   Senha incorreta');
      } else if (e.code == 'invalid-credential') {
        print('   Credenciais inválidas');
      }
      return null;
    } catch (e) {
      print('❌ Erro no login: $e');
      return null;
    }
  }

  // Login com username (IGUAL AO ANDROID - busca o email primeiro)
  Future<Admin?> signInWithUsername(String username, String password) async {
    try {
      print('🔍 Buscando email do username: $username');

      // Buscar o email pelo username no Firestore
      final query = await _firestore
          .collection('usuarios')
          .where('username', isEqualTo: username)
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        print('❌ Username não encontrado no Firestore');

        // Tentar buscar sem filtro para debug
        print('🔍 Listando todos os usuários para debug:');
        final todosUsuarios = await _firestore.collection('usuarios').get();
        for (var doc in todosUsuarios.docs) {
          final data = doc.data();
          print('   - Username: ${data['username']}, Email: ${data['email']}');
        }

        return null;
      }

      final userData = query.docs.first.data();
      final email = userData['email'];

      if (email == null || email.isEmpty) {
        print('❌ Email não encontrado para o username');
        return null;
      }

      print('✅ Email encontrado: $email');

      // Fazer login com o email encontrado
      return signInWithEmailPassword(email, password);

    } catch (e) {
      print('❌ Erro ao buscar username: $e');
      return null;
    }
  }

  // Logout
  Future<void> signOut() async {
    await _auth.signOut();
    print('👋 Logout realizado');
  }

  // Helpers
  TipoUsuario _getTipoUsuario(String? tipo) {
    if (tipo == null) return TipoUsuario.OPERACIONAL;
    try {
      return TipoUsuario.values.firstWhere((e) => e.name == tipo);
    } catch (e) {
      return TipoUsuario.OPERACIONAL;
    }
  }

  NivelHierarquia _getNivelHierarquia(String? nivel) {
    if (nivel == null) return NivelHierarquia.OPERACIONAL;
    try {
      return NivelHierarquia.values.firstWhere((e) => e.name == nivel);
    } catch (e) {
      return NivelHierarquia.OPERACIONAL;
    }
  }
}