import '../transacao.dart';
import 'package:uuid/uuid.dart';

class Banco {
  //atributos
  String id;
  String nome;
  double saldo;
  bool fisico; //true = dinheiro fisica, false = digital
  DateTime dataCriacao;
  bool ativo; //true = ativo, false = inativo
  String userId; // ID do usuário proprietário
  List<Transacao> transacoes;

  //construtor
  Banco({
    String? id,
    required this.nome,
    required this.saldo,
    required this.fisico,
    required this.ativo,
    required this.userId,
    DateTime? dataCriacao,
    List<Transacao>? transacoes,
  }) : id = id ?? const Uuid().v4(),
       dataCriacao = dataCriacao ?? DateTime.now(),
       transacoes = transacoes ?? <Transacao>[];

  //métodos
  void adicionarTransacao(Transacao transacao) {
    transacoes.add(transacao);
    saldo += transacao.valor;
  }

  void removerTransacao(Transacao transacao) {
    transacoes.remove(transacao);
    saldo -= transacao.valor;
  }

  void ativar() {
    ativo = true;
  }

  void desativar() {
    ativo = false;
  }

  // Recalcular saldo com base nas transações
  void recalcularSaldo() {
    saldo = 0.0;
    for (var transacao in transacoes) {
      saldo += transacao.valor;
    }
  }

  // Métodos de serialização para Supabase
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome': nome,
      'saldo': saldo,
      'fisico': fisico,
      'data_criacao': dataCriacao.toIso8601String(),
      'ativo': ativo,
      'user_id': userId,
    };
  }

  factory Banco.fromJson(Map<String, dynamic> json) {
    // Parse seguro do saldo
    double saldoParsed = 0.0;
    try {
      if (json['saldo'] is int) {
        saldoParsed = json['saldo'].toDouble();
      } else if (json['saldo'] is double) {
        saldoParsed = json['saldo'];
      } else if (json['saldo'] is String) {
        saldoParsed = double.tryParse(json['saldo']) ?? 0.0;
      }
    } catch (e) {
      print('ERRO ao fazer parse do saldo: ${json['saldo']} - $e');
      saldoParsed = 0.0;
    }

    return Banco(
      id: json['id'],
      nome: json['nome'],
      saldo: saldoParsed,
      fisico: json['fisico'] ?? false,
      dataCriacao: DateTime.parse(json['data_criacao']),
      ativo: json['ativo'] ?? true,
      userId: json['user_id'] ?? '',
    );
  }

  // Método para copiar com modificações
  Banco copyWith({
    String? id,
    String? nome,
    double? saldo,
    bool? fisico,
    DateTime? dataCriacao,
    bool? ativo,
    String? userId,
    List<Transacao>? transacoes,
  }) {
    return Banco(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      saldo: saldo ?? this.saldo,
      fisico: fisico ?? this.fisico,
      dataCriacao: dataCriacao ?? this.dataCriacao,
      ativo: ativo ?? this.ativo,
      userId: userId ?? this.userId,
      transacoes: transacoes ?? this.transacoes,
    );
  }
}
