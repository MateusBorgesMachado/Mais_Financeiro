import '../../user.dart';
import 'auth_service.dart';

/// Serviço para filtrar dados por usuário de forma segura
class UserFilterService {
  static UserFilterService? _instance;
  static UserFilterService get instance {
    _instance ??= UserFilterService._();
    return _instance!;
  }

  UserFilterService._();

  /// Obter ID do usuário atual ou vazio se não logado
  String get currentUserId {
    final user = AuthService.instance.currentUser;
    return user?.id ?? '';
  }

  /// Verificar se há usuário logado
  bool get isUserLoggedIn {
    return AuthService.instance.currentUser != null;
  }

  /// Obter usuário atual
  User? get currentUser {
    return AuthService.instance.currentUser;
  }

  /// Filtrar uma lista de mapas por user_id
  List<Map<String, dynamic>> filterByUserId(List<Map<String, dynamic>> data) {
    if (!isUserLoggedIn) {
      print('WARNING: Usuário não logado, retornando lista vazia');
      return [];
    }

    final userId = currentUserId;

    return data.where((item) {
      final itemUserId = item['user_id']?.toString() ?? '';

      // Se o item não tem user_id, incluir por compatibilidade (dados antigos)
      if (itemUserId.isEmpty) {
        print(
          'WARNING: Item sem user_id encontrado: ${item['id']} - ${item['nome'] ?? item['descricao']}',
        );
        return true; // Temporariamente incluir dados sem user_id
      }

      // Incluir apenas se pertence ao usuário atual
      return itemUserId == userId;
    }).toList();
  }

  /// Associar user_id a dados novos
  Map<String, dynamic> addUserIdToData(Map<String, dynamic> data) {
    if (!isUserLoggedIn) {
      throw Exception('Usuário deve estar logado para criar dados');
    }

    final updatedData = Map<String, dynamic>.from(data);
    updatedData['user_id'] = currentUserId;

    print('INFO: Dados associados ao usuário $currentUserId');
    return updatedData;
  }

  /// Verificar se dados pertencem ao usuário atual
  bool belongsToCurrentUser(Map<String, dynamic> data) {
    if (!isUserLoggedIn) {
      return false;
    }

    final itemUserId = data['user_id']?.toString() ?? '';

    // Se não tem user_id, considerar como pertencente (compatibilidade)
    if (itemUserId.isEmpty) {
      return true;
    }

    return itemUserId == currentUserId;
  }

  /// Log de debug para isolamento
  void logUserAccess(String operation, String entityType, String entityId) {
    final userId = currentUserId;
    print('USER_ACCESS: $operation $entityType[$entityId] by user[$userId]');
  }
}
