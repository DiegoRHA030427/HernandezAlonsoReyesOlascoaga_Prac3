import CoreData

/// Pila de Core Data (3.5: "Implementar Core Data para metadatos: fecha, ubicación, etiquetas").
/// El modelo se llama "CamaraMicrofono" y contiene una sola entidad: CapturedItem.
struct PersistenceController {
    static let shared = PersistenceController()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "CamaraMicrofono")
        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }
        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                // En una app de producción se manejaría con más cuidado;
                // para la práctica, si falla la carga del store no tiene sentido continuar.
                fatalError("No se pudo cargar el store de Core Data: \(error), \(error.userInfo)")
            }
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
    }

    func save() {
        let context = container.viewContext
        guard context.hasChanges else { return }
        do {
            try context.save()
        } catch {
            print("Error guardando el contexto de Core Data: \(error)")
        }
    }
}
