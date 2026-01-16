import SwiftUI
import Combine

class MainViewModel: ObservableObject {
    @Published var image: UIImage?
    @Published var classificationResult: [String: Double] = [:]
    @Published var isAntique: Bool = false
    
    private let coreMLService: CoreMLServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    
    // I'll assume some keywords that identify an antique
    private let antiqueKeywords = ["chair", "table", "lamp", "desk", "cupboard", "cabinet", "drawer", "chest", "mirror", "clock"]
    
    init(coreMLService: CoreMLServiceProtocol) {
        self.coreMLService = coreMLService
        
        $image
            .compactMap { $0 }
            .sink { [weak self] image in
                self?.classify(image: image)
            }
            .store(in: &cancellables)
    }
    
    func classify(image: UIImage) {
        do {
            let result = try coreMLService.classify(image: image)
            DispatchQueue.main.async {
                self.classificationResult = result
                self.checkIfAntique()
            }
        } catch {
            print("Error classifying image: \(error)")
        }
    }
    
    private func checkIfAntique() {
        guard let topClassification = classificationResult.max(by: { $0.value < $1.value }) else {
            isAntique = false
            return
        }
        
        // Check if any part of the top classification contains a keyword
        let topLabel = topClassification.key.lowercased()
        for keyword in antiqueKeywords {
            if topLabel.contains(keyword) {
                isAntique = true
                return
            }
        }
        
        isAntique = false
    }
}
