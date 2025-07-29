class Constants {
  // Database
  static const String databaseName = 'cafepeso.db';
  static const int databaseVersion = 1;

  // Collections Firebase
  static const String usuariosCollection = 'usuarios';
  static const String fazendasCollection = 'fazendas';
  static const String talhoesCollection = 'talhoes';
  static const String pesagensCascaCollection = 'pesagens_casca';
  static const String pesagensLimpoCollection = 'pesagens_limpo';
  static const String medidasCollection = 'medidas';

  // Shared Preferences Keys
  static const String adminIdKey = 'admin_id';
  static const String adminUsernameKey = 'admin_username';
  static const String loginTypeKey = 'login_type';
  static const String clienteIdKey = 'cliente_id';

  // Sync
  static const int syncIntervalSeconds = 30;
}