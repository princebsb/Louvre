import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = 'https://sqs103.com.br/blocob/api';

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<String?> getToken() async {
    return _getToken();
  }

  Future<Map<String, String>> _getHeaders() async {
    final token = await _getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<Map<String, String>> getHeaders() async {
    return _getHeaders();
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw Exception('Tempo esgotado. Verifique sua conexão com a internet.');
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('token', data['token']);
          await prefs.setString('user', jsonEncode(data['user']));
        }
        return data;
      } else if (response.statusCode == 401) {
        final data = jsonDecode(response.body);
        throw Exception(data['message'] ?? 'Email ou senha incorretos');
      } else {
        throw Exception('Erro no servidor. Código: ${response.statusCode}');
      }
    } catch (e) {
      if (e.toString().contains('SocketException') || e.toString().contains('Failed host lookup')) {
        throw Exception('Erro de conexão. Verifique se está conectado à internet.\n\nTentando acessar: $baseUrl');
      }
      rethrow;
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('user');
  }

  Future<Map<String, dynamic>?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userStr = prefs.getString('user');
    if (userStr != null) {
      return jsonDecode(userStr);
    }
    return null;
  }

  Future<List<dynamic>> getComunicados() async {
    final response = await http.get(
      Uri.parse('$baseUrl/comunicados'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['data'] ?? [];
    } else {
      throw Exception('Erro ao carregar comunicados');
    }
  }

  Future<Map<String, dynamic>> getComunicado(int id) async {
    final response = await http.get(
      Uri.parse('$baseUrl/comunicado/$id'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['data'];
    } else {
      throw Exception('Erro ao carregar comunicado');
    }
  }

  Future<List<dynamic>> getDocumentos() async {
    final response = await http.get(
      Uri.parse('$baseUrl/documentos'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['data'] ?? [];
    } else {
      throw Exception('Erro ao carregar documentos');
    }
  }

  Future<List<dynamic>> getCobrancas() async {
    final response = await http.get(
      Uri.parse('$baseUrl/cobrancas'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['data'] ?? [];
    } else {
      throw Exception('Erro ao carregar cobranças');
    }
  }

  Future<List<dynamic>> getPrestacaoContas() async {
    final response = await http.get(
      Uri.parse('$baseUrl/prestacao-contas'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['data'] ?? [];
    } else {
      throw Exception('Erro ao carregar prestação de contas');
    }
  }

  Future<List<dynamic>> getMalotes() async {
    final response = await http.get(
      Uri.parse('$baseUrl/malotes'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['data'] ?? [];
    } else {
      throw Exception('Erro ao carregar malotes');
    }
  }

  Future<Map<String, dynamic>> getInstitutionalInfo() async {
    final response = await http.get(
      Uri.parse('$baseUrl/institutional-info'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['data'] ?? {};
    } else {
      throw Exception('Erro ao carregar informações do condomínio');
    }
  }

  Future<String> getNomeCondominio() async {
    try {
      final info = await getInstitutionalInfo();
      return info['nome_condominio'] ?? 'CONDOMÍNIO LOUVRE';
    } catch (e) {
      return 'CONDOMÍNIO LOUVRE';
    }
  }

  // ==================== RESERVAS ====================

  Future<List<dynamic>> getReservas() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/reservas'),
        headers: await _getHeaders(),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'] ?? [];
      } else if (response.statusCode == 404) {
        // Endpoint não existe ainda - retorna lista vazia
        return [];
      } else {
        throw Exception('Erro ao carregar reservas');
      }
    } catch (e) {
      if (e.toString().contains('SocketException') ||
          e.toString().contains('Failed host lookup') ||
          e.toString().contains('Connection refused')) {
        // Erro de conexão - retorna lista vazia para não bloquear a tela
        return [];
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getReserva(int id) async {
    final response = await http.get(
      Uri.parse('$baseUrl/reservas/$id'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['data'] ?? {};
    } else {
      throw Exception('Erro ao carregar reserva');
    }
  }

  Future<List<String>> getDatasOcupadas(String area) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/reservas/datas-ocupadas?area=${Uri.encodeComponent(area)}'),
        headers: await _getHeaders(),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return List<String>.from(data['dates'] ?? []);
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>> getPrecoReserva(String area) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/reservas/preco?area=${Uri.encodeComponent(area)}'),
        headers: await _getHeaders(),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data;
      }
      return {'success': false};
    } catch (e) {
      return {'success': false};
    }
  }

  Future<Map<String, dynamic>> criarReserva({
    required String area,
    required String dataReserva,
    required String horarioInicio,
    required String horarioFim,
    String? observacoes,
    List<String>? convidados,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/reservas'),
      headers: await _getHeaders(),
      body: jsonEncode({
        'area': area,
        'data_reserva': dataReserva,
        'horario_inicio': horarioInicio,
        'horario_fim': horarioFim,
        'observacoes': observacoes,
        'convidados': convidados,
      }),
    ).timeout(const Duration(seconds: 15));

    final data = jsonDecode(response.body);
    if (response.statusCode == 200 || response.statusCode == 201) {
      return data;
    } else {
      throw Exception(data['message'] ?? 'Erro ao criar reserva');
    }
  }

  Future<Map<String, dynamic>> atualizarReserva({
    required int id,
    required String area,
    required String dataReserva,
    required String horarioInicio,
    required String horarioFim,
    String? observacoes,
    List<String>? convidados,
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl/reservas/$id'),
      headers: await _getHeaders(),
      body: jsonEncode({
        'area': area,
        'data_reserva': dataReserva,
        'horario_inicio': horarioInicio,
        'horario_fim': horarioFim,
        'observacoes': observacoes,
        'convidados': convidados,
      }),
    ).timeout(const Duration(seconds: 15));

    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data['message'] ?? 'Erro ao atualizar reserva');
    }
  }

  Future<Map<String, dynamic>> cancelarReserva(int id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/reservas/$id'),
      headers: await _getHeaders(),
    ).timeout(const Duration(seconds: 15));

    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data['message'] ?? 'Erro ao cancelar reserva');
    }
  }

  // ==================== SOLICITAÇÕES ====================

  Future<List<dynamic>> getSolicitacoes() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/solicitacoes'),
        headers: await _getHeaders(),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'] ?? [];
      } else if (response.statusCode == 404) {
        return [];
      } else {
        throw Exception('Erro ao carregar solicitações');
      }
    } catch (e) {
      if (e.toString().contains('SocketException') ||
          e.toString().contains('Failed host lookup') ||
          e.toString().contains('Connection refused')) {
        return [];
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getSolicitacao(int id) async {
    final response = await http.get(
      Uri.parse('$baseUrl/solicitacoes/$id'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['data'] ?? {};
    } else {
      throw Exception('Erro ao carregar solicitação');
    }
  }

  Future<Map<String, dynamic>> criarSolicitacao({
    required String titulo,
    required String descricao,
    String? tipo,
    String? prioridade,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/solicitacoes'),
      headers: await _getHeaders(),
      body: jsonEncode({
        'titulo': titulo,
        'descricao': descricao,
        'tipo': tipo ?? 'manutencao',
        'prioridade': prioridade ?? 'media',
      }),
    ).timeout(const Duration(seconds: 15));

    final data = jsonDecode(response.body);
    if (response.statusCode == 200 || response.statusCode == 201) {
      return data;
    } else {
      throw Exception(data['message'] ?? 'Erro ao criar solicitação');
    }
  }

  Future<Map<String, dynamic>> atualizarSolicitacao({
    required dynamic id,
    required String titulo,
    required String descricao,
    String? tipo,
    String? prioridade,
  }) async {
    final idInt = id is int ? id : int.parse(id.toString());
    final response = await http.put(
      Uri.parse('$baseUrl/solicitacoes/$idInt'),
      headers: await _getHeaders(),
      body: jsonEncode({
        'assunto': titulo,
        'descricao': descricao,
        'tipo': tipo ?? 'manutencao',
        'prioridade': prioridade ?? 'media',
      }),
    ).timeout(const Duration(seconds: 15));

    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data['message'] ?? 'Erro ao atualizar solicitação');
    }
  }

  Future<Map<String, dynamic>> excluirSolicitacao(dynamic id) async {
    final idInt = id is int ? id : int.parse(id.toString());
    final response = await http.delete(
      Uri.parse('$baseUrl/solicitacoes/$idInt'),
      headers: await _getHeaders(),
    ).timeout(const Duration(seconds: 15));

    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data['message'] ?? 'Erro ao excluir solicitação');
    }
  }

  // ==================== OCORRÊNCIAS ====================

  Future<List<dynamic>> getOcorrencias() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/ocorrencias'),
        headers: await _getHeaders(),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'] ?? [];
      } else if (response.statusCode == 404) {
        return [];
      } else {
        throw Exception('Erro ao carregar ocorrências');
      }
    } catch (e) {
      if (e.toString().contains('SocketException') ||
          e.toString().contains('Failed host lookup') ||
          e.toString().contains('Connection refused')) {
        return [];
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> criarOcorrencia({
    required String descricao,
    required String local,
    String? tipo,
    String? gravidade,
    String? dataOcorrencia,
    String? horaOcorrencia,
    String? providencias,
    String? envolvidos,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/ocorrencias'),
      headers: await _getHeaders(),
      body: jsonEncode({
        'descricao': descricao,
        'local': local,
        'tipo': tipo ?? 'outro',
        'gravidade': gravidade ?? 'media',
        'data_ocorrencia': dataOcorrencia ?? DateTime.now().toString().split(' ')[0],
        'hora_ocorrencia': horaOcorrencia ?? '${DateTime.now().hour}:${DateTime.now().minute}:00',
        'providencias': providencias,
        'envolvidos': envolvidos,
      }),
    ).timeout(const Duration(seconds: 15));

    final data = jsonDecode(response.body);
    if (response.statusCode == 200 || response.statusCode == 201) {
      return data;
    } else {
      throw Exception(data['message'] ?? 'Erro ao registrar ocorrência');
    }
  }

  Future<Map<String, dynamic>> atualizarOcorrencia({
    required dynamic id,
    required String descricao,
    required String local,
    String? tipo,
    String? gravidade,
    String? dataOcorrencia,
    String? horaOcorrencia,
    String? providencias,
    String? envolvidos,
  }) async {
    final idInt = id is int ? id : int.parse(id.toString());
    final response = await http.put(
      Uri.parse('$baseUrl/ocorrencias/$idInt'),
      headers: await _getHeaders(),
      body: jsonEncode({
        'descricao': descricao,
        'local': local,
        'tipo': tipo ?? 'outro',
        'gravidade': gravidade ?? 'media',
        'data_ocorrencia': dataOcorrencia,
        'hora_ocorrencia': horaOcorrencia,
        'providencias': providencias,
        'envolvidos': envolvidos,
      }),
    ).timeout(const Duration(seconds: 15));

    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data['message'] ?? 'Erro ao atualizar ocorrência');
    }
  }

  Future<Map<String, dynamic>> excluirOcorrencia(dynamic id) async {
    final idInt = id is int ? id : int.parse(id.toString());
    final response = await http.delete(
      Uri.parse('$baseUrl/ocorrencias/$idInt'),
      headers: await _getHeaders(),
    ).timeout(const Duration(seconds: 15));

    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data['message'] ?? 'Erro ao excluir ocorrência');
    }
  }

  // ==================== OBRAS ====================

  Future<List<dynamic>> getObras() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/obras'),
        headers: await _getHeaders(),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'] ?? [];
      } else if (response.statusCode == 404) {
        return [];
      } else {
        throw Exception('Erro ao carregar obras');
      }
    } catch (e) {
      if (e.toString().contains('SocketException') ||
          e.toString().contains('Failed host lookup')) {
        return [];
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getObra(dynamic id) async {
    final idInt = id is int ? id : int.parse(id.toString());
    final response = await http.get(
      Uri.parse('$baseUrl/obras/$idInt'),
      headers: await _getHeaders(),
    ).timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['data'] ?? {};
    } else {
      throw Exception('Erro ao carregar obra');
    }
  }

  // ==================== LAUDOS ====================

  Future<List<dynamic>> getLaudos() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/laudos'),
        headers: await _getHeaders(),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'] ?? [];
      } else if (response.statusCode == 404) {
        return [];
      } else {
        throw Exception('Erro ao carregar laudos');
      }
    } catch (e) {
      if (e.toString().contains('SocketException') ||
          e.toString().contains('Failed host lookup')) {
        return [];
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getLaudo(dynamic id) async {
    final idInt = id is int ? id : int.parse(id.toString());
    final response = await http.get(
      Uri.parse('$baseUrl/laudos/$idInt'),
      headers: await _getHeaders(),
    ).timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['data'] ?? {};
    } else {
      throw Exception('Erro ao carregar laudo');
    }
  }

  String getLaudoDownloadUrl(String arquivo) {
    return '$baseUrl/laudos/download/${Uri.encodeComponent(arquivo)}';
  }

  String getMinutaDownloadUrl() {
    return '$baseUrl/laudos/minuta';
  }
}
