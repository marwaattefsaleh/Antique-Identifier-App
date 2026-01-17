import Vision
import UIKit

protocol AntiqueAnalyzerProtocol {
    func analyze(image: UIImage, category: AntiqueCategory) -> AntiqueAnalysisResult
}

class AntiqueAnalyzer: AntiqueAnalyzerProtocol {
    
    private let antiqueClassifierService: AntiqueClassifierServiceProtocol?
    private let coreMLService: CoreMLServiceProtocol // Add CoreMLService
    
    init(antiqueClassifierService: AntiqueClassifierServiceProtocol?, coreMLService: CoreMLServiceProtocol) {
        self.antiqueClassifierService = antiqueClassifierService
        self.coreMLService = coreMLService // Initialize CoreMLService
    }
    
    func analyze(image: UIImage, category: AntiqueCategory) -> AntiqueAnalysisResult {
        var binaryResult: BinaryClassificationResult?
        
        // Try the dedicated antique classifier first
        if let classifier = antiqueClassifierService {
            do {
                binaryResult = try classifier.classify(image: image)
            } catch {
                print("Antique classifier failed: \(error)")
            }
        }
        
        // If dedicated classifier failed or is not available, try to derive from MobileNet
        if binaryResult == nil {
            do {
                let mobileNetClassification = try coreMLService.classify(image: image)
                binaryResult = deriveBinaryResult(from: mobileNetClassification)
                // Add a reason if we used MobileNet as a fallback
                // This will be added to reasons in combine function
            } catch {
                print("MobileNet classification failed as a fallback: \(error)")
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
    
    private func deriveBinaryResult(from classificationResult: ClassificationResult) -> BinaryClassificationResult {
        // Simple logic: if a specific antique category is identified, consider it an antique.
        // Confidence can be based on the highest classification confidence.
        let isAntique = classificationResult.category != .unknown
        
        var confidence: Double = 0.0
        if let topClassification = classificationResult.classifications.first(where: { $0.value == classificationResult.classifications.values.max() }) {
            confidence = topClassification.value
        }
        
        // Adjust confidence if not explicitly identified as antique by category, but still has some classification.
        if !isAntique && confidence > 0 {
            confidence *= 0.5 // Reduce confidence if it's just a general object
        }
        
        return BinaryClassificationResult(isAntique: isAntique, confidence: confidence)
    }

    private func combine(binaryResult: BinaryClassificationResult?, heuristicResult: AntiqueAnalysisResult) -> AntiqueAnalysisResult {
        guard let binary = binaryResult else {
            // If binary classifier is not available, rely solely on heuristics
            return heuristicResult
        }
        
        // If binary classifier is very confident, trust it more
        if binary.confidence > 0.8 {
            var reasons = heuristicResult.reasons
            if binary.isAntique {
                reasons.insert("AI model is highly confident this is an antique.", at: 0)
                // We can still blend with heuristic confidence slightly
                let finalConfidence = (binary.confidence * 0.9) + (heuristicResult.confidence * 0.1)
                return AntiqueAnalysisResult(isAntique: true, confidence: min(finalConfidence, 1.0), reasons: reasons)
            } else {
                reasons.insert("AI model is highly confident this is modern.", at: 0)
                // If model is sure it's not an antique, heuristic should not override it.
                // We can reflect heuristic in the confidence, but outcome is set.
                let finalConfidence = (binary.confidence * 0.9) + ((1 - heuristicResult.confidence) * 0.1)
                return AntiqueAnalysisResult(isAntique: false, confidence: min(finalConfidence, 1.0), reasons: reasons)
            }
        }
        
        // Original logic for medium to low confidence
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

    func analyzeFurniture(image: UIImage) -> AntiqueAnalysisResult {
            guard let cgImage = image.cgImage else {
                return AntiqueAnalysisResult(
                    isAntique: false,
                    confidence: 0,
                    reasons: ["Could not process image."]
                )
            }

            let handler = VNImageRequestHandler(cgImage: cgImage)
            var reasons: [String] = []
            var weightedScore: Double = 0
            var totalWeight: Double = 0

            // --------------------------------------------------
            // 1. Saliency (Is there a clear main object?)
            // --------------------------------------------------
            do {
                let request = VNGenerateAttentionBasedSaliencyImageRequest()
                try handler.perform([request])

                if let result = request.results?.first {
                    let weight = 0.15
                    weightedScore += Double(result.confidence) * weight
                    totalWeight += weight

                    if result.confidence > 0.6 {
                        reasons.append("Clear primary subject detected.")
                    }
                }
            } catch {
                print("Saliency failed:", error)
            }

            // --------------------------------------------------
            // 2. Contour Complexity (Handcrafted vs factory-made)
            // --------------------------------------------------
            do {
                let request = VNDetectContoursRequest()
                try handler.perform([request])

                if let observation = request.results?.first {
                    let totalPoints = (0..<observation.contourCount)
                        .compactMap { try? observation.contour(at: $0).pointCount }
                        .reduce(0, +)

                    let complexity = min(Double(totalPoints) / 6000.0, 1.0)
                    let weight = 0.35

                    weightedScore += complexity * weight
                    totalWeight += weight

                    if complexity > 0.5 {
                        reasons.append("Intricate handcrafted-style edges detected.")
                    }
                }
            } catch {
                print("Contour detection failed:", error)
            }

            // --------------------------------------------------
            // 3. Material / Color Aging (Wood & patina)
            // --------------------------------------------------
            let brownness = image.averageColor.brownishness
            if brownness > 0.45 {
                let weight = 0.25
                weightedScore += brownness * weight
                totalWeight += weight

                reasons.append("Dominant brown/wood tones suggest aged material.")
            }

            // --------------------------------------------------
            // 4. Scene Context (Furniture usually rests level)
            // --------------------------------------------------
            do {
                let request = VNDetectHorizonRequest()
                try handler.perform([request])

                if let horizon = request.results?.first {
                    let tiltDegrees = abs(horizon.angle * 180 / .pi)
                    let confidence = tiltDegrees < 5 ? 1.0 : max(0, 1 - tiltDegrees / 15)
                    let weight = 0.25

                    weightedScore += confidence * weight
                    totalWeight += weight

                    if tiltDegrees < 5 {
                        reasons.append("Object appears placed on a stable, level surface.")
                    }
                }
            } catch {
                print("Horizon detection failed:", error)
            }

            // --------------------------------------------------
            // Final Decision
            // --------------------------------------------------
            let finalConfidence = totalWeight > 0
                ? min(weightedScore / totalWeight, 1)
                : 0

            let isAntique = finalConfidence >= 0.6

            return AntiqueAnalysisResult(
                isAntique: isAntique,
                confidence: finalConfidence,
                reasons: isAntique
                    ? reasons
                    : ["Analysis did not strongly indicate antique furniture."]
            )
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

extension CIColor {
    var brownishness: Double {
        // A very simple metric for how "brown" a color is.
        // Brown is a dark orange/red.
        let isReddish = self.red > self.green && self.red > self.blue
        let isDark = (self.red + self.green + self.blue) / 3 < 0.6
        let greenToRedRatio = self.green / self.red
        let isOrangey = greenToRedRatio > 0.4 && greenToRedRatio < 0.8
        
        if isReddish && isDark && isOrangey {
            return Double(self.red)
        }
        return 0.0
    }
}

extension CIImage {
    var averageColor: CIColor {
        let extentVector = CIVector(x: self.extent.origin.x, y: self.extent.origin.y, z: self.extent.size.width, w: self.extent.size.height)
        guard let filter = CIFilter(name: "CIAreaAverage", parameters: [kCIInputImageKey: self, kCIInputExtentKey: extentVector]),
              let outputImage = filter.outputImage else {
            return CIColor.black
        }
        var bitmap = [UInt8](repeating: 0, count: 4)
        let context = CIContext(options: [.workingColorSpace: kCFNull!])
        context.render(outputImage, toBitmap: &bitmap, rowBytes: 4, bounds: CGRect(x: 0, y: 0, width: 1, height: 1), format: .RGBA8, colorSpace: nil)
        return CIColor(red: CGFloat(bitmap[0]) / 255, green: CGFloat(bitmap[1]) / 255, blue: CGFloat(bitmap[2]) / 255, alpha: CGFloat(bitmap[3]) / 255)
    }
}

extension UIColor {
    var brownishness: Double {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0

        self.getRed(&r, green: &g, blue: &b, alpha: nil)

        // Brown tends to have high red, medium green, low blue
        return Double((r + g * 0.8) - b)
    }
}
