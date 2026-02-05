import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'card_brand_detector.dart';

/// Helper para carregar imagens de bandeiras de cartão dos arquivos de imagem
class CardBrandImageLoader {
  /// Mapeia CardBrand para o caminho do arquivo de imagem
  static String? _getBrandImagePath(CardBrand brand) {
    switch (brand) {
      case CardBrand.visa:
        return 'assets/bandeiras_images/Visa.svg';
      case CardBrand.mastercard:
        return 'assets/bandeiras_images/MasterCard.svg';
      case CardBrand.amex:
        return 'assets/bandeiras_images/American_Express.svg';
      case CardBrand.elo:
        return 'assets/bandeiras_images/Elo.svg';
      case CardBrand.hipercard:
        return 'assets/bandeiras_images/Hipercard.svg';
      case CardBrand.hiper:
        return 'assets/bandeiras_images/Hiper.svg';
      case CardBrand.diners:
        return 'assets/bandeiras_images/Diners_Club.svg';
      case CardBrand.discover:
        return 'assets/bandeiras_images/Discover_Network.svg';
      case CardBrand.jcb:
        return 'assets/bandeiras_images/JCB.svg';
      case CardBrand.unknown:
        return null;
    }
  }

  /// Retorna a imagem da bandeira como Widget
  static Widget? getBrandImage(CardBrand brand) {
    final imagePath = _getBrandImagePath(brand);
    
    if (imagePath == null) {
      return null;
    }

    // Verifica se é SVG ou PNG/JPG
    final isSvg = imagePath.toLowerCase().endsWith('.svg');

    if (isSvg) {
      return SvgPicture.asset(
        imagePath,
        width: 40,
        height: 24,
        fit: BoxFit.contain,
        placeholderBuilder: (context) => const SizedBox(
          width: 40,
          height: 24,
          child: Center(
            child: SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white54,
              ),
            ),
          ),
        ),
      );
    } else {
      return Image.asset(
        imagePath,
        width: 40,
        height: 24,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          debugPrint('❌ Erro ao carregar imagem para $brand: $error');
          return const SizedBox.shrink();
        },
      );
    }
  }
}
