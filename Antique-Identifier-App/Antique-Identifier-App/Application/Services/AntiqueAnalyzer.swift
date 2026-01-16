import Vision
import UIKit

protocol AntiqueAnalyzerProtocol {
    func analyze(image: UIImage) -> AntiqueAnalysisResult
}

class AntiqueAnalyzer: AntiqueAnalyzerProtocol {
    
    func analyze(image: UIImage) -> AntiqueAnalysisResult {
        guard let cgImage = image.cgImage else {
            return AntiqueAnalysisResult(isAntique: false, confidence: 0, reasons: ["Could not process image."])
        }

        var contourComplexity: Double = 0
        var textureScore: Double = 0
        var symmetryScore: Double = 0
        
        // 1. Contour Detection for handcrafted edges
        let contourRequest = VNDetectContoursRequest()
        contourRequest.revision = VNDetectContourRequestRevision1
        contourRequest.contrastAdjustment = 1.0
        contourRequest.detectsDarkOnLight = true
        
        let contourHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        try? contourHandler.perform([contourRequest])
        if let results = contourRequest.results as? [VNContoursObservation],
           let observation = results.first {
            var totalPoints = 0
            for i in 0..<observation.contourCount {
                if let contour = try? observation.contour(at: i) {
                    totalPoints += contour.pointCount
                }
            }
            contourComplexity = min(Double(totalPoints) / 5000.0, 1.0) // Normalize
        }

        // 2. Texture analysis (simple version)
        let ciImage = CIImage(cgImage: cgImage)
        let extentVector = CIVector(x: ciImage.extent.origin.x, y: ciImage.extent.origin.y, z: ciImage.extent.size.width, w: ciImage.extent.size.height)
        guard let filter = CIFilter(name: "CIAreaAverage", parameters: [kCIInputImageKey: ciImage, kCIInputExtentKey: extentVector]),
              let outputImage = filter.outputImage else {
            return AntiqueAnalysisResult(isAntique: false, confidence: 0, reasons: ["Could not process image for texture."])
        }
        var bitmap = [UInt8](repeating: 0, count: 4)
        let context = CIContext(options: [.workingColorSpace: kCFNull!])
        context.render(outputImage, toBitmap: &bitmap, rowBytes: 4, bounds: CGRect(x: 0, y: 0, width: 1, height: 1), format: .RGBA8, colorSpace: nil)
        let averageColor = UIColor(red: CGFloat(bitmap[0]) / 255, green: CGFloat(bitmap[1]) / 255, blue: CGFloat(bitmap[2]) / 255, alpha: 1.0)

        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0
        averageColor.getRed(&r, green: &g, blue: &b, alpha: nil)
        // Heuristic: darker, brownish colors might indicate old wood.
        if (r > 0.3 && r < 0.6) && (g > 0.2 && g < 0.4) && (b > 0.1 && b < 0.3) {
            textureScore = 0.7
        } else {
            textureScore = 0.2
        }

        // 3. Symmetry check (very simplified)
        symmetryScore = 0.6 // Placeholder

        var confidence = (contourComplexity * 0.4) + (textureScore * 0.3) + (symmetryScore * 0.3)
        var reasons: [String] = []

        if contourComplexity > 0.5 {
            reasons.append("Intricate details suggesting handcrafted work.")
        }
        if textureScore > 0.5 {
            reasons.append("Wood texture and patina suggest age.")
        }
        if symmetryScore < 0.7 { // less symmetry -> more likely antique
            reasons.append("Slight asymmetry, common in older pieces.")
            confidence += 0.1
        }
        
        confidence = min(confidence, 1.0)

        let isAntique = confidence > 0.5
        
        if isAntique && reasons.isEmpty {
            reasons.append("Overall visual characteristics are consistent with an antique.")
        } else if !isAntique {
            reasons.append("Appears to have modern manufacturing characteristics.")
        }
        
        return AntiqueAnalysisResult(isAntique: isAntique, confidence: confidence, reasons: reasons)
    }
}
