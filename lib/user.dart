import 'package:uuid/uuid.dart';

class User {
  final String id;
  final String nome;
  final String email;
  final String senha;
  final DateTime dataCriacao;

  User({
    String? id,
    required this.nome,
    required this.email,
    required this.senha,
    DateTime? dataCriacao,
  }) : id = id ?? const Uuid().v4(),
        dataCriacao = dataCriacao ?? DateTime.now();

  // Criar User a partir de Map (para banco de dados)
  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      nome: map['nome'],
      email: map['email'],
      senha: map['senha'],
      dataCriacao: DateTime.parse(map['data_criacao']),
    );
  }

  // Converter User para Map (para banco de dados)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
      'email': email,
      'senha': senha,
      'data_criacao': dataCriacao.toIso8601String(),
    };
  }

  // Criar uma cópia do usuário com campos modificados
  User copyWith({
    String? id,
    String? nome,
    String? email,
    String? senha,
    DateTime? dataCriacao,
  }) {
    return User(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      email: email ?? this.email,
      senha: senha ?? this.senha,
      dataCriacao: dataCriacao ?? this.dataCriacao,
    );
  }

  @override
  String toString() {
    return 'User{id: $id, nome: $nome, email: $email}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is User &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
