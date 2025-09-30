import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static SupabaseService? _instance;
  static SupabaseClient get client => Supabase.instance.client;
  
  // Singleton pattern
  static SupabaseService get instance {
    _instance ??= SupabaseService._();
    return _instance!;
  }
  
  SupabaseService._();

  // Inicializar Supabase
  static Future<void> initialize({
    required String url,
    required String anonKey,
  }) async {
    await Supabase.initialize(
      url: url,
      anonKey: anonKey,
    );
  }

  // CRUD para Bancos
  Future<List<Map<String, dynamic>>> getBancos() async {
    try {
      final response = await client
          .from('bancos')
          .select()
          .eq('ativo', true)
          .order('data_criacao', ascending: false);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Erro ao buscar bancos: $e');
    }
  }

  Future<Map<String, dynamic>?> getBanco(String id) async {
    try {
      final response = await client
          .from('bancos')
          .select()
          .eq('id', id)
          .maybeSingle();
      
      return response;
    } catch (e) {
      throw Exception('Erro ao buscar banco: $e');
    }
  }

  Future<Map<String, dynamic>> insertBanco(Map<String, dynamic> banco) async {
    try {
      final response = await client
          .from('bancos')
          .insert(banco)
          .select()
          .single();
      
      return response;
    } catch (e) {
      throw Exception('Erro ao inserir banco: $e');
    }
  }

  Future<Map<String, dynamic>> updateBanco(String id, Map<String, dynamic> updates) async {
    try {
      final response = await client
          .from('bancos')
          .update(updates)
          .eq('id', id)
          .select()
          .single();
      
      return response;
    } catch (e) {
      throw Exception('Erro ao atualizar banco: $e');
    }
  }

  Future<void> deleteBanco(String id) async {
    try {
      await client
          .from('bancos')
          .delete()
          .eq('id', id);
    } catch (e) {
      throw Exception('Erro ao deletar banco: $e');
    }
  }

  // CRUD para Transações
  Future<List<Map<String, dynamic>>> getTransacoes({String? bancoId}) async {
    try {
      var query = client
          .from('transacoes')
          .select();
      
      if (bancoId != null) {
        query = query.eq('banco_id', bancoId);
      }
      
      final response = await query.order('data', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Erro ao buscar transações: $e');
    }
  }

  Future<Map<String, dynamic>?> getTransacao(String id) async {
    try {
      final response = await client
          .from('transacoes')
          .select()
          .eq('id', id)
          .maybeSingle();
      
      return response;
    } catch (e) {
      throw Exception('Erro ao buscar transação: $e');
    }
  }

  Future<Map<String, dynamic>> insertTransacao(Map<String, dynamic> transacao) async {
    try {
      final response = await client
          .from('transacoes')
          .insert(transacao)
          .select()
          .single();
      
      return response;
    } catch (e) {
      throw Exception('Erro ao inserir transação: $e');
    }
  }

  Future<Map<String, dynamic>> updateTransacao(String id, Map<String, dynamic> updates) async {
    try {
      final response = await client
          .from('transacoes')
          .update(updates)
          .eq('id', id)
          .select()
          .single();
      
      return response;
    } catch (e) {
      throw Exception('Erro ao atualizar transação: $e');
    }
  }

  Future<void> deleteTransacao(String id) async {
    try {
      await client
          .from('transacoes')
          .delete()
          .eq('id', id);
    } catch (e) {
      throw Exception('Erro ao deletar transação: $e');
    }
  }

  // Método para obter transações de um banco específico
  Future<List<Map<String, dynamic>>> getTransacoesPorBanco(String bancoId) async {
    try {
      final response = await client
          .from('transacoes')
          .select()
          .eq('banco_id', bancoId)
          .order('data', ascending: false);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Erro ao buscar transações do banco: $e');
    }
  }

  // Método para calcular saldo total
  Future<double> calcularSaldoTotal({String? userId}) async {
    try {
      var query = client
          .from('bancos')
          .select('saldo')
          .eq('ativo', true);
      
      if (userId != null) {
        query = query.eq('user_id', userId);
      }
      
      final response = await query;
      
      double saldoTotal = 0.0;
      for (var banco in response) {
        saldoTotal += banco['saldo'].toDouble();
      }
      
      return saldoTotal;
    } catch (e) {
      throw Exception('Erro ao calcular saldo total: $e');
    }
  }

  // Atualizar saldo do banco somando a nova transação
  Future<void> atualizarSaldoBanco(String bancoId, double valorTransacao) async {
    try {
      // Buscar o banco atual
      final bancoAtual = await getBanco(bancoId);
      if (bancoAtual == null) {
        throw Exception('Banco não encontrado');
      }
      
      // Calcular novo saldo somando o valor da transação
      double saldoAtual = bancoAtual['saldo'].toDouble();
      double novoSaldo = saldoAtual + valorTransacao;
      
      print('DEBUG: Atualizando saldo - Atual: $saldoAtual + Transação: $valorTransacao = Novo: $novoSaldo');
      
      // Atualizar o saldo no banco
      await updateBanco(bancoId, {'saldo': novoSaldo});
      print('DEBUG: Saldo atualizado no banco de dados');
    } catch (e) {
      print('ERRO ao atualizar saldo: $e');
      throw Exception('Erro ao atualizar saldo do banco: $e');
    }
  }

  // Método para executar transação (insert + update saldo)
  Future<Map<String, dynamic>> executarTransacao(Map<String, dynamic> transacao) async {
    try {
      // Inserir transação
      final novaTransacao = await insertTransacao(transacao);
      
      // Atualizar saldo do banco somando o valor da transação
      double valorTransacao = transacao['valor'].toDouble();
      await atualizarSaldoBanco(transacao['banco_id'], valorTransacao);
      
      return novaTransacao;
    } catch (e) {
      throw Exception('Erro ao executar transação: $e');
    }
  }

  // Método para recalcular saldo do banco baseado nas transações
  Future<void> recalcularSaldoBanco(String bancoId) async {
    try {
      // Buscar todas as transações do banco
      final transacoes = await getTransacoesPorBanco(bancoId);
      
      // Calcular saldo total das transações
      double saldoTransacoes = 0.0;
      for (var transacao in transacoes) {
        saldoTransacoes += transacao['valor'].toDouble();
      }
      
      print('DEBUG: Recalculando saldo - Total das transações: $saldoTransacoes');
      
      // Atualizar o saldo no banco (definir como o total das transações)
      await updateBanco(bancoId, {'saldo': saldoTransacoes});
      print('DEBUG: Saldo recalculado no banco de dados');
    } catch (e) {
      print('ERRO ao recalcular saldo: $e');
      throw Exception('Erro ao recalcular saldo do banco: $e');
    }
  }

  // Método para remover transação (delete + update saldo)
  Future<void> removerTransacao(String transacaoId, String bancoId) async {
    try {
      // Deletar transação
      await deleteTransacao(transacaoId);
      
      // Recalcular saldo do banco
      await recalcularSaldoBanco(bancoId);
    } catch (e) {
      throw Exception('Erro ao remover transação: $e');
    }
  }
}
