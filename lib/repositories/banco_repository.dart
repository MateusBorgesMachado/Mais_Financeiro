import '../../banco.dart';
import '../../transacao.dart';
import '../../services/supabase_service.dart';
import '../../services/user_filter_service.dart';

class BancoRepository {
  final SupabaseService _supabaseService = SupabaseService.instance;

  // Buscar todos os bancos ativos
  Future<List<Banco>> getBancos() async {
    try {
      final userFilter = UserFilterService.instance;

      // Buscar todos os bancos (sem filtro no Supabase)
      final response = await _supabaseService.getBancos();
      print('DEBUG: ${response.length} bancos encontrados no total');

      // Filtrar por usuário na camada de aplicação
      final filteredResponse = userFilter.filterByUserId(response);
      print('DEBUG: ${filteredResponse.length} bancos após filtro de usuário');

      final List<Banco> bancos = [];
      for (var json in filteredResponse) {
        try {
          final banco = Banco.fromJson(json);
          bancos.add(banco);
          userFilter.logUserAccess('READ', 'BANCO', banco.id);
        } catch (e) {
          print('ERRO ao converter banco: $json - Erro: $e');
          // Continua sem parar o app
        }
      }

      // Carregar transações para cada banco
      // NÃO recalcular saldo - usar o saldo já calculado no banco de dados
      for (var banco in bancos) {
        try {
          print('DEBUG: Banco ${banco.nome} - Saldo do BD: ${banco.saldo}');
          banco.transacoes = await getTransacoesPorBanco(banco.id);
          print(
            'DEBUG: Banco ${banco.nome} - Transações carregadas: ${banco.transacoes.length}',
          );

          // Debug: mostrar o saldo calculado manualmente para comparação
          double saldoCalculado = banco.transacoes.fold(
            0.0,
            (sum, t) => sum + t.valor,
          );
          print(
            'DEBUG: Banco ${banco.nome} - Saldo calculado: $saldoCalculado',
          );
        } catch (e) {
          print('ERRO ao carregar transações para banco ${banco.nome}: $e');
          banco.transacoes = []; // Lista vazia se der erro
        }
      }

      print('DEBUG: Total de bancos carregados: ${bancos.length}');
      return bancos;
    } catch (e) {
      print('ERRO GERAL ao carregar bancos: $e');
      print('STACK TRACE: ${StackTrace.current}');
      throw Exception('Erro ao carregar bancos: $e');
    }
  }

  // Buscar um banco específico
  Future<Banco?> getBanco(String id) async {
    try {
      final response = await _supabaseService.getBanco(id);
      if (response == null) return null;

      final banco = Banco.fromJson(response);
      banco.transacoes = await getTransacoesPorBanco(banco.id);
      // NÃO recalcular saldo - usar o saldo já calculado no banco de dados
      // banco.recalcularSaldo();

      return banco;
    } catch (e) {
      throw Exception('Erro ao carregar banco: $e');
    }
  }

  // Criar novo banco
  Future<Banco> createBanco(Banco banco) async {
    try {
      final userFilter = UserFilterService.instance;

      // Adicionar user_id aos dados
      final bancoData = userFilter.addUserIdToData(banco.toJson());

      final response = await _supabaseService.insertBanco(bancoData);
      final novoBanco = Banco.fromJson(response);

      userFilter.logUserAccess('CREATE', 'BANCO', novoBanco.id);
      return novoBanco;
    } catch (e) {
      throw Exception('Erro ao criar banco: $e');
    }
  }

  // Atualizar banco
  Future<Banco> updateBanco(Banco banco) async {
    try {
      final response = await _supabaseService.updateBanco(
        banco.id,
        banco.toJson(),
      );
      return Banco.fromJson(response);
    } catch (e) {
      throw Exception('Erro ao atualizar banco: $e');
    }
  }

  // Deletar banco
  Future<void> deleteBanco(String id) async {
    try {
      await _supabaseService.deleteBanco(id);
    } catch (e) {
      throw Exception('Erro ao deletar banco: $e');
    }
  }

  // Ativar banco
  Future<Banco> ativarBanco(String id) async {
    try {
      final response = await _supabaseService.updateBanco(id, {'ativo': true});
      return Banco.fromJson(response);
    } catch (e) {
      throw Exception('Erro ao ativar banco: $e');
    }
  }

  // Desativar banco
  Future<Banco> desativarBanco(String id) async {
    try {
      final response = await _supabaseService.updateBanco(id, {'ativo': false});
      return Banco.fromJson(response);
    } catch (e) {
      throw Exception('Erro ao desativar banco: $e');
    }
  }

  // Buscar transações de um banco específico
  Future<List<Transacao>> getTransacoesPorBanco(String bancoId) async {
    try {
      final userFilter = UserFilterService.instance;

      // Buscar todas as transações do banco (sem filtro de usuário no Supabase)
      final response = await _supabaseService.getTransacoesPorBanco(bancoId);

      // Filtrar por usuário na camada de aplicação
      final filteredResponse = userFilter.filterByUserId(response);

      return filteredResponse.map((json) => Transacao.fromJson(json)).toList();
    } catch (e) {
      print('ERRO ao carregar transações do banco $bancoId: $e');
      return []; // Retorna lista vazia em caso de erro
    }
  }

  // Adicionar transação a um banco
  Future<void> adicionarTransacao(String bancoId, Transacao transacao) async {
    try {
      print('DEBUG: Adicionando transação ao banco $bancoId');
      print(
        'DEBUG: Transação: ${transacao.descricao}, Valor: ${transacao.valor}',
      );

      final userFilter = UserFilterService.instance;

      // Criar uma nova transação com o bancoId correto
      final novaTransacao = Transacao(
        id: transacao.id,
        descricao: transacao.descricao,
        valor: transacao.valor,
        data: transacao.data,
        entrada: transacao.entrada,
        bancoId: bancoId, // Forçar o bancoId correto
        userId: '', // Será preenchido pelo userFilter
      );

      // Adicionar user_id aos dados
      final transacaoData = userFilter.addUserIdToData(novaTransacao.toJson());

      // Executar transação (insert + update saldo)
      await _supabaseService.executarTransacao(transacaoData);

      userFilter.logUserAccess('CREATE', 'TRANSACAO', novaTransacao.id);

      print('DEBUG: Transação executada com sucesso');
    } catch (e) {
      print('ERRO ao adicionar transação: $e');
      throw Exception('Erro ao adicionar transação: $e');
    }
  }

  // Remover transação de um banco
  Future<void> removerTransacao(String bancoId, String transacaoId) async {
    try {
      await _supabaseService.removerTransacao(transacaoId, bancoId);
    } catch (e) {
      throw Exception('Erro ao remover transação: $e');
    }
  }

  // Calcular saldo total de todos os bancos
  Future<double> calcularSaldoTotal() async {
    try {
      // Buscar bancos do usuário e calcular saldo na camada de aplicação
      final bancos = await getBancos();
      double saldoTotal = 0.0;
      for (var banco in bancos) {
        saldoTotal += banco.saldo;
      }
      return saldoTotal;
    } catch (e) {
      print('ERRO ao calcular saldo total: $e');
      return 0.0; // Retorna 0 em caso de erro
    }
  }

  // Recalcular saldo de um banco
  Future<void> recalcularSaldoBanco(String bancoId) async {
    try {
      await _supabaseService.recalcularSaldoBanco(bancoId);
    } catch (e) {
      throw Exception('Erro ao recalcular saldo do banco: $e');
    }
  }

  // Buscar todas as transações de todos os bancos
  Future<List<Transacao>> buscarTodasTransacoes() async {
    try {
      final userFilter = UserFilterService.instance;

      // Buscar todas as transações (sem filtro no Supabase)
      final response = await _supabaseService.getTransacoes();

      // Filtrar por usuário na camada de aplicação
      final filteredResponse = userFilter.filterByUserId(response);

      return filteredResponse.map((json) => Transacao.fromJson(json)).toList();
    } catch (e) {
      print('ERRO ao buscar todas as transações: $e');
      return []; // Retorna lista vazia em caso de erro
    }
  }
}
