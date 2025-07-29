import 'dart:async';
import '../models/enums/sync_status.dart';
import 'database_service.dart';
import 'firebase_service.dart';

class SyncService {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  final DatabaseService _db = DatabaseService();
  final FirebaseService _firebase = FirebaseService();
  Timer? _syncTimer;
  bool _isSyncing = false;

  void startAutoSync() {
    print('🔄 [MOCK] Auto sync iniciado');
  }

  void stopAutoSync() {
    print('⏹️ [MOCK] Auto sync parado');
  }

  Future<bool> isOnline() async {
    return true; // Sempre online no mock
  }

  Future<void> syncAll() async {
    print('🔄 [MOCK] Sincronização geral');
  }

  Future<void> registerChange(String entityType, String entityId, String action) async {
    print('📝 [MOCK] Mudança registrada: $entityType.$action para $entityId');
  }
}