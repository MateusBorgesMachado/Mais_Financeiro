import '../../transacao.dart';
import '../../services/supabase_service.dart';

class TransacaoRepository {
  final SupabaseService _supabaseService = SupabaseService.instance;

  // Buscar todas as transações
  Future<List<Transacao>> getTransacoes({String? bancoId}) async {
    try {
      final response = await _supabaseService.getTransacoes(bancoId: bancoId);
      return response.map((json) => Transacao.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Erro ao carregar transações: $e');
    }
  }

  // Buscar uma transação específica
  Future<Transacao?> getTransacao(String id) async {
    try {
      final response = await _supabaseService.getTransacao(id);
      if (response == null) return null;

      return Transacao.fromJson(response);
    } catch (e) {
      throw Exception('Erro ao carregar transação: $e');
    }
  }

  // Criar nova transação
  Future<Transacao> createTransacao(Transacao transacao) async {
    try {
      final response = await _supabaseService.executarTransacao(
        transacao.toJson(),
      );
      return Transacao.fromJson(response);
    } catch (e) {
      throw Exception('Erro ao criar transação: $e');
    }
  }

  // Atualizar transação
  Future<Transacao> updateTransacao(Transacao transacao) async {
    try {
      final response = await _supabaseService.updateTransacao(
        transacao.id,
        transacao.toJson(),
      );

      // Recalcular saldo do banco após atualização
      await _supabaseService.recalcularSaldoBanco(transacao.bancoId);

      return Transacao.fromJson(response);
    } catch (e) {
      throw Exception('Erro ao atualizar transação: $e');
    }
  }

  // Deletar transação
  Future<void> deleteTransacao(String id, String bancoId) async {
    try {
      await _supabaseService.removerTransacao(id, bancoId);
    } catch (e) {
      throw Exception('Erro ao deletar transação: $e');
    }
  }

  // Buscar transações por banco
  Future<List<Transacao>> getTransacoesPorBanco(String bancoId) async {
    try {
      final response = await _supabaseService.getTransacoesPorBanco(bancoId);
      return response.map((json) => Transacao.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Erro ao carregar transações do banco: $e');
    }
  }

  // Buscar transações por período
  Future<List<Transacao>> getTransacoesPorPeriodo(
    DateTime inicio,
    DateTime fim, {
    String? bancoId,
  }) async {
    try {
      final todasTransacoes = await getTransacoes(bancoId: bancoId);

      return todasTransacoes.where((transacao) {
        return transacao.data.isAfter(
              inicio.subtract(const Duration(days: 1)),
            ) &&
            transacao.data.isBefore(fim.add(const Duration(days: 1)));
      }).toList();
    } catch (e) {
      throw Exception('Erro ao buscar transações por período: $e');
    }
  }

  // Buscar transações por tipo (entrada/saída)
  Future<List<Transacao>> getTransacoesPorTipo(
    bool entrada, {
    String? bancoId,
  }) async {
    try {
      final todasTransacoes = await getTransacoes(bancoId: bancoId);

      return todasTransacoes
          .where((transacao) => transacao.entrada == entrada)
          .toList();
    } catch (e) {
      throw Exception('Erro ao buscar transações por tipo: $e');
    }
  }

  // Calcular total de entradas
  Future<double> calcularTotalEntradas({String? bancoId}) async {
    try {
      final entradas = await getTransacoesPorTipo(true, bancoId: bancoId);
      return entradas.fold<double>(
        0.0,
        (total, transacao) => total + transacao.valor,
      );
    } catch (e) {
      throw Exception('Erro ao calcular total de entradas: $e');
    }
  }

  // Calcular total de saídas
  Future<double> calcularTotalSaidas({String? bancoId}) async {
    try {
      final saidas = await getTransacoesPorTipo(false, bancoId: bancoId);
      return saidas.fold<double>(
        0.0,
        (total, transacao) => total + transacao.valor.abs(),
      );
    } catch (e) {
      throw Exception('Erro ao calcular total de saídas: $e');
    }
  }

  // Buscar transações recentes (últimos 30 dias)
  Future<List<Transacao>> getTransacoesRecentes({
    String? bancoId,
    int dias = 30,
  }) async {
    try {
      final dataLimite = DateTime.now().subtract(Duration(days: dias));
      return await getTransacoesPorPeriodo(
        dataLimite,
        DateTime.now(),
        bancoId: bancoId,
      );
    } catch (e) {
      throw Exception('Erro ao buscar transações recentes: $e');
    }
  }

  // Buscar transações por descrição (busca)
  Future<List<Transacao>> buscarTransacoesPorDescricao(
    String termoBusca, {
    String? bancoId,
  }) async {
    try {
      final todasTransacoes = await getTransacoes(bancoId: bancoId);

      return todasTransacoes.where((transacao) {
        return transacao.descricao.toLowerCase().contains(
          termoBusca.toLowerCase(),
        );
      }).toList();
    } catch (e) {
      throw Exception('Erro ao buscar transações por descrição: $e');
    }
  }

  // Obter estatísticas de transações
  Future<Map<String, dynamic>> getEstatisticas({String? bancoId}) async {
    try {
      final transacoes = await getTransacoes(bancoId: bancoId);

      final entradas = transacoes.where((t) => t.entrada).toList();
      final saidas = transacoes.where((t) => !t.entrada).toList();

      final totalEntradas = entradas.fold(0.0, (total, t) => total + t.valor);
      final totalSaidas = saidas.fold(0.0, (total, t) => total + t.valor.abs());

      return {
        'totalTransacoes': transacoes.length,
        'totalEntradas': totalEntradas,
        'totalSaidas': totalSaidas,
        'saldoLiquido': totalEntradas - totalSaidas,
        'quantidadeEntradas': entradas.length,
        'quantidadeSaidas': saidas.length,
        'mediaEntradas': entradas.isEmpty
            ? 0.0
            : totalEntradas / entradas.length,
        'mediaSaidas': saidas.isEmpty ? 0.0 : totalSaidas / saidas.length,
      };
    } catch (e) {
      throw Exception('Erro ao obter estatísticas: $e');
    }
  }
}
