import CoreML
import Vision
import UIKit

enum CoreMLError: Error {
    case modelLoadingFailed
    case imageProcessingFailed
    case predictionFailed
}

struct ClassificationResult {
    let category: AntiqueCategory
    let classifications: [String: Double]
}

protocol CoreMLServiceProtocol {
    func classify(image: UIImage) throws -> ClassificationResult
}

class CoreMLService: CoreMLServiceProtocol {
    private let model: VNCoreMLModel

    private let antiqueCategoryMapping: [String: AntiqueCategory] = [
        // Furniture
        "chair": .furniture, "armchair": .furniture, "rocking chair": .furniture, "swivel chair": .furniture,
        "table": .furniture, "dining table": .furniture, "coffee table": .furniture, "desk": .furniture,
        "cabinet": .furniture, "cupboard": .furniture, "wardrobe": .furniture, "bookcase": .furniture,
        "sofa": .furniture, "couch": .furniture, "loveseat": .furniture, "sofa bed": .furniture,

        // Clocks & Watches
        "clock": .clock, "wall clock": .clock, "digital clock": .clock, "stopwatch": .clock,
        
        // Artwork & Frames
        "artwork": .artwork, "painting": .artwork, "frame": .artwork, "picture frame": .artwork, "drawing": .artwork,
        
        // Ceramics & Porcelain
        "vase": .ceramic, "pot": .ceramic, "ceramic": .ceramic, "porcelain": .ceramic, "plate": .ceramic,
        
        // Glassware
        "glass": .glass, "goblet": .glass, "wine glass": .glass, "bottle": .glass,
        
        // Metal Objects
        "lamp": .metal, "metal": .metal, "iron": .metal, "bronze": .metal, "brass": .metal, "tools": .metal,
        
        // Books & Manuscripts
        "book": .book, "manuscript": .book,
        
        // Jewelry
        "jewelry": .jewelry, "necklace": .jewelry, "ring": .jewelry, "earring": .jewelry, "bracelet": .jewelry
    ]

    init() throws {
        guard let modelURL = Bundle.main.url(forResource: "MobileNetV2", withExtension: "mlmodelc") else {
            throw CoreMLError.modelLoadingFailed
        }
        
        let compiledModel = try MLModel(contentsOf: modelURL)
        for input in compiledModel.modelDescription.inputDescriptionsByName {
            print("Input name: \(input.key), type: \(input.value)")
        }
        self.model = try VNCoreMLModel(for: compiledModel)
    }

    func classify(image: UIImage) throws -> ClassificationResult {
        guard let resizedImage = image.resize(to: CGSize(width: 224, height: 224)),
              let pixelBuffer = resizedImage.toCVPixelBuffer() else {
            throw CoreMLError.imageProcessingFailed
        }

        var classifications: [String: Double] = [:]
        let request = VNCoreMLRequest(model: model) { (request, error) in
            if let results = request.results as? [VNClassificationObservation] {
                // Take top 5
                let topResults = results.prefix(5)
                for classification in topResults {
                    // ImageNet labels often have multiple parts, e.g., "dining table, board"
                    let primaryLabel = classification.identifier.components(separatedBy: ",")[0]
                    classifications[primaryLabel] = Double(classification.confidence)
                }
            }
        }

        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer)
        try handler.perform([request])
        
        if classifications.isEmpty {
            throw CoreMLError.predictionFailed
        }
        
        let category = getAntiqueCategory(from: classifications)
        
        return ClassificationResult(category: category, classifications: classifications)
    }
    
    private func getAntiqueCategory(from classifications: [String: Double]) -> AntiqueCategory {
        for (label, _) in classifications.sorted(by: { $0.value > $1.value }) {
            for (keyword, type) in antiqueCategoryMapping {
                if label.lowercased().contains(keyword) {
                    return type
                }
            }
        }
        return .unknown
    }
}
