import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';

class TermoResponsabilidadeScreen extends StatelessWidget {
  final Map<String, dynamic> reserva;
  final Map<String, dynamic>? usuario;

  const TermoResponsabilidadeScreen({
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

  String _getDataPorExtenso() {
    final meses = [
      'janeiro', 'fevereiro', 'março', 'abril', 'maio', 'junho',
      'julho', 'agosto', 'setembro', 'outubro', 'novembro', 'dezembro'
    ];
    final now = DateTime.now();
    return 'Brasília-DF., ${now.day} de ${meses[now.month - 1]} de ${now.year}';
  }

  Future<pw.Document> _gerarPDF() async {
    final pdf = pw.Document();

    final area = reserva['area'] ?? '';
    final dataReserva = _formatDate(reserva['data_reserva']);
    final horarioInicio = _formatTime(reserva['horario_inicio']);
    final horarioFim = _formatTime(reserva['horario_fim']);
    final observacoes = reserva['observacoes'] ?? '';
    final nomeUsuario = usuario?['name'] ?? usuario?['nome'] ?? 'MORADOR';
    final apartamento = usuario?['apartamento'] ?? '___';

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
                      'TERMO DE RESPONSABILIDADE',
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
              pw.SizedBox(height: 25),

              // Info do morador
              pw.RichText(
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
                    pw.TextSpan(
                      text: '     Apto: ',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11),
                    ),
                    pw.TextSpan(
                      text: apartamento,
                      style: const pw.TextStyle(fontSize: 11),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 15),

              // Texto introdutório
              pw.Text(
                'Na qualidade de morador (Condômino) do Condomínio do Edifício Louvre, sirvo-me do presente para requisitar para meu uso:',
                style: const pw.TextStyle(fontSize: 11),
                textAlign: pw.TextAlign.justify,
              ),
              pw.SizedBox(height: 12),

              // Checkboxes
              _buildCheckboxPDF('Salão de Festas', area == 'Salão de Festas'),
              _buildCheckboxPDF('Churrasqueira Principal', area == 'Churrasqueira Principal'),
              _buildCheckboxPDF('Churrasqueira Lateral', area == 'Churrasqueira Lateral'),
              pw.SizedBox(height: 15),

              // Data e horário
              pw.RichText(
                text: pw.TextSpan(
                  style: const pw.TextStyle(fontSize: 11),
                  children: [
                    const pw.TextSpan(text: 'Será utilizado no dia '),
                    pw.TextSpan(
                      text: dataReserva,
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                    const pw.TextSpan(text: ' e no horário compreendido entre '),
                    pw.TextSpan(
                      text: horarioInicio,
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                    const pw.TextSpan(text: ' às '),
                    pw.TextSpan(
                      text: horarioFim,
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                    const pw.TextSpan(
                      text: ', pelo que na melhor forma de direito comprometo-me e responsabilizo-me pelo que segue:',
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 15),

              // Termos
              _buildTermoPDF('1.', 'Utilizar junto a meus familiares e convidados, de tal modo que não perturbe a boa ordem do edifício e o sossego dos demais moradores;'),
              _buildTermoPDF('2.', 'Ressarcir o Condomínio por todo e qualquer dano sofrido nas dependências, durante o período de sua utilização, independentemente da pessoa que tenha provocado tal dano;'),
              _buildTermoPDF('3.', 'Cumprir e fazer cumprir o regulamento interno, em especial ao que diz respeito à Lei do Silêncio (artigo 9°);'),
              _buildTermoPDF('4.', 'É vedado a utilização de DUREX, DUPLAFACE OU SIMILAR para fixação de balões nas paredes do salão de festas, fica liberado o uso de durex ou similar nos vidros;'),
              _buildTermoPDF('5.', 'Não utilizar BOTIJÕES DE GÁS no salão nem na churrasqueira, FOGÕES/FORNOS ELÉTRICOS somente os que se adequarem às instalações do prédio;'),
              _buildTermoPDF('6.', 'Deixar a lista de convidados 1 dia antes do evento;'),
              _buildTermoPDF('7.', 'A desistência do espaço reservado deverá ser feito com 48 horas de antecedência para que outro condômino ou morador possa ter direito de utilização;'),
              _buildTermoPDF('8.', 'O Condômino ou morador que reservar o espaço e não utilizá-lo perderá automaticamente o direito da reserva anual gratuita.'),
              pw.SizedBox(height: 15),

              // Declaração final
              pw.Text(
                'Desde logo declaro estar ciente de que o não cumprimento do presente acarretará as multas previstas pelo regulamento interno e pela convenção do Condomínio.',
                style: const pw.TextStyle(fontSize: 11),
                textAlign: pw.TextAlign.justify,
              ),
              pw.SizedBox(height: 25),

              // Data por extenso
              pw.Center(
                child: pw.Text(
                  _getDataPorExtenso(),
                  style: const pw.TextStyle(fontSize: 11),
                ),
              ),
              pw.SizedBox(height: 40),

              // Assinaturas
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                children: [
                  pw.Column(
                    children: [
                      pw.Container(width: 150, height: 1, color: PdfColors.black),
                      pw.SizedBox(height: 5),
                      pw.Text('MORADOR', style: const pw.TextStyle(fontSize: 10)),
                    ],
                  ),
                  pw.Column(
                    children: [
                      pw.Container(width: 150, height: 1, color: PdfColors.black),
                      pw.SizedBox(height: 5),
                      pw.Text('SÍNDICO', style: const pw.TextStyle(fontSize: 10)),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 25),

              // Observações
              if (observacoes.isNotEmpty) ...[
                pw.Text(
                  'Observações:',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11),
                ),
                pw.SizedBox(height: 5),
                pw.Text(observacoes, style: const pw.TextStyle(fontSize: 10)),
              ],

              pw.Spacer(),
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

  pw.Widget _buildCheckboxPDF(String text, bool checked) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 3),
      child: pw.Row(
        children: [
          pw.Container(
            width: 12,
            height: 12,
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.black),
            ),
            child: checked
                ? pw.Center(child: pw.Text('X', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)))
                : null,
          ),
          pw.SizedBox(width: 8),
          pw.Text(text, style: const pw.TextStyle(fontSize: 11)),
        ],
      ),
    );
  }

  pw.Widget _buildTermoPDF(String numero, String texto) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 20,
            child: pw.Text(numero, style: const pw.TextStyle(fontSize: 10)),
          ),
          pw.Expanded(
            child: pw.Text(
              texto,
              style: const pw.TextStyle(fontSize: 10),
              textAlign: pw.TextAlign.justify,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _baixarPDF(BuildContext context) async {
    try {
      final pdf = await _gerarPDF();
      final bytes = await pdf.save();

      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/termo_responsabilidade_${reserva['id']}.pdf');
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
              Share.shareXFiles([XFile(file.path)], text: 'Termo de Responsabilidade');
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
    final observacoes = reserva['observacoes'] ?? '';
    final nomeUsuario = usuario?['name'] ?? usuario?['nome'] ?? 'MORADOR';
    final apartamento = usuario?['apartamento'] ?? '___';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Termo de Responsabilidade'),
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
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Center(
                  child: Column(
                    children: [
                      const Text(
                        'CONDOMÍNIO DO EDIFÍCIO LOUVRE',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2c3e50),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'TERMO DE RESPONSABILIDADE',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF34495e),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: 200,
                        height: 3,
                        color: const Color(0xFF2c3e50),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Info do morador
                RichText(
                  text: TextSpan(
                    style: const TextStyle(fontSize: 14, color: Colors.black),
                    children: [
                      const TextSpan(
                        text: 'Morador: ',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextSpan(text: nomeUsuario.toUpperCase()),
                      const TextSpan(
                        text: '     Apto: ',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextSpan(text: apartamento),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Texto introdutório
                const Text(
                  'Na qualidade de morador (Condômino) do Condomínio do Edifício Louvre, sirvo-me do presente para requisitar para meu uso:',
                  style: TextStyle(fontSize: 14),
                  textAlign: TextAlign.justify,
                ),
                const SizedBox(height: 16),

                // Checkboxes
                _buildCheckbox('Salão de Festas', area == 'Salão de Festas'),
                _buildCheckbox('Churrasqueira Principal', area == 'Churrasqueira Principal'),
                _buildCheckbox('Churrasqueira Lateral', area == 'Churrasqueira Lateral'),
                const SizedBox(height: 16),

                // Data e horário
                RichText(
                  text: TextSpan(
                    style: const TextStyle(fontSize: 14, color: Colors.black),
                    children: [
                      const TextSpan(text: 'Será utilizado no dia '),
                      TextSpan(
                        text: dataReserva,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const TextSpan(text: ' e no horário compreendido entre '),
                      TextSpan(
                        text: horarioInicio,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const TextSpan(text: ' às '),
                      TextSpan(
                        text: horarioFim,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const TextSpan(
                        text: ', pelo que na melhor forma de direito comprometo-me e responsabilizo-me pelo que segue:',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Termos
                _buildTermo('1.', 'Utilizar junto a meus familiares e convidados, de tal modo que não perturbe a boa ordem do edifício e o sossego dos demais moradores;'),
                _buildTermo('2.', 'Ressarcir o Condomínio por todo e qualquer dano sofrido nas dependências, durante o período de sua utilização, independentemente da pessoa que tenha provocado tal dano;'),
                _buildTermo('3.', 'Cumprir e fazer cumprir o regulamento interno, em especial ao que diz respeito à Lei do Silêncio (artigo 9°);'),
                _buildTermo('4.', 'É vedado a utilização de DUREX, DUPLAFACE OU SIMILAR para fixação de balões nas paredes do salão de festas, fica liberado o uso de durex ou similar nos vidros;'),
                _buildTermo('5.', 'Não utilizar BOTIJÕES DE GÁS no salão nem na churrasqueira, FOGÕES/FORNOS ELÉTRICOS somente os que se adequarem às instalações do prédio;'),
                _buildTermo('6.', 'Deixar a lista de convidados 1 dia antes do evento;'),
                _buildTermo('7.', 'A desistência do espaço reservado deverá ser feito com 48 horas de antecedência para que outro condômino ou morador possa ter direito de utilização;'),
                _buildTermo('8.', 'O Condômino ou morador que reservar o espaço e não utilizá-lo perderá automaticamente o direito da reserva anual gratuita.'),
                const SizedBox(height: 16),

                // Declaração final
                const Text(
                  'Desde logo declaro estar ciente de que o não cumprimento do presente acarretará as multas previstas pelo regulamento interno e pela convenção do Condomínio.',
                  style: TextStyle(fontSize: 14),
                  textAlign: TextAlign.justify,
                ),
                const SizedBox(height: 24),

                // Data por extenso
                Center(
                  child: Text(
                    _getDataPorExtenso(),
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
                const SizedBox(height: 40),

                // Assinaturas
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        Container(width: 120, height: 1, color: Colors.black),
                        const SizedBox(height: 8),
                        const Text('MORADOR', style: TextStyle(fontSize: 12)),
                      ],
                    ),
                    Column(
                      children: [
                        Container(width: 120, height: 1, color: Colors.black),
                        const SizedBox(height: 8),
                        const Text('SÍNDICO', style: TextStyle(fontSize: 12)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Observações
                if (observacoes.isNotEmpty) ...[
                  const Text(
                    'Observações:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Text(observacoes, style: const TextStyle(fontSize: 13)),
                  const SizedBox(height: 16),
                ],

                // Rodapé
                const Center(
                  child: Text(
                    'SQS 103 - BLOCO B',
                    style: TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ],
            ),
          ),
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

  Widget _buildCheckbox(String text, bool checked) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.black),
              borderRadius: BorderRadius.circular(2),
            ),
            child: checked
                ? const Icon(Icons.check, size: 16, color: Colors.black)
                : null,
          ),
          const SizedBox(width: 12),
          Text(text, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildTermo(String numero, String texto) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 24,
            child: Text(numero, style: const TextStyle(fontSize: 13)),
          ),
          Expanded(
            child: Text(
              texto,
              style: const TextStyle(fontSize: 13),
              textAlign: TextAlign.justify,
            ),
          ),
        ],
      ),
    );
  }
}
