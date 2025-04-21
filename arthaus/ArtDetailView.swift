import SwiftUI
import SwiftData

struct ArtDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let artPiece: ArtPiece
    let sortOption: SortOption
    @State private var currentIndex: Int?
    @State private var showPrices: Bool = false
    @State private var isDetailsVisible: Bool = true
    
    private var haus: Haus? { artPiece.haus }
    private var artPieces: [ArtPiece] {
        haus?.artPieces.filter { $0.type == artPiece.type }.sorted(by: sortOption.sortFunction) ?? []
    }
    
    init(artPiece: ArtPiece, sortOption: SortOption) {
        self.artPiece = artPiece
        self.sortOption = sortOption
        if let haus = artPiece.haus {
            let sortedPieces = haus.artPieces.filter { $0.type == artPiece.type }.sorted(by: sortOption.sortFunction)
            if let index = sortedPieces.firstIndex(where: { $0.id == artPiece.id }) {
                _currentIndex = State(initialValue: index)
            } else {
                _currentIndex = State(initialValue: nil)
            }
        } else {
            _currentIndex = State(initialValue: nil)
        }
    }
    
    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                ZStack(alignment: .topLeading) {
                    Color.black
                        .ignoresSafeArea()
                    
                    ScrollView(.vertical, showsIndicators: false) {
                        LazyVStack(spacing: 0) {
                            ForEach(artPieces.indices, id: \.self) { index in
                                let art = artPieces[index]
                                ArtDetailPage(art: art, showPrices: showPrices, isDetailsVisible: isDetailsVisible, onDetailsVisibilityChanged: { newValue in
                                    isDetailsVisible = newValue
                                })
                                    .frame(width: geometry.size.width, height: geometry.size.height)
                                    .id(index)
                                    .scrollTransition { content, phase in
                                        content
                                            .opacity(phase.isIdentity ? 1 : 0.45)
                                    }
                            }
                        }
                        .scrollTargetLayout()
                    }
                    .scrollTargetBehavior(.paging)
                    .scrollPosition(id: $currentIndex)
                    .scrollDisabled(artPieces.count <= 1)
                    .onShake {
                        withAnimation {
                            showPrices.toggle()
                        }
                    }
                    
                    // Back button
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 25))
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .clipShape(Circle())
                    }
                    .padding(.horizontal, 8)
                    .padding(.top, geometry.safeAreaInsets.bottom + 60)
                }
                .gesture(
                    DragGesture()
                        .onEnded { gesture in
                            if gesture.translation.width > 50 {
                                dismiss()
                            }
                        }
                )
            }
            .ignoresSafeArea()
            .navigationBarBackButtonHidden(true)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(.hidden, for: .navigationBar)
        }
        .background(.clear)
    }
}

struct ArtDetailPage: View {
    let art: ArtPiece
    let showPrices: Bool
    let isDetailsVisible: Bool
    let onDetailsVisibilityChanged: (Bool) -> Void
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    
    private let priceFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 0
        return formatter
    }()
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottom) {
                // Image View
                if let imageData = art.imageData,
                   let uiImage = UIImage(data: imageData) {
                    let aspectRatio = uiImage.size.height > 0 ? uiImage.size.width / uiImage.size.height : 1.0
                    let isPortrait = aspectRatio < 1
                    
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: isPortrait ? .fill : .fit)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .clipped()
                        .scaleEffect(scale)
                        .gesture(
                            MagnificationGesture()
                                .onChanged { value in
                                    let delta = value / lastScale
                                    lastScale = value
                                    scale = min(max(scale * delta, 1), 4)
                                }
                                .onEnded { _ in
                                    lastScale = 1.0
                                }
                        )
                        .gesture(
                            TapGesture(count: 2)
                                .onEnded {
                                    withAnimation {
                                        scale = scale > 1 ? 1 : 2
                                    }
                                }
                        )
                } else {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                }
                
                // Details View
                if isDetailsVisible {
                    VStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(art.title)
                                .font(.custom("Didot", size: 22))
                                .bold()
                                .foregroundColor(.white)
                            
                            Text(art.artist)
                                .font(.custom("Didot", size: 18))
                                .bold()
                                .italic()
                                .foregroundColor(.white)
                            
                            Text(art.gallery)
                                .font(.system(size: 15))
                                .foregroundColor(.white.opacity(0.7))
                                .padding(.top, 15)
                            
                            if let dateAcquired = art.dateAcquired {
                                Text("Acquired on \(dateAcquired, format: .dateTime.day().month().year())")
                                    .font(.system(size: 15))
                                    .foregroundColor(.white.opacity(0.7))
                            }
                            
                            if showPrices {
                                Text(priceFormatter.string(from: NSNumber(value: art.price)) ?? "")
                                    .font(.system(size: 15))
                                    .foregroundColor(.white.opacity(0.7))
                                    .transition(.opacity)
                            }
                        }
                        .padding(.horizontal, 10)
                        .padding(.bottom, 40)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    .padding(.top, 20)
                    .padding(.bottom, 10)
                    .transition(.opacity)
                    .background(Color(.black).opacity(0.45))
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation(.easeInOut(duration: 0)) {
                    onDetailsVisibilityChanged(!isDetailsVisible)
                }
            }
        }
        .background(.clear)
    }
}

// Add shake gesture support
extension View {
    func onShake(perform action: @escaping () -> Void) -> some View {
        self.modifier(ShakeGestureModifier(action: action))
    }
}

struct ShakeGestureModifier: ViewModifier {
    let action: () -> Void
    
    func body(content: Content) -> some View {
        content
            .onReceive(NotificationCenter.default.publisher(for: UIDevice.deviceDidShakeNotification)) { _ in
                action()
            }
    }
}

extension UIDevice {
    static let deviceDidShakeNotification = Notification.Name(rawValue: "deviceDidShakeNotification")
}

extension UIWindow {
    open override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        if motion == .motionShake {
            NotificationCenter.default.post(name: UIDevice.deviceDidShakeNotification, object: nil)
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Haus.self, configurations: config)
    
    let haus = Haus(title: "Sample Gallery")
    let sampleArt = ArtPiece(
        type: .collection,
        title: "Sample Artwork",
        artist: "John Doe",
        gallery: "Modern Gallery",
        price: 1500,
        dateAcquired: Date(),
        imageData: UIImage(named: "Arthaus_Canvas_Background")?.jpegData(compressionQuality: 0.8)
    )
    
    let secondArt = ArtPiece(
        type: .collection,
        title: "Abstract Harmony",
        artist: "Jane Smith",
        gallery: "Modern Gallery",
        price: 2200,
        dateAcquired: Date(),
        imageData: UIImage(named: "Arthaus_Canvas_Background")?.jpegData(compressionQuality: 0.8)
    )
    
    haus.artPieces.append(sampleArt)
    haus.artPieces.append(secondArt)
    container.mainContext.insert(haus)
    
    return ArtDetailView(artPiece: sampleArt, sortOption: .dateNewToOld)
        .modelContainer(container)
} 
