import SwiftUI
import SwiftData

enum SortOption: String, CaseIterable {
    case dateNewToOld = "Newest aquisition"
    case dateOldToNew = "Oldest aquisition"
    case priceHighToLow = "Highest price"
    case priceLowToHigh = "Lowest price"
    
    var sortFunction: (ArtPiece, ArtPiece) -> Bool {
        switch self {
        case .priceHighToLow:
            return { $0.price > $1.price }
        case .priceLowToHigh:
            return { $0.price < $1.price }
        case .dateNewToOld:
            return { ($0.dateAcquired ?? .distantPast) > ($1.dateAcquired ?? .distantPast) }
        case .dateOldToNew:
            return { ($0.dateAcquired ?? .distantPast) < ($1.dateAcquired ?? .distantPast) }
        }
    }
}

struct HausDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    let haus: Haus
    @State private var selectedTab = 0
    @State private var showingAddArtSheet = false
    @State private var selectedArtPiece: ArtPiece?
    @State private var artToEdit: ArtPiece?
    @State private var sortOption: SortOption = .dateNewToOld
    @State private var showConfetti = false
    
    var body: some View {
        ZStack(alignment: .top) {
            TabView(selection: $selectedTab) {
                ArtGridView(
                    haus: haus,
                    type: .collection,
                    sortOption: sortOption,
                    onArtSelected: { art in
                        selectedArtPiece = art
                    },
                    onEditArt: { art in
                        artToEdit = art
                    }
                )
                .tabItem {
                    Label("", systemImage: "photo.stack")
                }
                .tag(0)
                
                ArtGridView(
                    haus: haus,
                    type: .tracking,
                    sortOption: sortOption,
                    onArtSelected: { art in
                        selectedArtPiece = art
                    },
                    onEditArt: { art in
                        artToEdit = art
                    }
                )
                .tabItem {
                    Label("", systemImage: "cursorarrow.click.2")
                }
                .tag(1)
            }
            .tint(.black)
            
            // Custom Header
            VStack(spacing: 0) {
                HStack {
                    Menu {
                        ForEach(SortOption.allCases, id: \.self) { option in
                            Button(action: { sortOption = option }) {
                                Label(option.rawValue, systemImage: sortOption == option ? "checkmark" : "")
                            }
                        }
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease")
                            .foregroundColor(.black)
                            .font(.system(size: 20))
                            .padding(8)
                    }
                    
                    Spacer()
                    
                    Text(selectedTab == 0 ? "Collection" : "Tracking")
                        .font(.custom("Didot", size: 26))
                        .bold()
                    
                    Spacer()
                    
                    Button(action: { showingAddArtSheet = true }) {
                        Image(systemName: "plus")
                            .foregroundColor(.black)
                            .font(.system(size: 20))
                            .padding(8)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 14)
                .background(Color.white)
            }
            .background(Color.white)
            
            if showConfetti {
                ConfettiView()
                    .allowsHitTesting(false)
            }
        }
        .navigationBarHidden(true)
        .background(Color.white)
        .gesture(DragGesture(minimumDistance: 20)
            .onEnded { gesture in
                if gesture.translation.width > 100 && selectedTab == 0 {
                    dismiss()
                } else if gesture.translation.width < -100 && selectedTab == 0 {
                    selectedTab = 1
                } else if gesture.translation.width > 100 && selectedTab == 1 {
                    selectedTab = 0
                }
            })
        .sheet(isPresented: $showingAddArtSheet) {
            NavigationStack {
                ArtFormView(
                    haus: haus,
                    initialType: selectedTab == 0 ? .collection : .tracking,
                    onArtAdded: {
                        showConfetti = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                            showConfetti = false
                        }
                    }
                )
            }
        }
        .navigationDestination(item: $selectedArtPiece) { art in
            ArtDetailView(artPiece: art, sortOption: sortOption)
        }
        .sheet(item: $artToEdit) { art in
            NavigationStack {
                ArtFormView(
                    haus: haus,
                    initialType: selectedTab == 0 ? .collection : .tracking,
                    artToEdit: art
                )
            }
        }
    }
}

struct ArtGridView: View {
    let haus: Haus
    let type: ArtPieceType
    let sortOption: SortOption
    let onArtSelected: (ArtPiece) -> Void
    let onEditArt: (ArtPiece) -> Void
    
    var filteredArt: [ArtPiece] {
        haus.artPieces.filter { $0.type == type }.sorted(by: sortOption.sortFunction)
    }
    
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        ScrollView {
            if filteredArt.isEmpty {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        VStack(spacing: 16) {
                            Image(type == .collection ? "collection_is_empty" : "tracking_is_empty2")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 400, height: 400)
                            
                            Text(type == .collection ? "Add art to your collection." : "Add art you're considering.")
                                .foregroundColor(.gray)
                                .font(.system(size: 16))
                        }
                        Spacer()
                    }
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.top, 60)
            } else {
                LazyVGrid(columns: columns, spacing: 10) {
                    ForEach(filteredArt) { art in
                        ArtGridItem(art: art)
                            .onTapGesture {
                                onArtSelected(art)
                            }
                            .contextMenu {
                                Button {
                                    onEditArt(art)
                                } label: {
                                    Label("Edit", systemImage: "pencil")
                                }
                                
                                Button(role: .destructive) {
                                    haus.artPieces.removeAll { $0.id == art.id }
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                            .id(art.id)
                            .transition(.asymmetric(
                                insertion: .scale.combined(with: .opacity),
                                removal: .scale.combined(with: .opacity)
                            ))
                    }
                }
                .padding()
                .padding(.top, 50)
                .background(Color.white)
                .animation(.interactiveSpring(response: 0.4, dampingFraction: 1, blendDuration: 0.5), value: sortOption)
            }
        }
    }
}

struct ArtGridItem: View {
    let art: ArtPiece
    
    var body: some View {
        GeometryReader { geometry in
            Group {
                if let imageData = art.imageData,
                   let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: geometry.size.width, height: geometry.size.width * (16/9))
                        .clipped()
                } else {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .aspectRatio(9/16, contentMode: .fit)
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Haus.self, configurations: config)
    
    // Create sample haus
    let haus = Haus(title: "Modern Art Collection")
    
    // Sample collection pieces
    let collectionPieces = [
        ("Abstract Harmony", "Jane Smith", "Modern Gallery", 2500),
        ("Urban Landscape", "John Doe", "Contemporary Arts", 1800),
        ("Color Theory", "Maria Garcia", "Art Space", 3200),
        ("Geometric Dreams", "Alex Chen", "Modern Gallery", 2100),
        ("Nature's Voice", "Sarah Wilson", "Green Gallery", 2800),
        ("City Lights", "Mike Brown", "Urban Arts", 1900),
        ("Ocean Waves", "Lisa Park", "Coastal Gallery", 2300),
        ("Mountain View", "Tom White", "Nature Arts", 2700),
        ("Desert Sunset", "Emma Davis", "Southwest Gallery", 2400)
    ]
    
    // Sample tracking pieces
    let trackingPieces = [
        ("Desired Painting", "Alice Johnson", "Fine Arts Gallery", 3500),
        ("Future Acquisition", "Robert Lee", "Modern Masters", 4200),
        ("Watch List", "Sophie Martin", "European Arts", 3800),
        ("Dream Piece", "David Kim", "Asian Arts", 2900),
        ("Potential Buy", "Rachel Green", "Contemporary Space", 3100),
        ("Art to Watch", "Chris Taylor", "New Gallery", 2600)
    ]
    
    // Add collection pieces
    for (title, artist, gallery, price) in collectionPieces {
        let art = ArtPiece(
            type: .collection,
            title: title,
            artist: artist,
            gallery: gallery,
            price: Double(price),
            dateAcquired: Date(),
            imageData: nil
        )
        haus.artPieces.append(art)
    }
    
    // Add tracking pieces
    for (title, artist, gallery, price) in trackingPieces {
        let art = ArtPiece(
            type: .tracking,
            title: title,
            artist: artist,
            gallery: gallery,
            price: Double(price),
            dateAcquired: nil,
            imageData: nil
        )
        haus.artPieces.append(art)
    }
    
    container.mainContext.insert(haus)
    
    return NavigationStack {
        HausDetailView(haus: haus)
    }
    .modelContainer(container)
} 
