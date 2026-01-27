import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../services/badge_service.dart';

class ObrasScreen extends StatefulWidget {
  const ObrasScreen({super.key});

  @override
  State<ObrasScreen> createState() => _ObrasScreenState();
}

class _ObrasScreenState extends State<ObrasScreen> {
  final ApiService _apiService = ApiService();
  final BadgeService _badgeService = BadgeService();
  List<dynamic> _obras = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _carregarObras();
  }

  Future<void> _carregarObras() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final obras = await _apiService.getObras();
      if (mounted) {
        setState(() {
          _obras = obras;
          _isLoading = false;
        });
        // Marcar obras como vistas
        await _badgeService.markObrasAsSeen(obras);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'planejada':
        return Colors.blue;
      case 'em_andamento':
        return Colors.orange;
      case 'pausada':
        return Colors.grey;
      case 'concluida':
        return Colors.green;
      case 'cancelada':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getTipoIcon(String? tipo) {
    switch (tipo?.toLowerCase()) {
      case 'manutencao':
        return Icons.build;
      case 'reforma':
        return Icons.construction;
      case 'ampliacao':
        return Icons.add_home;
      case 'emergencial':
        return Icons.warning;
      case 'preventiva':
        return Icons.shield;
      case 'corretiva':
        return Icons.handyman;
      default:
        return Icons.engineering;
    }
  }

  String _formatarData(String? data) {
    if (data == null || data.isEmpty) return '-';
    try {
      final dateTime = DateTime.parse(data);
      return DateFormat('dd/MM/yyyy', 'pt_BR').format(dateTime);
    } catch (e) {
      return data;
    }
  }

  String _formatarValor(double? valor) {
    if (valor == null || valor == 0) return '-';
    return NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$').format(valor);
  }

  void _verDetalhes(Map<String, dynamic> obra) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _DetalhesObra(obra: obra, apiService: _apiService),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Obras do Condomínio'),
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
                        onPressed: _carregarObras,
                        child: const Text('Tentar novamente'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _carregarObras,
                  child: _obras.isEmpty
                      ? ListView(
                          children: [
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.6,
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.construction,
                                      size: 80,
                                      color: Colors.grey[400],
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Nenhuma obra disponível',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey[600],
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
                          itemCount: _obras.length,
                          itemBuilder: (context, index) {
                            final obra = _obras[index];
                            final percentual = obra['valor_orcado'] > 0
                                ? (obra['valor_gasto'] / obra['valor_orcado'] * 100)
                                : 0.0;

                            return Card(
                              margin: const EdgeInsets.only(bottom: 16),
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: InkWell(
                                onTap: () => _verDetalhes(obra),
                                borderRadius: BorderRadius.circular(12),
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
                                              _getTipoIcon(obra['tipo']),
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
                                                  obra['titulo'] ?? 'Sem título',
                                                  style: const TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                  maxLines: 2,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  obra['tipo_label'] ?? obra['tipo'] ?? '',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey[600],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 5,
                                            ),
                                            decoration: BoxDecoration(
                                              color: _getStatusColor(obra['status']).withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              obra['status_label'] ?? obra['status'] ?? '',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: _getStatusColor(obra['status']),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (obra['descricao'] != null && obra['descricao'].isNotEmpty) ...[
                                        const SizedBox(height: 12),
                                        Text(
                                          obra['descricao'],
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey[600],
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                      const SizedBox(height: 12),
                                      Row(
                                        children: [
                                          if (obra['data_inicio'] != null) ...[
                                            Icon(Icons.play_arrow, size: 14, color: Colors.grey[500]),
                                            const SizedBox(width: 4),
                                            Text(
                                              _formatarData(obra['data_inicio']),
                                              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                            ),
                                            const SizedBox(width: 16),
                                          ],
                                          if (obra['data_previsao_termino'] != null) ...[
                                            Icon(Icons.flag, size: 14, color: Colors.grey[500]),
                                            const SizedBox(width: 4),
                                            Text(
                                              _formatarData(obra['data_previsao_termino']),
                                              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                            ),
                                          ],
                                        ],
                                      ),
                                      if (obra['valor_orcado'] != null && obra['valor_orcado'] > 0) ...[
                                        const SizedBox(height: 12),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              _formatarValor(obra['valor_orcado']?.toDouble()),
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF2563EB),
                                              ),
                                            ),
                                            if (obra['valor_gasto'] != null && obra['valor_gasto'] > 0)
                                              Text(
                                                '${percentual.toStringAsFixed(0)}% executado',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                          ],
                                        ),
                                        if (percentual > 0) ...[
                                          const SizedBox(height: 8),
                                          LinearProgressIndicator(
                                            value: percentual / 100,
                                            backgroundColor: Colors.grey[200],
                                            valueColor: AlwaysStoppedAnimation<Color>(
                                              percentual >= 100 ? Colors.green : const Color(0xFF2563EB),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ],
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

class _DetalhesObra extends StatefulWidget {
  final Map<String, dynamic> obra;
  final ApiService apiService;

  const _DetalhesObra({required this.obra, required this.apiService});

  @override
  State<_DetalhesObra> createState() => _DetalhesObraState();
}

class _DetalhesObraState extends State<_DetalhesObra> {
  Map<String, dynamic>? _obraDetalhes;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _carregarDetalhes();
  }

  Future<void> _carregarDetalhes() async {
    try {
      final detalhes = await widget.apiService.getObra(widget.obra['id']);
      if (mounted) {
        setState(() {
          _obraDetalhes = detalhes;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _obraDetalhes = widget.obra;
          _isLoading = false;
        });
      }
    }
  }

  String _formatarData(String? data) {
    if (data == null || data.isEmpty) return '-';
    try {
      final dateTime = DateTime.parse(data);
      return DateFormat('dd/MM/yyyy', 'pt_BR').format(dateTime);
    } catch (e) {
      return data;
    }
  }

  String _formatarValor(double? valor) {
    if (valor == null || valor == 0) return '-';
    return NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$').format(valor);
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'planejada':
        return Colors.blue;
      case 'em_andamento':
        return Colors.orange;
      case 'pausada':
        return Colors.grey;
      case 'concluida':
        return Colors.green;
      case 'cancelada':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void _abrirFoto(BuildContext context, Map<String, dynamic> foto) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.7,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.black,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  foto['url'] ?? '',
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 200,
                    color: Colors.grey[800],
                    child: const Center(
                      child: Icon(Icons.broken_image, color: Colors.white, size: 64),
                    ),
                  ),
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      height: 200,
                      color: Colors.grey[800],
                      child: const Center(child: CircularProgressIndicator(color: Colors.white)),
                    );
                  },
                ),
              ),
            ),
            if (foto['descricao'] != null && foto['descricao'].toString().isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  foto['descricao'],
                  style: const TextStyle(fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close),
              label: const Text('Fechar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final obra = _obraDetalhes ?? widget.obra;
    final percentual = (obra['valor_orcado'] ?? 0) > 0
        ? ((obra['valor_gasto'] ?? 0) / obra['valor_orcado'] * 100)
        : 0.0;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        obra['titulo'] ?? 'Detalhes da Obra',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _getStatusColor(obra['status']).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        obra['status_label'] ?? obra['status'] ?? '',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: _getStatusColor(obra['status']),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Tipo
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2563EB).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.label, size: 16, color: Color(0xFF2563EB)),
                              const SizedBox(width: 8),
                              Text(
                                obra['tipo_label'] ?? obra['tipo'] ?? '',
                                style: const TextStyle(
                                  color: Color(0xFF2563EB),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Descrição
                        if (obra['descricao'] != null && obra['descricao'].isNotEmpty) ...[
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
                            obra['descricao'],
                            style: const TextStyle(fontSize: 15, height: 1.5),
                          ),
                          const SizedBox(height: 20),
                        ],

                        // Datas
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              _buildInfoRow('Início', _formatarData(obra['data_inicio'])),
                              _buildInfoRow('Previsão de Término', _formatarData(obra['data_previsao_termino'])),
                              if (obra['data_termino_real'] != null)
                                _buildInfoRow('Término Real', _formatarData(obra['data_termino_real'])),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Valores
                        if ((obra['valor_orcado'] ?? 0) > 0) ...[
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2563EB).withOpacity(0.05),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFF2563EB).withOpacity(0.2)),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('Valor Orçado', style: TextStyle(color: Colors.grey)),
                                    Text(
                                      _formatarValor(obra['valor_orcado']?.toDouble()),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: Color(0xFF2563EB),
                                      ),
                                    ),
                                  ],
                                ),
                                if ((obra['valor_gasto'] ?? 0) > 0) ...[
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text('Valor Gasto', style: TextStyle(color: Colors.grey)),
                                      Text(
                                        _formatarValor(obra['valor_gasto']?.toDouble()),
                                        style: const TextStyle(fontWeight: FontWeight.w500),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  LinearProgressIndicator(
                                    value: percentual / 100,
                                    backgroundColor: Colors.grey[200],
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      percentual >= 100 ? Colors.green : const Color(0xFF2563EB),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${percentual.toStringAsFixed(1)}% executado',
                                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Responsável e Empresa
                        if ((obra['responsavel'] != null && obra['responsavel'].toString().isNotEmpty) ||
                            (obra['empresa_contratada'] != null && obra['empresa_contratada'].toString().isNotEmpty)) ...[
                          const Text(
                            'Equipe e Execução',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (obra['responsavel'] != null && obra['responsavel'].toString().isNotEmpty)
                            Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    const Color(0xFF2563EB).withOpacity(0.05),
                                    const Color(0xFF2563EB).withOpacity(0.02),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFF2563EB).withOpacity(0.15),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF2563EB).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(
                                      Icons.person,
                                      color: Color(0xFF2563EB),
                                      size: 22,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Responsável',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          obra['responsavel'],
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          if (obra['empresa_contratada'] != null && obra['empresa_contratada'].toString().isNotEmpty)
                            Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.orange.withOpacity(0.05),
                                    Colors.orange.withOpacity(0.02),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.orange.withOpacity(0.15),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(
                                      Icons.business,
                                      color: Colors.orange,
                                      size: 22,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Empresa Contratada',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          obra['empresa_contratada'],
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          const SizedBox(height: 4),
                        ],

                        // Fotos da Obra
                        if (_obraDetalhes?['fotos'] != null &&
                            (_obraDetalhes!['fotos'] as List).isNotEmpty) ...[
                          const Text(
                            'Fotos da Obra',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 180,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: (_obraDetalhes!['fotos'] as List).length,
                              itemBuilder: (context, index) {
                                final foto = (_obraDetalhes!['fotos'] as List)[index];
                                return GestureDetector(
                                  onTap: () => _abrirFoto(context, foto),
                                  child: Container(
                                    width: 160,
                                    margin: EdgeInsets.only(right: index < (_obraDetalhes!['fotos'] as List).length - 1 ? 12 : 0),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.grey.shade200),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        ClipRRect(
                                          borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
                                          child: Image.network(
                                            foto['url'] ?? '',
                                            height: 120,
                                            width: 160,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) => Container(
                                              height: 120,
                                              width: 160,
                                              color: Colors.grey[200],
                                              child: const Icon(Icons.broken_image, color: Colors.grey, size: 40),
                                            ),
                                            loadingBuilder: (context, child, loadingProgress) {
                                              if (loadingProgress == null) return child;
                                              return Container(
                                                height: 120,
                                                width: 160,
                                                color: Colors.grey[100],
                                                child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                                              );
                                            },
                                          ),
                                        ),
                                        Expanded(
                                          child: Padding(
                                            padding: const EdgeInsets.all(8),
                                            child: Text(
                                              foto['descricao'] ?? 'Sem descrição',
                                              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],

                        // Acompanhamentos
                        if (_obraDetalhes?['acompanhamentos'] != null &&
                            (_obraDetalhes!['acompanhamentos'] as List).isNotEmpty) ...[
                          const Text(
                            'Acompanhamentos',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ...(_obraDetalhes!['acompanhamentos'] as List).map((a) => Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  a['descricao'] ?? '',
                                  style: const TextStyle(fontSize: 14),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _formatarData(a['data_registro']),
                                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                ),
                              ],
                            ),
                          )),
                        ],

                        const SizedBox(height: 24),
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
                            child: const Text('Fechar', style: TextStyle(color: Colors.white)),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600])),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
