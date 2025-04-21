import SwiftUI

struct ConfettiPiece: Identifiable {
    let id = UUID()
    var position: CGPoint
    var color: Color
    var scale: Double
    var opacity: Double
    var horizontalOffset: Double
    var shape: ConfettiShape
}

enum ConfettiShape {
    case rectangle
    case circle
    case triangle
    
    @ViewBuilder
    func view(color: Color) -> some View {
        switch self {
        case .rectangle:
            Rectangle()
                .fill(color)
                .frame(width: 10, height: 4)
        case .circle:
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
        case .triangle:
            Triangle()
                .fill(color)
                .frame(width: 8, height: 8)
        }
    }
}

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

struct ConfettiView: View {
    @State private var pieces: [ConfettiPiece] = []
    @State private var isAnimating = false
    
    let colors: [Color] = [.red, .blue, .green, .yellow, .pink, .purple, .orange]
    let shapes: [ConfettiShape] = [.rectangle, .circle, .triangle]
    
    var body: some View {
        ZStack {
            ForEach(pieces) { piece in
                piece.shape.view(color: piece.color)
                    .position(piece.position)
                    .scaleEffect(piece.scale)
                    .opacity(piece.opacity)
            }
        }
        .onAppear {
            startConfetti()
        }
    }
    
    private func startConfetti() {
        pieces = []
        isAnimating = true
        
        // Create initial pieces
        for _ in 0..<150 {
            let piece = ConfettiPiece(
                position: CGPoint(
                    x: Double.random(in: 0...UIScreen.main.bounds.width),
                    y: -20
                ),
                color: colors.randomElement() ?? .red,
                scale: Double.random(in: 0.8...1.4),
                opacity: 1,
                horizontalOffset: Double.random(in: -50...50),
                shape: shapes.randomElement() ?? .rectangle
            )
            pieces.append(piece)
        }
        
        // Animate each piece
        for index in pieces.indices {
            let duration = Double.random(in: 1.2...1.8)
            
            withAnimation(.easeIn(duration: duration)) {
                pieces[index].position.y = UIScreen.main.bounds.height + 20
                pieces[index].position.x += pieces[index].horizontalOffset
                pieces[index].opacity = 0
            }
        }
        
        // Reset after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            isAnimating = false
            pieces = []
        }
    }
}

#Preview {
    ConfettiView()
} 
