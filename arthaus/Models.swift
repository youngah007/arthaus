import SwiftUI
import SwiftData

@Model
final class Haus {
    var title: String
    var artPieces: [ArtPiece]
    var createdAt: Date
    
    init(title: String) {
        self.title = title
        self.artPieces = []
        self.createdAt = Date()
    }
}

@Model
final class ArtPiece {
    var type: ArtPieceType
    var title: String
    var artist: String
    var gallery: String
    var price: Double
    var dateAcquired: Date?
    var imageData: Data?
    var haus: Haus?
    var createdAt: Date
    
    init(type: ArtPieceType, title: String, artist: String, gallery: String, price: Double, dateAcquired: Date? = nil, imageData: Data? = nil) {
        self.type = type
        self.title = title
        self.artist = artist
        self.gallery = gallery
        self.price = price
        self.dateAcquired = dateAcquired
        self.imageData = imageData
        self.createdAt = Date()
    }
}

enum ArtPieceType: String, Codable {
    case collection
    case tracking
} 