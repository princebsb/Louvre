import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/badge_service.dart';
import 'package:intl/intl.dart';

class SolicitacoesScreen extends StatefulWidget {
  const SolicitacoesScreen({super.key});

  @override
  State<SolicitacoesScreen> createState() => _SolicitacoesScreenState();
}

class _SolicitacoesScreenState extends State<SolicitacoesScreen> {
  final ApiService _apiService = ApiService();
  final BadgeService _badgeService = BadgeService();
  List<dynamic> _solicitacoes = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _carregarSolicitacoes();
  }

  Future<void> _carregarSolicitacoes() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final solicitacoes = await _apiService.getSolicitacoes();
      setState(() {
        _solicitacoes = solicitacoes;
        _isLoading = false;
      });
      // Marcar solicitacoes como vistas
      await _badgeService.markSolicitacoesAsSeen(solicitacoes);
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _abrirNovaSolicitacao() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _FormNovaSolicitacao(
        onSuccess: () {
          _carregarSolicitacoes();
        },
      ),
    );
  }

  void _verDetalhes(Map<String, dynamic> solicitacao) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _DetalhesSolicitacao(
        solicitacao: solicitacao,
        onEditar: () => _editarSolicitacao(solicitacao),
        onExcluir: () => _excluirSolicitacao(solicitacao),
        onRefresh: _carregarSolicitacoes,
      ),
    );
  }

  void _editarSolicitacao(Map<String, dynamic> solicitacao) {
    Navigator.pop(context); // Fecha o modal de detalhes
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _FormEditarSolicitacao(
        solicitacao: solicitacao,
        onSuccess: _carregarSolicitacoes,
      ),
    );
  }

  Future<void> _excluirSolicitacao(Map<String, dynamic> solicitacao) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir Solicitação'),
        content: const Text('Tem certeza que deseja excluir esta solicitação?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    try {
      await _apiService.excluirSolicitacao(solicitacao['id']);
      if (mounted) {
        Navigator.pop(context); // Fecha o modal de detalhes
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Solicitação excluída com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
        _carregarSolicitacoes();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao excluir: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'pendente':
      case 'aberto':
        return Colors.blue;
      case 'em_andamento':
        return Colors.orange;
      case 'resolvido':
        return Colors.green;
      case 'cancelado':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  String _getStatusLabel(String? status) {
    switch (status?.toLowerCase()) {
      case 'pendente':
        return 'Pendente';
      case 'aberto':
        return 'Aberto';
      case 'em_andamento':
        return 'Em Andamento';
      case 'resolvido':
        return 'Resolvido';
      case 'cancelado':
        return 'Cancelado';
      default:
        return status ?? 'Desconhecido';
    }
  }

  Color _getPrioridadeColor(String? prioridade) {
    switch (prioridade?.toLowerCase()) {
      case 'baixa':
        return Colors.blue;
      case 'media':
        return Colors.orange;
      case 'alta':
        return Colors.deepOrange;
      case 'urgente':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getTipoLabel(String? tipo) {
    switch (tipo?.toLowerCase()) {
      case 'agenda_manutencao':
        return 'Agenda de Manutenção';
      case 'manutencao':
        return 'Manutenção';
      case 'mudanca':
        return 'Mudança';
      case 'reforma_interna':
        return 'Reforma Interna';
      case '2via_boleto':
        return '2ª Via Boleto';
      default:
        return tipo ?? 'Outros';
    }
  }

  IconData _getTipoIcon(String? tipo) {
    switch (tipo?.toLowerCase()) {
      case 'agenda_manutencao':
        return Icons.calendar_month;
      case 'manutencao':
        return Icons.build;
      case 'mudanca':
        return Icons.local_shipping;
      case 'reforma_interna':
        return Icons.construction;
      case '2via_boleto':
        return Icons.receipt_long;
      default:
        return Icons.assignment;
    }
  }

  String _formatarData(String? data) {
    if (data == null || data.isEmpty) return '';
    try {
      final dateTime = DateTime.parse(data);
      return DateFormat('dd/MM/yyyy HH:mm', 'pt_BR').format(dateTime);
    } catch (e) {
      return data;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Minhas Solicitações'),
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(_error!, textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _carregarSolicitacoes,
                        child: const Text('Tentar novamente'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _carregarSolicitacoes,
                  child: _solicitacoes.isEmpty
                      ? ListView(
                          children: [
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.6,
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.assignment_outlined,
                                      size: 80,
                                      color: Colors.grey[400],
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Nenhuma solicitação encontrada',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Clique em + para criar uma nova',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[500],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _solicitacoes.length,
                          itemBuilder: (context, index) {
                            final solicitacao = _solicitacoes[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: InkWell(
                                onTap: () => _verDetalhes(solicitacao),
                                borderRadius: BorderRadius.circular(12),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: _getStatusColor(solicitacao['status'])
                                                  .withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              _getStatusLabel(solicitacao['status']),
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: _getStatusColor(solicitacao['status']),
                                              ),
                                            ),
                                          ),
                                          if (solicitacao['prioridade'] != null) ...[
                                            const SizedBox(width: 8),
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 4,
                                              ),
                                              decoration: BoxDecoration(
                                                color: _getPrioridadeColor(solicitacao['prioridade'])
                                                    .withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                solicitacao['prioridade']?.toString().toUpperCase() ?? '',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                  color: _getPrioridadeColor(solicitacao['prioridade']),
                                                ),
                                              ),
                                            ),
                                          ],
                                          const Spacer(),
                                          Text(
                                            '#${solicitacao['id']}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[500],
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (solicitacao['tipo'] != null) ...[
                                        const SizedBox(height: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 5,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF2563EB).withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                _getTipoIcon(solicitacao['tipo']),
                                                size: 14,
                                                color: const Color(0xFF2563EB),
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                _getTipoLabel(solicitacao['tipo']),
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w500,
                                                  color: Color(0xFF2563EB),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                      const SizedBox(height: 12),
                                      Text(
                                        solicitacao['assunto'] ?? solicitacao['titulo'] ?? 'Sem título',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        solicitacao['descricao'] ?? '',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[600],
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 12),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.access_time,
                                            size: 14,
                                            color: Colors.grey[500],
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            _formatarData(solicitacao['created_at']),
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[500],
                                            ),
                                          ),
                                          if (solicitacao['resposta'] != null) ...[
                                            const Spacer(),
                                            Icon(
                                              Icons.reply,
                                              size: 14,
                                              color: Colors.green[600],
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              'Respondido',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.green[600],
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _abrirNovaSolicitacao,
        backgroundColor: const Color(0xFF2563EB),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

class _FormNovaSolicitacao extends StatefulWidget {
  final VoidCallback onSuccess;

  const _FormNovaSolicitacao({required this.onSuccess});

  @override
  State<_FormNovaSolicitacao> createState() => _FormNovaSolicitacaoState();
}

class _FormNovaSolicitacaoState extends State<_FormNovaSolicitacao> {
  final _formKey = GlobalKey<FormState>();
  final _tituloController = TextEditingController();
  final _descricaoController = TextEditingController();
  final ApiService _apiService = ApiService();

  String _tipoSelecionado = '';
  String _prioridadeSelecionada = 'media';
  bool _isLoading = false;

  final List<Map<String, String>> _tipos = [
    {'value': 'agenda_manutencao', 'label': 'Agenda de Manutenção Preventiva'},
    {'value': 'manutencao', 'label': 'Manutenção'},
    {'value': 'mudanca', 'label': 'Mudança'},
    {'value': 'reforma_interna', 'label': 'Reforma Interna'},
    {'value': '2via_boleto', 'label': 'Segunda Via de Boleto'},
  ];

  final List<Map<String, String>> _prioridades = [
    {'value': 'baixa', 'label': 'Baixa'},
    {'value': 'media', 'label': 'Média'},
    {'value': 'alta', 'label': 'Alta'},
    {'value': 'urgente', 'label': 'Urgente'},
  ];

  Future<void> _enviarSolicitacao() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await _apiService.criarSolicitacao(
        titulo: _tituloController.text,
        descricao: _descricaoController.text,
        tipo: _tipoSelecionado.isNotEmpty ? _tipoSelecionado : 'manutencao',
        prioridade: _prioridadeSelecionada,
      );

      if (mounted) {
        Navigator.pop(context);
        widget.onSuccess();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Solicitação enviada com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao enviar: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _descricaoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Nova Solicitação',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Preencha os campos abaixo para enviar sua solicitação',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 24),
              DropdownButtonFormField<String>(
                value: _tipoSelecionado.isEmpty ? null : _tipoSelecionado,
                decoration: InputDecoration(
                  labelText: 'Tipo de Solicitação',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.category),
                ),
                items: _tipos.map((tipo) {
                  return DropdownMenuItem<String>(
                    value: tipo['value'],
                    child: Text(tipo['label']!),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _tipoSelecionado = value ?? '');
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Selecione o tipo';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _prioridadeSelecionada,
                decoration: InputDecoration(
                  labelText: 'Prioridade',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.flag),
                ),
                items: _prioridades.map((p) {
                  return DropdownMenuItem<String>(
                    value: p['value'],
                    child: Text(p['label']!),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _prioridadeSelecionada = value ?? 'media');
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _tituloController,
                decoration: InputDecoration(
                  labelText: 'Assunto',
                  hintText: 'Digite um título resumido',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.title),
                ),
                maxLength: 200,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Digite o assunto';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descricaoController,
                decoration: InputDecoration(
                  labelText: 'Descrição Completa',
                  hintText: 'Descreva detalhadamente sua solicitação...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignLabelWithHint: true,
                ),
                maxLines: 5,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Digite a descrição';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isLoading ? null : () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _enviarSolicitacao,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Enviar',
                              style: TextStyle(color: Colors.white),
                            ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetalhesSolicitacao extends StatelessWidget {
  final Map<String, dynamic> solicitacao;
  final VoidCallback onEditar;
  final VoidCallback onExcluir;
  final VoidCallback onRefresh;

  const _DetalhesSolicitacao({
    required this.solicitacao,
    required this.onEditar,
    required this.onExcluir,
    required this.onRefresh,
  });

  String _formatarData(String? data) {
    if (data == null || data.isEmpty) return '';
    try {
      final dateTime = DateTime.parse(data);
      return DateFormat('dd/MM/yyyy HH:mm', 'pt_BR').format(dateTime);
    } catch (e) {
      return data;
    }
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'pendente':
      case 'aberto':
        return Colors.blue;
      case 'em_andamento':
        return Colors.orange;
      case 'resolvido':
        return Colors.green;
      case 'cancelado':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  String _getStatusLabel(String? status) {
    switch (status?.toLowerCase()) {
      case 'pendente':
        return 'Pendente';
      case 'aberto':
        return 'Aberto';
      case 'em_andamento':
        return 'Em Andamento';
      case 'resolvido':
        return 'Resolvido';
      case 'cancelado':
        return 'Cancelado';
      default:
        return status ?? 'Desconhecido';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    const Text(
                      'Detalhes da Solicitação',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor(solicitacao['status']).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _getStatusLabel(solicitacao['status']),
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: _getStatusColor(solicitacao['status']),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildInfoRow('Número', '#${solicitacao['id']}'),
                _buildInfoRow('Tipo', solicitacao['tipo']?.toString().replaceAll('_', ' ') ?? '-'),
                _buildInfoRow('Prioridade', solicitacao['prioridade'] ?? '-'),
                _buildInfoRow('Data de Criação', _formatarData(solicitacao['created_at'])),
                const Divider(height: 32),
                const Text(
                  'Assunto',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  solicitacao['assunto'] ?? solicitacao['titulo'] ?? 'Sem título',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Descrição',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  solicitacao['descricao'] ?? '',
                  style: const TextStyle(fontSize: 15, height: 1.5),
                ),
                if (solicitacao['resposta'] != null) ...[
                  const SizedBox(height: 24),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.green.withOpacity(0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.reply, color: Colors.green[700], size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Resposta da Administração',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.green[700],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          solicitacao['resposta'],
                          style: const TextStyle(fontSize: 15, height: 1.5),
                        ),
                        if (solicitacao['respondido_em'] != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Respondido em ${_formatarData(solicitacao['respondido_em'])}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 32),
                // Botões de ação - só mostra editar/excluir se status for 'aberto'
                if (solicitacao['status']?.toLowerCase() == 'aberto') ...[
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: onEditar,
                          icon: const Icon(Icons.edit),
                          label: const Text('Editar'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: onExcluir,
                          icon: const Icon(Icons.delete, color: Colors.red),
                          label: const Text('Excluir', style: TextStyle(color: Colors.red)),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: const BorderSide(color: Colors.red),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Fechar',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _FormEditarSolicitacao extends StatefulWidget {
  final Map<String, dynamic> solicitacao;
  final VoidCallback onSuccess;

  const _FormEditarSolicitacao({
    required this.solicitacao,
    required this.onSuccess,
  });

  @override
  State<_FormEditarSolicitacao> createState() => _FormEditarSolicitacaoState();
}

class _FormEditarSolicitacaoState extends State<_FormEditarSolicitacao> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _tituloController;
  late TextEditingController _descricaoController;
  final ApiService _apiService = ApiService();

  late String _tipoSelecionado;
  late String _prioridadeSelecionada;
  bool _isLoading = false;

  final List<Map<String, String>> _tipos = [
    {'value': 'agenda_manutencao', 'label': 'Agenda de Manutenção Preventiva'},
    {'value': 'manutencao', 'label': 'Manutenção'},
    {'value': 'mudanca', 'label': 'Mudança'},
    {'value': 'reforma_interna', 'label': 'Reforma Interna'},
    {'value': '2via_boleto', 'label': 'Segunda Via de Boleto'},
  ];

  final List<Map<String, String>> _prioridades = [
    {'value': 'baixa', 'label': 'Baixa'},
    {'value': 'media', 'label': 'Média'},
    {'value': 'alta', 'label': 'Alta'},
    {'value': 'urgente', 'label': 'Urgente'},
  ];

  @override
  void initState() {
    super.initState();
    _tituloController = TextEditingController(
      text: widget.solicitacao['assunto'] ?? widget.solicitacao['titulo'] ?? '',
    );
    _descricaoController = TextEditingController(
      text: widget.solicitacao['descricao'] ?? '',
    );
    _tipoSelecionado = widget.solicitacao['tipo'] ?? 'manutencao';
    _prioridadeSelecionada = widget.solicitacao['prioridade'] ?? 'media';
  }

  Future<void> _salvarSolicitacao() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await _apiService.atualizarSolicitacao(
        id: widget.solicitacao['id'],
        titulo: _tituloController.text,
        descricao: _descricaoController.text,
        tipo: _tipoSelecionado,
        prioridade: _prioridadeSelecionada,
      );

      if (mounted) {
        Navigator.pop(context);
        widget.onSuccess();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Solicitação atualizada com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao atualizar: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _descricaoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Editar Solicitação',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Atualize os dados da sua solicitação',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 24),
              DropdownButtonFormField<String>(
                value: _tipoSelecionado,
                decoration: InputDecoration(
                  labelText: 'Tipo de Solicitação',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.category),
                ),
                items: _tipos.map((tipo) {
                  return DropdownMenuItem<String>(
                    value: tipo['value'],
                    child: Text(tipo['label']!),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _tipoSelecionado = value ?? 'manutencao');
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _prioridadeSelecionada,
                decoration: InputDecoration(
                  labelText: 'Prioridade',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.flag),
                ),
                items: _prioridades.map((p) {
                  return DropdownMenuItem<String>(
                    value: p['value'],
                    child: Text(p['label']!),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _prioridadeSelecionada = value ?? 'media');
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _tituloController,
                decoration: InputDecoration(
                  labelText: 'Assunto',
                  hintText: 'Digite um título resumido',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.title),
                ),
                maxLength: 200,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Digite o assunto';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descricaoController,
                decoration: InputDecoration(
                  labelText: 'Descrição Completa',
                  hintText: 'Descreva detalhadamente sua solicitação...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignLabelWithHint: true,
                ),
                maxLines: 5,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Digite a descrição';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isLoading ? null : () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _salvarSolicitacao,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Salvar',
                              style: TextStyle(color: Colors.white),
                            ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
