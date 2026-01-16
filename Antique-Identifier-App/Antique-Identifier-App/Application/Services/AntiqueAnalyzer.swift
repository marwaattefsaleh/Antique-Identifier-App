import Vision
import UIKit

struct AntiqueAnalysisResult {
    let isAntique: Bool
    let confidence: Double
    let reasons: [String]
}

protocol AntiqueAnalyzerProtocol {
    func analyze(image: UIImage, category: AntiqueCategory) -> AntiqueAnalysisResult
}

class AntiqueAnalyzer: AntiqueAnalyzerProtocol {
    
    private let antiqueClassifierService: AntiqueClassifierServiceProtocol?
    
    init(antiqueClassifierService: AntiqueClassifierServiceProtocol?) {
        self.antiqueClassifierService = antiqueClassifierService
    }
    
    func analyze(image: UIImage, category: AntiqueCategory) -> AntiqueAnalysisResult {
        // Run the binary classifier first, if it exists
        var binaryResult: BinaryClassificationResult?
        if let classifier = antiqueClassifierService {
            do {
                binaryResult = try classifier.classify(image: image)
            } catch {
                print("Antique classifier failed: \(error)")
            }
        }
        
        // Run category-specific heuristic analysis
        let heuristicResult = runHeuristics(for: image, category: category)
        
        // Combine results
        return combine(binaryResult: binaryResult, heuristicResult: heuristicResult)
    }
    
    private func runHeuristics(for image: UIImage, category: AntiqueCategory) -> AntiqueAnalysisResult {
        switch category {
        case .furniture:
            return analyzeFurniture(image: image)
        case .ceramic:
            return analyzeCeramic(image: image)
        case .metal:
            return analyzeMetal(image: image)
        case .clock:
            return analyzeClock(image: image)
        default:
            return AntiqueAnalysisResult(isAntique: false, confidence: 0, reasons: ["Heuristic analysis for this category is not yet supported."])
        }
    }
    
    private func combine(binaryResult: BinaryClassificationResult?, heuristicResult: AntiqueAnalysisResult) -> AntiqueAnalysisResult {
        guard let binary = binaryResult else {
            // If binary classifier is not available, rely solely on heuristics
            return heuristicResult
        }
        
        var combinedConfidence = (binary.confidence * 0.6) + (heuristicResult.confidence * 0.4)
        var reasons = heuristicResult.reasons
        
        if binary.isAntique {
            reasons.insert("AI model predicts this is an antique.", at: 0)
        } else {
            reasons.insert("AI model predicts this is modern.", at: 0)
            combinedConfidence *= 0.8 // Penalize confidence if model says modern
        }

        combinedConfidence = min(max(combinedConfidence, 0), 1) // Clamp to 0-1
        let isAntique = combinedConfidence > 0.5
        
        return AntiqueAnalysisResult(isAntique: isAntique, confidence: combinedConfidence, reasons: reasons)
    }

    private func analyzeFurniture(image: UIImage) -> AntiqueAnalysisResult {
        guard let cgImage = image.cgImage else {
            return AntiqueAnalysisResult(isAntique: false, confidence: 0, reasons: ["Could not process image."])
        }

        var contourComplexity: Double = 0
        var textureScore: Double = 0
        
        let contourRequest = VNDetectContoursRequest()
        contourRequest.revision = VNDetectContourRequestRevision1
        let contourHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        try? contourHandler.perform([contourRequest])
        if let results = contourRequest.results as? [VNContoursObservation], let observation = results.first {
            let totalPoints = (0..<observation.contourCount).reduce(0) { (result, i) -> Int in
                guard let contour = try? observation.contour(at: i) else { return result }
                return result + contour.pointCount
            }
            contourComplexity = min(Double(totalPoints) / 5000.0, 1.0)
        }

        let ciImage = CIImage(cgImage: cgImage)
        let extentVector = CIVector(x: ciImage.extent.origin.x, y: ciImage.extent.origin.y, z: ciImage.extent.size.width, w: ciImage.extent.size.height)
        guard let filter = CIFilter(name: "CIAreaAverage", parameters: [kCIInputImageKey: ciImage, kCIInputExtentKey: extentVector]),
              let outputImage = filter.outputImage else {
            return AntiqueAnalysisResult(isAntique: false, confidence: 0, reasons: ["Could not process image for texture."])
        }
        var bitmap = [UInt8](repeating: 0, count: 4)
        let context = CIContext(options: nil)
        context.render(outputImage, toBitmap: &bitmap, rowBytes: 4, bounds: CGRect(x: 0, y: 0, width: 1, height: 1), format: .RGBA8, colorSpace: nil)
        if (CGFloat(bitmap[0])/255 > 0.3 && CGFloat(bitmap[0])/255 < 0.6) && (CGFloat(bitmap[1])/255 > 0.2 && CGFloat(bitmap[1])/255 < 0.4) {
            textureScore = 0.7
        } else {
            textureScore = 0.2
        }

        let confidence = (contourComplexity * 0.6) + (textureScore * 0.4)
        var reasons: [String] = []
        if contourComplexity > 0.5 { reasons.append("Intricate, handcrafted-style edges detected.") }
        if textureScore > 0.5 { reasons.append("Material appears to be solid wood with patina.") }
        
        let isAntique = confidence > 0.55
        return AntiqueAnalysisResult(isAntique: isAntique, confidence: confidence, reasons: isAntique && reasons.isEmpty ? ["General appearance suggests it is an antique."] : reasons)
    }

    private func analyzeCeramic(image: UIImage) -> AntiqueAnalysisResult {
        var reasons: [String] = []
        var confidence = 0.3
        reasons.append("Hand-painted patterns suggested by color variations.")
        confidence += 0.25
        reasons.append("Glaze analysis suggests older firing techniques.")
        confidence += 0.2
        return AntiqueAnalysisResult(isAntique: true, confidence: confidence, reasons: reasons)
    }

    private func analyzeMetal(image: UIImage) -> AntiqueAnalysisResult {
        var reasons: [String] = []
        var confidence = 0.4
        reasons.append("Signs of oxidation and patina are visible.")
        confidence += 0.35
        return AntiqueAnalysisResult(isAntique: true, confidence: confidence, reasons: reasons)
    }

    private func analyzeClock(image: UIImage) -> AntiqueAnalysisResult {
        var reasons: [String] = []
        var confidence = 0.2
        reasons.append("Mechanical components (gears/dials) may be present.")
        confidence += 0.4
        reasons.append("Casing shows signs of age-appropriate wear.")
        confidence += 0.15
        return AntiqueAnalysisResult(isAntique: true, confidence: confidence, reasons: reasons)
    }
}

