import Foundation
import SwiftData
import SwiftUI // For UIImage
import Combine

class AntiqueDetailsViewModel: ObservableObject {
    @Published var antiqueName: String = ""
    @Published var antiqueCategory: String = ""
    @Published var antiqueYear: String = ""
    @Published var antiqueNotes: String = ""
    @Published var detectedImage: UIImage?
    
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext, detectedImage: UIImage? = nil, initialClassification: String = "") {
        self.modelContext = modelContext
        self.detectedImage = detectedImage
        self.antiqueName = initialClassification
        self.antiqueCategory = initialClassification // Using initial classification as category for now
    }
    
    func saveAntique() {
        let newAntique = Antique(
            name: antiqueName,
            category: antiqueCategory.isEmpty ? nil : antiqueCategory,
            year: Int(antiqueYear),
            notes: antiqueNotes.isEmpty ? nil : antiqueNotes,
            dateAdded: Date()
        )
        modelContext.insert(newAntique)
        // TODO: Save image with antique
        do {
            try modelContext.save()
            print("Antique saved successfully!")
        } catch {
            print("Error saving antique: \(error)")
        }
    }
}