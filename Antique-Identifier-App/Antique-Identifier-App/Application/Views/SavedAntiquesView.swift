import SwiftUI
import SwiftData

struct SavedAntiquesView: View {
    @Query(sort: \Antique.dateAdded, order: .reverse) private var antiques: [Antique]
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        List {
            ForEach(antiques) { antique in
                NavigationLink(destination: SavedAntiqueDetailView(antique: antique)) {
                    HStack {
                        if let imageData = antique.imageData, let uiImage = UIImage(data: imageData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 60, height: 60)
                                .cornerRadius(8)
                        } else {
                            Image(systemName: "photo")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 60, height: 60)
                                .cornerRadius(8)
                                .foregroundColor(.gray)
                        }
                        
                        VStack(alignment: .leading) {
                            Text(antique.name)
                                .font(.headline)
                            Text(antique.category ?? "No category")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .onDelete(perform: deleteAntiques)
        }
        .navigationTitle("Saved Antiques")
        .toolbar {
            EditButton()
        }
    }
    
    private func deleteAntiques(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(antiques[index])
            }
        }
    }
}
