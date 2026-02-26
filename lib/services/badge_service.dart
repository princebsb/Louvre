import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BadgeService extends ChangeNotifier {
  static final BadgeService _instance = BadgeService._internal();
  factory BadgeService() => _instance;
  BadgeService._internal();

  // Chaves para SharedPreferences
  static const String _keyLastSeenComunicados = 'last_seen_comunicados';
  static const String _keyLastSeenDocumentos = 'last_seen_documentos';
  static const String _keyLastSeenCobrancas = 'last_seen_cobrancas';
  static const String _keyLastSeenReservas = 'last_seen_reservas';
  static const String _keyLastSeenSolicitacoes = 'last_seen_solicitacoes';
  static const String _keyLastSeenOcorrencias = 'last_seen_ocorrencias';
  static const String _keyLastSeenObras = 'last_seen_obras';
  static const String _keyLastSeenLaudos = 'last_seen_laudos';

  // Contadores de novos itens
  int _newComunicados = 0;
  int _newDocumentos = 0;
  int _newCobrancas = 0;
  int _newReservas = 0;
  int _newSolicitacoes = 0;
  int _newOcorrencias = 0;
  int _newObras = 0;
  int _newLaudos = 0;

  // Getters
  int get newComunicados => _newComunicados;
  int get newDocumentos => _newDocumentos;
  int get newCobrancas => _newCobrancas;
  int get newReservas => _newReservas;
  int get newSolicitacoes => _newSolicitacoes;
  int get newOcorrencias => _newOcorrencias;
  int get newObras => _newObras;
  int get newLaudos => _newLaudos;

  // Total de notificações
  int get totalBadges =>
      _newComunicados +
      _newDocumentos +
      _newCobrancas +
      _newReservas +
      _newSolicitacoes +
      _newOcorrencias +
      _newObras +
      _newLaudos;

  // Atualizar contagem de comunicados
  Future<void> updateComunicadosCount(List<dynamic> comunicados) async {
    if (comunicados.isEmpty) {
      _newComunicados = 0;
      notifyListeners();
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final lastSeenIds = prefs.getStringList(_keyLastSeenComunicados) ?? [];

    int count = 0;
    for (var item in comunicados) {
      final id = item['id']?.toString() ?? '';
      if (id.isNotEmpty && !lastSeenIds.contains(id)) {
        count++;
      }
    }

    _newComunicados = count;
    notifyListeners();
  }

  // Marcar comunicados como vistos
  Future<void> markComunicadosAsSeen(List<dynamic> comunicados) async {
    final prefs = await SharedPreferences.getInstance();
    final ids = comunicados.map((c) => c['id']?.toString() ?? '').where((id) => id.isNotEmpty).toList();
    await prefs.setStringList(_keyLastSeenComunicados, ids);
    _newComunicados = 0;
    notifyListeners();
  }

  // Atualizar contagem de documentos
  Future<void> updateDocumentosCount(List<dynamic> documentos) async {
    if (documentos.isEmpty) {
      _newDocumentos = 0;
      notifyListeners();
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final lastSeenIds = prefs.getStringList(_keyLastSeenDocumentos) ?? [];

    int count = 0;
    for (var item in documentos) {
      final id = item['id']?.toString() ?? '';
      if (id.isNotEmpty && !lastSeenIds.contains(id)) {
        count++;
      }
    }

    _newDocumentos = count;
    notifyListeners();
  }

  Future<void> markDocumentosAsSeen(List<dynamic> documentos) async {
    final prefs = await SharedPreferences.getInstance();
    final ids = documentos.map((d) => d['id']?.toString() ?? '').where((id) => id.isNotEmpty).toList();
    await prefs.setStringList(_keyLastSeenDocumentos, ids);
    _newDocumentos = 0;
    notifyListeners();
  }

  // Atualizar contagem de cobranças
  Future<void> updateCobrancasCount(List<dynamic> cobrancas) async {
    if (cobrancas.isEmpty) {
      _newCobrancas = 0;
      notifyListeners();
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final lastSeenIds = prefs.getStringList(_keyLastSeenCobrancas) ?? [];

    int count = 0;
    for (var item in cobrancas) {
      final id = item['id']?.toString() ?? '';
      if (id.isNotEmpty && !lastSeenIds.contains(id)) {
        count++;
      }
    }

    _newCobrancas = count;
    notifyListeners();
  }

  Future<void> markCobrancasAsSeen(List<dynamic> cobrancas) async {
    final prefs = await SharedPreferences.getInstance();
    final ids = cobrancas.map((c) => c['id']?.toString() ?? '').where((id) => id.isNotEmpty).toList();
    await prefs.setStringList(_keyLastSeenCobrancas, ids);
    _newCobrancas = 0;
    notifyListeners();
  }

  // Atualizar contagem de reservas
  Future<void> updateReservasCount(List<dynamic> reservas) async {
    if (reservas.isEmpty) {
      _newReservas = 0;
      notifyListeners();
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final lastSeenIds = prefs.getStringList(_keyLastSeenReservas) ?? [];

    int count = 0;
    for (var item in reservas) {
      final id = item['id']?.toString() ?? '';
      if (id.isNotEmpty && !lastSeenIds.contains(id)) {
        count++;
      }
    }

    _newReservas = count;
    notifyListeners();
  }

  Future<void> markReservasAsSeen(List<dynamic> reservas) async {
    final prefs = await SharedPreferences.getInstance();
    final ids = reservas.map((r) => r['id']?.toString() ?? '').where((id) => id.isNotEmpty).toList();
    await prefs.setStringList(_keyLastSeenReservas, ids);
    _newReservas = 0;
    notifyListeners();
  }

  // Atualizar contagem de solicitações
  Future<void> updateSolicitacoesCount(List<dynamic> solicitacoes) async {
    if (solicitacoes.isEmpty) {
      _newSolicitacoes = 0;
      notifyListeners();
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final lastSeenIds = prefs.getStringList(_keyLastSeenSolicitacoes) ?? [];

    int count = 0;
    for (var item in solicitacoes) {
      final id = item['id']?.toString() ?? '';
      if (id.isNotEmpty && !lastSeenIds.contains(id)) {
        count++;
      }
    }

    _newSolicitacoes = count;
    notifyListeners();
  }

  Future<void> markSolicitacoesAsSeen(List<dynamic> solicitacoes) async {
    final prefs = await SharedPreferences.getInstance();
    final ids = solicitacoes.map((s) => s['id']?.toString() ?? '').where((id) => id.isNotEmpty).toList();
    await prefs.setStringList(_keyLastSeenSolicitacoes, ids);
    _newSolicitacoes = 0;
    notifyListeners();
  }

  // Atualizar contagem de ocorrências
  Future<void> updateOcorrenciasCount(List<dynamic> ocorrencias) async {
    if (ocorrencias.isEmpty) {
      _newOcorrencias = 0;
      notifyListeners();
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final lastSeenIds = prefs.getStringList(_keyLastSeenOcorrencias) ?? [];

    int count = 0;
    for (var item in ocorrencias) {
      final id = item['id']?.toString() ?? '';
      if (id.isNotEmpty && !lastSeenIds.contains(id)) {
        count++;
      }
    }

    _newOcorrencias = count;
    notifyListeners();
  }

  Future<void> markOcorrenciasAsSeen(List<dynamic> ocorrencias) async {
    final prefs = await SharedPreferences.getInstance();
    final ids = ocorrencias.map((o) => o['id']?.toString() ?? '').where((id) => id.isNotEmpty).toList();
    await prefs.setStringList(_keyLastSeenOcorrencias, ids);
    _newOcorrencias = 0;
    notifyListeners();
  }

  // Atualizar contagem de obras
  Future<void> updateObrasCount(List<dynamic> obras) async {
    if (obras.isEmpty) {
      _newObras = 0;
      notifyListeners();
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final lastSeenIds = prefs.getStringList(_keyLastSeenObras) ?? [];

    int count = 0;
    for (var item in obras) {
      final id = item['id']?.toString() ?? '';
      if (id.isNotEmpty && !lastSeenIds.contains(id)) {
        count++;
      }
    }

    _newObras = count;
    notifyListeners();
  }

  Future<void> markObrasAsSeen(List<dynamic> obras) async {
    final prefs = await SharedPreferences.getInstance();
    final ids = obras.map((o) => o['id']?.toString() ?? '').where((id) => id.isNotEmpty).toList();
    await prefs.setStringList(_keyLastSeenObras, ids);
    _newObras = 0;
    notifyListeners();
  }

  // Atualizar contagem de laudos
  Future<void> updateLaudosCount(List<dynamic> laudos) async {
    if (laudos.isEmpty) {
      _newLaudos = 0;
      notifyListeners();
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final lastSeenIds = prefs.getStringList(_keyLastSeenLaudos) ?? [];

    int count = 0;
    for (var item in laudos) {
      final id = item['id']?.toString() ?? '';
      if (id.isNotEmpty && !lastSeenIds.contains(id)) {
        count++;
      }
    }

    _newLaudos = count;
    notifyListeners();
  }

  Future<void> markLaudosAsSeen(List<dynamic> laudos) async {
    final prefs = await SharedPreferences.getInstance();
    final ids = laudos.map((l) => l['id']?.toString() ?? '').where((id) => id.isNotEmpty).toList();
    await prefs.setStringList(_keyLastSeenLaudos, ids);
    _newLaudos = 0;
    notifyListeners();
  }

  // Resetar todos os badges (para logout)
  // Apenas zera os contadores em memória, mantém os IDs salvos no SharedPreferences
  // para que ao fazer login novamente, os itens já vistos não apareçam como novos
  Future<void> resetAllBadges() async {
    _newComunicados = 0;
    _newDocumentos = 0;
    _newCobrancas = 0;
    _newReservas = 0;
    _newSolicitacoes = 0;
    _newOcorrencias = 0;
    _newObras = 0;
    _newLaudos = 0;

    notifyListeners();
  }

  // Limpar completamente todos os dados de badges (para troca de usuário)
  Future<void> clearAllBadgeData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyLastSeenComunicados);
    await prefs.remove(_keyLastSeenDocumentos);
    await prefs.remove(_keyLastSeenCobrancas);
    await prefs.remove(_keyLastSeenReservas);
    await prefs.remove(_keyLastSeenSolicitacoes);
    await prefs.remove(_keyLastSeenOcorrencias);
    await prefs.remove(_keyLastSeenObras);
    await prefs.remove(_keyLastSeenLaudos);

    _newComunicados = 0;
    _newDocumentos = 0;
    _newCobrancas = 0;
    _newReservas = 0;
    _newSolicitacoes = 0;
    _newOcorrencias = 0;
    _newObras = 0;
    _newLaudos = 0;

    notifyListeners();
  }
}
