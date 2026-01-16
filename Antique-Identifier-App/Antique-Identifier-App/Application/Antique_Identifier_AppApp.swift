import SwiftUI
import Swinject
import SwiftData

@main
struct Antique_Identifier_AppApp: App {
    let assembler: Assembler
    let resolver: Resolver
    let modelContainer: ModelContainer
    
    init() {
        // Initialize the SwiftData ModelContainer
        modelContainer = try! ModelContainer(for: Antique.self)
        
        assembler = Assembler([
            AppAssembly(modelContainer: modelContainer)
        ])
        resolver = assembler.resolver
    }

    var body: some Scene {
        WindowGroup {
            MainView(viewModel: resolver.resolve(MainViewModel.self)!, resolver: resolver)
        }
        .modelContainer(modelContainer)
    }
}

