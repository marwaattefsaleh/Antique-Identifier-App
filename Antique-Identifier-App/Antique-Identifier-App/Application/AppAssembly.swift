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
        
        container.register(AntiqueClassifierServiceProtocol?.self) { _ in
            AntiqueClassifierService()
        }.inObjectScope(.container)

        container.register(AntiqueAnalyzerProtocol.self) { r in
            AntiqueAnalyzer(
                antiqueClassifierService: r.resolve(AntiqueClassifierServiceProtocol.self)
            )
        }.inObjectScope(.container)

        container.register(MainViewModel.self) { r in
            MainViewModel(
                coreMLService: r.resolve(CoreMLServiceProtocol.self)!,
                antiqueAnalyzer: r.resolve(AntiqueAnalyzerProtocol.self)!
            )
        }
        
        container.register(AntiqueDetailsViewModel.self) { (r, detectedImage: UIImage, initialClassification: String) in
            let modelContext = ModelContext(self.modelContainer)
            return AntiqueDetailsViewModel(modelContext: modelContext, detectedImage: detectedImage, initialClassification: initialClassification)
        }
    }
}
