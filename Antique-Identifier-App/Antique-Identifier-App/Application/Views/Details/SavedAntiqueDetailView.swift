import SwiftUI

struct SavedAntiqueDetailView: View {
    let antique: Antique

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                if let imageData = antique.imageData, let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 300)
                        .cornerRadius(12)
                        .shadow(radius: 5)
                }

                VStack(alignment: .leading, spacing: 16) {
                    Text("Details")
                        .font(.title2)
                        .fontWeight(.bold)

                    VStack(alignment: .leading, spacing: 12) {
                        detailRow(label: "Category", value: antique.category)
                        if let year = antique.year {
                            detailRow(label: "Year", value: String(year))
                        }
                        if let date = antique.dateAdded {
                            detailRow(label: "Date Added", value: date.formatted(date: .long, time: .shortened))
                        }
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(10)
                }

                if let notes = antique.notes, !notes.isEmpty {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Notes")
                            .font(.title2)
                            .fontWeight(.bold)
                        Text(notes)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(10)
                    }
                }
                
                Spacer()
            }
            .padding()
        }
        .navigationTitle(antique.name)
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(.systemGroupedBackground).edgesIgnoringSafeArea(.all))
    }

    @ViewBuilder
    private func detailRow(label: String, value: String?) -> some View {
        if let value = value, !value.isEmpty {
            VStack(alignment: .leading) {
                Text(label)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.body)
            }
        }
    }
}
