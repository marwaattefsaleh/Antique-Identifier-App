import Foundation
import Swinject
import SwiftData
import UIKit

// Define your application's dependency assembly for Swinject.
// This structure accepts a SwiftData ModelContainer so you can register
// repositories, services, and other dependencies that need database access.
struct AppAssembly: Assembly {
    let modelContainer: ModelContainer

    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
    }

    func assemble(container: Container) {
        container.register(CoreMLServiceProtocol.self) { _ in
            try! CoreMLService()
        }.inObjectScope(.container)

        container.register(MainViewModel.self) { r in
            MainViewModel(coreMLService: r.resolve(CoreMLServiceProtocol.self)!)
        }
        
        container.register(AntiqueDetailsViewModel.self) { (_, detectedImage: UIImage, initialClassification: String) in
            // Create a new ModelContext for the details view model.
            // This ensures that the details view model has its own context for saving,
            // independent of the main app's context if needed.
            let modelContext = ModelContext(self.modelContainer)
            return AntiqueDetailsViewModel(modelContext: modelContext, detectedImage: detectedImage, initialClassification: initialClassification)
        }
    }
}
