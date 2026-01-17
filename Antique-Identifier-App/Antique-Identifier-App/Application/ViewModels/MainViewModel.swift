import SwiftUI
import Combine

class MainViewModel: ObservableObject {
    @Published var image: UIImage?
    @Published var combinedResult: CombinedAnalysisResult?
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
        combinedResult = nil // Reset previous result
        
        do {
            let classificationResult = try coreMLService.classify(image: image)
            let antiqueAnalysisResult = self.antiqueAnalyzer.analyze(image: image, category: classificationResult.category)
            
            DispatchQueue.main.async {
                // Get the top confidence from MobileNet's classifications
                let topMobileNetConfidence = classificationResult.classifications.values.max() ?? 0.0
                
                // Determine the final confidence
                let finalConfidence = max(antiqueAnalysisResult.confidence, topMobileNetConfidence)
                let isAntiqueFinal = finalConfidence > 0.5 // Make isAntique depend on the final confidence

                self.combinedResult = CombinedAnalysisResult(
                    isAntique: isAntiqueFinal, // Use the new isAntique
                    confidence: finalConfidence, // Use the higher confidence
                    reasons: antiqueAnalysisResult.reasons,
                    category: classificationResult.category,
                    classifications: classificationResult.classifications
                )
                
                print("Marwa: \(antiqueAnalysisResult.confidence)")
                print("Marwa: \(classificationResult)")

                self.isAnalysisComplete = true
            }
        } catch {
            print("Error analyzing image: \(error)")
            DispatchQueue.main.async {
                // You might want to create a CombinedAnalysisResult for the error case as well
                self.isAnalysisComplete = true
            }
        }
    }
}
