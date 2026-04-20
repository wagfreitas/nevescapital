// A biblioteca flutter_credit_card_detector está instalada e disponível
// Ela fornece um widget completo CreditCardWidget, mas para detecção simples
// usamos nossa implementação customizada que é mais eficiente e não requer Provider
// A biblioteca pode ser usada no futuro se precisarmos do widget completo de cartão

/// Utilitário para detectar a bandeira de cartão de crédito
/// baseado nos primeiros dígitos (BIN - Bank Identification Number)
/// Implementação baseada nos padrões da biblioteca flutter_credit_card_detector
/// Suporta: Visa, Mastercard, American Express, Elo, Hipercard, Diners, Discover, JCB
class CardBrandDetector {
  /// Detecta a bandeira do cartão baseado nos primeiros dígitos
  /// Usa algoritmos de detecção baseados nos padrões BIN (Bank Identification Number)
  static CardBrand detectBrand(String cardNumber) {
    // Remove espaços e caracteres não numéricos
    final digits = cardNumber.replaceAll(RegExp(r'\D'), '');
    
    if (digits.isEmpty) {
      return CardBrand.unknown;
    }
    
    // Verificar BINs específicos ANTES das regras genéricas (ex.: "começa com 4" = Visa).
    // Ordem: Hiper (6 dígitos), Hipercard (6062), Elo (6 dígitos).
    if (digits.length >= 6) {
      if (_isHiper(digits)) return CardBrand.hiper;
      if (_isHipercard(digits)) return CardBrand.hipercard;
      if (_isElo(digits)) return CardBrand.elo;
    }
    if (digits.length >= 4) {
      if (_isHipercard(digits)) return CardBrand.hipercard;
    }
    
    // Visa: começa com 4
    if (digits.startsWith('4')) {
      return CardBrand.visa;
    }
    
    // Mastercard: 51-55 ou 2221-2720
    if (digits.startsWith(RegExp(r'^5[1-5]'))) {
      return CardBrand.mastercard;
    }
    if (digits.length >= 4) {
      final first4 = int.tryParse(digits.substring(0, 4)) ?? 0;
      if (first4 >= 2221 && first4 <= 2720) {
        return CardBrand.mastercard;
      }
    }
    
    // American Express: 34 ou 37
    if (digits.startsWith('34') || digits.startsWith('37')) {
      return CardBrand.amex;
    }
    
    // Diners Club: 36, 38, ou 300-305
    if (digits.startsWith('36') || digits.startsWith('38')) {
      return CardBrand.diners;
    }
    if (digits.length >= 3) {
      final first3 = int.tryParse(digits.substring(0, 3)) ?? 0;
      if (first3 >= 300 && first3 <= 305) {
        return CardBrand.diners;
      }
    }
    
    // Discover: 6011, 622126-622925, 644-649, 65
    if (digits.startsWith('6011') || digits.startsWith('65')) {
      return CardBrand.discover;
    }
    if (digits.length >= 6) {
      final first6 = int.tryParse(digits.substring(0, 6)) ?? 0;
      if (first6 >= 622126 && first6 <= 622925) {
        return CardBrand.discover;
      }
    }
    if (digits.length >= 3) {
      final first3 = int.tryParse(digits.substring(0, 3)) ?? 0;
      if (first3 >= 644 && first3 <= 649) {
        return CardBrand.discover;
      }
    }
    
    // JCB: 3528-3589
    if (digits.length >= 4) {
      final first4 = int.tryParse(digits.substring(0, 4)) ?? 0;
      if (first4 >= 3528 && first4 <= 3589) {
        return CardBrand.jcb;
      }
    }
    
    return CardBrand.unknown;
  }
  
  /// Verifica se é cartão Elo
  static bool _isElo(String digits) {
    if (digits.length < 6) return false;
    
    final eloBins = [
      '401178', '401179', '438935', '457631', '457632',
      '431274', '451416', '457393', '504175', '506699',
      '506778', '509000', '509001', '509002', '509003',
      '627780', '636297', '636368', '650031', '650032',
      '650033', '650035', '650036', '650037', '650038',
      '650039', '650040', '650041', '650042', '650043',
      '650044', '650045', '650046', '650047', '650048',
      '650049', '650050', '650051', '650405', '650406',
      '650407', '650408', '650409', '650410', '650411',
      '650412', '650413', '650414', '650415', '650416',
      '650417', '650418', '650419', '650420', '650421',
      '650422', '650423', '650424', '650425', '650426',
      '650427', '650428', '650429', '650430', '650431',
      '650432', '650433', '650434', '650435', '650436',
      '650437', '650438', '650439', '650440', '650441',
      '650442', '650443', '650444', '650445', '650446',
      '650447', '650448', '650449', '650450', '650451',
      '650452', '650453', '650454', '650455', '650456',
      '650457', '650458', '650459', '650460', '650461',
      '650462', '650463', '650464', '650465', '650466',
      '650467', '650468', '650469', '650470', '650471',
      '650472', '650473', '650474', '650475', '650476',
      '650477', '650478', '650479', '650480', '650481',
      '650482', '650483', '650484', '650485', '650486',
      '650487', '650488', '650489', '650490', '650491',
      '650492', '650493', '650494', '650495', '650496',
      '650497', '650498', '650499', '650500', '650501',
      '650502', '650503', '650504', '650505', '650506',
      '650507', '650508', '650509', '650510', '650511',
      '650512', '650513', '650514', '650515', '650516',
      '650517', '650518', '650519', '650520', '650521',
      '650522', '650523', '650524', '650525', '650526',
      '650527', '650528', '650529', '650530', '650531',
      '650532', '650533', '650534', '650535', '650536',
      '650537', '650538', '650539', '650540', '650541',
    ];
    
    final first6 = digits.substring(0, 6);
    return eloBins.contains(first6);
  }
  
  /// Hiper: BINs 637095, 637612, 637599, 637609 (6 primeiros dígitos)
  static bool _isHiper(String digits) {
    if (digits.length < 6) return false;
    const hiperBins = ['637095', '637612', '637599', '637609'];
    return hiperBins.contains(digits.substring(0, 6));
  }

  /// Hipercard: prefixo 6062 (qualquer número que comece com 6062)
  static bool _isHipercard(String digits) {
    if (digits.length < 4) return false;
    return digits.startsWith('6062');
  }
  
  /// Retorna o nome da bandeira em português
  static String getBrandName(CardBrand brand) {
    switch (brand) {
      case CardBrand.visa:
        return 'Visa';
      case CardBrand.mastercard:
        return 'Mastercard';
      case CardBrand.amex:
        return 'American Express';
      case CardBrand.elo:
        return 'Elo';
      case CardBrand.hipercard:
        return 'Hipercard';
      case CardBrand.hiper:
        return 'Hiper';
      case CardBrand.diners:
        return 'Diners Club';
      case CardBrand.discover:
        return 'Discover';
      case CardBrand.jcb:
        return 'JCB';
      case CardBrand.unknown:
        return 'Desconhecido';
    }
  }
  
  /// Número de dígitos esperado (padrão) para a bandeira.
  /// Usado para validação de comprimento. Para bandeiras de comprimento
  /// variável, retorna o tamanho mais comum.
  static int getExpectedDigits(CardBrand brand) {
    switch (brand) {
      case CardBrand.amex:
        return 15;
      case CardBrand.diners:
        return 14;
      default:
        return 16;
    }
  }

  /// Limite máximo de dígitos aceitos para a bandeira.
  /// Usado para truncar o input sem rejeitar números válidos mais longos.
  static int getMaxDigits(CardBrand brand) {
    switch (brand) {
      case CardBrand.amex:
        return 15;
      case CardBrand.diners:
        return 14;
      case CardBrand.unknown:
        return 19;
      default:
        return 16;
    }
  }

  /// Tamanho dos grupos para formatação visual do número.
  /// Sempre agrupa de 4 em 4 dígitos, independentemente da bandeira.
  /// Para 15 dígitos (Amex): 4-4-4-3 | 14 (Diners): 4-4-4-2 | 16: 4-4-4-4.
  static List<int> getGroupSizes(CardBrand brand) {
    return const [4, 4, 4, 4];
  }

  /// Comprimento esperado do CVV/CID para a bandeira.
  static int getCvvLength(CardBrand brand) {
    return brand == CardBrand.amex ? 4 : 3;
  }

  /// Retorna o ícone/asset path para a bandeira
  static String? getBrandAssetPath(CardBrand brand) {
    switch (brand) {
      case CardBrand.visa:
        return 'assets/icons/visa.png';
      case CardBrand.mastercard:
        return 'assets/icons/mastercard.png';
      case CardBrand.amex:
        return 'assets/icons/amex.png';
      case CardBrand.elo:
        return 'assets/icons/elo.png';
      case CardBrand.hipercard:
        return 'assets/icons/hipercard.png';
      case CardBrand.hiper:
        return 'assets/icons/hiper.png';
      case CardBrand.diners:
        return 'assets/icons/diners.png';
      case CardBrand.discover:
        return 'assets/icons/discover.png';
      case CardBrand.jcb:
        return 'assets/icons/jcb.png';
      default:
        return null;
    }
  }
}

/// Enum com as bandeiras de cartão suportadas
enum CardBrand {
  visa,
  mastercard,
  amex,
  elo,
  hipercard,
  hiper,
  diners,
  discover,
  jcb,
  unknown,
}

