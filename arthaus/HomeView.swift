import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var hauses: [Haus]
    @State private var showingNewHausSheet = false
    @State private var showingEditHausSheet = false
    @State private var showingDeleteAlert = false
    @State private var hausToDelete: Haus?
    @State private var newHausTitle = ""
    @State private var hausToEdit: Haus?
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.98, green: 0.97, blue: 0.94) //eggshell
                    .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    Spacer()
                    Image("logomark_white")
                         .resizable()
                         .scaledToFit()
                         .frame(width: 200, height: 200)
                    
                    ScrollView {
                        VStack(spacing: 16) {
                            Spacer()
                            if hauses.isEmpty {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Create your first collection.")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary.opacity(0.8))
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .padding(.horizontal)
                            } else {
                                LazyVStack(spacing: 16) {
                                    ForEach(hauses) { haus in
                                        NavigationLink(destination: HausDetailView(haus: haus)) {
                                            HStack {
                                                VStack(alignment: .leading, spacing: 5) {
                                                    Text(haus.title)
                                                        .font(.custom("Didot", size: 20))
                                                        .bold()
                                                    HStack(spacing: 8) {
                                                        Text("\(haus.artPieces.filter { $0.type == .collection }.count) collected")
                                                            .font(.subheadline)
                                                            .foregroundColor(.secondary)
                                                        Text("•")
                                                            .font(.subheadline)
                                                            .foregroundColor(.secondary)
                                                        Text("\(haus.artPieces.filter { $0.type == .tracking }.count) tracked")
                                                            .font(.subheadline)
                                                            .foregroundColor(.secondary)
                                                    }
                                                }
                                                Spacer()
                                                Image(systemName: "chevron.right")
                                                    .foregroundColor(.secondary)
                                                    .font(.subheadline)
                                            }
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .padding(25)
                                            .background(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .fill(Color.white.opacity(0.8))
                                                    .shadow(color: .black.opacity(0.15), radius: 7, x: 0, y: 0)
                                            )
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                        .contextMenu {
                                            Button(action: {
                                                hausToEdit = haus
                                                newHausTitle = haus.title
                                                showingEditHausSheet = true
                                            }) {
                                                Label("Edit", systemImage: "pencil")
                                            }
                                            
                                            Button(role: .destructive, action: {
                                                hausToDelete = haus
                                                showingDeleteAlert = true
                                            }) {
                                                Label("Delete", systemImage: "trash")
                                            }
                                        }
                                    }
                                }
                                .padding(.horizontal, 45)
                            }
                            
                            Button(action: { showingNewHausSheet = true }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "plus")
                                    Text("collection")
                                }
                                .font(.callout)
                                .bold()
                                .foregroundColor(.white)
                                .padding(.horizontal, 25)
                                .padding(.vertical, 15)
                                .background(Color.black)
                                .clipShape(Capsule())
                            }
                            .padding(.top, 40)
                        }
                    }
                }
            }
            .alert("Delete collection?", isPresented: $showingDeleteAlert) {
                Button("Cancel", role: .cancel) {
                    hausToDelete = nil
                }
                Button("Delete", role: .destructive) {
                    if let haus = hausToDelete {
                        withAnimation {
                            modelContext.delete(haus)
                            hausToDelete = nil
                        }
                    }
                }
            } message: {
                if let haus = hausToDelete {
                    Text("\(haus.title) will not be recoverable.")
                }
            }
            .sheet(isPresented: $showingNewHausSheet) {
                NavigationStack {
                    VStack(spacing: 20) {
                        Text("What will you name your new collection?")
                            .font(.custom("Didot", size: 20))
                            .frame(width: 250)
                            .bold()
                            .multilineTextAlignment(.center)
                        
                        TextField("Name", text: $newHausTitle)
                            .padding(.vertical, 12)
                            .padding(.horizontal, 8)
                            .background(Color(.white).opacity(0.1))
                            .cornerRadius(8)
                            .frame(width: 250)
                            .multilineTextAlignment(.center)
                        
                        Button(action: {
                            addHaus()
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "checkmark")
                            }
                            .font(.callout)
                            .bold()
                            .foregroundColor(.black)
                            .frame(width: 100)
                            .padding(.vertical, 15)
                            .background(Color.white)
                            .clipShape(Capsule())
                        }
                        .disabled(newHausTitle.isEmpty)
                    }
                    .padding(.vertical, 20)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 15))
                    .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: -5)
                }
                .presentationDetents([.height(250)])
                .presentationDragIndicator(.visible)
                .preferredColorScheme(.dark)
                .onDisappear {
                    newHausTitle = ""
                }
            }
            .sheet(isPresented: $showingEditHausSheet) {
                NavigationStack {
                    VStack(spacing: 20) {
                        Text("Whoopsie, made a oopsie!")
                            .font(.custom("Didot", size: 20))
                            .frame(width: 250)
                            .bold()
                            .multilineTextAlignment(.center)
                        
                        TextField("Name", text: $newHausTitle)
                            .padding(.vertical, 12)
                            .padding(.horizontal, 8)
                            .background(Color(.white).opacity(0.1))
                            .cornerRadius(8)
                            .frame(width: 250)
                            .multilineTextAlignment(.center)
                        
                        Button(action: {
                            if let haus = hausToEdit {
                                haus.title = newHausTitle
                                hausToEdit = nil
                            }
                            showingEditHausSheet = false
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "checkmark")
                            }
                            .font(.callout)
                            .bold()
                            .foregroundColor(.black)
                            .frame(width: 100)
                            .padding(.vertical, 15)
                            .background(Color.white)
                            .clipShape(Capsule())
                        }
                        .disabled(newHausTitle.isEmpty)
                    }
                    .padding(.vertical, 20)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 15))
                    .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: -5)
                }
                .presentationDetents([.height(250)])
                .presentationDragIndicator(.visible)
                .preferredColorScheme(.dark)
                .onDisappear {
                    newHausTitle = ""
                }
            }
        }
    }
    
    private func addHaus() {
        withAnimation {
            let haus = Haus(title: newHausTitle)
            modelContext.insert(haus)
            newHausTitle = ""
            showingNewHausSheet = false
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let schema = Schema([
        Haus.self,
        ArtPiece.self,
    ])
    let container = try! ModelContainer(for: schema, configurations: config)
    
    // Add sample data
    let haus1 = Haus(title: "Modern Art Collection")
    let haus2 = Haus(title: "Renaissance Masterpieces")
    let haus3 = Haus(title: "Contemporary Works")
    
    container.mainContext.insert(haus1)
    container.mainContext.insert(haus2)
    container.mainContext.insert(haus3)
    
    return HomeView()
        .modelContainer(container)
} 
