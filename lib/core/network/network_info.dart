/// Interface para verificar conectividade de rede
abstract class NetworkInfo {
  Future<bool> get isConnected;
}

/// Implementação da verificação de conectividade
class NetworkInfoImpl implements NetworkInfo {
  @override
  Future<bool> get isConnected async {
    // TODO: Implementar verificação real de conectividade
    // Pode usar o pacote connectivity_plus
    return true;
  }
}
