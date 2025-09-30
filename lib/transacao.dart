import 'package:uuid/uuid.dart';

class Transacao {
  //atributos
  String id;
  String descricao;
  double valor;
  DateTime data;
  bool entrada; //true = entrada, false = saída
  String bancoId; // ID do banco ao qual pertence
  String userId; // ID do usuário proprietário

  //construtor
  Transacao({
    String? id,
    required this.descricao,
    required this.valor,
    DateTime? data,
    this.entrada = true,
    required this.bancoId,
    required this.userId,
  }) :
    id = id ?? const Uuid().v4(),
    data = data ?? DateTime.now();

  // Métodos de serialização para Supabase
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'descricao': descricao,
      'valor': valor,
      'data': data.toIso8601String(),
      'entrada': entrada,
      'banco_id': bancoId,
      'user_id': userId,
    };
  }

  factory Transacao.fromJson(Map<String, dynamic> json) {
    // Parse seguro do valor
    double valorParsed = 0.0;
    try {
      if (json['valor'] is int) {
        valorParsed = json['valor'].toDouble();
      } else if (json['valor'] is double) {
        valorParsed = json['valor'];
      } else if (json['valor'] is String) {
        valorParsed = double.tryParse(json['valor']) ?? 0.0;
      }
    } catch (e) {
      print('ERRO ao fazer parse do valor: ${json['valor']} - $e');
      valorParsed = 0.0;
    }
    
    return Transacao(
      id: json['id'],
      descricao: json['descricao'],
      valor: valorParsed,
      data: DateTime.parse(json['data']),
      entrada: json['entrada'] ?? true,
      bancoId: json['banco_id'],
      userId: json['user_id'] ?? '',
    );
  }

  // Método para copiar com modificações
  Transacao copyWith({
    String? id,
    String? descricao,
    double? valor,
    DateTime? data,
    bool? entrada,
    String? bancoId,
    String? userId,
  }) {
    return Transacao(
      id: id ?? this.id,
      descricao: descricao ?? this.descricao,
      valor: valor ?? this.valor,
      data: data ?? this.data,
      entrada: entrada ?? this.entrada,
      bancoId: bancoId ?? this.bancoId,
      userId: userId ?? this.userId,
    );
  }
}

