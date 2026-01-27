import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_html/flutter_html.dart';
import '../services/api_service.dart';
import '../services/badge_service.dart';

class ComunicadosScreen extends StatefulWidget {
  const ComunicadosScreen({super.key});

  @override
  State<ComunicadosScreen> createState() => _ComunicadosScreenState();
}

class _ComunicadosScreenState extends State<ComunicadosScreen> {
  final _apiService = ApiService();
  final _badgeService = BadgeService();
  List<dynamic> _comunicados = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadComunicados();
  }

  Future<void> _loadComunicados() async {
    try {
      final data = await _apiService.getComunicados();
      setState(() {
        _comunicados = data;
        _isLoading = false;
      });
      // Marcar comunicados como vistos
      await _badgeService.markComunicadosAsSeen(data);
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('dd/MM/yyyy HH:mm').format(date);
    } catch (e) {
      return dateStr;
    }
  }

  Color _getTipoColor(String? tipo) {
    switch (tipo) {
      case 'urgente':
        return Colors.red;
      case 'importante':
        return Colors.orange;
      default:
        return Colors.blue;
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

    if (_comunicados.isEmpty) {
      return const Center(child: Text('Nenhum comunicado encontrado'));
    }

    return RefreshIndicator(
      onRefresh: _loadComunicados,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _comunicados.length,
        itemBuilder: (context, index) {
          final comunicado = _comunicados[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text(_stripHtmlTags(comunicado['title'])),
                    content: SingleChildScrollView(
                      child: Html(
                        data: comunicado['content'] ?? '',
                        style: {
                          "body": Style(
                            margin: Margins.zero,
                            padding: HtmlPaddings.zero,
                          ),
                        },
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Fechar'),
                      ),
                    ],
                  ),
                );
              },
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
                            color: _getTipoColor(comunicado['tipo']),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            (comunicado['tipo'] ?? 'info').toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          _formatDate(comunicado['created_at'] ?? ''),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _stripHtmlTags(comunicado['title']),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _stripHtmlTags(comunicado['content']),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
