import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class BiometricService {
  final LocalAuthentication _localAuth = LocalAuthentication();

  // Configuração do secure storage com opções para Android
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
      resetOnError: true, // Reseta se houver erro de criptografia
    ),
  );

  static const String _emailKey = 'biometric_email';
  static const String _passwordKey = 'biometric_password';
  static const String _enabledKey = 'biometric_enabled';

  /// Verifica se o dispositivo suporta biometria
  Future<bool> isBiometricAvailable() async {
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();

      // Verificar se há biometrias cadastradas
      if (canCheck && isDeviceSupported) {
        final availableBiometrics = await _localAuth.getAvailableBiometrics();
        return availableBiometrics.isNotEmpty;
      }
      return false;
    } on PlatformException catch (e) {
      print('Erro ao verificar biometria: $e');
      return false;
    } catch (e) {
      print('Erro inesperado ao verificar biometria: $e');
      return false;
    }
  }

  /// Verifica se a biometria está habilitada pelo usuário
  Future<bool> isBiometricEnabled() async {
    try {
      final enabled = await _secureStorage.read(key: _enabledKey);
      return enabled == 'true';
    } catch (e) {
      print('Erro ao verificar biometria habilitada: $e');
      // Se houver erro de criptografia, limpar dados corrompidos
      await _clearAllSecureData();
      return false;
    }
  }

  /// Verifica se há credenciais salvas
  Future<bool> hasStoredCredentials() async {
    try {
      final email = await _secureStorage.read(key: _emailKey);
      final password = await _secureStorage.read(key: _passwordKey);
      return email != null && password != null && email.isNotEmpty && password.isNotEmpty;
    } catch (e) {
      print('Erro ao verificar credenciais: $e');
      await _clearAllSecureData();
      return false;
    }
  }

  /// Limpa todos os dados seguros (em caso de erro de criptografia)
  Future<void> _clearAllSecureData() async {
    try {
      await _secureStorage.deleteAll();
    } catch (e) {
      print('Erro ao limpar dados seguros: $e');
    }
  }

  /// Salva as credenciais de forma segura
  Future<bool> saveCredentials(String email, String password) async {
    try {
      // Limpar dados antigos antes de salvar novos
      await _clearAllSecureData();
      await _secureStorage.write(key: _emailKey, value: email);
      await _secureStorage.write(key: _passwordKey, value: password);
      await _secureStorage.write(key: _enabledKey, value: 'true');
      return true;
    } catch (e) {
      print('Erro ao salvar credenciais: $e');
      return false;
    }
  }

  /// Recupera as credenciais salvas
  Future<Map<String, String>?> getCredentials() async {
    try {
      final email = await _secureStorage.read(key: _emailKey);
      final password = await _secureStorage.read(key: _passwordKey);

      if (email != null && password != null) {
        return {'email': email, 'password': password};
      }
      return null;
    } catch (e) {
      print('Erro ao recuperar credenciais: $e');
      await _clearAllSecureData();
      return null;
    }
  }

  /// Remove as credenciais e desabilita biometria
  Future<void> clearCredentials() async {
    try {
      await _secureStorage.delete(key: _emailKey);
      await _secureStorage.delete(key: _passwordKey);
      await _secureStorage.write(key: _enabledKey, value: 'false');
    } catch (e) {
      print('Erro ao limpar credenciais: $e');
      await _clearAllSecureData();
    }
  }

  /// Autentica usando biometria
  Future<bool> authenticate() async {
    try {
      return await _localAuth.authenticate(
        localizedReason: 'Use sua impressão digital ou reconhecimento facial para entrar no app',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false, // Permite PIN/senha como fallback
          useErrorDialogs: true,
          sensitiveTransaction: true,
        ),
      );
    } on PlatformException catch (e) {
      print('Erro na autenticação biométrica: $e');
      return false;
    } catch (e) {
      print('Erro inesperado na autenticação: $e');
      return false;
    }
  }

  /// Verifica se pode mostrar opção de biometria (disponível + credenciais salvas)
  Future<bool> canUseBiometric() async {
    final available = await isBiometricAvailable();
    final enabled = await isBiometricEnabled();
    final hasCredentials = await hasStoredCredentials();
    return available && enabled && hasCredentials;
  }
}
