import CoreLocation
import Combine

/// Ubicación opcional para los metadatos de Core Data (3.5). Si el usuario no da permiso,
/// o no hay ubicación disponible, simplemente se guarda sin coordenadas (hasLocation = false).
final class LocationHelper: NSObject, ObservableObject, CLLocationManagerDelegate {
    static let shared = LocationHelper()

    private let manager = CLLocationManager()
    private var completion: (((lat: Double, lon: Double)?) -> Void)?

    override init() {
        super.init()
        manager.delegate = self
    }

    /// Pide un "fix" de ubicación puntual con un pequeño timeout. No bloquea la captura si falla.
    func requestOneShotLocation(completion: @escaping ((lat: Double, lon: Double)?) -> Void) {
        let status = manager.authorizationStatus
        guard status == .authorizedWhenInUse || status == .authorizedAlways else {
            if status == .notDetermined {
                manager.requestWhenInUseAuthorization()
            }
            completion(nil)
            return
        }
        self.completion = completion
        manager.requestLocation()

        // Si CoreLocation no responde en 3s (común en el simulador sin ubicación simulada), no bloqueamos.
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
            if let pending = self?.completion {
                pending(nil)
                self?.completion = nil
            }
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first, let completion else { return }
        completion((location.coordinate.latitude, location.coordinate.longitude))
        self.completion = nil
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        completion?(nil)
        completion = nil
    }
}
