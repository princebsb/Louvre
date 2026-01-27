import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/badge_service.dart';
import 'package:intl/intl.dart';

class OcorrenciasScreen extends StatefulWidget {
  const OcorrenciasScreen({super.key});

  @override
  State<OcorrenciasScreen> createState() => _OcorrenciasScreenState();
}

class _OcorrenciasScreenState extends State<OcorrenciasScreen> {
  final ApiService _apiService = ApiService();
  final BadgeService _badgeService = BadgeService();
  List<dynamic> _ocorrencias = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _carregarOcorrencias();
  }

  Future<void> _carregarOcorrencias() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final ocorrencias = await _apiService.getOcorrencias();
      setState(() {
        _ocorrencias = ocorrencias;
        _isLoading = false;
      });
      // Marcar ocorrencias como vistas
      await _badgeService.markOcorrenciasAsSeen(ocorrencias);
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _abrirNovaOcorrencia() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _FormNovaOcorrencia(
        onSuccess: () {
          _carregarOcorrencias();
        },
      ),
    );
  }

  void _verDetalhes(Map<String, dynamic> ocorrencia) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _DetalhesOcorrencia(
        ocorrencia: ocorrencia,
        onEditar: () => _editarOcorrencia(ocorrencia),
        onExcluir: () => _excluirOcorrencia(ocorrencia),
        onRefresh: _carregarOcorrencias,
      ),
    );
  }

  void _editarOcorrencia(Map<String, dynamic> ocorrencia) {
    Navigator.pop(context); // Fecha o modal de detalhes
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _FormEditarOcorrencia(
        ocorrencia: ocorrencia,
        onSuccess: _carregarOcorrencias,
      ),
    );
  }

  Future<void> _excluirOcorrencia(Map<String, dynamic> ocorrencia) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir Ocorrência'),
        content: const Text('Tem certeza que deseja excluir esta ocorrência?'),
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
      await _apiService.excluirOcorrencia(ocorrencia['id']);
      if (mounted) {
        Navigator.pop(context); // Fecha o modal de detalhes
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ocorrência excluída com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
        _carregarOcorrencias();
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

  Color _getGravidadeColor(String? gravidade) {
    switch (gravidade?.toLowerCase()) {
      case 'baixa':
        return Colors.blue;
      case 'media':
        return Colors.orange;
      case 'alta':
        return Colors.red;
      case 'critica':
        return const Color(0xFF991B1B);
      default:
        return Colors.grey;
    }
  }

  String _getGravidadeLabel(String? gravidade) {
    switch (gravidade?.toLowerCase()) {
      case 'baixa':
        return 'Baixa';
      case 'media':
        return 'Média';
      case 'alta':
        return 'Alta';
      case 'critica':
        return 'Crítica';
      default:
        return gravidade ?? 'Desconhecida';
    }
  }

  IconData _getTipoIcon(String? tipo) {
    switch (tipo?.toLowerCase()) {
      case 'seguranca':
        return Icons.security;
      case 'vandalismo':
        return Icons.warning;
      case 'furto':
        return Icons.local_police;
      case 'incendio':
        return Icons.local_fire_department;
      case 'acidente':
        return Icons.car_crash;
      case 'barulho':
        return Icons.volume_up;
      case 'brigas':
        return Icons.people;
      case 'agua':
        return Icons.water_drop;
      default:
        return Icons.report_problem;
    }
  }

  String _getTipoLabel(String? tipo) {
    switch (tipo?.toLowerCase()) {
      case 'seguranca':
        return 'Segurança';
      case 'vandalismo':
        return 'Vandalismo';
      case 'furto':
        return 'Furto/Roubo';
      case 'incendio':
        return 'Incêndio';
      case 'acidente':
        return 'Acidente';
      case 'barulho':
        return 'Perturbação';
      case 'brigas':
        return 'Brigas';
      case 'agua':
        return 'Vazamento';
      default:
        return tipo ?? 'Outro';
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
        title: const Text('Ocorrências'),
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
                        onPressed: _carregarOcorrencias,
                        child: const Text('Tentar novamente'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _carregarOcorrencias,
                  child: _ocorrencias.isEmpty
                      ? ListView(
                          children: [
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.6,
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.shield_outlined,
                                      size: 80,
                                      color: Colors.grey[400],
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Nenhuma ocorrência registrada',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Clique em + para registrar uma ocorrência',
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
                          itemCount: _ocorrencias.length,
                          itemBuilder: (context, index) {
                            final ocorrencia = _ocorrencias[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: InkWell(
                                onTap: () => _verDetalhes(ocorrencia),
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border(
                                      left: BorderSide(
                                        color: _getGravidadeColor(ocorrencia['gravidade']),
                                        width: 4,
                                      ),
                                    ),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color: _getGravidadeColor(ocorrencia['gravidade'])
                                                    .withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Icon(
                                                _getTipoIcon(ocorrencia['tipo']),
                                                color: _getGravidadeColor(ocorrencia['gravidade']),
                                                size: 20,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    _getTipoLabel(ocorrencia['tipo']),
                                                    style: const TextStyle(
                                                      fontSize: 16,
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                  ),
                                                  if (ocorrencia['local'] != null) ...[
                                                    const SizedBox(height: 2),
                                                    Text(
                                                      ocorrencia['local'],
                                                      style: TextStyle(
                                                        fontSize: 13,
                                                        color: Colors.grey[600],
                                                      ),
                                                    ),
                                                  ],
                                                ],
                                              ),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 4,
                                              ),
                                              decoration: BoxDecoration(
                                                color: _getGravidadeColor(ocorrencia['gravidade'])
                                                    .withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                _getGravidadeLabel(ocorrencia['gravidade']),
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                  color: _getGravidadeColor(ocorrencia['gravidade']),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          ocorrencia['descricao'] ?? '',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey[700],
                                          ),
                                          maxLines: 3,
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
                                              _formatarData(ocorrencia['created_at']),
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey[500],
                                              ),
                                            ),
                                            if (ocorrencia['resposta_admin'] != null) ...[
                                              const Spacer(),
                                              Icon(
                                                Icons.check_circle,
                                                size: 14,
                                                color: Colors.green[600],
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                'Com resposta',
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
                              ),
                            );
                          },
                        ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _abrirNovaOcorrencia,
        backgroundColor: const Color(0xFF2563EB),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

class _FormNovaOcorrencia extends StatefulWidget {
  final VoidCallback onSuccess;

  const _FormNovaOcorrencia({required this.onSuccess});

  @override
  State<_FormNovaOcorrencia> createState() => _FormNovaOcorrenciaState();
}

class _FormNovaOcorrenciaState extends State<_FormNovaOcorrencia> {
  final _formKey = GlobalKey<FormState>();
  final _localController = TextEditingController();
  final _descricaoController = TextEditingController();
  final _envolvidosController = TextEditingController();
  final _providenciasController = TextEditingController();
  final ApiService _apiService = ApiService();

  String _tipoSelecionado = '';
  String _gravidadeSelecionada = 'media';
  DateTime _dataOcorrencia = DateTime.now();
  TimeOfDay _horaOcorrencia = TimeOfDay.now();
  bool _isLoading = false;

  final List<Map<String, dynamic>> _tipos = [
    {'value': 'seguranca', 'label': 'Segurança', 'icon': Icons.security},
    {'value': 'vandalismo', 'label': 'Vandalismo', 'icon': Icons.warning},
    {'value': 'furto', 'label': 'Furto/Roubo', 'icon': Icons.local_police},
    {'value': 'incendio', 'label': 'Incêndio', 'icon': Icons.local_fire_department},
    {'value': 'acidente', 'label': 'Acidente', 'icon': Icons.car_crash},
    {'value': 'barulho', 'label': 'Perturbação/Barulho', 'icon': Icons.volume_up},
    {'value': 'brigas', 'label': 'Brigas/Discussões', 'icon': Icons.people},
    {'value': 'agua', 'label': 'Vazamento de Água', 'icon': Icons.water_drop},
    {'value': 'outro', 'label': 'Outro', 'icon': Icons.report_problem},
  ];

  final List<Map<String, String>> _gravidades = [
    {'value': 'baixa', 'label': 'Baixa'},
    {'value': 'media', 'label': 'Média'},
    {'value': 'alta', 'label': 'Alta'},
  ];

  Future<void> _selecionarData() async {
    final data = await showDatePicker(
      context: context,
      initialDate: _dataOcorrencia,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now(),
      locale: const Locale('pt', 'BR'),
    );
    if (data != null) {
      setState(() => _dataOcorrencia = data);
    }
  }

  Future<void> _selecionarHora() async {
    final hora = await showTimePicker(
      context: context,
      initialTime: _horaOcorrencia,
    );
    if (hora != null) {
      setState(() => _horaOcorrencia = hora);
    }
  }

  Future<void> _enviarOcorrencia() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Formatar data e hora
      final dataFormatada = '${_dataOcorrencia.year}-${_dataOcorrencia.month.toString().padLeft(2, '0')}-${_dataOcorrencia.day.toString().padLeft(2, '0')}';
      final horaFormatada = '${_horaOcorrencia.hour.toString().padLeft(2, '0')}:${_horaOcorrencia.minute.toString().padLeft(2, '0')}:00';

      await _apiService.criarOcorrencia(
        descricao: _descricaoController.text,
        local: _localController.text,
        tipo: _tipoSelecionado.isNotEmpty ? _tipoSelecionado : 'outro',
        gravidade: _gravidadeSelecionada,
        dataOcorrencia: dataFormatada,
        horaOcorrencia: horaFormatada,
        envolvidos: _envolvidosController.text.isNotEmpty ? _envolvidosController.text : null,
        providencias: _providenciasController.text.isNotEmpty ? _providenciasController.text : null,
      );

      if (mounted) {
        Navigator.pop(context);
        widget.onSuccess();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ocorrência registrada com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao registrar: ${e.toString()}'),
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

  String _getTipoLabel(String? tipo) {
    final t = _tipos.firstWhere(
      (t) => t['value'] == tipo,
      orElse: () => {'label': tipo ?? 'Outro'},
    );
    return t['label'];
  }

  @override
  void dispose() {
    _localController.dispose();
    _descricaoController.dispose();
    _envolvidosController.dispose();
    _providenciasController.dispose();
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
                'Registrar Ocorrência',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Registre incidentes de segurança ou problemas no condomínio',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 24),
              DropdownButtonFormField<String>(
                value: _tipoSelecionado.isEmpty ? null : _tipoSelecionado,
                decoration: InputDecoration(
                  labelText: 'Tipo de Ocorrência *',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.report_problem),
                ),
                items: _tipos.map((tipo) {
                  return DropdownMenuItem<String>(
                    value: tipo['value'],
                    child: Row(
                      children: [
                        Icon(tipo['icon'], size: 20, color: Colors.grey[600]),
                        const SizedBox(width: 8),
                        Text(tipo['label']),
                      ],
                    ),
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
                value: _gravidadeSelecionada,
                decoration: InputDecoration(
                  labelText: 'Gravidade *',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.flag),
                ),
                items: _gravidades.map((g) {
                  return DropdownMenuItem<String>(
                    value: g['value'],
                    child: Text(g['label']!),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _gravidadeSelecionada = value ?? 'media');
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: _selecionarData,
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Data *',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon: const Icon(Icons.calendar_today),
                        ),
                        child: Text(
                          DateFormat('dd/MM/yyyy').format(_dataOcorrencia),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: InkWell(
                      onTap: _selecionarHora,
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Hora *',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon: const Icon(Icons.access_time),
                        ),
                        child: Text(
                          _horaOcorrencia.format(context),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _localController,
                decoration: InputDecoration(
                  labelText: 'Local da Ocorrência *',
                  hintText: 'Ex: Portaria, Garagem, Bloco A',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.location_on),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Digite o local';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descricaoController,
                decoration: InputDecoration(
                  labelText: 'Descrição Detalhada *',
                  hintText: 'Descreva o que aconteceu com detalhes...',
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
              const SizedBox(height: 16),
              TextFormField(
                controller: _envolvidosController,
                decoration: InputDecoration(
                  labelText: 'Pessoas Envolvidas (opcional)',
                  hintText: 'Nome das pessoas envolvidas, se houver...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.people),
                  alignLabelWithHint: true,
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _providenciasController,
                decoration: InputDecoration(
                  labelText: 'Providências Tomadas (opcional)',
                  hintText: 'Quais ações foram tomadas imediatamente...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.checklist),
                  alignLabelWithHint: true,
                ),
                maxLines: 3,
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
                      onPressed: _isLoading ? null : _enviarOcorrencia,
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
                              'Registrar',
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

class _DetalhesOcorrencia extends StatelessWidget {
  final Map<String, dynamic> ocorrencia;
  final VoidCallback onEditar;
  final VoidCallback onExcluir;
  final VoidCallback onRefresh;

  const _DetalhesOcorrencia({
    required this.ocorrencia,
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

  Color _getGravidadeColor(String? gravidade) {
    switch (gravidade?.toLowerCase()) {
      case 'baixa':
        return Colors.blue;
      case 'media':
        return Colors.orange;
      case 'alta':
        return Colors.red;
      case 'critica':
        return const Color(0xFF991B1B);
      default:
        return Colors.grey;
    }
  }

  String _getGravidadeLabel(String? gravidade) {
    switch (gravidade?.toLowerCase()) {
      case 'baixa':
        return 'Baixa';
      case 'media':
        return 'Média';
      case 'alta':
        return 'Alta';
      case 'critica':
        return 'Crítica';
      default:
        return gravidade ?? 'Desconhecida';
    }
  }

  String _getTipoLabel(String? tipo) {
    switch (tipo?.toLowerCase()) {
      case 'seguranca':
        return 'Segurança';
      case 'vandalismo':
        return 'Vandalismo';
      case 'furto':
        return 'Furto/Roubo';
      case 'incendio':
        return 'Incêndio';
      case 'acidente':
        return 'Acidente';
      case 'barulho':
        return 'Perturbação';
      case 'brigas':
        return 'Brigas';
      case 'agua':
        return 'Vazamento';
      default:
        return tipo ?? 'Outro';
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
                      'Detalhes da Ocorrência',
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
                        color: _getGravidadeColor(ocorrencia['gravidade']).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _getGravidadeLabel(ocorrencia['gravidade']),
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: _getGravidadeColor(ocorrencia['gravidade']),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildInfoRow('Tipo', _getTipoLabel(ocorrencia['tipo'])),
                _buildInfoRow('Local', ocorrencia['local'] ?? '-'),
                _buildInfoRow('Data do Registro', _formatarData(ocorrencia['created_at'])),
                if (ocorrencia['data_ocorrencia'] != null)
                  _buildInfoRow('Data da Ocorrência', _formatarData(ocorrencia['data_ocorrencia'])),
                const Divider(height: 32),
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
                  ocorrencia['descricao'] ?? '',
                  style: const TextStyle(fontSize: 15, height: 1.5),
                ),
                if (ocorrencia['envolvidos'] != null && ocorrencia['envolvidos'].toString().isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Envolvidos',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          ocorrencia['envolvidos'],
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ],
                if (ocorrencia['providencias'] != null && ocorrencia['providencias'].toString().isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Providências Tomadas',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.blue[800],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          ocorrencia['providencias'],
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ],
                if (ocorrencia['resposta_admin'] != null) ...[
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
                            Icon(Icons.check_circle, color: Colors.green[700], size: 20),
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
                          ocorrencia['resposta_admin'],
                          style: const TextStyle(fontSize: 15, height: 1.5),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 32),
                // Botões de ação - editar/excluir
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
          Flexible(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}

class _FormEditarOcorrencia extends StatefulWidget {
  final Map<String, dynamic> ocorrencia;
  final VoidCallback onSuccess;

  const _FormEditarOcorrencia({
    required this.ocorrencia,
    required this.onSuccess,
  });

  @override
  State<_FormEditarOcorrencia> createState() => _FormEditarOcorrenciaState();
}

class _FormEditarOcorrenciaState extends State<_FormEditarOcorrencia> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _localController;
  late TextEditingController _descricaoController;
  late TextEditingController _envolvidosController;
  late TextEditingController _providenciasController;
  final ApiService _apiService = ApiService();

  late String _tipoSelecionado;
  late String _gravidadeSelecionada;
  late DateTime _dataOcorrencia;
  late TimeOfDay _horaOcorrencia;
  bool _isLoading = false;

  final List<Map<String, dynamic>> _tipos = [
    {'value': 'seguranca', 'label': 'Segurança', 'icon': Icons.security},
    {'value': 'vandalismo', 'label': 'Vandalismo', 'icon': Icons.warning},
    {'value': 'furto', 'label': 'Furto/Roubo', 'icon': Icons.local_police},
    {'value': 'incendio', 'label': 'Incêndio', 'icon': Icons.local_fire_department},
    {'value': 'acidente', 'label': 'Acidente', 'icon': Icons.car_crash},
    {'value': 'barulho', 'label': 'Perturbação/Barulho', 'icon': Icons.volume_up},
    {'value': 'brigas', 'label': 'Brigas/Discussões', 'icon': Icons.people},
    {'value': 'agua', 'label': 'Vazamento de Água', 'icon': Icons.water_drop},
    {'value': 'outro', 'label': 'Outro', 'icon': Icons.report_problem},
  ];

  final List<Map<String, String>> _gravidades = [
    {'value': 'baixa', 'label': 'Baixa'},
    {'value': 'media', 'label': 'Média'},
    {'value': 'alta', 'label': 'Alta'},
  ];

  @override
  void initState() {
    super.initState();
    _localController = TextEditingController(text: widget.ocorrencia['local'] ?? '');
    _descricaoController = TextEditingController(text: widget.ocorrencia['descricao'] ?? '');
    _envolvidosController = TextEditingController(text: widget.ocorrencia['envolvidos'] ?? '');
    _providenciasController = TextEditingController(text: widget.ocorrencia['providencias'] ?? '');
    _tipoSelecionado = widget.ocorrencia['tipo'] ?? 'outro';
    _gravidadeSelecionada = widget.ocorrencia['gravidade'] ?? 'media';

    // Parse data
    if (widget.ocorrencia['data_ocorrencia'] != null) {
      try {
        _dataOcorrencia = DateTime.parse(widget.ocorrencia['data_ocorrencia']);
      } catch (e) {
        _dataOcorrencia = DateTime.now();
      }
    } else {
      _dataOcorrencia = DateTime.now();
    }

    // Parse hora
    if (widget.ocorrencia['hora_ocorrencia'] != null) {
      try {
        final parts = widget.ocorrencia['hora_ocorrencia'].toString().split(':');
        _horaOcorrencia = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
      } catch (e) {
        _horaOcorrencia = TimeOfDay.now();
      }
    } else {
      _horaOcorrencia = TimeOfDay.now();
    }
  }

  Future<void> _selecionarData() async {
    final data = await showDatePicker(
      context: context,
      initialDate: _dataOcorrencia,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now(),
      locale: const Locale('pt', 'BR'),
    );
    if (data != null) {
      setState(() => _dataOcorrencia = data);
    }
  }

  Future<void> _selecionarHora() async {
    final hora = await showTimePicker(
      context: context,
      initialTime: _horaOcorrencia,
    );
    if (hora != null) {
      setState(() => _horaOcorrencia = hora);
    }
  }

  Future<void> _salvarOcorrencia() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final dataFormatada = '${_dataOcorrencia.year}-${_dataOcorrencia.month.toString().padLeft(2, '0')}-${_dataOcorrencia.day.toString().padLeft(2, '0')}';
      final horaFormatada = '${_horaOcorrencia.hour.toString().padLeft(2, '0')}:${_horaOcorrencia.minute.toString().padLeft(2, '0')}:00';

      await _apiService.atualizarOcorrencia(
        id: widget.ocorrencia['id'],
        descricao: _descricaoController.text,
        local: _localController.text,
        tipo: _tipoSelecionado,
        gravidade: _gravidadeSelecionada,
        dataOcorrencia: dataFormatada,
        horaOcorrencia: horaFormatada,
        envolvidos: _envolvidosController.text.isNotEmpty ? _envolvidosController.text : null,
        providencias: _providenciasController.text.isNotEmpty ? _providenciasController.text : null,
      );

      if (mounted) {
        Navigator.pop(context);
        widget.onSuccess();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ocorrência atualizada com sucesso!'),
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
    _localController.dispose();
    _descricaoController.dispose();
    _envolvidosController.dispose();
    _providenciasController.dispose();
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
                'Editar Ocorrência',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Atualize os dados da ocorrência',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 24),
              DropdownButtonFormField<String>(
                value: _tipoSelecionado,
                decoration: InputDecoration(
                  labelText: 'Tipo de Ocorrência *',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.report_problem),
                ),
                items: _tipos.map((tipo) {
                  return DropdownMenuItem<String>(
                    value: tipo['value'],
                    child: Row(
                      children: [
                        Icon(tipo['icon'], size: 20, color: Colors.grey[600]),
                        const SizedBox(width: 8),
                        Text(tipo['label']),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _tipoSelecionado = value ?? 'outro');
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _gravidadeSelecionada,
                decoration: InputDecoration(
                  labelText: 'Gravidade *',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.flag),
                ),
                items: _gravidades.map((g) {
                  return DropdownMenuItem<String>(
                    value: g['value'],
                    child: Text(g['label']!),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _gravidadeSelecionada = value ?? 'media');
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: _selecionarData,
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Data *',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon: const Icon(Icons.calendar_today),
                        ),
                        child: Text(
                          DateFormat('dd/MM/yyyy').format(_dataOcorrencia),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: InkWell(
                      onTap: _selecionarHora,
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Hora *',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon: const Icon(Icons.access_time),
                        ),
                        child: Text(
                          _horaOcorrencia.format(context),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _localController,
                decoration: InputDecoration(
                  labelText: 'Local da Ocorrência *',
                  hintText: 'Ex: Portaria, Garagem, Bloco A',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.location_on),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Digite o local';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descricaoController,
                decoration: InputDecoration(
                  labelText: 'Descrição Detalhada *',
                  hintText: 'Descreva o que aconteceu com detalhes...',
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
              const SizedBox(height: 16),
              TextFormField(
                controller: _envolvidosController,
                decoration: InputDecoration(
                  labelText: 'Pessoas Envolvidas (opcional)',
                  hintText: 'Nome das pessoas envolvidas, se houver...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.people),
                  alignLabelWithHint: true,
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _providenciasController,
                decoration: InputDecoration(
                  labelText: 'Providências Tomadas (opcional)',
                  hintText: 'Quais ações foram tomadas imediatamente...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.checklist),
                  alignLabelWithHint: true,
                ),
                maxLines: 3,
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
                      onPressed: _isLoading ? null : _salvarOcorrencia,
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
