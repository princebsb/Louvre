import 'dart:async';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../services/api_service.dart';
import '../services/biometric_service.dart';
import '../services/badge_service.dart';
import 'comunicados_screen.dart';
import 'documentos_screen.dart';
import 'cobrancas_screen.dart';
import 'prestacao_contas_screen.dart';
import 'login_screen.dart';
import 'reservas_screen.dart';
import 'solicitacoes_screen.dart';
import 'ocorrencias_screen.dart';
import 'obras_screen.dart';
import 'laudos_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final _apiService = ApiService();
  final _biometricService = BiometricService();
  final _badgeService = BadgeService();
  Map<String, dynamic>? _user;
  String _appVersion = '';
  String _nomeCondominio = 'CONDOMINIO LOUVRE';
  bool _biometricAvailable = false;
  bool _biometricEnabled = false;
  Timer? _updateTimer;

  @override
  void initState() {
    super.initState();
    _loadUser();
    _loadAppVersion();
    _loadNomeCondominio();
    _checkBiometric();
    _checkForUpdates();
    _badgeService.addListener(_onBadgeUpdate);
    // Verificar atualizacoes a cada 2 minutos
    _updateTimer = Timer.periodic(const Duration(minutes: 2), (_) => _checkForUpdates());
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    _badgeService.removeListener(_onBadgeUpdate);
    super.dispose();
  }

  void _onBadgeUpdate() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _checkForUpdates() async {
    try {
      // Verificar comunicados
      final comunicados = await _apiService.getComunicados();
      await _badgeService.updateComunicadosCount(comunicados);

      // Verificar documentos
      final documentos = await _apiService.getDocumentos();
      await _badgeService.updateDocumentosCount(documentos);

      // Verificar cobrancas
      final cobrancas = await _apiService.getCobrancas();
      await _badgeService.updateCobrancasCount(cobrancas);

      // Verificar reservas
      final reservas = await _apiService.getReservas();
      await _badgeService.updateReservasCount(reservas);

      // Verificar solicitacoes
      final solicitacoes = await _apiService.getSolicitacoes();
      await _badgeService.updateSolicitacoesCount(solicitacoes);

      // Verificar ocorrencias
      final ocorrencias = await _apiService.getOcorrencias();
      await _badgeService.updateOcorrenciasCount(ocorrencias);

      // Verificar obras
      final obras = await _apiService.getObras();
      await _badgeService.updateObrasCount(obras);

      // Verificar laudos
      final laudos = await _apiService.getLaudos();
      await _badgeService.updateLaudosCount(laudos);
    } catch (e) {
      // Silenciosamente ignorar erros
    }
  }

  Future<void> _checkBiometric() async {
    final available = await _biometricService.isBiometricAvailable();
    final enabled = await _biometricService.isBiometricEnabled();
    if (mounted) {
      setState(() {
        _biometricAvailable = available;
        _biometricEnabled = enabled;
      });
    }
  }

  Future<void> _loadUser() async {
    final user = await _apiService.getUser();
    setState(() => _user = user);
  }

  Future<void> _loadAppVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      _appVersion = 'Ver ${packageInfo.version}';
    });
  }

  Future<void> _loadNomeCondominio() async {
    final nome = await _apiService.getNomeCondominio();
    setState(() => _nomeCondominio = nome);
  }

  List<Widget> get _screens => [
    DashboardTab(badgeService: _badgeService),
    const ComunicadosScreen(),
    const DocumentosScreen(),
    const CobrancasScreen(),
    const PrestacaoContasScreen(),
  ];

  void _logout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sair'),
        content: const Text('Deseja realmente sair?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              await _apiService.logout();
              await _badgeService.resetAllBadges();
              if (!context.mounted) return;
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
            child: const Text('Sair', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleBiometric(bool enable) async {
    if (enable) {
      final authenticated = await _biometricService.authenticate();
      if (!authenticated) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Autenticacao biometrica cancelada'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      final user = await _apiService.getUser();
      if (user != null && user['email'] != null) {
        final password = await _showPasswordDialog();
        if (password != null && password.isNotEmpty) {
          final saved = await _biometricService.saveCredentials(user['email'], password);
          if (mounted) {
            if (saved) {
              setState(() => _biometricEnabled = true);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Biometria ativada com sucesso!'),
                  backgroundColor: Colors.green,
                ),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Erro ao ativar biometria. Tente novamente.'),
                  backgroundColor: Colors.orange,
                ),
              );
            }
          }
        }
      }
    } else {
      await _biometricService.clearCredentials();
      if (mounted) {
        setState(() => _biometricEnabled = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Biometria desativada'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  Future<String?> _showPasswordDialog() async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Senha'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Digite sua senha para ativar o login por biometria:',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Senha',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.lock),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
            ),
            child: const Text('Confirmar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(int count) {
    if (count == 0) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: const BoxDecoration(
        color: Colors.red,
        shape: BoxShape.circle,
      ),
      constraints: const BoxConstraints(
        minWidth: 18,
        minHeight: 18,
      ),
      child: Text(
        count > 99 ? '99+' : count.toString(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildIconWithBadge(IconData icon, int badgeCount, {Color? color}) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(icon, color: color),
        if (badgeCount > 0)
          Positioned(
            right: -8,
            top: -4,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(10),
              ),
              constraints: const BoxConstraints(
                minWidth: 16,
                minHeight: 16,
              ),
              child: Text(
                badgeCount > 99 ? '99+' : badgeCount.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_nomeCondominio),
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        actions: [
          if (_badgeService.totalBadges > 0)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_badgeService.totalBadges} novo${_badgeService.totalBadges > 1 ? 's' : ''}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      drawer: _buildDrawer(),
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF2563EB),
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Inicio',
          ),
          BottomNavigationBarItem(
            icon: _buildIconWithBadge(Icons.announcement, _badgeService.newComunicados),
            activeIcon: _buildIconWithBadge(Icons.announcement, _badgeService.newComunicados, color: const Color(0xFF2563EB)),
            label: 'Comunicados',
          ),
          BottomNavigationBarItem(
            icon: _buildIconWithBadge(Icons.folder, _badgeService.newDocumentos),
            activeIcon: _buildIconWithBadge(Icons.folder, _badgeService.newDocumentos, color: const Color(0xFF2563EB)),
            label: 'Documentos',
          ),
          BottomNavigationBarItem(
            icon: _buildIconWithBadge(Icons.receipt, _badgeService.newCobrancas),
            activeIcon: _buildIconWithBadge(Icons.receipt, _badgeService.newCobrancas, color: const Color(0xFF2563EB)),
            label: 'Boletos',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.account_balance),
            label: 'Contabilidade',
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              color: Color(0xFF2563EB),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Icon(
                  Icons.apartment,
                  size: 48,
                  color: Colors.white,
                ),
                const SizedBox(height: 12),
                Text(
                  _nomeCondominio,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _user?['name'] ?? 'Carregando...',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          _buildDrawerItem(
            icon: Icons.event_available,
            title: 'Reservas',
            badgeCount: _badgeService.newReservas,
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ReservasScreen()),
              );
            },
          ),
          _buildDrawerItem(
            icon: Icons.assignment,
            title: 'Solicitacoes',
            badgeCount: _badgeService.newSolicitacoes,
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SolicitacoesScreen()),
              );
            },
          ),
          _buildDrawerItem(
            icon: Icons.report_problem,
            title: 'Ocorrencias',
            badgeCount: _badgeService.newOcorrencias,
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const OcorrenciasScreen()),
              );
            },
          ),
          _buildDrawerItem(
            icon: Icons.construction,
            title: 'Obras',
            badgeCount: _badgeService.newObras,
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ObrasScreen()),
              );
            },
          ),
          _buildDrawerItem(
            icon: Icons.description,
            title: 'Laudos de Pericia',
            badgeCount: _badgeService.newLaudos,
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const LaudosScreen()),
              );
            },
          ),
          const Divider(),
          if (_biometricAvailable)
            ListTile(
              leading: Icon(
                Icons.fingerprint,
                color: _biometricEnabled ? Colors.green : Colors.grey,
              ),
              title: const Text('Login por Biometria'),
              subtitle: Text(
                _biometricEnabled ? 'Ativado' : 'Desativado',
                style: TextStyle(
                  color: _biometricEnabled ? Colors.green : Colors.grey,
                  fontSize: 12,
                ),
              ),
              trailing: Switch(
                value: _biometricEnabled,
                onChanged: (value) => _toggleBiometric(value),
                activeColor: const Color(0xFF2563EB),
              ),
              onTap: () => _toggleBiometric(!_biometricEnabled),
            ),
          if (_biometricAvailable) const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Sair'),
            onTap: () {
              Navigator.pop(context);
              _logout();
            },
          ),
          const Divider(),
          if (_appVersion.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                _appVersion,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required int badgeCount,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: _buildIconWithBadge(icon, badgeCount, color: const Color(0xFF2563EB)),
      title: Row(
        children: [
          Text(title),
          if (badgeCount > 0) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                badgeCount.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
      onTap: onTap,
    );
  }
}

class DashboardTab extends StatefulWidget {
  final BadgeService badgeService;

  const DashboardTab({super.key, required this.badgeService});

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
  final _apiService = ApiService();
  Map<String, dynamic>? _user;

  @override
  void initState() {
    super.initState();
    _loadUser();
    widget.badgeService.addListener(_onBadgeUpdate);
  }

  @override
  void dispose() {
    widget.badgeService.removeListener(_onBadgeUpdate);
    super.dispose();
  }

  void _onBadgeUpdate() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _loadUser() async {
    final user = await _apiService.getUser();
    setState(() => _user = user);
  }

  bool get _hasAlerts =>
      widget.badgeService.newReservas > 0 ||
      widget.badgeService.newSolicitacoes > 0 ||
      widget.badgeService.newOcorrencias > 0;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Bem-vindo!',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _user?['name'] ?? 'Carregando...',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                  if (_user?['apartamento'] != null) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.home, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Apartamento ${_user!['apartamento']}${_user!['bloco'] != null ? ' - Bloco ${_user!['bloco']}' : ''}',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          // Seção de Alertas
          if (_hasAlerts) ...[
            const SizedBox(height: 20),
            Row(
              children: [
                const Icon(Icons.notifications_active, color: Colors.red, size: 24),
                const SizedBox(width: 8),
                const Text(
                  'Alertas',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (widget.badgeService.newReservas > 0)
              _buildAlertCard(
                icon: Icons.event_available,
                title: 'Reservas',
                count: widget.badgeService.newReservas,
                color: const Color(0xFF10B981),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ReservasScreen()),
                  );
                },
              ),
            if (widget.badgeService.newSolicitacoes > 0)
              _buildAlertCard(
                icon: Icons.assignment,
                title: 'Solicitacoes',
                count: widget.badgeService.newSolicitacoes,
                color: const Color(0xFF3B82F6),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SolicitacoesScreen()),
                  );
                },
              ),
            if (widget.badgeService.newOcorrencias > 0)
              _buildAlertCard(
                icon: Icons.report_problem,
                title: 'Ocorrencias',
                count: widget.badgeService.newOcorrencias,
                color: const Color(0xFFF59E0B),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const OcorrenciasScreen()),
                  );
                },
              ),
          ],
          const SizedBox(height: 20),
          const Text(
            'Acesso Rapido',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            children: [
              _buildQuickAccessCard(
                icon: Icons.announcement,
                title: 'Comunicados',
                color: Colors.blue,
                tabIndex: 1,
                badgeCount: widget.badgeService.newComunicados,
              ),
              _buildQuickAccessCard(
                icon: Icons.folder,
                title: 'Documentos',
                color: Colors.green,
                tabIndex: 2,
                badgeCount: widget.badgeService.newDocumentos,
              ),
              _buildQuickAccessCard(
                icon: Icons.receipt,
                title: 'Boletos',
                color: Colors.orange,
                tabIndex: 3,
                badgeCount: widget.badgeService.newCobrancas,
              ),
              _buildQuickAccessCard(
                icon: Icons.account_balance,
                title: 'Contabilidade',
                color: Colors.purple,
                tabIndex: 4,
                badgeCount: 0,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAlertCard({
    required IconData icon,
    required String title,
    required int count,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color.withOpacity(0.3), width: 1),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '$count ${count == 1 ? 'nova atualizacao' : 'novas atualizacoes'}',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  count.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.arrow_forward_ios, color: Colors.grey[400], size: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickAccessCard({
    required IconData icon,
    required String title,
    required Color color,
    required int tabIndex,
    required int badgeCount,
  }) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: () {
          final homeState = context.findAncestorStateOfType<_HomeScreenState>();
          homeState?.setState(() {
            homeState._currentIndex = tabIndex;
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 48, color: color),
                  const SizedBox(height: 12),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            if (badgeCount > 0)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    badgeCount > 99 ? '99+' : badgeCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
