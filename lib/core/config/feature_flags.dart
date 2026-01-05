/// Feature Flags - Controle de funcionalidades
class FeatureFlags {
  // OTP Password Recovery via WhatsApp/SMS
  // TODO: Ativar após configurar Twilio/Zenvia
  static const bool enableOtpPasswordRecovery = false;
  
  // Pular telas de foto e documentos durante o cadastro
  // Se true, após completar informações pessoais, salva no Firestore e vai direto para dashboard
  static const bool skipPhotoAndDocuments = true;
}

