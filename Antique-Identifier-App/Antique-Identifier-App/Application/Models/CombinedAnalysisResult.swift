import Foundation

struct CombinedAnalysisResult {
    // From AntiqueAnalysisResult
    let isAntique: Bool
    let confidence: Double
    let reasons: [String]
    
    // From ClassificationResult
    let category: AntiqueCategory
    let classifications: [String: Double]
    
    // Computed properties moved from MainViewModel
    var userFriendlyMessage: String {
        guard category != .unknown else {
            return "Could not identify as a known antique category."
        }
        
        let likelihood = isAntique ? "Likely" : "Unlikely"
        let confidenceLevel: String
        if confidence > 0.75 {
            confidenceLevel = "High"
        } else if confidence > 0.5 {
            confidenceLevel = "Medium"
        } else {
            confidenceLevel = "Low"
        }
        let confidenceText = "Confidence: \(confidenceLevel) (\(Int(confidence * 100))%)"
        
        return "\(likelihood) Antique \(category.rawValue.capitalized)\n\(confidenceText)"
    }
    
    var estimatedPeriod: String {
        guard isAntique else { return "" } 
        
        if confidence > 0.8 {
            return "Estimated Period: 18th Century"
        } else if confidence > 0.6 {
            return "Estimated Period: 18th-19th Century"
        } else {
            return "Estimated Period: 19th-20th Century"
        }
    }
}

