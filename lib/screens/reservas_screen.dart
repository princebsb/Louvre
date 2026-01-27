import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../services/badge_service.dart';
import 'termo_responsabilidade_screen.dart';
import 'lista_convidados_screen.dart';

class ReservasScreen extends StatefulWidget {
  const ReservasScreen({super.key});

  @override
  State<ReservasScreen> createState() => _ReservasScreenState();
}

class _ReservasScreenState extends State<ReservasScreen> {
  final ApiService _apiService = ApiService();
  final BadgeService _badgeService = BadgeService();
  List<dynamic> _reservas = [];
  Map<String, dynamic>? _usuario;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await _loadUsuario();
    await _loadReservas();
  }

  Future<void> _loadUsuario() async {
    try {
      final user = await _apiService.getUser();
      if (!mounted) return;
      setState(() => _usuario = user);
    } catch (e) {
      // ignore
    }
  }

  Future<void> _loadReservas() async {
    setState(() => _loading = true);
    try {
      final reservas = await _apiService.getReservas();
      if (!mounted) return;
      setState(() {
        _reservas = reservas;
        _loading = false;
      });
      // Marcar reservas como vistas
      await _badgeService.markReservasAsSeen(reservas);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _reservas = [];
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Minhas Reservas'),
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadReservas,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildNovaReservaCard(),
                    const SizedBox(height: 20),
                    _buildHistoricoReservas(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildNovaReservaCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showNovaReservaDialog(),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.add_circle_outline,
                  color: Color(0xFF2563EB),
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Nova Reserva',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Reserve áreas comuns do condomínio',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                color: Color(0xFF2563EB),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHistoricoReservas() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Histórico de Reservas',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 12),
        if (_reservas.isEmpty)
          _buildEmptyState()
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _reservas.length,
            itemBuilder: (context, index) {
              final reserva = _reservas[index];
              return _buildReservaCard(reserva);
            },
          ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.event_available,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'Você não possui reservas',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Clique em "Nova Reserva" para começar',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReservaCard(Map<String, dynamic> reserva) {
    final status = reserva['status']?.toString().toLowerCase() ?? '';
    final area = reserva['area'] ?? 'Área não especificada';
    final dataReserva = reserva['data_reserva'] ?? '';
    final horarioInicio = reserva['horario_inicio'] ?? '';
    final horarioFim = reserva['horario_fim'] ?? '';

    String dataFormatada = '';
    if (dataReserva.isNotEmpty) {
      try {
        final date = DateTime.parse(dataReserva);
        dataFormatada = DateFormat('dd/MM/yyyy').format(date);
      } catch (e) {
        dataFormatada = dataReserva;
      }
    }

    String horarioFormatado = '';
    if (horarioInicio.isNotEmpty && horarioFim.isNotEmpty) {
      final hi = horarioInicio.length >= 5 ? horarioInicio.substring(0, 5) : horarioInicio;
      final hf = horarioFim.length >= 5 ? horarioFim.substring(0, 5) : horarioFim;
      horarioFormatado = '$hi - $hf';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2563EB).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    _getIconForArea(area),
                    color: const Color(0xFF2563EB),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        area,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        dataFormatada,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                _buildStatusBadge(status),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.access_time, size: 18, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(
                    'Horário: $horarioFormatado',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),
            if (status == 'pendente' || status == 'aprovada') ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (status == 'aprovada') ...[
                    _buildActionButton('Termo', Icons.description, const Color(0xFF2563EB), () => _showTermoDialog(reserva)),
                    _buildActionButton('Lista', Icons.people, Colors.grey[700]!, () => _showConvidadosDialog(reserva)),
                  ],
                  _buildActionButton('Editar', Icons.edit, const Color(0xFF10B981), () => _editarReserva(reserva)),
                  _buildActionButton('Cancelar', Icons.cancel, Colors.red, () => _confirmarCancelamento(reserva)),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(String label, IconData icon, Color color, VoidCallback onPressed) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color backgroundColor;
    Color textColor;
    String text;

    switch (status) {
      case 'aprovada':
        backgroundColor = const Color(0xFF10B981).withOpacity(0.1);
        textColor = const Color(0xFF10B981);
        text = 'Aprovada';
        break;
      case 'pendente':
        backgroundColor = const Color(0xFFF59E0B).withOpacity(0.1);
        textColor = const Color(0xFFF59E0B);
        text = 'Pendente';
        break;
      case 'cancelada':
        backgroundColor = const Color(0xFFEF4444).withOpacity(0.1);
        textColor = const Color(0xFFEF4444);
        text = 'Cancelada';
        break;
      default:
        backgroundColor = Colors.grey.withOpacity(0.1);
        textColor = Colors.grey;
        text = status.isNotEmpty ? status[0].toUpperCase() + status.substring(1) : 'Desconhecido';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  IconData _getIconForArea(String? area) {
    final areaLower = area?.toLowerCase() ?? '';
    if (areaLower.contains('churrasqueira')) return Icons.outdoor_grill;
    if (areaLower.contains('salão') || areaLower.contains('salao') || areaLower.contains('festa')) return Icons.celebration;
    if (areaLower.contains('quadra')) return Icons.sports_soccer;
    if (areaLower.contains('piscina')) return Icons.pool;
    return Icons.event;
  }

  void _showNovaReservaDialog() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NovaReservaScreen(onReservaCriada: _loadReservas),
      ),
    );
  }

  void _editarReserva(Map<String, dynamic> reserva) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NovaReservaScreen(
          reservaExistente: reserva,
          onReservaCriada: _loadReservas,
        ),
      ),
    );
  }

  void _confirmarCancelamento(Map<String, dynamic> reserva) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancelar Reserva'),
        content: const Text('Tem certeza que deseja cancelar esta reserva?\n\nEsta ação não pode ser desfeita.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Não'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _cancelarReserva(reserva);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Sim, Cancelar'),
          ),
        ],
      ),
    );
  }

  Future<void> _cancelarReserva(Map<String, dynamic> reserva) async {
    try {
      final id = reserva['id'];
      if (id == null) throw Exception('ID da reserva não encontrado');
      final idInt = id is int ? id : int.parse(id.toString());
      await _apiService.cancelarReserva(idInt);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reserva cancelada com sucesso!'), backgroundColor: Colors.green),
      );
      _loadReservas();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao cancelar reserva: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _showTermoDialog(Map<String, dynamic> reserva) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TermoResponsabilidadeScreen(
          reserva: reserva,
          usuario: _usuario,
        ),
      ),
    );
  }

  void _showConvidadosDialog(Map<String, dynamic> reserva) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ListaConvidadosScreen(
          reserva: reserva,
          usuario: _usuario,
        ),
      ),
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('dd/MM/yyyy').format(date);
    } catch (e) {
      return dateStr;
    }
  }
}

// ==================== TELA DE NOVA RESERVA ====================

class NovaReservaScreen extends StatefulWidget {
  final Map<String, dynamic>? reservaExistente;
  final VoidCallback? onReservaCriada;

  const NovaReservaScreen({super.key, this.reservaExistente, this.onReservaCriada});

  @override
  State<NovaReservaScreen> createState() => _NovaReservaScreenState();
}

class _NovaReservaScreenState extends State<NovaReservaScreen> {
  final ApiService _apiService = ApiService();
  final _formKey = GlobalKey<FormState>();

  String? _areaSelecionada;
  DateTime? _dataSelecionada;
  TimeOfDay? _horarioInicio;
  TimeOfDay? _horarioFim;
  final TextEditingController _observacoesController = TextEditingController();
  final List<TextEditingController> _convidadosControllers = [TextEditingController()];

  List<String> _datasOcupadas = [];
  Map<String, dynamic>? _precoInfo;
  bool _loadingPreco = false;
  bool _salvando = false;

  final List<String> _areasDisponiveis = [
    'Salão de Festas',
    'Churrasqueira Principal',
    'Churrasqueira Lateral',
  ];

  bool get _isEdicao => widget.reservaExistente != null;

  @override
  void initState() {
    super.initState();
    if (_isEdicao) _carregarDadosReserva();
  }

  void _carregarDadosReserva() {
    final reserva = widget.reservaExistente!;
    _areaSelecionada = reserva['area'];

    if (reserva['data_reserva'] != null) {
      try {
        _dataSelecionada = DateTime.parse(reserva['data_reserva']);
      } catch (e) {}
    }

    if (reserva['horario_inicio'] != null) {
      final parts = reserva['horario_inicio'].toString().split(':');
      if (parts.length >= 2) {
        _horarioInicio = TimeOfDay(hour: int.tryParse(parts[0]) ?? 0, minute: int.tryParse(parts[1]) ?? 0);
      }
    }

    if (reserva['horario_fim'] != null) {
      final parts = reserva['horario_fim'].toString().split(':');
      if (parts.length >= 2) {
        _horarioFim = TimeOfDay(hour: int.tryParse(parts[0]) ?? 0, minute: int.tryParse(parts[1]) ?? 0);
      }
    }

    _observacoesController.text = reserva['observacoes'] ?? '';

    if (reserva['convidados'] != null && reserva['convidados'] is List) {
      final convidados = List<String>.from(reserva['convidados']);
      _convidadosControllers.clear();
      if (convidados.isEmpty) {
        _convidadosControllers.add(TextEditingController());
      } else {
        for (var nome in convidados) {
          _convidadosControllers.add(TextEditingController(text: nome));
        }
      }
    }

    if (_areaSelecionada != null) {
      _carregarDatasOcupadas();
      _carregarPreco();
    }
  }

  @override
  void dispose() {
    _observacoesController.dispose();
    for (var c in _convidadosControllers) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _carregarDatasOcupadas() async {
    if (_areaSelecionada == null) return;
    try {
      final datas = await _apiService.getDatasOcupadas(_areaSelecionada!);
      if (!mounted) return;
      setState(() => _datasOcupadas = datas);
    } catch (e) {}
  }

  Future<void> _carregarPreco() async {
    if (_areaSelecionada == null) return;
    setState(() => _loadingPreco = true);
    try {
      final preco = await _apiService.getPrecoReserva(_areaSelecionada!);
      if (!mounted) return;
      setState(() {
        _precoInfo = preco;
        _loadingPreco = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingPreco = false);
    }
  }

  void _adicionarConvidado() {
    setState(() => _convidadosControllers.add(TextEditingController()));
  }

  void _removerConvidado(int index) {
    if (_convidadosControllers.length > 1) {
      setState(() {
        _convidadosControllers[index].dispose();
        _convidadosControllers.removeAt(index);
      });
    }
  }

  Future<void> _selecionarData() async {
    if (_areaSelecionada == null) {
      _showError('Selecione uma área primeiro');
      return;
    }

    final hoje = DateTime.now();
    final dataInicial = _dataSelecionada ?? hoje;

    final data = await showDatePicker(
      context: context,
      initialDate: dataInicial.isBefore(hoje) ? hoje : dataInicial,
      firstDate: hoje,
      lastDate: hoje.add(const Duration(days: 365)),
      selectableDayPredicate: (DateTime day) {
        final dateStr = DateFormat('yyyy-MM-dd').format(day);
        // Se estamos editando, permitir a data atual da reserva
        if (_isEdicao && widget.reservaExistente!['data_reserva'] == dateStr) {
          return true;
        }
        // Bloquear datas ocupadas
        return !_datasOcupadas.contains(dateStr);
      },
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: Color(0xFF2563EB)),
        ),
        child: child!,
      ),
    );

    if (data != null) {
      final dateStr = DateFormat('yyyy-MM-dd').format(data);
      // Verificação adicional (caso o usuário consiga selecionar de alguma forma)
      if (_datasOcupadas.contains(dateStr) &&
          !(_isEdicao && widget.reservaExistente!['data_reserva'] == dateStr)) {
        _showError('Esta data já está ocupada para $_areaSelecionada');
        return;
      }
      setState(() => _dataSelecionada = data);
    }
  }

  Future<void> _selecionarHorario(bool isInicio) async {
    final horarioAtual = isInicio ? _horarioInicio : _horarioFim;
    final horario = await showTimePicker(
      context: context,
      initialTime: horarioAtual ?? const TimeOfDay(hour: 10, minute: 0),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(colorScheme: const ColorScheme.light(primary: Color(0xFF2563EB))),
        child: child!,
      ),
    );

    if (horario != null) {
      setState(() {
        if (isInicio) {
          _horarioInicio = horario;
        } else {
          _horarioFim = horario;
        }
      });
    }
  }

  String _formatTimeOfDay(TimeOfDay? time) {
    if (time == null) return '';
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _salvarReserva() async {
    if (!_formKey.currentState!.validate()) return;

    if (_areaSelecionada == null) {
      _showError('Selecione uma área');
      return;
    }
    if (_dataSelecionada == null) {
      _showError('Selecione uma data');
      return;
    }
    if (_horarioInicio == null) {
      _showError('Selecione o horário de início');
      return;
    }
    if (_horarioFim == null) {
      _showError('Selecione o horário de fim');
      return;
    }

    final inicioMinutos = _horarioInicio!.hour * 60 + _horarioInicio!.minute;
    final fimMinutos = _horarioFim!.hour * 60 + _horarioFim!.minute;
    if (fimMinutos <= inicioMinutos) {
      _showError('O horário de fim deve ser posterior ao horário de início');
      return;
    }

    setState(() => _salvando = true);

    try {
      final convidados = _convidadosControllers.map((c) => c.text.trim()).where((n) => n.isNotEmpty).toList();
      final dataStr = DateFormat('yyyy-MM-dd').format(_dataSelecionada!);

      if (_isEdicao) {
        final id = widget.reservaExistente!['id'];
        final idInt = id is int ? id : int.parse(id.toString());
        await _apiService.atualizarReserva(
          id: idInt,
          area: _areaSelecionada!,
          dataReserva: dataStr,
          horarioInicio: _formatTimeOfDay(_horarioInicio),
          horarioFim: _formatTimeOfDay(_horarioFim),
          observacoes: _observacoesController.text.trim(),
          convidados: convidados,
        );
      } else {
        await _apiService.criarReserva(
          area: _areaSelecionada!,
          dataReserva: dataStr,
          horarioInicio: _formatTimeOfDay(_horarioInicio),
          horarioFim: _formatTimeOfDay(_horarioFim),
          observacoes: _observacoesController.text.trim(),
          convidados: convidados,
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEdicao ? 'Reserva atualizada com sucesso!' : 'Reserva solicitada com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );
      widget.onReservaCriada?.call();
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      _showError(e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.red));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdicao ? 'Editar Reserva' : 'Nova Reserva'),
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('Área Comum'),
              Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: DropdownButtonFormField<String>(
                    value: _areaSelecionada,
                    decoration: const InputDecoration(border: InputBorder.none, hintText: 'Selecione a área'),
                    items: _areasDisponiveis.map((area) {
                      return DropdownMenuItem(
                        value: area,
                        child: Row(
                          children: [
                            Icon(_getIconForArea(area), color: const Color(0xFF2563EB), size: 20),
                            const SizedBox(width: 12),
                            Text(area),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _areaSelecionada = value;
                        _dataSelecionada = null;
                      });
                      _carregarDatasOcupadas();
                      _carregarPreco();
                    },
                  ),
                ),
              ),

              if (_precoInfo != null && _precoInfo!['success'] == true) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(8),
                    border: const Border(left: BorderSide(color: Color(0xFF2563EB), width: 4)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: Color(0xFF2563EB)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _precoInfo!['isFirst'] == true
                              ? 'Primeira vez usando $_areaSelecionada - GRÁTIS!'
                              : 'Valor desta reserva: R\$ ${(_precoInfo!['price'] ?? 0.0).toStringAsFixed(2).replaceAll('.', ',')}',
                          style: const TextStyle(color: Color(0xFF1E40AF), fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              if (_loadingPreco) ...[
                const SizedBox(height: 12),
                const Center(child: CircularProgressIndicator()),
              ],

              if (_datasOcupadas.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: const Color(0xFFFEF3C7), borderRadius: BorderRadius.circular(8)),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber, color: Color(0xFFD97706), size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Datas ocupadas: ${_datasOcupadas.map((d) => _formatDateStr(d)).join(', ')}',
                          style: const TextStyle(color: Color(0xFF92400E), fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 20),
              _buildSectionTitle('Data'),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.calendar_today, color: Color(0xFF2563EB)),
                  title: Text(
                    _dataSelecionada != null ? DateFormat('dd/MM/yyyy').format(_dataSelecionada!) : 'Selecione a data',
                    style: TextStyle(color: _dataSelecionada != null ? Colors.black : Colors.grey[600]),
                  ),
                  trailing: const Icon(Icons.arrow_drop_down, color: Colors.grey),
                  onTap: _areaSelecionada != null ? _selecionarData : null,
                ),
              ),

              const SizedBox(height: 20),
              _buildSectionTitle('Horário'),
              Row(
                children: [
                  Expanded(
                    child: Card(
                      child: ListTile(
                        leading: const Icon(Icons.access_time, color: Color(0xFF2563EB)),
                        title: Text(
                          _horarioInicio != null ? _formatTimeOfDay(_horarioInicio) : 'Início',
                          style: TextStyle(color: _horarioInicio != null ? Colors.black : Colors.grey[600]),
                        ),
                        onTap: () => _selecionarHorario(true),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Card(
                      child: ListTile(
                        leading: const Icon(Icons.access_time_filled, color: Color(0xFF2563EB)),
                        title: Text(
                          _horarioFim != null ? _formatTimeOfDay(_horarioFim) : 'Fim',
                          style: TextStyle(color: _horarioFim != null ? Colors.black : Colors.grey[600]),
                        ),
                        onTap: () => _selecionarHorario(false),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),
              _buildSectionTitle('Observações (opcional)'),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: TextFormField(
                    controller: _observacoesController,
                    maxLines: 3,
                    decoration: const InputDecoration(hintText: 'Digite observações sobre a reserva...', border: InputBorder.none),
                  ),
                ),
              ),

              const SizedBox(height: 20),
              _buildSectionTitle('Lista de Convidados'),
              Text('Adicione o nome completo de cada convidado', style: TextStyle(fontSize: 13, color: Colors.grey[600])),
              const SizedBox(height: 8),
              ..._convidadosControllers.asMap().entries.map((entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Card(
                            margin: EdgeInsets.zero,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: TextFormField(
                                controller: entry.value,
                                decoration: InputDecoration(
                                  hintText: 'Nome do convidado ${entry.key + 1}',
                                  border: InputBorder.none,
                                  prefixIcon: const Icon(Icons.person_outline),
                                ),
                              ),
                            ),
                          ),
                        ),
                        if (_convidadosControllers.length > 1) ...[
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: () => _removerConvidado(entry.key),
                            icon: const Icon(Icons.remove_circle, color: Colors.red),
                          ),
                        ],
                      ],
                    ),
                  )),
              TextButton.icon(onPressed: _adicionarConvidado, icon: const Icon(Icons.add), label: const Text('Adicionar Convidado')),

              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _salvando ? null : _salvarReserva,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: _salvando
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text(_isEdicao ? 'Atualizar Reserva' : 'Solicitar Reserva', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF1F2937))),
    );
  }

  IconData _getIconForArea(String? area) {
    final areaLower = area?.toLowerCase() ?? '';
    if (areaLower.contains('churrasqueira')) return Icons.outdoor_grill;
    if (areaLower.contains('salão') || areaLower.contains('salao') || areaLower.contains('festa')) return Icons.celebration;
    if (areaLower.contains('quadra')) return Icons.sports_soccer;
    if (areaLower.contains('piscina')) return Icons.pool;
    return Icons.event;
  }

  String _formatDateStr(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('dd/MM').format(date);
    } catch (e) {
      return dateStr;
    }
  }
}
