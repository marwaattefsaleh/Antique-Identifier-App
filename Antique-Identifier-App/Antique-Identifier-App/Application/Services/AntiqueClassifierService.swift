import CoreML
import Vision
import UIKit

struct BinaryClassificationResult {
    let isAntique: Bool
    let confidence: Double
}

protocol AntiqueClassifierServiceProtocol {
    func classify(image: UIImage) throws -> BinaryClassificationResult
}

class AntiqueClassifierService: AntiqueClassifierServiceProtocol {
    private let model: VNCoreMLModel

    init?() {
        guard let modelURL = Bundle.main.url(forResource: "AntiqueClassifier", withExtension: "mlmodelc"),
              let compiledModel = try? MLModel(contentsOf: modelURL),
              let visionModel = try? VNCoreMLModel(for: compiledModel) else {
            return nil // Model not found or failed to load, so service is not available.
        }
        self.model = visionModel
    }
    
    func classify(image: UIImage) throws -> BinaryClassificationResult {
        guard let ciImage = CIImage(image: image) else {
            throw CoreMLError.imageProcessingFailed
        }

        var classificationResult: BinaryClassificationResult?
        let request = VNCoreMLRequest(model: model) { (request, error) in
            if let results = request.results as? [VNClassificationObservation],
               let topResult = results.first {
                classificationResult = BinaryClassificationResult(
                    isAntique: topResult.identifier.lowercased() == "antique",
                    confidence: Double(topResult.confidence)
                )
            }
        }

        let handler = VNImageRequestHandler(ciImage: ciImage)
        try handler.perform([request])
        
        guard let result = classificationResult else {
            throw CoreMLError.predictionFailed
        }

        return result
    }
}
