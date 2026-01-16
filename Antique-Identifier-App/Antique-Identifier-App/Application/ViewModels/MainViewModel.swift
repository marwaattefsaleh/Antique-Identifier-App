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
        
        do {
            let result = try coreMLService.classify(image: image)
            DispatchQueue.main.async {
                self.classificationResult = result
                
                let analysisResult = self.antiqueAnalyzer.analyze(image: image, category: result.category)
                self.antiqueAnalysisResult = analysisResult
                
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
        guard isAnalysisComplete, let category = classificationResult?.category, category != .unknown, let analysis = antiqueAnalysisResult else {
            if isAnalysisComplete {
                return "Could not identify as a known antique category."
            }
            return ""
        }
        
        let likelihood = analysis.isAntique ? "Likely" : "Unlikely"
        let confidenceLevel: String
        if analysis.confidence > 0.75 {
            confidenceLevel = "High"
        } else if analysis.confidence > 0.5 {
            confidenceLevel = "Medium"
        } else {
            confidenceLevel = "Low"
        }
        let confidenceText = "Confidence: \(confidenceLevel) (\(Int(analysis.confidence * 100))%)"
        
        return "\(likelihood) Antique \(category.rawValue.capitalized)\n\(confidenceText)"
    }
    
    var estimatedPeriod: String {
        guard let analysis = antiqueAnalysisResult, analysis.isAntique else { return "" }
        
        let confidence = analysis.confidence
        if confidence > 0.8 {
            return "Estimated Period: 18th Century"
        } else if confidence > 0.6 {
            return "Estimated Period: 18th-19th Century"
        } else {
            return "Estimated Period: 19th-20th Century"
        }
    }
}
