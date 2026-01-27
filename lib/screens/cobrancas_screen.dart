import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import '../services/api_service.dart';
import '../services/badge_service.dart';

class CobrancasScreen extends StatefulWidget {
  const CobrancasScreen({super.key});

  @override
  State<CobrancasScreen> createState() => _CobrancasScreenState();
}

class _CobrancasScreenState extends State<CobrancasScreen> {
  final _apiService = ApiService();
  final _badgeService = BadgeService();
  List<dynamic> _cobrancas = [];
  Map<String, List<dynamic>> _cobrancasPorMes = {};
  bool _isLoading = true;
  int? _expandedIndex;

  @override
  void initState() {
    super.initState();
    _loadCobrancas();
  }

  Future<void> _loadCobrancas() async {
    try {
      final data = await _apiService.getCobrancas();
      setState(() {
        _cobrancas = data;
        _cobrancasPorMes = _agruparPorMes(data);
        _isLoading = false;
      });
      // Marcar cobrancas como vistas
      await _badgeService.markCobrancasAsSeen(data);
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Map<String, List<dynamic>> _agruparPorMes(List<dynamic> cobrancas) {
    final Map<String, List<dynamic>> agrupado = {};
    for (var cobranca in cobrancas) {
      final mesAno = cobranca['mes_ano'] ?? 'Sem data';
      final mesAnoFormatado = _formatarMesAno(mesAno);
      if (!agrupado.containsKey(mesAnoFormatado)) {
        agrupado[mesAnoFormatado] = [];
      }
      agrupado[mesAnoFormatado]!.add(cobranca);
    }
    return agrupado;
  }

  String _formatarMesAno(String mesAno) {
    if (mesAno == 'Sem data') return mesAno;

    final partes = mesAno.split('/');
    if (partes.length != 2) return mesAno;

    final mes = int.tryParse(partes[0]);
    final ano = partes[1];

    const meses = [
      'Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho',
      'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro'
    ];

    if (mes == null || mes < 1 || mes > 12) return mesAno;

    return '${meses[mes - 1]}/$ano';
  }

  Future<void> _openBoleto(String? url, BuildContext context) async {
    if (url == null || url.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('URL do boleto não disponível')),
        );
      }
      return;
    }

    // Mostrar indicador de carregamento
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      // Completar URL se necessário
      String fullUrl = url;
      if (!url.startsWith('http')) {
        fullUrl = 'https://sqs103.com.br$url';
      }

      // Obter token de autenticação
      final token = await _apiService.getToken();
      final headers = {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

      // Baixar o arquivo
      final response = await http.get(Uri.parse(fullUrl), headers: headers);

      if (response.statusCode != 200) {
        throw Exception('Erro ao baixar (código ${response.statusCode})');
      }

      // Obter diretório temporário
      final dir = await getTemporaryDirectory();

      // Extrair nome do arquivo da URL ou usar nome padrão
      String filename = fullUrl.split('/').last;
      if (filename.isEmpty || !filename.contains('.')) {
        filename = 'boleto_${DateTime.now().millisecondsSinceEpoch}.pdf';
      }

      // Garantir que o arquivo tenha extensão .pdf
      if (!filename.toLowerCase().endsWith('.pdf')) {
        filename = '$filename.pdf';
      }

      final file = File('${dir.path}/$filename');

      // Salvar arquivo
      await file.writeAsBytes(response.bodyBytes);

      // Fechar loading
      if (context.mounted) Navigator.pop(context);

      // Abrir com chooser de aplicativos
      final result = await OpenFilex.open(
        file.path,
        type: 'application/pdf',
        uti: 'com.adobe.pdf',
      );

      // Verificar se houve erro
      if (result.type != ResultType.done && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao abrir arquivo: ${result.message}')),
        );
      }
    } catch (e) {
      // Fechar loading se ainda estiver aberto
      if (context.mounted) Navigator.pop(context);

      // Mostrar erro
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao baixar boleto: $e')),
        );
      }
    }
  }

  String _formatCurrency(dynamic value) {
    final num = double.tryParse(value.toString()) ?? 0;
    return NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$').format(num);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_cobrancas.isEmpty) {
      return const Center(child: Text('Nenhuma cobrança encontrada'));
    }

    final mesesOrdenados = _cobrancasPorMes.keys.toList();

    return RefreshIndicator(
      onRefresh: _loadCobrancas,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: ExpansionPanelList(
          expansionCallback: (int index, bool isExpanded) {
            setState(() {
              // Se já está expandido, fechar. Se não, abrir e fechar outros
              _expandedIndex = _expandedIndex == index ? null : index;
            });
          },
          children: mesesOrdenados.asMap().entries.map<ExpansionPanel>((entry) {
            final index = entry.key;
            final mesAno = entry.value;
            final boletosDoMes = _cobrancasPorMes[mesAno]!;
            final totalMes = boletosDoMes.fold<double>(
              0,
              (sum, boleto) => sum + (double.tryParse(boleto['valor'].toString()) ?? 0),
            );

            return ExpansionPanel(
              isExpanded: _expandedIndex == index,
              canTapOnHeader: true,
              headerBuilder: (BuildContext context, bool isExpanded) {
                return ListTile(
                  title: Text(
                    mesAno,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2563EB),
                    ),
                  ),
                  subtitle: Text(
                    '${boletosDoMes.length} ${boletosDoMes.length == 1 ? 'boleto' : 'boletos'} - Total: ${_formatCurrency(totalMes)}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                );
              },
              body: Column(
                children: boletosDoMes.map((boleto) {
                  final isRecalculo = boleto['recalculo'] == true;
                  final isPago = boleto['status'] == 'pago';

                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(color: Colors.grey[200]!),
                      ),
                      color: isPago ? const Color(0xFFF0FDF4) : null,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                boleto['data_vencimento'] != null && boleto['data_vencimento'] != ''
                                    ? 'Vencimento: ${boleto['data_vencimento']}'
                                    : 'Sem data de vencimento',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            Row(
                              children: [
                                if (isRecalculo)
                                  Container(
                                    margin: const EdgeInsets.only(right: 8),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.orange,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      'RECÁLCULO',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isPago ? const Color(0xFF22C55E) : const Color(0xFFEF4444),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        isPago ? Icons.check_circle : Icons.schedule,
                                        color: Colors.white,
                                        size: 14,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        isPago ? 'PAGO' : 'PENDENTE',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _formatCurrency(boleto['valor']),
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: isPago ? const Color(0xFF22C55E) : const Color(0xFF2563EB),
                            decoration: isPago ? TextDecoration.lineThrough : null,
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () => _openBoleto(boleto['download_url'], context),
                            icon: const Icon(Icons.download),
                            label: const Text('Abrir Boleto'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isPago ? const Color(0xFF22C55E) : const Color(0xFF2563EB),
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
