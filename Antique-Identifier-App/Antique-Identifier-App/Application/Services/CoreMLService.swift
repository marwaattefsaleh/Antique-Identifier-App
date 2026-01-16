import CoreML
import Vision
import UIKit

enum CoreMLError: Error {
    case modelLoadingFailed
    case imageProcessingFailed
    case predictionFailed
}

protocol CoreMLServiceProtocol {
    func classify(image: UIImage) throws -> [String: Double]
}

class CoreMLService: CoreMLServiceProtocol {
    private let model: VNCoreMLModel

    init() throws {
        guard let modelURL = Bundle.main.url(forResource: "MobileNetV2", withExtension: "mlmodelc") else {
            throw CoreMLError.modelLoadingFailed
        }
        let compiledModel = try MLModel(contentsOf: modelURL)
        self.model = try VNCoreMLModel(for: compiledModel)
    }

    func classify(image: UIImage) throws -> [String: Double] {
        guard let ciImage = CIImage(image: image) else {
            throw CoreMLError.imageProcessingFailed
        }

        var classifications: [String: Double] = [:]
        let request = VNCoreMLRequest(model: model) { (request, error) in
            if let results = request.results as? [VNClassificationObservation] {
                for classification in results {
                    classifications[classification.identifier] = Double(classification.confidence)
                }
            }
        }

        let handler = VNImageRequestHandler(ciImage: ciImage)
        try handler.perform([request])
        
        if classifications.isEmpty {
            throw CoreMLError.predictionFailed
        }

        return classifications
    }
}
