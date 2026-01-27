import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import '../services/api_service.dart';
import '../services/badge_service.dart';

class DocumentosScreen extends StatefulWidget {
  const DocumentosScreen({super.key});

  @override
  State<DocumentosScreen> createState() => _DocumentosScreenState();
}

class _DocumentosScreenState extends State<DocumentosScreen> {
  final _apiService = ApiService();
  final _badgeService = BadgeService();
  List<dynamic> _documentos = [];
  Map<String, List<dynamic>> _documentosPorTipo = {};
  bool _isLoading = true;
  int? _expandedIndex;

  @override
  void initState() {
    super.initState();
    _loadDocumentos();
  }

  Future<void> _loadDocumentos() async {
    try {
      final data = await _apiService.getDocumentos();
      setState(() {
        _documentos = data;
        _documentosPorTipo = _agruparPorTipo(data);
        _isLoading = false;
      });
      // Marcar documentos como vistos
      await _badgeService.markDocumentosAsSeen(data);
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Map<String, List<dynamic>> _agruparPorTipo(List<dynamic> documentos) {
    final Map<String, List<dynamic>> agrupado = {};
    for (var doc in documentos) {
      String tipo = doc['tipo']?.toString() ?? 'Outros';
      if (tipo.isEmpty) tipo = 'Outros';

      if (!agrupado.containsKey(tipo)) {
        agrupado[tipo] = [];
      }
      agrupado[tipo]!.add(doc);
    }

    // Ordenar as chaves alfabeticamente
    final ordenado = Map<String, List<dynamic>>.fromEntries(
      agrupado.entries.toList()..sort((a, b) => a.key.compareTo(b.key))
    );

    return ordenado;
  }

  Future<void> _openDocument(String? url, BuildContext context) async {
    if (url == null || url.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('URL do documento não disponível')),
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
        filename = 'documento_${DateTime.now().millisecondsSinceEpoch}.pdf';
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
          SnackBar(content: Text('Erro ao baixar documento: $e')),
        );
      }
    }
  }

  String _stripHtmlTags(String? text) {
    if (text == null || text.isEmpty) return '';
    return text.replaceAll(RegExp(r'<[^>]*>'), '').trim();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_documentos.isEmpty) {
      return const Center(child: Text('Nenhum documento encontrado'));
    }

    final tiposOrdenados = _documentosPorTipo.keys.toList();

    if (tiposOrdenados.isEmpty) {
      return const Center(child: Text('Nenhum documento encontrado'));
    }

    return RefreshIndicator(
      onRefresh: _loadDocumentos,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: ExpansionPanelList(
          expansionCallback: (int index, bool isExpanded) {
            setState(() {
              _expandedIndex = _expandedIndex == index ? null : index;
            });
          },
          children: tiposOrdenados.asMap().entries.map<ExpansionPanel>((entry) {
            final index = entry.key;
            final tipo = entry.value;
            final documentosDoTipo = _documentosPorTipo[tipo]!;

            return ExpansionPanel(
              isExpanded: _expandedIndex == index,
              canTapOnHeader: true,
              headerBuilder: (BuildContext context, bool isExpanded) {
                return ListTile(
                  leading: const Icon(Icons.folder, color: Color(0xFF2563EB)),
                  title: Text(
                    tipo,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    '${documentosDoTipo.length} ${documentosDoTipo.length == 1 ? 'documento' : 'documentos'}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                );
              },
              body: Column(
                children: documentosDoTipo.map((doc) {
                  return ListTile(
                    leading: const Icon(Icons.description, color: Color(0xFF2563EB), size: 20),
                    title: Text(_stripHtmlTags(doc['titulo'])),
                    trailing: IconButton(
                      icon: const Icon(Icons.download),
                      onPressed: () => _openDocument(doc['download_url'], context),
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
