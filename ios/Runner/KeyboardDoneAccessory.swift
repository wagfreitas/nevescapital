import UIKit
import Flutter

/// Plugin nativo para adicionar uma action bar customizada ao teclado iOS.
/// Esta implementação usa UITextInputAssistantItem e Input Accessory View nativos,
/// proporcionando uma experiência mais fluida e integrada com o iOS.
@objc public class KeyboardDoneAccessory: NSObject, FlutterPlugin {

    // MARK: - Properties

    private static var channel: FlutterMethodChannel?
    fileprivate static var isEnabled: Bool = true
    fileprivate static var buttonText: String = "OK"
    fileprivate static var buttonColor: UIColor = UIColor.systemBlue
    fileprivate static var toolbarColor: UIColor = UIColor.systemGray6
    fileprivate static var toolbarHeight: CGFloat = 44.0

    // Singleton para acesso global
    @objc public static let shared = KeyboardDoneAccessory()

    private override init() {
        super.init()
    }

    // MARK: - FlutterPlugin Registration

    public static func register(with registrar: FlutterPluginRegistrar) {
        channel = FlutterMethodChannel(
            name: "com.nevescapital.pagpag/keyboard_accessory",
            binaryMessenger: registrar.messenger()
        )

        let instance = KeyboardDoneAccessory.shared
        registrar.addMethodCallDelegate(instance, channel: channel!)

        // Ativa automaticamente após registro
        instance.enableGlobalAccessory()

        debugPrint("[KeyboardDoneAccessory] Plugin registrado com sucesso")
    }

    // MARK: - FlutterPlugin Method Handler

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "enable":
            enableGlobalAccessory()
            result(true)

        case "disable":
            disableGlobalAccessory()
            result(true)

        case "configure":
            if let args = call.arguments as? [String: Any] {
                configure(with: args)
            }
            result(true)

        case "isEnabled":
            result(KeyboardDoneAccessory.isEnabled)

        default:
            result(FlutterMethodNotImplemented)
        }
    }

    // MARK: - Configuration

    private func configure(with args: [String: Any]) {
        if let text = args["buttonText"] as? String {
            KeyboardDoneAccessory.buttonText = text
        }

        if let colorHex = args["buttonColor"] as? String {
            KeyboardDoneAccessory.buttonColor = UIColor(hex: colorHex) ?? .systemBlue
        }

        if let toolbarColorHex = args["toolbarColor"] as? String {
            KeyboardDoneAccessory.toolbarColor = UIColor(hex: toolbarColorHex) ?? .systemGray6
        }

        if let height = args["toolbarHeight"] as? Double {
            KeyboardDoneAccessory.toolbarHeight = CGFloat(height)
        }
    }

    // MARK: - Public Methods

    /// Método legado para compatibilidade com AppDelegate existente
    @objc public func start() {
        // Este método agora é chamado automaticamente pelo register()
        // Mantido para compatibilidade com código existente
        debugPrint("[KeyboardDoneAccessory] start() chamado - usando registro automático")
    }

    /// Ativa a action bar globalmente para todos os campos de texto
    public func enableGlobalAccessory() {
        KeyboardDoneAccessory.isEnabled = true
        swizzleTextFieldMethods()
        debugPrint("[KeyboardDoneAccessory] Action bar ativada globalmente")
    }

    /// Desativa a action bar global
    public func disableGlobalAccessory() {
        KeyboardDoneAccessory.isEnabled = false
        debugPrint("[KeyboardDoneAccessory] Action bar desativada")
    }

    // MARK: - Swizzling para interceptar UITextField

    private static var hasSwizzled = false

    private func swizzleTextFieldMethods() {
        guard !KeyboardDoneAccessory.hasSwizzled else { return }

        // Swizzle UITextField
        swizzleInputAccessoryView(for: UITextField.self)

        // Swizzle UITextView
        swizzleInputAccessoryView(for: UITextView.self)

        KeyboardDoneAccessory.hasSwizzled = true
    }

    private func swizzleInputAccessoryView(for targetClass: AnyClass) {
        let originalSelector = #selector(getter: UITextField.inputAccessoryView)
        let swizzledSelector = #selector(getter: UITextField.pagpag_inputAccessoryView)

        guard let originalMethod = class_getInstanceMethod(targetClass, originalSelector),
              let swizzledMethod = class_getInstanceMethod(targetClass, swizzledSelector) else {
            return
        }

        method_exchangeImplementations(originalMethod, swizzledMethod)
    }

    // MARK: - Toolbar Factory

    fileprivate static func createDoneToolbar() -> UIToolbar {
        let toolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: toolbarHeight))
        toolbar.barStyle = .default
        toolbar.isTranslucent = false // Não translúcido para parecer parte do teclado
        toolbar.barTintColor = toolbarColor
        toolbar.tintColor = buttonColor
        
        // Remove bordas arredondadas e sombras para integrar com o teclado
        toolbar.clipsToBounds = true
        toolbar.layer.cornerRadius = 0 // Sem bordas arredondadas

        // Aplica estilo que se integra com o teclado (sem bordas arredondadas)
        if #available(iOS 15.0, *) {
            let appearance = UIToolbarAppearance()
            appearance.configureWithOpaqueBackground() // Fundo opaco para parecer parte do teclado
            appearance.backgroundColor = toolbarColor
            
            // Remove sombras e bordas arredondadas
            appearance.shadowColor = .clear
            appearance.shadowImage = UIImage()
            
            // Remove bordas arredondadas da toolbar
            toolbar.standardAppearance = appearance
            toolbar.scrollEdgeAppearance = appearance
            toolbar.compactAppearance = appearance
        } else {
            // Para iOS < 15, remove sombras manualmente
            toolbar.setShadowImage(UIImage(), forToolbarPosition: .any)
        }

        // Espaçador flexível para empurrar o botão para a direita
        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)

        // Botão Done customizado
        let doneButton = UIBarButtonItem(
            title: buttonText,
            style: .done,
            target: KeyboardDoneAccessory.shared,
            action: #selector(doneButtonTapped)
        )

        // Estiliza o botão
        doneButton.setTitleTextAttributes([
            .font: UIFont.systemFont(ofSize: 17, weight: .semibold),
            .foregroundColor: buttonColor
        ], for: .normal)

        toolbar.items = [flexSpace, doneButton]
        toolbar.sizeToFit()

        return toolbar
    }

    @objc private func doneButtonTapped() {
        // Recolhe o teclado
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)

        // Notifica o Flutter que o botão foi pressionado
        KeyboardDoneAccessory.channel?.invokeMethod("onDonePressed", arguments: nil)
    }
}

// MARK: - UITextField Extension para Swizzling

extension UITextField {
    
    // Flag para evitar recursão infinita
    private static var isCreatingAccessory = false

    @objc var pagpag_inputAccessoryView: UIView? {
        // Evitar recursão infinita
        guard !UITextField.isCreatingAccessory else {
            return nil
        }
        
        // Verifica se está habilitado
        guard KeyboardDoneAccessory.isEnabled else {
            return nil
        }

        // Verifica se o keyboardType é numérico (para mostrar o botão OK apenas em teclados numéricos)
        let shouldShowAccessory = self.keyboardType == .numberPad || 
                                  self.keyboardType == .phonePad ||
                                  self.keyboardType == .decimalPad

        guard shouldShowAccessory else {
            return nil
        }

        // Marcar que estamos criando para evitar recursão
        UITextField.isCreatingAccessory = true
        defer { UITextField.isCreatingAccessory = false }

        // Cria a toolbar com o botão Done
        return KeyboardDoneAccessory.createDoneToolbar()
    }
}

// MARK: - UITextView Extension para Swizzling

extension UITextView {

    @objc var pagpag_inputAccessoryView: UIView? {
        // Verifica se está habilitado
        guard KeyboardDoneAccessory.isEnabled else {
            return nil
        }

        // Cria a toolbar com o botão Done para TextViews também
        return KeyboardDoneAccessory.createDoneToolbar()
    }
}

// MARK: - UIColor Extension para parsing de Hex

extension UIColor {
    convenience init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0

        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }

        let length = hexSanitized.count

        if length == 6 {
            self.init(
                red: CGFloat((rgb & 0xFF0000) >> 16) / 255.0,
                green: CGFloat((rgb & 0x00FF00) >> 8) / 255.0,
                blue: CGFloat(rgb & 0x0000FF) / 255.0,
                alpha: 1.0
            )
        } else if length == 8 {
            self.init(
                red: CGFloat((rgb & 0xFF000000) >> 24) / 255.0,
                green: CGFloat((rgb & 0x00FF0000) >> 16) / 255.0,
                blue: CGFloat((rgb & 0x0000FF00) >> 8) / 255.0,
                alpha: CGFloat(rgb & 0x000000FF) / 255.0
            )
        } else {
            return nil
        }
    }

    func toHex() -> String {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0

        getRed(&r, green: &g, blue: &b, alpha: &a)

        return String(format: "#%02X%02X%02X", Int(r * 255), Int(g * 255), Int(b * 255))
    }
}
