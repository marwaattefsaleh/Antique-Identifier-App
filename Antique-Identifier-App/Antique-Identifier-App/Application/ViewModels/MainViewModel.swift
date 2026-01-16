import SwiftUI
import Combine

class MainViewModel: ObservableObject {
    @Published var image: UIImage?
    @Published var classificationResult: ClassificationResult?
    @Published var antiqueAnalysisResult: AntiqueAnalysisResult?
    @Published var isAnalysisComplete: Bool = false
    
    private let coreMLService: CoreMLServiceProtocol
    private let antiqueAnalyzer: AntiqueAnalyzerProtocol
    private var cancellables = Set<AnyCancellable>()
    
    init(coreMLService: CoreMLServiceProtocol, antiqueAnalyzer: AntiqueAnalyzerProtocol) {
        self.coreMLService = coreMLService
        self.antiqueAnalyzer = antiqueAnalyzer
        
        $image
            .compactMap { $0 }
            .sink { [weak self] image in
                self?.analyze(image: image)
            }
            .store(in: &cancellables)
    }
    
    func analyze(image: UIImage) {
        isAnalysisComplete = false
        
        // Step 1: Classify furniture type
        do {
            let result = try coreMLService.classify(image: image)
            DispatchQueue.main.async {
                self.classificationResult = result
                
                // Step 2: If it's a known furniture type, analyze if it's an antique
                if result.furnitureType != .unknown {
                    let analysisResult = self.antiqueAnalyzer.analyze(image: image)
                    self.antiqueAnalysisResult = analysisResult
                } else {
                    self.antiqueAnalysisResult = AntiqueAnalysisResult(isAntique: false, confidence: 0, reasons: ["Could not identify furniture type."])
                }
                self.isAnalysisComplete = true
            }
        } catch {
            print("Error analyzing image: \(error)")
            DispatchQueue.main.async {
                self.antiqueAnalysisResult = AntiqueAnalysisResult(isAntique: false, confidence: 0, reasons: ["Failed to analyze image."])
                self.isAnalysisComplete = true
            }
        }
    }
    
    var userFriendlyMessage: String {
        guard isAnalysisComplete, let furnitureType = classificationResult?.furnitureType, furnitureType != .unknown, let analysis = antiqueAnalysisResult else {
            if isAnalysisComplete {
                return "Could not identify as a known furniture type."
            }
            return ""
        }
        
        let likelihood = analysis.isAntique ? "Likely" : "Unlikely"
        let confidenceText = "Confidence: \(Int(analysis.confidence * 100))%"
        
        return "\(likelihood) Antique \(furnitureType.rawValue.capitalized)\n\(confidenceText)"
    }
    
    var estimatedPeriod: String {
        guard let analysis = antiqueAnalysisResult, analysis.isAntique else { return "" }
        // This is a placeholder as requested.
        // A real implementation would require a more sophisticated model.
        let confidence = analysis.confidence
        if confidence > 0.8 {
            return "Estimated Period: 1850-1890"
        } else if confidence > 0.6 {
            return "Estimated Period: 1890-1920"
        } else {
            return "Estimated Period: 1920-1950"
        }
    }
}
