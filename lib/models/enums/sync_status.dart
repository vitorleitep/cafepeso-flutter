enum SyncStatus {
  pending,   // PENDING no Kotlin
  syncing,   // SYNCING no Kotlin
  synced,    // SYNCED no Kotlin
  error      // ERROR no Kotlin
}

extension SyncStatusExtension on SyncStatus {
  String get name {
    switch (this) {
      case SyncStatus.pending:
        return 'PENDING';
      case SyncStatus.syncing:
        return 'SYNCING';
      case SyncStatus.synced:
        return 'SYNCED';
      case SyncStatus.error:
        return 'ERROR';
    }
  }

  static SyncStatus fromString(String value) {
    switch (value.toUpperCase()) {
      case 'PENDING':
        return SyncStatus.pending;
      case 'SYNCING':
        return SyncStatus.syncing;
      case 'SYNCED':
        return SyncStatus.synced;
      case 'ERROR':
        return SyncStatus.error;
      default:
        return SyncStatus.pending;
    }
  }
}