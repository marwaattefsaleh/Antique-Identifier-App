import SwiftUI
import Swinject

struct MainView: View {
    @StateObject var viewModel: MainViewModel
    let resolver: Resolver
    
    @State private var showingImagePicker = false
    @State private var sourceType: UIImagePickerController.SourceType = .photoLibrary
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemGroupedBackground).edgesIgnoringSafeArea(.all)
                
                ScrollView {
                    VStack(alignment: .center, spacing: 24) {
                        
                        // MARK: - Image Display
                        Group {
                            if let image = viewModel.image {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(maxHeight: 300)
                                    .cornerRadius(12)
                                    .shadow(radius: 5)
                            } else {
                                VStack {
                                    Image(systemName: "photo.on.rectangle.angled")
                                        .font(.largeTitle)
                                        .foregroundColor(.secondary)
                                    Text("Select an image to begin.")
                                        .font(.headline)
                                        .foregroundColor(.secondary)
                                }
                                .frame(height: 300)
                                .frame(maxWidth: .infinity)
                                .background(Color(.secondarySystemBackground))
                                .cornerRadius(12)
                            }
                        }
                        
                        // MARK: - Action Buttons
                        HStack(spacing: 16) {
                            Button(action: {
                                self.sourceType = .photoLibrary
                                self.showingImagePicker = true
                            }) {
                                HStack {
                                    Image(systemName: "photo.fill.on.rectangle.fill")
                                    Text("Photo Library")
                                }
                                .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.blue)
                            
                            Button(action: {
                                self.sourceType = .camera
                                self.showingImagePicker = true
                            }) {
                                HStack {
                                    Image(systemName: "camera.fill")
                                    Text("Camera")
                                }
                                .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.green)
                        }
                        
                        // MARK: - Analysis Results
                        if viewModel.isAnalysisComplete {
                            if let result = viewModel.combinedResult {
                                VStack(alignment: .leading, spacing: 16) {
                                    
                                    // --- User Friendly Message ---
                                    Text(result.userFriendlyMessage)
                                        .font(.title2)
                                        .fontWeight(.bold)
                                        .multilineTextAlignment(.center)
                                        .frame(maxWidth: .infinity)
                                    
                                    if result.isAntique {
                                        
                                        // --- Estimated Period & Top Classification ---
                                        VStack(alignment: .leading, spacing: 8) {
                                            Text(result.estimatedPeriod)
                                                .font(.headline)
                                            
                                            if let topClassification = result.classifications.first(where: { $0.value == result.classifications.values.max() }) {
                                                Text("Top MobileNet Classification: **\(topClassification.key.capitalized)** (\(String(format: "%.1f%%", topClassification.value * 100)))")
                                                    .font(.subheadline)
                                            }
                                        }
                                        .padding()
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .background(Color(.secondarySystemBackground))
                                        .cornerRadius(10)

                                        // --- Reasons ---
                                        VStack(alignment: .leading, spacing: 8) {
                                            Text("Reasons:")
                                                .font(.headline)
                                            ForEach(result.reasons, id: \.self) { reason in
                                                HStack(alignment: .top) {
                                                    Image(systemName: "checkmark.circle.fill").foregroundColor(.green)
                                                    Text(reason)
                                                }
                                            }
                                        }
                                        .padding()
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .background(Color(.secondarySystemBackground))
                                        .cornerRadius(10)
                                    }
                                        
                                    // --- MobileNet Classifications (moved outside if result.isAntique) ---
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("MobileNet Classifications (Top 5)")
                                            .font(.headline)
                                        ForEach(result.classifications.sorted(by: { $0.value > $1.value }), id: \.key) { key, value in
                                            HStack {
                                                Text(key.capitalized)
                                                Spacer()
                                                Text(String(format: "%.1f%%", value * 100))
                                                    .foregroundColor(.secondary)
                                            }
                                        }
                                    }
                                    .padding()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color(.secondarySystemBackground))
                                    .cornerRadius(10)
                                    
                                    // --- Save Button (this part remains inside if result.isAntique again) ---
                                    if result.isAntique {
                                        NavigationLink(destination: AntiqueDetailsScreen(
                                            viewModel: resolver.resolve(
                                                AntiqueDetailsViewModel.self,
                                                arguments: viewModel.image, result
                                            )!
                                        )) {
                                            Text("View Details & Save")
                                                .fontWeight(.bold)
                                                .frame(maxWidth: .infinity)
                                        }
                                        .buttonStyle(.borderedProminent)
                                        .tint(.purple)
                                        .padding(.top)
                                    }
                                }
                            } else {
                                Text("Analysis failed. Please try again.")
                                    .foregroundColor(.red)
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(Color(.secondarySystemBackground))
                                    .cornerRadius(10)
                            }
                        } else if viewModel.image != nil {
                            ProgressView("Analyzing...")
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color(.secondarySystemBackground))
                                .cornerRadius(10)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Antique Identifier")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: SavedAntiquesView()) {
                        Image(systemName: "bookmark.fill")
                    }
                }
            }
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(image: self.$viewModel.image, sourceType: self.sourceType)
            }
        }
    }
}
