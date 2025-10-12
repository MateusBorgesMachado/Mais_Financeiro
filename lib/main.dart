import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../transacao.dart';
import 'banco.dart';
import '../user.dart';
import 'services/supabase_service.dart';
import 'services/auth_service.dart';
import 'config/supabase_config.dart';
import 'repositories/banco_repository.dart';
import 'screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializa o Supabase
  try {
    if (SupabaseConfig.isConfigured) {
      await SupabaseService.initialize(
        url: SupabaseConfig.supabaseUrl,
        anonKey: SupabaseConfig.supabaseAnonKey,
      );
    } else {
      print(
        'ATENÇÃO: Configure as credenciais do Supabase em config/supabase_config.dart',
      );
    }
  } catch (e) {
    print('Erro ao inicializar Supabase: $e');
  }

  runApp(FinanceiroApp());
}

class FinanceiroApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "+Financeiro",
      theme: ThemeData(primarySwatch: Colors.green),
      initialRoute: '/',
      routes: {
        '/': (context) => AuthWrapper(),
        '/login': (context) => LoginScreen(),
        '/home': (context) => ListaScreen(),
      },
    );
  }
}

class AuthWrapper extends StatefulWidget {
  @override
  AuthWrapperState createState() => AuthWrapperState();
}

class AuthWrapperState extends State<AuthWrapper> {
  bool isLoading = true;
  User? currentUser;

  @override
  void initState() {
    super.initState();
    checkAuthStatus();
  }

  Future<void> checkAuthStatus() async {
    try {
      final user = await AuthService.instance.loadSavedUser();
      if (mounted) {
        setState(() {
          currentUser = user;
          isLoading = false;
        });
      }
    } catch (e) {
      print('Erro ao verificar status de autenticação: $e');
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        backgroundColor: Color(0xFF2E7D32),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.account_balance_wallet, size: 80, color: Colors.white),
              SizedBox(height: 24),
              Text(
                '+Financeiro',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 40),
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ],
          ),
        ),
      );
    }

    return currentUser != null ? ListaScreen() : LoginScreen();
  }
}

class ListaScreen extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return ListaScreenState();
  }
}

class ListaScreenState extends State<ListaScreen> {
  List<Banco> bancos = [];
  List<Transacao> transacoes = [];
  String nomePessoa = "Usuário";
  bool isLoading = false;
  String? errorMessage;

  final BancoRepository _bancoRepository = BancoRepository();

  @override
  void initState() {
    super.initState();
    inicializarDados();
  }

  Future<void> inicializarDados() async {
    // Obter nome do usuário logado
    final user = AuthService.instance.currentUser;
    if (user != null) {
      setState(() {
        nomePessoa = user.nome;
      });
    }

    await carregarDados();
  }

  Future<void> carregarDados() async {
    if (!SupabaseConfig.isConfigured) {
      setState(() {
        errorMessage = 'Configure as credenciais do Supabase primeiro';
      });
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      // Carregar dados do Supabase
      bancos = await _bancoRepository.getBancos();
      transacoes = await _bancoRepository.buscarTodasTransacoes();

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Erro ao carregar dados: ${e.toString()}';
      });
    }
  }

  List<Transacao> buscarTodasTransacoes() {
    List<Transacao> listaTransacoes = [];
    for (var banco in bancos) {
      listaTransacoes.addAll(banco.transacoes);
    }
    return listaTransacoes;
  }

  double calcularSaldoTotal(List<Banco> bancos) {
    double saldoTotal = 0.0;
    for (var banco in bancos) {
      saldoTotal += banco.saldo;
    }
    return saldoTotal;
  }

  String formatarMoeda(double valor) {
    return NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$ ').format(valor);
  }

  Future<void> adicionarBanco(Banco novoBanco) async {
    try {
      setState(() {
        isLoading = true;
      });

      await _bancoRepository.createBanco(novoBanco);
      await carregarDados(); // Recarregar dados
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Erro ao adicionar banco: $e';
      });
    }
  }

  Future<void> removerBanco(Banco banco) async {
    try {
      setState(() {
        isLoading = true;
      });

      await _bancoRepository.deleteBanco(banco.id);
      await carregarDados(); // Recarregar dados
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Erro ao remover banco: $e';
      });
    }
  }

  void verificarBancoAtivo(Banco banco) {
    if (!banco.ativo) {}
  }

  List<Transacao> obterTransacoesPorBanco(Banco banco) {
    return banco.transacoes;
  }

  Future<void> adicionarTransacao(String bancoId, Transacao transacao) async {
    try {
      setState(() {
        isLoading = true;
      });

      await _bancoRepository.adicionarTransacao(bancoId, transacao);
      await carregarDados(); // Recarregar dados
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Erro ao adicionar transação: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color corPrincipal = Color(0xFF2E7D32);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(
          "+Financeiro",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: corPrincipal,
        centerTitle: true,
        elevation: 4.0,
        actions: [
          if (isLoading)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
          IconButton(icon: Icon(Icons.refresh), onPressed: carregarDados),
          PopupMenuButton<String>(
            icon: Icon(Icons.account_circle, color: Colors.white),
            onSelected: (value) {
              if (value == 'logout') {
                handleLogout();
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              PopupMenuItem<String>(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.exit_to_app, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Sair'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: buildBody(corPrincipal),
    );
  }

  Future<void> handleLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirmar Saída'),
          content: Text('Deseja realmente sair da sua conta?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text('Sair', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (shouldLogout == true) {
      try {
        await AuthService.instance.logout();
        if (mounted) {
          Navigator.of(
            context,
          ).pushNamedAndRemoveUntil('/login', (route) => false);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro ao fazer logout: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Widget buildBody(Color corPrincipal) {
    if (errorMessage != null && !SupabaseConfig.isConfigured) {
      return buildConfigurationError();
    }

    if (errorMessage != null) {
      return buildErrorWidget();
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Card(
            elevation: 5.0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Olá, $nomePessoa',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Saldo Total',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                      Text(
                        formatarMoeda(calcularSaldoTotal(bancos)),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: corPrincipal,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 20),
          Expanded(
            child: ListView.builder(
              itemCount: bancos.length,
              itemBuilder: (context, index) {
                final banco = bancos[index];
                return Card(
                  elevation: 3.0,
                  margin: const EdgeInsets.symmetric(vertical: 8.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 10.0,
                      horizontal: 16.0,
                    ),
                    leading: CircleAvatar(
                      radius: 25,
                      backgroundColor: banco.fisico
                          ? corPrincipal.withValues()
                          : Colors.blue.withValues(),
                      child: Icon(
                        banco.fisico
                            ? Icons.money_outlined
                            : Icons.attach_money_outlined,
                        color: Colors.white,
                      ),
                    ),
                    title: Text(
                      banco.nome,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      'Saldo: ${formatarMoeda(banco.saldo)}',
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => TransacaoForm(
                                  onTransacaoAdicionado: (novaTransacao) async {
                                    await adicionarTransacao(
                                      banco.id,
                                      novaTransacao,
                                    );
                                    if (mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            "Transação adicionada ao banco ${banco.nome}",
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                ),
                              ),
                            );
                          },
                          icon: Icon(
                            Icons.add_circle_outline,
                            color: corPrincipal,
                          ),
                          tooltip: 'Adicionar Transação',
                        ),
                        IconButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ListaTransacaoScreen(
                                  banco: banco,
                                  transacoes: obterTransacoesPorBanco(banco),
                                ),
                              ),
                            );
                          },
                          icon: Icon(Icons.list_alt, color: Colors.blueGrey),
                          tooltip: 'Ver Transações',
                        ),
                        IconButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => DeletarForm(
                                  banco: banco,
                                  onBancoDeletado: (banco) async {
                                    await removerBanco(banco);
                                  },
                                ),
                              ),
                            );
                          },
                          icon: Icon(
                            Icons.delete_outline,
                            color: Colors.redAccent,
                          ),
                          tooltip: 'Deletar Banco',
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => BancoForm(
                          onBancoAdicionado: (novoBanco) async {
                            await adicionarBanco(novoBanco);
                          },
                        ),
                      ),
                    );
                  },
                  icon: Icon(Icons.add, color: Colors.white),
                  label: Text(
                    "Adicionar Banco",
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: corPrincipal,
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    // Ação para o botão Relatórios
                    buscarTodasTransacoes();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ListaTransacaoScreen(
                          banco: Banco(
                            nome: "Todos os Bancos",
                            saldo: 0.0,
                            fisico: true,
                            ativo: true,
                            userId: AuthService.instance.currentUser?.id ?? '',
                          ),
                          transacoes: buscarTodasTransacoes(),
                        ),
                      ),
                    );
                  },
                  icon: Icon(Icons.bar_chart, color: Colors.white),
                  label: Text(
                    "Relatórios",
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueGrey, // Cor secundária
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildConfigurationError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.settings, size: 64, color: Colors.orange),
            SizedBox(height: 16),
            Text(
              'Configuração Necessária',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Configure as credenciais do Supabase em config/supabase_config.dart',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  errorMessage = null;
                });
                carregarDados();
              },
              child: Text('Tentar Novamente'),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red),
            SizedBox(height: 16),
            Text(
              'Erro ao Carregar Dados',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              errorMessage ?? 'Erro desconhecido',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  errorMessage = null;
                });
                carregarDados();
              },
              child: Text('Tentar Novamente'),
            ),
          ],
        ),
      ),
    );
  }
}

class DeletarForm extends StatefulWidget {
  final Banco banco;
  final Future<void> Function(Banco) onBancoDeletado;

  const DeletarForm({required this.onBancoDeletado, required this.banco});

  @override
  DeletarFormScreen createState() => DeletarFormScreen();
}

class DeletarFormScreen extends State<DeletarForm> {
  @override
  Widget build(BuildContext context) {
    final Color corPrincipal = Color(0xFF2E7D32);
    final Color corPerigo = Colors.redAccent;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(
          "Deletar Banco",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: corPrincipal,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.warning_amber_rounded,
                size: 80,
                color: Colors.orange.shade700,
              ),
              SizedBox(height: 20),

              Text(
                "Você tem certeza que deseja deletar o banco '${widget.banco.nome}'?",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 12),
              Text(
                "Esta ação não pode ser desfeita.",
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
              SizedBox(height: 40),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Text("Cancelar"),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: corPrincipal,
                      side: BorderSide(color: corPrincipal, width: 2),
                      padding: EdgeInsets.symmetric(
                        horizontal: 30,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),

                  ElevatedButton(
                    onPressed: () async {
                      try {
                        await widget.onBancoDeletado(widget.banco);
                        if (context.mounted) {
                          Navigator.pop(context);
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Erro ao deletar banco: ${e.toString()}',
                              ),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
                    child: Text(
                      "Confirmar",
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: corPerigo,
                      padding: EdgeInsets.symmetric(
                        horizontal: 30,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ListaTransacaoScreen extends StatefulWidget {
  final Banco banco;
  final List<Transacao> transacoes;

  const ListaTransacaoScreen({required this.banco, required this.transacoes});
  @override
  ListaTransacoesScreenState createState() => ListaTransacoesScreenState();
}

class ListaTransacoesScreenState extends State<ListaTransacaoScreen> {
  Map<String, String> bancosNomes = {}; // Mapa bancoId -> nome do banco
  bool isLoadingBancos = true;

  @override
  void initState() {
    super.initState();
    _carregarNomesBancos();
  }

  Future<void> _carregarNomesBancos() async {
    try {
      final BancoRepository bancoRepository = BancoRepository();
      final bancos = await bancoRepository.getBancos();

      setState(() {
        bancosNomes = {for (var banco in bancos) banco.id: banco.nome};
        isLoadingBancos = false;
      });
    } catch (e) {
      setState(() {
        isLoadingBancos = false;
      });
    }
  }

  String obterNomeBanco(String bancoId) {
    return bancosNomes[bancoId] ?? 'Banco Desconhecido';
  }

  @override
  Widget build(BuildContext context) {
    // Cor principal para manter o padrão do app
    final Color corPrincipal = Color(0xFF2E7D32);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(
          "Relatório de Transações",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: corPrincipal,
        centerTitle: true,
      ),
      body: isLoadingBancos
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 8.0,
                vertical: 12.0,
              ),
              child: ListView.builder(
                itemCount: widget.transacoes.length,
                itemBuilder: (context, index) {
                  final transacao = widget.transacoes[index];
                  final isEntrada = transacao.entrada;
                  final nomeBanco = obterNomeBanco(transacao.bancoId);

                  return Card(
                    elevation: 3.0,
                    margin: const EdgeInsets.symmetric(
                      vertical: 6.0,
                      horizontal: 8.0,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 12.0,
                        horizontal: 16.0,
                      ),
                      leading: CircleAvatar(
                        backgroundColor: isEntrada
                            ? Colors.green.shade100
                            : Colors.red.shade100,
                        child: Icon(
                          isEntrada ? Icons.arrow_downward : Icons.arrow_upward,
                          color: isEntrada
                              ? Colors.green.shade800
                              : Colors.red.shade800,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        transacao.descricao,
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        '$nomeBanco • ${DateFormat('dd/MM/yyyy').format(transacao.data)}',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                      trailing: Text(
                        '${isEntrada ? '+' : '-'} R\$ ${transacao.valor.toStringAsFixed(2)}',
                        style: TextStyle(
                          color: isEntrada ? corPrincipal : Colors.red.shade700,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}

class BancoForm extends StatefulWidget {
  final Future<void> Function(Banco) onBancoAdicionado;

  const BancoForm({required this.onBancoAdicionado});

  @override
  BancoFormScreenState createState() => BancoFormScreenState();
}

class BancoFormScreenState extends State<BancoForm> {
  final TextEditingController saldoController = TextEditingController(text: '');
  final formatter = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    saldoController.addListener(() {
      final text = saldoController.text.replaceAll(RegExp(r'[^0-9]'), '');

      final value = double.parse(text) / 100;
      final newText = formatter.format(value);
      saldoController.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: newText.length),
      );
    });
  }

  final TextEditingController nomeController = TextEditingController();
  bool fisico = true;

  get check01 => false;
  get check02 => false;

  // Método para fazer parse de valor monetário
  double _parseValorMonetario(String valor) {
    if (valor.isEmpty) return 0.0;

    // Remove todos os caracteres não numéricos
    String valorLimpo = valor.replaceAll(RegExp(r'[^0-9]'), '');

    // Se está vazio após limpeza, retorna 0
    if (valorLimpo.isEmpty) return 0.0;

    // Converte para double dividindo por 100 (formato de centavos)
    return double.parse(valorLimpo) / 100.0;
  }

  @override
  Widget build(BuildContext context) {
    final Color corPrincipal = Color(0xFF2E7D32);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(
          "Adicionar Novo Banco",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: corPrincipal,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),

        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            // Permite rolagem se o teclado aparecer
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Campo de Nome do Banco
                TextFormField(
                  controller: nomeController,
                  decoration: InputDecoration(
                    labelText: "Nome do Banco",
                    prefixIcon: Icon(
                      Icons.account_balance,
                      color: corPrincipal,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                  ),
                  maxLength: 20,
                  textCapitalization: TextCapitalization.words,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Por favor, insira o nome do banco.';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 20),

                // Campo de Saldo Inicial
                TextFormField(
                  controller: saldoController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: "Saldo Inicial",
                    prefixIcon: Icon(Icons.attach_money, color: corPrincipal),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                  ),
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, insira o saldo inicial.';
                    }
                    try {
                      double saldoParsed = _parseValorMonetario(value);
                      if (saldoParsed < 0) {
                        return 'Saldo não pode ser negativo.';
                      }
                    } catch (e) {
                      return 'Valor inválido.';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 20),

                // Seletor de Tipo de Conta (Físico/Digital)
                SwitchListTile(
                  title: Text(
                    "É uma conta física?",
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    fisico ? "Sim, conta física" : "Não, conta digital",
                  ),
                  value: fisico,
                  onChanged: (value) {
                    setState(() {
                      fisico = value;
                    });
                  },
                  activeColor: corPrincipal,
                  secondary: Icon(
                    fisico ? Icons.store : Icons.computer,
                    color: corPrincipal,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    side: BorderSide(color: Colors.grey.shade300),
                  ),
                  tileColor: Colors.white,
                ),
                SizedBox(height: 40),

                // Botão Salvar
                ElevatedButton(
                  onPressed: () async {
                    // Valida o formulário antes de prosseguir
                    if (_formKey.currentState!.validate()) {
                      try {
                        final nome = nomeController.text;
                        final saldo = _parseValorMonetario(
                          saldoController.text,
                        );

                        final currentUser = AuthService.instance.currentUser;
                        if (currentUser == null) {
                          throw Exception('Usuário não está logado');
                        }

                        final novoBanco = Banco(
                          nome: nome,
                          saldo: saldo,
                          fisico: fisico,
                          ativo: true,
                          userId: currentUser.id,
                        );

                        // Aguarda a operação assíncrona
                        await widget.onBancoAdicionado(novoBanco);

                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                "Banco '$nome' adicionado com sucesso!",
                              ),
                            ),
                          );

                          // Fecha a tela apenas após sucesso
                          Navigator.pop(context);
                        }
                      } catch (e) {
                        // Mostra erro se houver
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Erro ao salvar banco: ${e.toString()}',
                              ),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    }
                  },
                  child: Text(
                    "Salvar Banco",
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: corPrincipal,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class TransacaoForm extends StatefulWidget {
  final Future<void> Function(Transacao) onTransacaoAdicionado;

  const TransacaoForm({required this.onTransacaoAdicionado});

  @override
  TransacaoFormScreenState createState() => TransacaoFormScreenState();
}

class TransacaoFormScreenState extends State<TransacaoForm> {
  final TextEditingController valorController = TextEditingController(text: '');
  final formatter = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    valorController.addListener(() {
      final text = valorController.text.replaceAll(RegExp(r'[^0-9]'), '');
      // if (text.isEmpty) {
      //   valorController.text = '';
      //   return;
      // }

      final value = double.parse(text) / 100;
      final newText = formatter.format(value);

      valorController.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: newText.length),
      );
    });
  }

  final TextEditingController descricaoController = TextEditingController();
  DateTime data = DateTime.now();
  bool entrada = true;

  // Método para fazer parse de valor monetário
  double _parseValorMonetario(String valor) {
    if (valor.isEmpty) return 0.0;

    // Remove todos os caracteres não numéricos
    String valorLimpo = valor.replaceAll(RegExp(r'[^0-9]'), '');

    // Se está vazio após limpeza, retorna 0
    if (valorLimpo.isEmpty) return 0.0;

    // Converte para double dividindo por 100 (formato de centavos)
    return double.parse(valorLimpo) / 100.0;
  }

  @override
  Widget build(BuildContext context) {
    final Color corPrincipal = Color(0xFF2E7D32);
    final Color corSaida = Colors.red.shade700;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(
          "Adicionar Transação",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: corPrincipal,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        // Usar um Form para validação profissional
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            // Permite rolagem se o teclado aparecer
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Seletor de Tipo de Transação (Entrada/Saída)
                SegmentedButton<bool>(
                  segments: <ButtonSegment<bool>>[
                    ButtonSegment<bool>(
                      value: true,
                      label: Text('Entrada'),
                      icon: Icon(Icons.arrow_downward),
                    ),
                    ButtonSegment<bool>(
                      value: false,
                      label: Text('Saída'),
                      icon: Icon(Icons.arrow_upward),
                    ),
                  ],
                  selected: <bool>{entrada},
                  onSelectionChanged: (Set<bool> newSelection) {
                    setState(() {
                      entrada = newSelection.first;
                    });
                  },
                  style: SegmentedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.grey.shade700,
                    selectedForegroundColor: Colors.white,
                    selectedBackgroundColor: entrada ? corPrincipal : corSaida,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                  ),
                ),
                SizedBox(height: 24),

                // Campo de Descrição
                TextFormField(
                  controller: descricaoController,
                  decoration: InputDecoration(
                    labelText: "Descrição",
                    prefixIcon: Icon(
                      Icons.description_outlined,
                      color: corPrincipal,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                  ),
                  textCapitalization: TextCapitalization.sentences,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Por favor, insira uma descrição.';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 20),

                // Campo de Valor
                TextFormField(
                  controller: valorController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: "Valor",
                    prefixIcon: Icon(
                      Icons.monetization_on_outlined,
                      color: corPrincipal,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                  ),
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, insira um valor.';
                    }
                    try {
                      double valorParsed = _parseValorMonetario(value);
                      if (valorParsed <= 0) {
                        return 'O valor deve ser maior que zero.';
                      }
                    } catch (e) {
                      return 'Valor inválido.';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 40),

                // Botão Salvar
                ElevatedButton(
                  onPressed: () async {
                    // Valida o formulário antes de prosseguir
                    if (_formKey.currentState!.validate()) {
                      try {
                        final descricao = descricaoController.text;
                        var valor = _parseValorMonetario(valorController.text);

                        if (!entrada) {
                          valor = -valor; // Torna o valor negativo para saídas
                        }

                        final currentUser = AuthService.instance.currentUser;
                        if (currentUser == null) {
                          throw Exception('Usuário não está logado');
                        }

                        final novaTransacao = Transacao(
                          descricao: descricao,
                          valor: valor,
                          entrada: entrada,
                          bancoId: 'temp', // Será definido no repositório
                          userId: currentUser.id,
                        );

                        // Aguarda a operação assíncrona
                        await widget.onTransacaoAdicionado(novaTransacao);

                        // Fecha a tela apenas após sucesso
                        if (context.mounted) {
                          Navigator.pop(context);
                        }
                      } catch (e) {
                        // Mostra erro se houver
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Erro ao salvar transação: ${e.toString()}',
                              ),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    }
                  },
                  child: Text(
                    "Salvar Transação",
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: corPrincipal,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
