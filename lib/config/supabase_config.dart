/// Configuração do Supabase
///
/// IMPORTANTE: Substitua os valores abaixo pelas suas credenciais do Supabase
///
/// Para obter estas credenciais:
/// 1. Vá para https://supabase.com
/// 2. Crie um novo projeto ou selecione um existente
/// 3. Vá para Settings > API
/// 4. Copie a URL do projeto e a chave anon/public
class SupabaseConfig {
  /// URL do seu projeto Supabase
  /// Exemplo: https://xyzcompany.supabase.co
  static const String supabaseUrl = 'https://fsdmlspamdxyracfcmvp.supabase.co';

  /// Chave pública/anônima do Supabase
  /// Esta chave é segura para ser usada no frontend
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZzZG1sc3BhbWR4eXJhY2ZjbXZwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTgyMzYwMzgsImV4cCI6MjA3MzgxMjAzOH0.O47CWpxcs3FLY6oDlK43Wr6NxGpgOgmotTZpHgAoGEc';

  /// Verificar se as configurações foram definidas
  static bool get isConfigured {
    return supabaseUrl != 'SUPABASE_URL_AQUI' &&
        supabaseAnonKey != 'SUPABASE_ANON_KEY_AQUI' &&
        supabaseUrl.isNotEmpty &&
        supabaseAnonKey.isNotEmpty;
  }
}
