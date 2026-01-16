import CoreML
import Vision
import UIKit

enum CoreMLError: Error {
    case modelLoadingFailed
    case imageProcessingFailed
    case predictionFailed
}

struct ClassificationResult {
    let furnitureType: FurnitureType
    let classifications: [String: Double]
}

protocol CoreMLServiceProtocol {
    func classify(image: UIImage) throws -> ClassificationResult
}

class CoreMLService: CoreMLServiceProtocol {
    private let model: VNCoreMLModel

    private let furnitureMapping: [String: FurnitureType] = [
        "chair": .chair, "armchair": .chair, "rocking chair": .chair, "swivel chair": .chair,
        "table": .table, "dining table": .table, "coffee table": .table, "desk": .table,
        "cabinet": .cabinet, "cupboard": .cabinet, "wardrobe": .cabinet,
        "sofa": .sofa, "couch": .sofa, "loveseat": .sofa, "sofa bed": .sofa
    ]

    init() throws {
        guard let modelURL = Bundle.main.url(forResource: "MobileNetV2", withExtension: "mlmodelc") else {
            throw CoreMLError.modelLoadingFailed
        }
        let compiledModel = try MLModel(contentsOf: modelURL)
        self.model = try VNCoreMLModel(for: compiledModel)
    }

    func classify(image: UIImage) throws -> ClassificationResult {
        guard let ciImage = CIImage(image: image) else {
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

        let handler = VNImageRequestHandler(ciImage: ciImage)
        try handler.perform([request])
        
        if classifications.isEmpty {
            throw CoreMLError.predictionFailed
        }
        
        let furnitureType = getFurnitureType(from: classifications)
        
        return ClassificationResult(furnitureType: furnitureType, classifications: classifications)
    }
    
    private func getFurnitureType(from classifications: [String: Double]) -> FurnitureType {
        for (label, _) in classifications.sorted(by: { $0.value > $1.value }) {
            for (keyword, type) in furnitureMapping {
                if label.lowercased().contains(keyword) {
                    return type
                }
            }
        }
        return .unknown
    }
}
