import SwiftUI

struct AntiqueDetailsScreen: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject var viewModel: AntiqueDetailsViewModel
    
    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).edgesIgnoringSafeArea(.all)
            
            ScrollView {
                VStack(spacing: 24) {
                    
                    // MARK: - Image Display
                    if let image = viewModel.detectedImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 250)
                            .cornerRadius(12)
                            .shadow(radius: 5)
                    } else {
                        VStack {
                            Image(systemName: "photo.on.rectangle.angled")
                                .font(.largeTitle)
                                .foregroundColor(.secondary)
                            Text("No Image Available")
                                .font(.headline)
                                .foregroundColor(.secondary)
                        }
                        .frame(height: 250)
                        .frame(maxWidth: .infinity)
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(12)
                    }
                    
                    // MARK: - Antique Details Form
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Antique Details")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        VStack {
                            TextField("Name", text: $viewModel.antiqueName)
                                .padding(10)
                                .background(Color(.secondarySystemBackground))
                                .cornerRadius(8)
                            
                            TextField("Category", text: $viewModel.antiqueCategory)
                                .padding(10)
                                .background(Color(.secondarySystemBackground))
                                .cornerRadius(8)
                            
                            TextField("Year (Optional)", text: $viewModel.antiqueYear)
                                .keyboardType(.numberPad)
                                .padding(10)
                                .background(Color(.secondarySystemBackground))
                                .cornerRadius(8)
                            
                            ZStack(alignment: .topLeading) {
                                TextEditor(text: $viewModel.antiqueNotes)
                                    .frame(height: 100)
                                    .padding(5)
                                
                                if viewModel.antiqueNotes.isEmpty {
                                    Text("Notes (Optional)")
                                        .foregroundColor(.gray.opacity(0.6))
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 13)
                                }
                            }
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(8)
                        }
                    }
                    
                    // MARK: - Save Button
                    Button(action: {
                        viewModel.saveAntique()
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Text("Save Antique")
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.green)
                    .disabled(viewModel.antiqueName.isEmpty) // Disable if name is empty
                    
                }
                .padding()
            }
        }
        .navigationTitle("Antique Details")
        .navigationBarTitleDisplayMode(.inline)
    }
}
