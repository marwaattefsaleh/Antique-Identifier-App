import SwiftUI
import Swinject

struct MainView: View {
    @StateObject var viewModel: MainViewModel
    let resolver: Resolver // Add resolver property
    
    @State private var showingImagePicker = false
    @State private var sourceType: UIImagePickerController.SourceType = .photoLibrary
    @State private var showingDetailsScreen = false
    
    var body: some View {
        NavigationView {
            VStack {
                if viewModel.image != nil {
                    Image(uiImage: viewModel.image!)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 300)
                } else {
                    Text("No Image Selected")
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
                
                if viewModel.isAntique {
                    Text("This looks like an antique!")
                        .font(.title)
                        .foregroundColor(.green)
                    
                    NavigationLink(destination: AntiqueDetailsScreen(
                        viewModel: resolver.resolve(
                            AntiqueDetailsViewModel.self,
                            arguments: viewModel.image!, // Pass detected image
                            // Pass the most likely classification as initial name/category
                            viewModel.classificationResult.max(by: { $0.value < $1.value })?.key ?? ""
                        )!
                    ), isActive: $showingDetailsScreen) {
                        EmptyView()
                    }
                    .hidden()
                    .onAppear {
                        // Automatically navigate to details if antique is detected
                        // This might be too aggressive, ideally triggered by user action
                        // For now, let's keep it automatic for demonstration
                        if !showingDetailsScreen { // Prevent re-triggering navigation
                           self.showingDetailsScreen = true
                        }
                    }
                    
                    Button("View Details & Save") {
                        self.showingDetailsScreen = true
                    }
                    .padding()
                    .background(Color.purple)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                } else if !viewModel.classificationResult.isEmpty {
                    Text("This does not look like an antique.")
                        .font(.title)
                        .foregroundColor(.red)
                }
            }
            .navigationTitle("Antique Identifier")
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(image: self.$viewModel.image, sourceType: self.sourceType)
            }
        }
    }
}
