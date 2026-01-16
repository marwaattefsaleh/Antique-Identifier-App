import SwiftUI
import Swinject

struct MainView: View {
    @StateObject var viewModel: MainViewModel
    let resolver: Resolver
    
    @State private var showingImagePicker = false
    @State private var sourceType: UIImagePickerController.SourceType = .photoLibrary
    
    var body: some View {
        NavigationView {
            VStack {
                if let image = viewModel.image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 300)
                } else {
                    Text("Select an image to begin.")
                        .font(.headline)
                        .frame(maxHeight: 300)
                }
                
                HStack(spacing: 20) {
                    Button("Photo Library") {
                        self.sourceType = .photoLibrary
                        self.showingImagePicker = true
                    }
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    
                    Button("Camera") {
                        self.sourceType = .camera
                        self.showingImagePicker = true
                    }
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .padding()
                
                if viewModel.isAnalysisComplete {
                    VStack {
                        Text(viewModel.userFriendlyMessage)
                            .font(.title2)
                            .multilineTextAlignment(.center)
                            .padding()

                        if let analysis = viewModel.antiqueAnalysisResult, analysis.isAntique {
                            Text(viewModel.estimatedPeriod)
                                .font(.headline)
                                .padding(.bottom)
                            
                            Text("Reasons:")
                                .font(.headline)
                            ForEach(analysis.reasons, id: \.self) { reason in
                                Text("• \(reason)")
                                    .font(.body)
                            }
                            
                            NavigationLink(destination: AntiqueDetailsScreen(
                                viewModel: resolver.resolve(
                                    AntiqueDetailsViewModel.self,
                                    arguments: viewModel.image!,
                                    viewModel.classificationResult?.category.rawValue.capitalized ?? ""
                                )!
                            )) {
                                Text("View Details & Save")
                                    .padding()
                                    .background(Color.purple)
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                            }
                            .padding(.top)

                        }
                    }
                } else if viewModel.image != nil {
                    ProgressView("Analyzing...")
                }
                
                Spacer()
            }
            .navigationTitle("Antique Identifier")
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(image: self.$viewModel.image, sourceType: self.sourceType)
            }
        }
    }
}
