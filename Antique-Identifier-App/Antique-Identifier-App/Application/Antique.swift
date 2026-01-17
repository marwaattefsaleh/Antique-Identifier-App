import Foundation
import SwiftData

@Model
final class Antique {
    @Attribute(.unique) var id: UUID
    var name: String
    var category: String?
    var year: Int?
    var notes: String?
    var dateAdded: Date?
    @Attribute(.externalStorage) var imageData: Data?

    init(id: UUID = UUID(), name: String, category: String? = nil, year: Int? = nil, notes: String? = nil, dateAdded: Date? = Date(), imageData: Data? = nil) {
        self.id = id
        self.name = name
        self.category = category
        self.year = year
        self.notes = notes
        self.dateAdded = dateAdded
        self.imageData = imageData
    }
}
