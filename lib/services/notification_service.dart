import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

  // Chaves para SharedPreferences - controle de notificações vistas
  static const String _keyLastComunicadoId = 'last_comunicado_id';
  static const String _keyLastCobrancaId = 'last_cobranca_id';
  static const String _keyLastReservaId = 'last_reserva_id';
  static const String _keyLastSolicitacaoId = 'last_solicitacao_id';
  static const String _keyLastOcorrenciaId = 'last_ocorrencia_id';
  static const String _keyLastObraId = 'last_obra_id';
  static const String _keyLastLaudoId = 'last_laudo_id';
  static const String _keyLastDocumentoId = 'last_documento_id';

  // IDs dos canais de notificação
  static const String _channelComunicados = 'comunicados_channel';
  static const String _channelCobrancas = 'cobrancas_channel';
  static const String _channelReservas = 'reservas_channel';
  static const String _channelSolicitacoes = 'solicitacoes_channel';
  static const String _channelOcorrencias = 'ocorrencias_channel';
  static const String _channelObras = 'obras_channel';
  static const String _channelLaudos = 'laudos_channel';
  static const String _channelDocumentos = 'documentos_channel';
  static const String _channelGeral = 'geral_channel';

  // Callback para quando uma notificação é tocada
  static void Function(String? payload)? onNotificationTap;

  Future<void> initialize() async {
    tz.initializeTimeZones();

    // Configurações Android
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    // Configurações iOS
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
    );

    // Criar canais de notificação no Android
    await _createNotificationChannels();

    // Solicitar permissões
    await requestPermissions();
  }

  Future<void> _createNotificationChannels() async {
    final androidPlugin = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      // Canal para Comunicados
      await androidPlugin.createNotificationChannel(const AndroidNotificationChannel(
        _channelComunicados,
        'Comunicados',
        description: 'Notificações de novos comunicados do condomínio',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      ));

      // Canal para Cobranças
      await androidPlugin.createNotificationChannel(const AndroidNotificationChannel(
        _channelCobrancas,
        'Cobranças',
        description: 'Notificações de cobranças e boletos',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      ));

      // Canal para Reservas
      await androidPlugin.createNotificationChannel(const AndroidNotificationChannel(
        _channelReservas,
        'Reservas',
        description: 'Notificações de reservas de áreas comuns',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      ));

      // Canal para Solicitações
      await androidPlugin.createNotificationChannel(const AndroidNotificationChannel(
        _channelSolicitacoes,
        'Solicitações',
        description: 'Notificações de atualizações em solicitações',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      ));

      // Canal para Ocorrências
      await androidPlugin.createNotificationChannel(const AndroidNotificationChannel(
        _channelOcorrencias,
        'Ocorrências',
        description: 'Notificações de ocorrências no condomínio',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      ));

      // Canal para Obras
      await androidPlugin.createNotificationChannel(const AndroidNotificationChannel(
        _channelObras,
        'Obras',
        description: 'Notificações de obras e manutenções',
        importance: Importance.defaultImportance,
        playSound: true,
        enableVibration: true,
      ));

      // Canal para Laudos
      await androidPlugin.createNotificationChannel(const AndroidNotificationChannel(
        _channelLaudos,
        'Laudos',
        description: 'Notificações de laudos técnicos',
        importance: Importance.defaultImportance,
        playSound: true,
        enableVibration: true,
      ));

      // Canal para Documentos
      await androidPlugin.createNotificationChannel(const AndroidNotificationChannel(
        _channelDocumentos,
        'Documentos',
        description: 'Notificações de novos documentos',
        importance: Importance.defaultImportance,
        playSound: true,
        enableVibration: true,
      ));

      // Canal Geral
      await androidPlugin.createNotificationChannel(const AndroidNotificationChannel(
        _channelGeral,
        'Geral',
        description: 'Notificações gerais do aplicativo',
        importance: Importance.defaultImportance,
        playSound: true,
        enableVibration: true,
      ));
    }
  }

  void _onNotificationResponse(NotificationResponse response) {
    if (onNotificationTap != null && response.payload != null) {
      onNotificationTap!(response.payload);
    }
  }

  Future<bool> requestPermissions() async {
    if (Platform.isAndroid) {
      final status = await Permission.notification.request();
      return status.isGranted;
    } else if (Platform.isIOS) {
      final iosPlugin = _notifications.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      final granted = await iosPlugin?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    }
    return false;
  }

  // Notificação de novo Comunicado
  Future<void> showComunicadoNotification({
    required int id,
    required String titulo,
    String? descricao,
  }) async {
    await _showNotification(
      id: id,
      channelId: _channelComunicados,
      channelName: 'Comunicados',
      title: 'Novo Comunicado',
      body: titulo,
      payload: 'comunicado:$id',
    );
  }

  // Notificação de nova Cobrança
  Future<void> showCobrancaNotification({
    required int id,
    required String titulo,
    String? valor,
    String? vencimento,
  }) async {
    String body = titulo;
    if (valor != null) body += ' - R\$ $valor';
    if (vencimento != null) body += ' - Vence em: $vencimento';

    await _showNotification(
      id: id + 10000, // Offset para evitar conflito de IDs
      channelId: _channelCobrancas,
      channelName: 'Cobranças',
      title: 'Nova Cobrança',
      body: body,
      payload: 'cobranca:$id',
    );
  }

  // Notificação de Reserva
  Future<void> showReservaNotification({
    required int id,
    required String titulo,
    String? status,
    String? data,
  }) async {
    String body = titulo;
    if (status != null) body += ' - Status: $status';
    if (data != null) body += ' - Data: $data';

    await _showNotification(
      id: id + 20000,
      channelId: _channelReservas,
      channelName: 'Reservas',
      title: 'Atualização de Reserva',
      body: body,
      payload: 'reserva:$id',
    );
  }

  // Notificação de Solicitação
  Future<void> showSolicitacaoNotification({
    required int id,
    required String titulo,
    String? status,
  }) async {
    String body = titulo;
    if (status != null) body += ' - Status: $status';

    await _showNotification(
      id: id + 30000,
      channelId: _channelSolicitacoes,
      channelName: 'Solicitações',
      title: 'Atualização de Solicitação',
      body: body,
      payload: 'solicitacao:$id',
    );
  }

  // Notificação de Ocorrência
  Future<void> showOcorrenciaNotification({
    required int id,
    required String titulo,
    String? status,
  }) async {
    String body = titulo;
    if (status != null) body += ' - Status: $status';

    await _showNotification(
      id: id + 40000,
      channelId: _channelOcorrencias,
      channelName: 'Ocorrências',
      title: 'Atualização de Ocorrência',
      body: body,
      payload: 'ocorrencia:$id',
    );
  }

  // Notificação de Obra
  Future<void> showObraNotification({
    required int id,
    required String titulo,
    String? status,
  }) async {
    String body = titulo;
    if (status != null) body += ' - Status: $status';

    await _showNotification(
      id: id + 50000,
      channelId: _channelObras,
      channelName: 'Obras',
      title: 'Atualização de Obra',
      body: body,
      payload: 'obra:$id',
    );
  }

  // Notificação de Laudo
  Future<void> showLaudoNotification({
    required int id,
    required String titulo,
  }) async {
    await _showNotification(
      id: id + 60000,
      channelId: _channelLaudos,
      channelName: 'Laudos',
      title: 'Novo Laudo Disponível',
      body: titulo,
      payload: 'laudo:$id',
    );
  }

  // Notificação de Documento
  Future<void> showDocumentoNotification({
    required int id,
    required String titulo,
  }) async {
    await _showNotification(
      id: id + 70000,
      channelId: _channelDocumentos,
      channelName: 'Documentos',
      title: 'Novo Documento',
      body: titulo,
      payload: 'documento:$id',
    );
  }

  // Notificação Geral
  Future<void> showGeneralNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    await _showNotification(
      id: id + 80000,
      channelId: _channelGeral,
      channelName: 'Geral',
      title: title,
      body: body,
      payload: payload,
    );
  }

  Future<void> _showNotification({
    required int id,
    required String channelId,
    required String channelName,
    required String title,
    required String body,
    String? payload,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(id, title, body, details, payload: payload);
  }

  // Agendar notificação
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      _channelGeral,
      'Geral',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload,
    );
  }

  // Cancelar notificação
  Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }

  // Cancelar todas as notificações
  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  // Métodos para verificar atualizações e notificar

  Future<void> checkAndNotifyNewComunicados(List<dynamic> comunicados) async {
    if (comunicados.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final lastId = prefs.getInt(_keyLastComunicadoId) ?? 0;

    for (var comunicado in comunicados) {
      final id = comunicado['id'] ?? 0;
      if (id > lastId) {
        await showComunicadoNotification(
          id: id,
          titulo: comunicado['titulo'] ?? 'Novo comunicado',
          descricao: comunicado['descricao'],
        );
      }
    }

    // Salvar o maior ID
    if (comunicados.isNotEmpty) {
      final maxId = comunicados.map((c) => c['id'] ?? 0).reduce((a, b) => a > b ? a : b);
      await prefs.setInt(_keyLastComunicadoId, maxId);
    }
  }

  Future<void> checkAndNotifyNewCobrancas(List<dynamic> cobrancas) async {
    if (cobrancas.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final lastId = prefs.getInt(_keyLastCobrancaId) ?? 0;

    for (var cobranca in cobrancas) {
      final id = cobranca['id'] ?? 0;
      if (id > lastId) {
        await showCobrancaNotification(
          id: id,
          titulo: cobranca['titulo'] ?? cobranca['descricao'] ?? 'Nova cobrança',
          valor: cobranca['valor']?.toString(),
          vencimento: cobranca['vencimento'],
        );
      }
    }

    if (cobrancas.isNotEmpty) {
      final maxId = cobrancas.map((c) => c['id'] ?? 0).reduce((a, b) => a > b ? a : b);
      await prefs.setInt(_keyLastCobrancaId, maxId);
    }
  }

  Future<void> checkAndNotifyNewReservas(List<dynamic> reservas) async {
    if (reservas.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final lastId = prefs.getInt(_keyLastReservaId) ?? 0;

    for (var reserva in reservas) {
      final id = reserva['id'] ?? 0;
      if (id > lastId) {
        await showReservaNotification(
          id: id,
          titulo: reserva['local'] ?? reserva['titulo'] ?? 'Reserva',
          status: reserva['status'],
          data: reserva['data'],
        );
      }
    }

    if (reservas.isNotEmpty) {
      final maxId = reservas.map((r) => r['id'] ?? 0).reduce((a, b) => a > b ? a : b);
      await prefs.setInt(_keyLastReservaId, maxId);
    }
  }

  Future<void> checkAndNotifyNewSolicitacoes(List<dynamic> solicitacoes) async {
    if (solicitacoes.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final lastId = prefs.getInt(_keyLastSolicitacaoId) ?? 0;

    for (var solicitacao in solicitacoes) {
      final id = solicitacao['id'] ?? 0;
      if (id > lastId) {
        await showSolicitacaoNotification(
          id: id,
          titulo: solicitacao['titulo'] ?? solicitacao['assunto'] ?? 'Solicitação',
          status: solicitacao['status'],
        );
      }
    }

    if (solicitacoes.isNotEmpty) {
      final maxId = solicitacoes.map((s) => s['id'] ?? 0).reduce((a, b) => a > b ? a : b);
      await prefs.setInt(_keyLastSolicitacaoId, maxId);
    }
  }

  Future<void> checkAndNotifyNewOcorrencias(List<dynamic> ocorrencias) async {
    if (ocorrencias.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final lastId = prefs.getInt(_keyLastOcorrenciaId) ?? 0;

    for (var ocorrencia in ocorrencias) {
      final id = ocorrencia['id'] ?? 0;
      if (id > lastId) {
        await showOcorrenciaNotification(
          id: id,
          titulo: ocorrencia['titulo'] ?? ocorrencia['descricao'] ?? 'Ocorrência',
          status: ocorrencia['status'],
        );
      }
    }

    if (ocorrencias.isNotEmpty) {
      final maxId = ocorrencias.map((o) => o['id'] ?? 0).reduce((a, b) => a > b ? a : b);
      await prefs.setInt(_keyLastOcorrenciaId, maxId);
    }
  }

  Future<void> checkAndNotifyNewObras(List<dynamic> obras) async {
    if (obras.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final lastId = prefs.getInt(_keyLastObraId) ?? 0;

    for (var obra in obras) {
      final id = obra['id'] ?? 0;
      if (id > lastId) {
        await showObraNotification(
          id: id,
          titulo: obra['titulo'] ?? obra['descricao'] ?? 'Obra',
          status: obra['status'],
        );
      }
    }

    if (obras.isNotEmpty) {
      final maxId = obras.map((o) => o['id'] ?? 0).reduce((a, b) => a > b ? a : b);
      await prefs.setInt(_keyLastObraId, maxId);
    }
  }

  Future<void> checkAndNotifyNewLaudos(List<dynamic> laudos) async {
    if (laudos.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final lastId = prefs.getInt(_keyLastLaudoId) ?? 0;

    for (var laudo in laudos) {
      final id = laudo['id'] ?? 0;
      if (id > lastId) {
        await showLaudoNotification(
          id: id,
          titulo: laudo['titulo'] ?? laudo['descricao'] ?? 'Laudo',
        );
      }
    }

    if (laudos.isNotEmpty) {
      final maxId = laudos.map((l) => l['id'] ?? 0).reduce((a, b) => a > b ? a : b);
      await prefs.setInt(_keyLastLaudoId, maxId);
    }
  }

  Future<void> checkAndNotifyNewDocumentos(List<dynamic> documentos) async {
    if (documentos.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final lastId = prefs.getInt(_keyLastDocumentoId) ?? 0;

    for (var documento in documentos) {
      final id = documento['id'] ?? 0;
      if (id > lastId) {
        await showDocumentoNotification(
          id: id,
          titulo: documento['titulo'] ?? documento['nome'] ?? 'Documento',
        );
      }
    }

    if (documentos.isNotEmpty) {
      final maxId = documentos.map((d) => d['id'] ?? 0).reduce((a, b) => a > b ? a : b);
      await prefs.setInt(_keyLastDocumentoId, maxId);
    }
  }

  // Resetar IDs salvos (útil para logout)
  Future<void> resetSavedIds() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyLastComunicadoId);
    await prefs.remove(_keyLastCobrancaId);
    await prefs.remove(_keyLastReservaId);
    await prefs.remove(_keyLastSolicitacaoId);
    await prefs.remove(_keyLastOcorrenciaId);
    await prefs.remove(_keyLastObraId);
    await prefs.remove(_keyLastLaudoId);
    await prefs.remove(_keyLastDocumentoId);
  }
}
