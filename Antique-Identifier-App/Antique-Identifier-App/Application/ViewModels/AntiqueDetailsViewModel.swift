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
    
    init(modelContext: ModelContext, image: UIImage?, result: CombinedAnalysisResult) {
        self.modelContext = modelContext
        self.detectedImage = image
        self.antiqueName = result.category.rawValue.capitalized
        self.antiqueCategory = result.category.rawValue.capitalized
        
        // Pre-fill notes with reasons
        self.antiqueNotes = result.reasons.map { "• \($0)" }.joined(separator: "\n")
        
        // Attempt to parse year from estimated period
        if let year = parseYear(from: result.estimatedPeriod) {
            self.antiqueYear = String(year)
        }
    }
    
    // Helper function to be added
    private func parseYear(from period: String) -> Int? {
        // Example: "Estimated Period: 18th-19th Century" -> tries to find a year
        // This is a simple implementation. A more robust one would use regex.
        let numbers = period.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        if numbers.count >= 4 {
            // A bit of a guess, take the first 4 digits
            return Int(numbers.prefix(4))
        }
        return nil
    }
    
    func saveAntique() {
        let imageData = detectedImage?.pngData()
        
        let newAntique = Antique(
            name: antiqueName,
            category: antiqueCategory.isEmpty ? nil : antiqueCategory,
            year: Int(antiqueYear),
            notes: antiqueNotes.isEmpty ? nil : antiqueNotes,
            dateAdded: Date(),
            imageData: imageData
        )
        modelContext.insert(newAntique)
        
        do {
            try modelContext.save()
            print("Antique saved successfully!")
        } catch {
            print("Error saving antique: \(error)")
        }
    }
}