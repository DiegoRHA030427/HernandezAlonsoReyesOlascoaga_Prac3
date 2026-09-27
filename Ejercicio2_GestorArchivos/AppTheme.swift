import SwiftUI

/// Temas personalizables de la aplicación (Ejercicio 2.2).
/// Los colores son aproximaciones de los tonos institucionales;
/// ajústalos con el hex exacto de tu manual de identidad si lo tienes.
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

    /// Color de acento. SwiftUI adapta automáticamente el resto de la interfaz
    /// (fondos, separadores, texto) al modo claro/oscuro porque usamos colores
    /// semánticos del sistema (.systemBackground, .secondary, etc.) en las vistas.
    var accentColor: Color {
        switch self {
        case .guinda:
            return Color(red: 0.608, green: 0.008, blue: 0.239) // ~ #9B023D
        case .azul:
            return Color(red: 0.0, green: 0.243, blue: 0.502) // ~ #003E80
        }
    }
}

/// Preferencias de sesión persistentes (Ejercicio 2.3):
/// tema seleccionado y última carpeta visitada.
final class SettingsStore: ObservableObject {
    @Published var theme: AppTheme {
        didSet { UserDefaults.standard.set(theme.rawValue, forKey: Keys.theme) }
    }

    @Published var lastVisitedPath: String {
        didSet { UserDefaults.standard.set(lastVisitedPath, forKey: Keys.lastVisitedPath) }
    }

    private enum Keys {
        static let theme = "appTheme"
        static let lastVisitedPath = "lastVisitedPath"
    }

    init() {
        let storedTheme = UserDefaults.standard.string(forKey: Keys.theme).flatMap(AppTheme.init(rawValue:)) ?? .guinda
        self.theme = storedTheme
        self.lastVisitedPath = UserDefaults.standard.string(forKey: Keys.lastVisitedPath) ?? ""
    }
}
