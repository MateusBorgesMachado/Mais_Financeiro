import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';
import '../../user.dart';
import 'supabase_service.dart';

class AuthService {
  static AuthService? _instance;
  static AuthService get instance {
    _instance ??= AuthService._();
    return _instance!;
  }

  AuthService._();

  User? _currentUser;
  User? get currentUser => _currentUser;

  static const String _userKey = 'current_user';

  // Hash da senha usando SHA-256
  String _hashPassword(String password) {
    var bytes = utf8.encode(password);
    var digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Salvar usuário logado no SharedPreferences
  Future<void> _saveUser(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(user.toMap()));
    _currentUser = user;
  }

  // Carregar usuário logado do SharedPreferences
  Future<User?> loadSavedUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(_userKey);

    if (userJson != null) {
      try {
        final userMap = jsonDecode(userJson);
        _currentUser = User.fromMap(userMap);
        return _currentUser;
      } catch (e) {
        print('Erro ao carregar usuário salvo: $e');
        await clearSavedUser(); // Limpa dados corrompidos
      }
    }

    return null;
  }

  // Limpar usuário salvo
  Future<void> clearSavedUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
    _currentUser = null;
  }

  // Cadastrar novo usuário
  Future<User> register({
    required String nome,
    required String email,
    required String senha,
  }) async {
    try {
      // Verificar se o email já existe
      final existingUsers = await SupabaseService.client
          .from('usuarios')
          .select()
          .eq('email', email.toLowerCase());

      if (existingUsers.isNotEmpty) {
        throw Exception('Este email já está em uso');
      }

      // Criar novo usuário com senha hasheada
      final senhaHash = _hashPassword(senha);
      print('DEBUG CADASTRO: Email: ${email.toLowerCase().trim()}');
      print('DEBUG CADASTRO: Hash da senha: $senhaHash');

      final user = User(
        nome: nome.trim(),
        email: email.toLowerCase().trim(),
        senha: senhaHash,
      );

      // Inserir no banco de dados
      await SupabaseService.client.from('usuarios').insert(user.toMap());

      // Salvar usuário logado
      await _saveUser(user);

      return user;
    } catch (e) {
      throw Exception('Erro ao cadastrar usuário: $e');
    }
  }

  // Fazer login
  Future<User> login({required String email, required String senha}) async {
    try {
      print('DEBUG LOGIN: Tentando fazer login com email: $email');

      // Buscar usuário por email
      final emailLower = email.toLowerCase().trim();
      print('DEBUG LOGIN: Buscando usuário com email normalizado: $emailLower');

      final response = await SupabaseService.client
          .from('usuarios')
          .select()
          .eq('email', emailLower)
          .maybeSingle();

      print('DEBUG LOGIN: Resposta do Supabase: $response');

      if (response == null) {
        print('DEBUG LOGIN: Nenhum usuário encontrado com este email');
        throw Exception('Email não encontrado');
      }

      print(
        'DEBUG LOGIN: Usuário encontrado: ${response['nome']} (${response['email']})',
      );
      final user = User.fromMap(response);

      // Verificar senha
      final senhaHash = _hashPassword(senha);
      print('DEBUG LOGIN: Hash da senha fornecida: $senhaHash');
      print('DEBUG LOGIN: Hash da senha no BD: ${user.senha}');

      if (user.senha != senhaHash) {
        print('DEBUG LOGIN: Senhas não coincidem!');
        throw Exception('Senha incorreta');
      }

      print('DEBUG LOGIN: Login bem-sucedido!');
      // Salvar usuário logado
      await _saveUser(user);

      return user;
    } catch (e) {
      print('DEBUG LOGIN: Erro durante login: $e');
      throw Exception('Erro ao fazer login: $e');
    }
  }

  // Logout
  Future<void> logout() async {
    await clearSavedUser();
  }

  // Verificar se há usuário logado
  bool get isLoggedIn => _currentUser != null;

  // Atualizar dados do usuário
  Future<User> updateUser({
    String? nome,
    String? email,
    String? novaSenha,
  }) async {
    if (_currentUser == null) {
      throw Exception('Usuário não está logado');
    }

    try {
      Map<String, dynamic> updates = {};

      if (nome != null && nome.trim().isNotEmpty) {
        updates['nome'] = nome.trim();
      }

      if (email != null && email.trim().isNotEmpty) {
        updates['email'] = email.toLowerCase().trim();
      }

      if (novaSenha != null && novaSenha.isNotEmpty) {
        updates['senha'] = _hashPassword(novaSenha);
      }

      if (updates.isEmpty) {
        return _currentUser!;
      }

      // Atualizar no banco de dados
      final response = await SupabaseService.client
          .from('usuarios')
          .update(updates)
          .eq('id', _currentUser!.id)
          .select()
          .single();

      final updatedUser = User.fromMap(response);
      await _saveUser(updatedUser);

      return updatedUser;
    } catch (e) {
      throw Exception('Erro ao atualizar usuário: $e');
    }
  }

  // Validar email
  bool isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  // Validar senha (mínimo 6 caracteres)
  bool isValidPassword(String password) {
    return password.length >= 6;
  }
}
