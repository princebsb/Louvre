import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import '../services/api_service.dart';

class PrestacaoContasScreen extends StatefulWidget {
  const PrestacaoContasScreen({super.key});

  @override
  State<PrestacaoContasScreen> createState() => _PrestacaoContasScreenState();
}

class _PrestacaoContasScreenState extends State<PrestacaoContasScreen>
    with SingleTickerProviderStateMixin {
  final _apiService = ApiService();
  List<dynamic> _prestacoes = [];
  List<dynamic> _malotes = [];
  Map<String, List<dynamic>> _prestacoesPorMes = {};
  bool _isLoading = true;
  int? _expandedPrestacaoIndex;
  int? _expandedMaloteIndex;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final prestacoes = await _apiService.getPrestacaoContas();
      final malotes = await _apiService.getMalotes();
      setState(() {
        _prestacoes = prestacoes;
        _malotes = malotes;
        _prestacoesPorMes = _agruparPorMes(prestacoes);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Map<String, List<dynamic>> _agruparPorMes(List<dynamic> prestacoes) {
    final Map<String, List<dynamic>> agrupado = {};
    for (var prestacao in prestacoes) {
      final mesAno = prestacao['mes_ano'];
      final anoFormatado = _formatarAno(mesAno);
      if (!agrupado.containsKey(anoFormatado)) {
        agrupado[anoFormatado] = [];
      }
      agrupado[anoFormatado]!.add(prestacao);
    }
    return agrupado;
  }

  String _formatarAno(String? mesAno) {
    if (mesAno == null || mesAno.isEmpty) {
      return 'Prestacao de Contas - ${DateTime.now().year}';
    }

    final partes = mesAno.split('/');
    if (partes.length == 2) {
      final ano = partes[1];
      return 'Prestacao de Contas - $ano';
    }

    final anoInt = int.tryParse(mesAno);
    if (anoInt != null && anoInt > 2000 && anoInt < 2100) {
      return 'Prestacao de Contas - $mesAno';
    }

    return 'Prestacao de Contas - ${DateTime.now().year}';
  }

  Future<void> _openDocument(String? url, BuildContext context) async {
    if (url == null || url.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('URL do documento nao disponivel')),
        );
      }
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      String fullUrl = url;
      if (!url.startsWith('http')) {
        fullUrl = 'https://sqs103.com.br$url';
      }

      final token = await _apiService.getToken();
      final headers = {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

      final response = await http.get(Uri.parse(fullUrl), headers: headers);

      if (response.statusCode != 200) {
        throw Exception('Erro ao baixar (codigo ${response.statusCode})');
      }

      final dir = await getTemporaryDirectory();

      String filename = fullUrl.split('/').last;
      if (filename.isEmpty || !filename.contains('.')) {
        filename = 'documento_${DateTime.now().millisecondsSinceEpoch}.pdf';
      }

      if (!filename.toLowerCase().endsWith('.pdf')) {
        filename = '$filename.pdf';
      }

      final file = File('${dir.path}/$filename');

      await file.writeAsBytes(response.bodyBytes);

      if (context.mounted) Navigator.pop(context);

      final result = await OpenFilex.open(
        file.path,
        type: 'application/pdf',
        uti: 'com.adobe.pdf',
      );

      if (result.type != ResultType.done && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao abrir arquivo: ${result.message}')),
        );
      }
    } catch (e) {
      if (context.mounted) Navigator.pop(context);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao baixar documento: $e')),
        );
      }
    }
  }

  String _formatFileSize(dynamic bytes) {
    if (bytes == null) return '';
    final size = double.tryParse(bytes.toString()) ?? 0;
    if (size < 1024) return '${size.toStringAsFixed(0)} B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: Colors.white,
          child: TabBar(
            controller: _tabController,
            labelColor: const Color(0xFF2563EB),
            unselectedLabelColor: Colors.grey,
            indicatorColor: const Color(0xFF2563EB),
            tabs: const [
              Tab(
                icon: Icon(Icons.account_balance),
                text: 'Prestacao de Contas',
              ),
              Tab(
                icon: Icon(Icons.mail_outline),
                text: 'Malotes',
              ),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildPrestacaoContasTab(),
              _buildMalotesTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPrestacaoContasTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_prestacoes.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.account_balance, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Nenhuma prestacao de contas encontrada',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ],
        ),
      );
    }

    final mesesOrdenados = _prestacoesPorMes.keys.toList();

    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: ExpansionPanelList(
          expansionCallback: (int index, bool isExpanded) {
            setState(() {
              _expandedPrestacaoIndex =
                  _expandedPrestacaoIndex == index ? null : index;
            });
          },
          children:
              mesesOrdenados.asMap().entries.map<ExpansionPanel>((entry) {
            final index = entry.key;
            final mesAno = entry.value;
            final prestacaoDoMes = _prestacoesPorMes[mesAno]!;

            return ExpansionPanel(
              isExpanded: _expandedPrestacaoIndex == index,
              canTapOnHeader: true,
              headerBuilder: (BuildContext context, bool isExpanded) {
                return ListTile(
                  leading: const Icon(
                    Icons.account_balance,
                    color: Color(0xFF2563EB),
                  ),
                  title: Text(
                    mesAno,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2563EB),
                    ),
                  ),
                  subtitle: Text(
                    '${prestacaoDoMes.length} ${prestacaoDoMes.length == 1 ? 'documento' : 'documentos'}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                );
              },
              body: Column(
                children: prestacaoDoMes.map((prestacao) {
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(color: Colors.grey[200]!),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          prestacao['titulo'] ??
                              prestacao['nome'] ??
                              'Prestacao de Contas',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (prestacao['descricao'] != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            prestacao['descricao'],
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () => _openDocument(
                              prestacao['download_url'] ?? prestacao['url'],
                              context,
                            ),
                            icon: const Icon(Icons.download),
                            label: const Text('Abrir Documento'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2563EB),
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

  Widget _buildMalotesTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_malotes.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.mail_outline, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Nenhum malote encontrado',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _malotes.length,
        itemBuilder: (context, index) {
          final malote = _malotes[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: 2,
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFF0369A1).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.mail_outline,
                  color: Color(0xFF0369A1),
                  size: 28,
                ),
              ),
              title: Text(
                malote['mes_ref'] ?? 'Malote',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0369A1),
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text(
                    malote['titulo'] ?? malote['filename'] ?? '',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.calendar_today,
                          size: 12, color: Colors.grey[500]),
                      const SizedBox(width: 4),
                      Text(
                        malote['data_upload'] != null
                            ? DateFormat('dd/MM/yyyy HH:mm').format(
                                DateTime.parse(malote['data_upload']))
                            : '',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(Icons.file_present,
                          size: 12, color: Colors.grey[500]),
                      const SizedBox(width: 4),
                      Text(
                        _formatFileSize(malote['tamanho']),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              trailing: IconButton(
                icon: const Icon(Icons.download, color: Color(0xFF0369A1)),
                onPressed: () => _openDocument(malote['download_url'], context),
              ),
            ),
          );
        },
      ),
    );
  }
}
