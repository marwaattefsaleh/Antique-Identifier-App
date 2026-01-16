import SwiftUI

struct AntiqueDetailsScreen: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject var viewModel: AntiqueDetailsViewModel
    
    var body: some View {
        Form {
            Section("Detected Image") {
                if let image = viewModel.detectedImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity, maxHeight: 200)
                } else {
                    Text("No image available")
                }
            }
            
            Section("Antique Details") {
                TextField("Name", text: $viewModel.antiqueName)
                TextField("Category", text: $viewModel.antiqueCategory)
                TextField("Year (Optional)", text: $viewModel.antiqueYear)
                    .keyboardType(.numberPad)
                TextField("Notes (Optional)", text: $viewModel.antiqueNotes)
            }
            
            Button("Save Antique") {
                viewModel.saveAntique()
                presentationMode.wrappedValue.dismiss()
            }
        }
        .navigationTitle("Antique Details")
        .navigationBarTitleDisplayMode(.inline)
    }
}
