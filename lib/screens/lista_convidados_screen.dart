import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';

class ListaConvidadosScreen extends StatelessWidget {
  final Map<String, dynamic> reserva;
  final Map<String, dynamic>? usuario;

  const ListaConvidadosScreen({
    super.key,
    required this.reserva,
    this.usuario,
  });

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('dd/MM/yyyy').format(date);
    } catch (e) {
      return dateStr;
    }
  }

  String _formatTime(String? timeStr) {
    if (timeStr == null || timeStr.isEmpty) return '';
    if (timeStr.length >= 5) return timeStr.substring(0, 5);
    return timeStr;
  }

  List<String> _getConvidados() {
    if (reserva['convidados'] == null) return [];
    if (reserva['convidados'] is List) {
      return List<String>.from(reserva['convidados'].map((e) => e.toString()));
    }
    return [];
  }

  Future<pw.Document> _gerarPDF() async {
    final pdf = pw.Document();

    final area = reserva['area'] ?? '';
    final dataReserva = _formatDate(reserva['data_reserva']);
    final horarioInicio = _formatTime(reserva['horario_inicio']);
    final horarioFim = _formatTime(reserva['horario_fim']);
    final nomeUsuario = usuario?['name'] ?? usuario?['nome'] ?? 'MORADOR';
    final apartamento = usuario?['apartamento'] ?? '___';
    final convidados = _getConvidados();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Text(
                      'CONDOMÍNIO DO EDIFÍCIO LOUVRE',
                      style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Text(
                      'LISTA DE CONVIDADOS',
                      style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Container(
                      width: 200,
                      height: 2,
                      color: PdfColors.black,
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 30),

              // Info do morador
              pw.Container(
                padding: const pw.EdgeInsets.all(15),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey400),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Row(
                      children: [
                        pw.Expanded(
                          child: pw.RichText(
                            text: pw.TextSpan(
                              children: [
                                pw.TextSpan(
                                  text: 'Morador: ',
                                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11),
                                ),
                                pw.TextSpan(
                                  text: nomeUsuario.toUpperCase(),
                                  style: const pw.TextStyle(fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                        ),
                        pw.RichText(
                          text: pw.TextSpan(
                            children: [
                              pw.TextSpan(
                                text: 'Apto: ',
                                style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11),
                              ),
                              pw.TextSpan(
                                text: apartamento,
                                style: const pw.TextStyle(fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 10),
                    pw.Row(
                      children: [
                        pw.Expanded(
                          child: pw.RichText(
                            text: pw.TextSpan(
                              children: [
                                pw.TextSpan(
                                  text: 'Área: ',
                                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11),
                                ),
                                pw.TextSpan(
                                  text: area,
                                  style: const pw.TextStyle(fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 10),
                    pw.Row(
                      children: [
                        pw.RichText(
                          text: pw.TextSpan(
                            children: [
                              pw.TextSpan(
                                text: 'Data: ',
                                style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11),
                              ),
                              pw.TextSpan(
                                text: dataReserva,
                                style: const pw.TextStyle(fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                        pw.SizedBox(width: 30),
                        pw.RichText(
                          text: pw.TextSpan(
                            children: [
                              pw.TextSpan(
                                text: 'Horário: ',
                                style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11),
                              ),
                              pw.TextSpan(
                                text: '$horarioInicio às $horarioFim',
                                style: const pw.TextStyle(fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 25),

              // Título da lista
              pw.Text(
                'Relação de Convidados:',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 15),

              // Lista de convidados
              if (convidados.isEmpty)
                pw.Padding(
                  padding: const pw.EdgeInsets.all(20),
                  child: pw.Center(
                    child: pw.Text(
                      'Nenhum convidado cadastrado',
                      style: pw.TextStyle(
                        fontSize: 12,
                        fontStyle: pw.FontStyle.italic,
                        color: PdfColors.grey600,
                      ),
                    ),
                  ),
                )
              else
                pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.grey400),
                  columnWidths: {
                    0: const pw.FixedColumnWidth(40),
                    1: const pw.FlexColumnWidth(),
                  },
                  children: [
                    // Header
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                            'Nº',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11),
                            textAlign: pw.TextAlign.center,
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                            'Nome Completo',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                    // Convidados
                    ...convidados.asMap().entries.map((entry) => pw.TableRow(
                          children: [
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(8),
                              child: pw.Text(
                                '${entry.key + 1}',
                                style: const pw.TextStyle(fontSize: 11),
                                textAlign: pw.TextAlign.center,
                              ),
                            ),
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(8),
                              child: pw.Text(
                                entry.value,
                                style: const pw.TextStyle(fontSize: 11),
                              ),
                            ),
                          ],
                        )),
                  ],
                ),

              pw.Spacer(),

              // Total
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Text(
                  'Total de convidados: ${convidados.length}',
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 20),

              // Rodapé
              pw.Center(
                child: pw.Text(
                  'SQS 103 - BLOCO B',
                  style: pw.TextStyle(fontSize: 10, fontStyle: pw.FontStyle.italic),
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf;
  }

  Future<void> _baixarPDF(BuildContext context) async {
    try {
      final pdf = await _gerarPDF();
      final bytes = await pdf.save();

      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/lista_convidados_${reserva['id']}.pdf');
      await file.writeAsBytes(bytes);

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('PDF salvo com sucesso!'),
          backgroundColor: Colors.green,
          action: SnackBarAction(
            label: 'Compartilhar',
            textColor: Colors.white,
            onPressed: () {
              Share.shareXFiles([XFile(file.path)], text: 'Lista de Convidados');
            },
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao gerar PDF: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _imprimirPDF(BuildContext context) async {
    try {
      final pdf = await _gerarPDF();
      await Printing.layoutPdf(onLayout: (format) async => pdf.save());
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao imprimir: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final area = reserva['area'] ?? '';
    final dataReserva = _formatDate(reserva['data_reserva']);
    final horarioInicio = _formatTime(reserva['horario_inicio']);
    final horarioFim = _formatTime(reserva['horario_fim']);
    final nomeUsuario = usuario?['name'] ?? usuario?['nome'] ?? 'MORADOR';
    final apartamento = usuario?['apartamento'] ?? '___';
    final convidados = _getConvidados();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lista de Convidados'),
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: () => _imprimirPDF(context),
            tooltip: 'Imprimir',
          ),
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () => _baixarPDF(context),
            tooltip: 'Baixar PDF',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Text(
                      'CONDOMÍNIO DO EDIFÍCIO LOUVRE',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2c3e50),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'LISTA DE CONVIDADOS',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF34495e),
                      ),
                    ),
                    const Divider(height: 24),

                    // Info da reserva
                    _buildInfoRow('Morador', nomeUsuario.toUpperCase()),
                    _buildInfoRow('Apartamento', apartamento),
                    _buildInfoRow('Área', area),
                    _buildInfoRow('Data', dataReserva),
                    _buildInfoRow('Horário', '$horarioInicio às $horarioFim'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Lista de convidados
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Relação de Convidados',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2563EB).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${convidados.length} convidado${convidados.length != 1 ? 's' : ''}',
                            style: const TextStyle(
                              color: Color(0xFF2563EB),
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    if (convidados.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            children: [
                              Icon(Icons.people_outline, size: 48, color: Colors.grey[400]),
                              const SizedBox(height: 12),
                              Text(
                                'Nenhum convidado cadastrado',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: convidados.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: const Color(0xFF2563EB),
                              radius: 16,
                              child: Text(
                                '${index + 1}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(
                              convidados[index],
                              style: const TextStyle(fontSize: 14),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _imprimirPDF(context),
                  icon: const Icon(Icons.print),
                  label: const Text('Imprimir'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: Color(0xFF2563EB)),
                    foregroundColor: const Color(0xFF2563EB),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _baixarPDF(context),
                  icon: const Icon(Icons.download),
                  label: const Text('Baixar PDF'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: Color(0xFF6B7280),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
