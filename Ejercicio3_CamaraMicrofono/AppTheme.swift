import SwiftUI

/// Mismos temas institucionales del Ejercicio 2 (3.4: "Aplicar los mismos temas personalizables").
enum AppTheme: String, CaseIterable, Identifiable, Codable {
    case guinda
    case azul

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .guinda: return "Guinda (IPN)"
        case .azul: return "Azul (ESCOM)"
        }
    }

    /// SwiftUI adapta el resto de la interfaz al modo claro/oscuro automáticamente
    /// porque solo fijamos el color de acento; el resto usa colores semánticos del sistema.
    var accentColor: Color {
        switch self {
        case .guinda:
            return Color(red: 0.608, green: 0.008, blue: 0.239) // ~ #9B023D
        case .azul:
            return Color(red: 0.0, green: 0.243, blue: 0.502) // ~ #003E80
        }
    }
}

final class SettingsStore: ObservableObject {
    @Published var theme: AppTheme {
        didSet { UserDefaults.standard.set(theme.rawValue, forKey: Keys.theme) }
    }

    @Published var defaultAlbum: String {
        didSet { UserDefaults.standard.set(defaultAlbum, forKey: Keys.defaultAlbum) }
    }

    private enum Keys {
        static let theme = "cm.appTheme"
        static let defaultAlbum = "cm.defaultAlbum"
    }

    init() {
        let storedTheme = UserDefaults.standard.string(forKey: Keys.theme).flatMap(AppTheme.init(rawValue:)) ?? .guinda
        self.theme = storedTheme
        self.defaultAlbum = UserDefaults.standard.string(forKey: Keys.defaultAlbum) ?? "General"
    }
}
