import 'package:flutter/material.dart';
import 'presentation/screens/payment_step1_screen.dart';

/// Rotas do módulo de pagamento
class PaymentRoutes {
  static const String step1 = '/payment/step1';
  static const String step2 = '/payment/step2';
  static const String step3 = '/payment/step3';
  static const String step4 = '/payment/step4';
  static const String result = '/payment/result';

  static Map<String, WidgetBuilder> routes = {
    step1: (context) => const PaymentStep1Screen(),
  };
}


