import SwiftUI
import PhotosUI
import SwiftData

/// A view component for displaying and selecting an art piece image
private struct ArtImageView: View {
    let selectedImageData: Data?
    let selectedItem: Binding<PhotosPickerItem?>
    
    var body: some View {
        VStack {
            GeometryReader { geometry in
                Group {
                    if let selectedImageData,
                       let uiImage = UIImage(data: selectedImageData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: min(geometry.size.width, 100), height: min(geometry.size.width, 100) * (16/9))
                            .clipped()
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color(.white).opacity(0.3), lineWidth: 4)
                            )
                    } else {
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(width: min(geometry.size.width, 100), height: min(geometry.size.width, 100) * (16/9))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color(.white).opacity(0.3), lineWidth: 4)
                            )
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .frame(height: min(UIScreen.main.bounds.width, 100) * (16/9))
            .frame(width: 100)
            Spacer()
            Spacer()
            
            PhotosPicker(selection: selectedItem, matching: .images) {
                Text(selectedImageData == nil ? "Select photo" : "Change photo")
                    .font(.system(size: 12))
                    .bold()
                    .frame(width: 110)
                    .padding(.vertical, 12)
                    .background(Color(.white).opacity(0.1))
                    .foregroundColor(.white)
                    .clipShape(Capsule())
            }
            .buttonStyle(.borderless)
            .frame(width: 110)
        }
        .frame(maxWidth: .infinity)
        .listRowInsets(EdgeInsets())
        .listRowBackground(Color.clear)
    }
}

/// A view for creating and editing art pieces
struct ArtFormView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let haus: Haus
    let initialType: ArtPieceType
    var artToEdit: ArtPiece?
    var onArtAdded: (() -> Void)?
    
    @State private var type: ArtPieceType
    @State private var title = ""
    @State private var artist = ""
    @State private var gallery = ""
    @State private var price: Double?
    @State private var dateAcquired: Date?
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImageData: Data?
    @FocusState private var focusedField: Field?
    
    private enum Field: Int, CaseIterable {
        case title, artist, gallery, price
    }
    
    private var isFormValid: Bool {
        !title.isEmpty && selectedImageData != nil
    }
    
    private func nextField() {
        guard let currentField = focusedField,
              let currentIndex = Field.allCases.firstIndex(of: currentField),
              currentIndex + 1 < Field.allCases.count else {
            focusedField = nil
            return
        }
        focusedField = Field.allCases[currentIndex + 1]
    }
    
    init(haus: Haus, initialType: ArtPieceType, artToEdit: ArtPiece? = nil, onArtAdded: (() -> Void)? = nil) {
        self.haus = haus
        self.initialType = initialType
        self.artToEdit = artToEdit
        self.onArtAdded = onArtAdded
        
        _type = State(initialValue: artToEdit?.type ?? initialType)
        if let art = artToEdit {
            _title = State(initialValue: art.title)
            _artist = State(initialValue: art.artist)
            _gallery = State(initialValue: art.gallery)
            _price = State(initialValue: art.price)
            _dateAcquired = State(initialValue: art.dateAcquired)
            _selectedImageData = State(initialValue: art.imageData)
        }
    }
    
    var body: some View {
        Form {
            // Image Section
            ArtImageView(selectedImageData: selectedImageData, selectedItem: $selectedItem)
                .padding(.top, 35)
            
            // Type Selection
            Section {
                Picker("Type", selection: $type) {
                    Text("Collection").tag(ArtPieceType.collection)
                    Text("Tracking").tag(ArtPieceType.tracking)
                }
                .pickerStyle(.segmented)
            }
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)
            
            // Basic Information
            Section {
                TextField("Title", text: $title)
                    .textFieldStyle(.plain)
                    .focused($focusedField, equals: .title)
                TextField("Artist", text: $artist)
                    .textFieldStyle(.plain)
                    .focused($focusedField, equals: .artist)
            }
            .listRowBackground(Color(.white).opacity(0.1))
            
            // Additional Details
            Section {
                TextField("Source", text: $gallery)
                    .textFieldStyle(.plain)
                    .focused($focusedField, equals: .gallery)
                TextField("Price", value: $price, format: .currency(code: "USD").precision(.fractionLength(0)))
                    .textFieldStyle(.plain)
                    .keyboardType(.numberPad)
                    .focused($focusedField, equals: .price)
                
                if type == .collection {
                    DatePicker("Date acquired", selection: Binding(
                        get: { dateAcquired ?? Date() },
                        set: { dateAcquired = $0 }
                    ), displayedComponents: .date)
                }
            }
            .listRowBackground(Color(.white).opacity(0.1))
        }
        .scrollContentBackground(.hidden)
        .frame(maxWidth: 400)
        .background(Color(red: 0.1, green: 0.1, blue: 0.1))
        .preferredColorScheme(.dark)
        .navigationBarHidden(true)
        .overlay(alignment: .top) {
            HStack {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                        .padding(8)
                }
                
                Spacer()
                
                Text(artToEdit == nil ? "Add art" : "Edit art")
                    .font(.custom("Didot", size: 26))
                    .bold()
                    .foregroundColor(.white)
                
                Spacer()
                
                Button {
                    saveArt()
                } label: {
                    Image(systemName: "checkmark")
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                        .padding(8)
                }
                .disabled(!isFormValid)
            }
            .padding(.horizontal)
            .padding(.vertical, 14)
            .background(Color(red: 0.1, green: 0.1, blue: 0.1))
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Button("Done") {
                    focusedField = nil
                }
                Spacer()
                Button("Next") {
                    nextField()
                }
            }
        }
        .onChange(of: selectedItem) { _, newValue in
            Task {
                if let data = try? await newValue?.loadTransferable(type: Data.self) {
                    selectedImageData = data
                    focusedField = nil
                }
            }
        }
    }
    
    private func saveArt() {
        if let artToEdit = artToEdit {
            // Update existing art
            artToEdit.type = type
            artToEdit.title = title
            artToEdit.artist = artist
            artToEdit.gallery = gallery
            artToEdit.price = price ?? 0
            artToEdit.dateAcquired = type == .collection ? dateAcquired : nil
            artToEdit.imageData = selectedImageData
        } else {
            // Create new art
            let art = ArtPiece(
                type: type,
                title: title,
                artist: artist,
                gallery: gallery,
                price: price ?? 0,
                dateAcquired: type == .collection ? dateAcquired : nil,
                imageData: selectedImageData
            )
            art.haus = haus
            haus.artPieces.append(art)
            onArtAdded?()
        }
        dismiss()
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Haus.self, configurations: config)
    let haus = Haus(title: "Sample Gallery")
    container.mainContext.insert(haus)
    
    return NavigationStack {
        ArtFormView(
            haus: haus,
            initialType: .collection
        )
    }
    .modelContainer(container)
}

#Preview("Edit Mode") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Haus.self, configurations: config)
    let haus = Haus(title: "Sample Gallery")
    let art = ArtPiece(
        type: .collection,
        title: "Sample Art",
        artist: "John Doe",
        gallery: "Modern Gallery",
        price: 1500,
        dateAcquired: Date(),
        imageData: nil
    )
    haus.artPieces.append(art)
    container.mainContext.insert(haus)
    
    return NavigationStack {
        ArtFormView(
            haus: haus,
            initialType: .collection,
            artToEdit: art
        )
    }
    .modelContainer(container)
} 
