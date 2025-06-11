import SwiftUI

// MARK: - SalvadanaiView completamente riscritta
struct SalvadanaiView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var showingAddSalvadanaio = false
    @State private var selectedSalvadanaio: SalvadanaiModel?
    @State private var searchText = ""
    @State private var selectedCategory = "Tutti" // NUOVO: Filtro categoria
    
    // NUOVO: Categorie disponibili per il filtro
    private var availableCategories: [String] {
        var categories = ["Tutti"]
        let usedCategories = dataManager.usedSalvadanaiCategories
        categories.append(contentsOf: usedCategories)
        return categories
    }
    
    // AGGIORNATO: Filtro per categoria e ricerca
    var filteredSalvadanai: [SalvadanaiModel] {
        var salvadanai = dataManager.salvadanai
        
        // Filtro per categoria
        if selectedCategory != "Tutti" {
            salvadanai = salvadanai.filter { $0.category == selectedCategory }
        }
        
        // Filtro per ricerca
        if !searchText.isEmpty {
            salvadanai = salvadanai.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
        
        return salvadanai
    }
    
    // NUOVO: Conteggio per categoria
    private func getCategoryCount(_ category: String) -> Int {
        if category == "Tutti" {
            return dataManager.salvadanai.count
        }
        return dataManager.salvadanai.filter { $0.category == category }.count
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [Color.green.opacity(0.05), Color.blue.opacity(0.05)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack {
                    if dataManager.accounts.isEmpty {
                        NoAccountsView()
                    } else if dataManager.salvadanai.isEmpty {
                        EmptySalvadanaiView(action: { showingAddSalvadanaio = true })
                    } else {
                        VStack(spacing: 0) {
                            // NUOVO: Filtri categoria (solo se ci sono categorie)
                            if availableCategories.count > 1 {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 12) {
                                        ForEach(availableCategories, id: \.self) { category in
                                            CategoryFilterButton(
                                                title: category,
                                                isSelected: selectedCategory == category,
                                                count: getCategoryCount(category)
                                            ) {
                                                withAnimation(.spring()) {
                                                    selectedCategory = category
                                                }
                                            }
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                                .padding(.vertical, 12)
                            }
                            
                            // Lista salvadanai
                            ScrollView {
                                if filteredSalvadanai.isEmpty {
                                    // NUOVO: Vista vuota per filtri
                                    VStack(spacing: 20) {
                                        Image(systemName: "magnifyingglass")
                                            .font(.system(size: 50))
                                            .foregroundColor(.secondary)
                                        
                                        VStack(spacing: 8) {
                                            Text("Nessun salvadanaio trovato")
                                                .font(.title3)
                                                .fontWeight(.semibold)
                                            
                                            if selectedCategory != "Tutti" {
                                                Text("Nessun salvadanaio nella categoria '\(selectedCategory)'")
                                                    .font(.subheadline)
                                                    .foregroundColor(.secondary)
                                                    .multilineTextAlignment(.center)
                                            } else if !searchText.isEmpty {
                                                Text("Prova con termini di ricerca diversi")
                                                    .font(.subheadline)
                                                    .foregroundColor(.secondary)
                                            }
                                        }
                                        
                                        if selectedCategory != "Tutti" {
                                            Button("Mostra tutti") {
                                                withAnimation {
                                                    selectedCategory = "Tutti"
                                                }
                                            }
                                            .font(.subheadline)
                                            .foregroundColor(.blue)
                                        }
                                    }
                                    .padding(40)
                                } else {
                                    LazyVStack(spacing: 16) {
                                        ForEach(filteredSalvadanai, id: \.id) { salvadanaio in
                                            SalvadanaiCardView(salvadanaio: salvadanaio)
                                                .onTapGesture {
                                                    selectedSalvadanaio = salvadanaio
                                                }
                                        }
                                    }
                                    .padding()
                                }
                            }
                            .searchable(text: $searchText, prompt: "Cerca salvadanai...")
                        }
                    }
                }
            }
            .navigationTitle("Salvadanai")
            .toolbar(content: {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddSalvadanaio = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(.blue)
                    }
                    .disabled(dataManager.accounts.isEmpty)
                }
            })
        }
        .sheet(isPresented: $showingAddSalvadanaio) {
            if dataManager.accounts.isEmpty {
                SimpleModalView(
                    title: "Nessun conto disponibile",
                    message: "Prima di procedere, devi creare almeno un conto nel tab 'Conti'",
                    buttonText: "Ho capito"
                )
            } else {
                SimpleSalvadanaiFormView()
            }
        }
        .sheet(item: $selectedSalvadanaio) { salvadanaio in
            SimpleSalvadanaiDetailView(salvadanaio: salvadanaio)
        }
    }
}

// MARK: - NUOVO: Category Filter Button
struct CategoryFilterButton: View {
    let title: String
    let isSelected: Bool
    let count: Int
    let action: () -> Void
    
    // NUOVO: Emoji per categoria
    private var categoryEmoji: String {
        if let firstChar = title.first, firstChar.isEmoji {
            return String(firstChar)
        }
        return ""
    }
    
    private var categoryName: String {
        if let firstChar = title.first, firstChar.isEmoji {
            return String(title.dropFirst()).trimmingCharacters(in: .whitespaces)
        }
        return title
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                // Emoji se presente
                if !categoryEmoji.isEmpty && title != "Tutti" {
                    Text(categoryEmoji)
                        .font(.subheadline)
                } else if title == "Tutti" {
                    Image(systemName: "list.bullet")
                        .font(.subheadline)
                }
                
                Text(categoryName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                if count > 0 {
                    Text("\(count)")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(isSelected ? .white : .secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(isSelected ? Color.white.opacity(0.3) : Color.gray.opacity(0.2))
                        )
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(isSelected ?
                          LinearGradient(gradient: Gradient(colors: [.green, .mint]), startPoint: .leading, endPoint: .trailing) :
                            LinearGradient(gradient: Gradient(colors: [Color.gray.opacity(0.15)]), startPoint: .leading, endPoint: .trailing)
                         )
                    .shadow(color: isSelected ? .green.opacity(0.3) : .clear, radius: 8, x: 0, y: 4)
            )
            .foregroundColor(isSelected ? .white : .primary)
        }
        .buttonStyle(PlainButtonStyle())
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isSelected)
    }
}

// MARK: - Enhanced Salvadanaio Page Card - Accattivante con Gradienti
struct SalvadanaiCardView: View {
    let salvadanaio: SalvadanaiModel
    @EnvironmentObject var dataManager: DataManager
    @State private var isExpanded = false
    @State private var animateProgress = false
    @State private var animateGlow = false
    @State private var animateIcon = false
    @State private var animateAmount = false
    @State private var animateCoins = false
    @State private var isPressed = false
    @State private var showingTransactions = false
    
    private var progress: Double {
        // Per glass: currentAmount / monthlyRefill
        if salvadanaio.type == "glass" {
            let current = salvadanaio.currentAmount
            let monthly = salvadanaio.monthlyRefill
            
            if current > 0 && monthly > 0 {
                let result = current / monthly
                return min(result, 1.0)
            }
        }
        
        // Per obiettivi: currentAmount / targetAmount
        if salvadanaio.type == "objective" && !salvadanaio.isInfinite {
            let current = salvadanaio.currentAmount
            let target = salvadanaio.targetAmount
            
            if current > 0 && target > 0 {
                let result = current / target
                return min(result, 1.0)
            }
        }
        
        return 0
    }
    
    // Funzione per convertire string colore in Color
    private func getColor(from colorString: String) -> Color {
        switch colorString.lowercased() {
        case "blue": return .blue
        case "green": return .green
        case "red": return .red
        case "orange": return .orange
        case "purple": return .purple
        case "pink": return .pink
        case "yellow": return .yellow
        case "indigo": return .indigo
        case "mint": return .mint
        case "teal": return .teal
        case "cyan": return .cyan
        case "brown": return .brown
        default: return .blue
        }
    }
    
    private var cardGradient: LinearGradient {
        let baseColor = getColor(from: salvadanaio.color)
        
        if salvadanaio.currentAmount < 0 {
            // Gradiente rosso per saldi negativi
            return LinearGradient(
                gradient: Gradient(colors: [
                    Color.red.opacity(0.9),
                    Color.orange.opacity(0.8),
                    Color.pink.opacity(0.7)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else if progress >= 1.0 && !salvadanaio.isInfinite {
            // Gradiente dorato per obiettivi completati
            return LinearGradient(
                gradient: Gradient(colors: [
                    Color.yellow.opacity(0.9),
                    Color.orange.opacity(0.8),
                    baseColor.opacity(0.7)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            // Gradiente normale con il colore del salvadanaio
            return LinearGradient(
                gradient: Gradient(colors: [
                    baseColor.opacity(0.9),
                    baseColor.opacity(0.7),
                    baseColor.opacity(0.8)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
    
    private var statusInfo: (String, String, Color) {
        if salvadanaio.currentAmount < 0 {
            return ("⚠️", "In Rosso", .red)
        } else if progress >= 1.0 && !salvadanaio.isInfinite {
            return ("🎉", "Completato!", .yellow)
        } else if progress >= 0.8 && !salvadanaio.isInfinite {
            return ("🔥", "Quasi Fatto!", .orange)
        } else if salvadanaio.isInfinite {
            return ("♾️", "Infinito", getColor(from: salvadanaio.color))
        } else {
            return ("💪", "In Corso", getColor(from: salvadanaio.color))
        }
    }
    
    private var relatedTransactions: [TransactionModel] {
        dataManager.transactions.filter { transaction in
            transaction.salvadanaiName == salvadanaio.name
        }
    }
    
    var body: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.4)) {
                isExpanded.toggle()
            }
        }) {
            VStack(spacing: 0) {
                ZStack {
                    // Background con gradiente animato
                    RoundedRectangle(cornerRadius: 18)
                        .fill(cardGradient)
                        .shadow(
                            color: getColor(from: salvadanaio.color).opacity(animateGlow ? 0.4 : 0.2),
                            radius: animateGlow ? 12 : 6,
                            x: 0,
                            y: animateGlow ? 6 : 3
                        )
                        .animation(.easeInOut(duration: 3.5).repeatForever(autoreverses: true), value: animateGlow)
                    
                    // Overlay decorativo
                    RoundedRectangle(cornerRadius: 18)
                        .fill(
                            RadialGradient(
                                gradient: Gradient(colors: [
                                    Color.white.opacity(0.25),
                                    Color.clear,
                                    Color.black.opacity(0.1)
                                ]),
                                center: .topTrailing,
                                startRadius: 20,
                                endRadius: 120
                            )
                        )
                    
                    // Elementi decorativi fluttuanti
                    GeometryReader { geometry in
                        ZStack {
                            // Elementi decorativi fluttuanti + monete
                            Circle()
                                .fill(Color.white.opacity(0.15))
                                .frame(width: 50, height: 50)
                                .position(x: geometry.size.width * 0.85, y: geometry.size.height * 0.25)
                                .scaleEffect(animateIcon ? 1.2 : 0.8)
                                .animation(.easeInOut(duration: 4).repeatForever(autoreverses: true), value: animateIcon)
                            
                            Circle()
                                .fill(Color.white.opacity(0.08))
                                .frame(width: 30, height: 30)
                                .position(x: geometry.size.width * 0.15, y: geometry.size.height * 0.8)
                                .scaleEffect(animateIcon ? 0.6 : 1.1)
                                .animation(.easeInOut(duration: 3.5).repeatForever(autoreverses: true), value: animateIcon)
                            
                            // Monete decorative che fluttuano
                            Image(systemName: "dollarsign.circle.fill")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.3))
                                .position(x: geometry.size.width * 0.8, y: geometry.size.height * 0.6)
                                .scaleEffect(animateCoins ? 1.2 : 0.8)
                                .rotationEffect(.degrees(animateCoins ? 15 : -15))
                                .animation(.easeInOut(duration: 3).repeatForever(autoreverses: true), value: animateCoins)
                            
                            Image(systemName: "eurosign.circle")
                                .font(.caption2)
                                .foregroundColor(.white.opacity(0.25))
                                .position(x: geometry.size.width * 0.2, y: geometry.size.height * 0.4)
                                .scaleEffect(animateCoins ? 0.7 : 1.0)
                                .rotationEffect(.degrees(animateCoins ? -10 : 10))
                                .animation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true), value: animateCoins)
                            
                            // Stelline per stati speciali
                            if progress >= 0.8 || salvadanaio.currentAmount < 0 {
                                Image(systemName: "sparkles")
                                    .font(.subheadline)
                                    .foregroundColor(.white.opacity(0.6))
                                    .position(x: geometry.size.width * 0.25, y: geometry.size.height * 0.3)
                                    .scaleEffect(animateGlow ? 1.3 : 0.7)
                                    .animation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true), value: animateGlow)
                            }
                        }
                    }
                    
                    // Contenuto principale
                    VStack(spacing: 0) {
                        // Contenuto sempre visibile
                        HStack(spacing: 16) {
                            // Icona principale animata con salvadanaio
                            ZStack {
                                Circle()
                                    .fill(Color.white.opacity(0.25))
                                    .frame(width: 48, height: 48)
                                    .blur(radius: animateGlow ? 1 : 0)
                                
                                // Icona salvadanaio sempre riconoscibile
                                Image(systemName: "banknote.fill")
                                    .font(.title3)
                                    .foregroundColor(.white)
                                    .scaleEffect(animateIcon ? 1.1 : 1.0)
                                    .animation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true), value: animateIcon)
                                
                                // Mini icona tipo in overlay
                                Image(systemName: salvadanaio.type == "objective" ? (salvadanaio.isInfinite ? "infinity.circle.fill" : "target") : "cup.and.saucer.fill")
                                    .font(.caption2)
                                    .foregroundColor(.white.opacity(0.8))
                                    .background(
                                        Circle()
                                            .fill(Color.black.opacity(0.3))
                                            .frame(width: 16, height: 16)
                                    )
                                    .offset(x: 12, y: -12)
                            }
                            
                            // Info principale
                            VStack(alignment: .leading, spacing: 6) {
                                // Nome salvadanaio
                                Text(salvadanaio.name)
                                    .font(isExpanded ? .headline : .subheadline)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .lineLimit(isExpanded ? 3 : 1)
                                    .fixedSize(horizontal: false, vertical: isExpanded)
                                
                                // Status e categoria
                                HStack(spacing: 8) {
                                    // Status badge
                                    HStack(spacing: 4) {
                                        Text(statusInfo.0)
                                            .font(.caption)
                                            .scaleEffect(statusInfo.0 == "🎉" ? (animateIcon ? 1.2 : 1.0) : 1.0)
                                            .animation(.spring(response: 0.6, dampingFraction: 0.5).repeatForever(autoreverses: true), value: animateIcon)
                                        
                                        Text(statusInfo.1)
                                            .font(.caption2)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.white.opacity(0.9))
                                    }
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 3)
                                    .background(
                                        Capsule()
                                            .fill(Color.white.opacity(0.2))
                                    )
                                    
                                    // Categoria del salvadanaio
                                    if !salvadanaio.category.isEmpty {
                                        HStack(spacing: 4) {
                                            Image(systemName: "tag.fill")
                                                .font(.caption2)
                                                .foregroundColor(.white.opacity(0.7))
                                            
                                            Text(salvadanaio.category)
                                                .font(.caption2)
                                                .fontWeight(.medium)
                                                .foregroundColor(.white.opacity(0.9))
                                                .lineLimit(1)
                                        }
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 3)
                                        .background(
                                            Capsule()
                                                .fill(Color.white.opacity(0.15))
                                        )
                                    }
                                    
                                    Spacer()
                                }
                            }
                            
                            Spacer()
                            
                            // Importo principale
                            VStack(alignment: .trailing, spacing: 4) {
                                // Importo
                                HStack(alignment: .firstTextBaseline, spacing: 3) {
                                    Text("€")
                                        .font(.subheadline)
                                        .foregroundColor(.white.opacity(0.8))
                                    
                                    Text(String(format: "%.0f", abs(salvadanaio.currentAmount)))
                                        .font(isExpanded ? .title2 : .callout)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                        .scaleEffect(animateAmount ? 1.05 : 1.0)
                                        .shadow(color: .white.opacity(0.5), radius: animateGlow ? 4 : 2)
                                }
                                
                                // Freccia espansione
                                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white.opacity(0.7))
                                    .rotationEffect(.degrees(isExpanded ? 180 : 0))
                            }
                        }
                        .padding(.horizontal, 18)
                        .padding(.vertical, 16)
                        
                        // Progress bar sempre visibile (compatta)
                        if !salvadanaio.isInfinite && salvadanaio.currentAmount >= 0 {
                            VStack(spacing: 8) {
                                // Progress bar compatta
                                GeometryReader { geometry in
                                    ZStack(alignment: .leading) {
                                        // Background
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(Color.white.opacity(0.2))
                                            .frame(height: 6)
                                        
                                        // Progress fill
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(
                                                LinearGradient(
                                                    gradient: Gradient(colors: [
                                                        Color.white.opacity(0.9),
                                                        Color.white.opacity(0.7),
                                                        Color.white.opacity(0.9)
                                                    ]),
                                                    startPoint: .leading,
                                                    endPoint: .trailing
                                                )
                                            )
                                            .frame(width: max(0, geometry.size.width * (animateProgress ? progress : 0)), height: 6)
                                            .shadow(color: .white.opacity(0.5), radius: 2, x: 0, y: 1)
                                            .animation(.easeOut(duration: 1.5).delay(0.3), value: animateProgress)
                                        
                                        // Shimmer effect
                                        if progress > 0 {
                                            RoundedRectangle(cornerRadius: 4)
                                                .fill(
                                                    LinearGradient(
                                                        gradient: Gradient(colors: [
                                                            Color.clear,
                                                            Color.white.opacity(0.6),
                                                            Color.clear
                                                        ]),
                                                        startPoint: .leading,
                                                        endPoint: .trailing
                                                    )
                                                )
                                                .frame(width: max(0, geometry.size.width * progress), height: 6)
                                                .opacity(animateGlow ? 0.8 : 0.0)
                                                .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: animateGlow)
                                        }
                                    }
                                }
                                .frame(height: 6)
                                
                                // Info progress compatta
                                HStack {
                                    Text("\(Int(progress * 100))%")
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                    
                                    Spacer()
                                    
                                    if progress >= 1.0 {
                                        Text("🏆 Completato!")
                                            .font(.caption)
                                            .fontWeight(.medium)
                                            .foregroundColor(.white)
                                    } else {
                                        Text("di €\(String(format: "%.0f", salvadanaio.type == "objective" ? salvadanaio.targetAmount : salvadanaio.monthlyRefill))")
                                            .font(.caption)
                                            .foregroundColor(.white.opacity(0.8))
                                    }
                                }
                            }
                            .padding(.horizontal, 18)
                            .padding(.bottom, 16)
                        }
                        
                        // Contenuto espandibile
                        if isExpanded {
                            VStack(spacing: 0) {
                                // Separatore
                                Rectangle()
                                    .fill(Color.white.opacity(0.2))
                                    .frame(height: 1)
                                    .padding(.horizontal, 18)
                                
                                // Dettagli espansi
                                VStack(alignment: .leading, spacing: 14) {
                                    // Tipo e data
                                    HStack(spacing: 12) {
                                        HStack(spacing: 8) {
                                            Image(systemName: "tag")
                                                .font(.subheadline)
                                                .foregroundColor(.white.opacity(0.8))
                                                .frame(width: 20)
                                            
                                            Text(salvadanaio.type == "objective" ? (salvadanaio.isInfinite ? "Obiettivo Infinito" : "Obiettivo con Target") : "Glass Jar")
                                                .font(.subheadline)
                                                .foregroundColor(.white.opacity(0.9))
                                        }
                                        
                                        Spacer()
                                    }
                                    
                                    // Data creazione
                                    HStack(spacing: 8) {
                                        Image(systemName: "calendar")
                                            .font(.subheadline)
                                            .foregroundColor(.white.opacity(0.8))
                                            .frame(width: 20)
                                        
                                        Text("Creato il \(salvadanaio.createdAt, format: .dateTime.day().month(.wide).year())")
                                            .font(.subheadline)
                                            .foregroundColor(.white.opacity(0.9))
                                        
                                        Spacer()
                                    }
                                    
                                    // Transazioni correlate (cliccabile)
                                    Button(action: {
                                        showingTransactions = true
                                    }) {
                                        HStack(spacing: 8) {
                                            Image(systemName: "list.bullet.circle.fill")
                                                .font(.subheadline)
                                                .foregroundColor(.white.opacity(0.8))
                                                .frame(width: 20)
                                            
                                            Text("\(relatedTransactions.count) transazioni collegate")
                                                .font(.subheadline)
                                                .foregroundColor(.white.opacity(0.9))
                                            
                                            Spacer()
                                            
                                            Image(systemName: "chevron.right")
                                                .font(.caption)
                                                .foregroundColor(.white.opacity(0.6))
                                        }
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                                .padding(.horizontal, 18)
                                .padding(.vertical, 16)
                            }
                            .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 18))
            }
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.easeInOut(duration: 0.15), value: isPressed)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(.easeInOut(duration: 0.15)) {
                isPressed = pressing
            }
        }) {
            // Long press action
        }
        .onAppear {
            // Animazioni con delay casuali
            let delay = Double.random(in: 0.2...0.6)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                withAnimation(.easeInOut(duration: 0.8)) {
                    animateAmount = true
                }
                withAnimation(.easeInOut(duration: 1.2)) {
                    animateGlow = true
                }
                withAnimation(.easeInOut(duration: 1.5)) {
                    animateIcon = true
                }
                withAnimation(.easeInOut(duration: 2.0)) {
                    animateCoins = true
                }
                withAnimation(.easeOut(duration: 1.5).delay(0.3)) {
                    animateProgress = true
                }
            }
        }
        .sheet(isPresented: $showingTransactions) {
            SalvadanaiTransactionsView(salvadanaio: salvadanaio, transactions: relatedTransactions)
        }
    }
}

// MARK: - Vista Transazioni Salvadanaio
struct SalvadanaiTransactionsView: View {
    let salvadanaio: SalvadanaiModel
    let transactions: [TransactionModel]
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(.systemBackground),
                        Color(.systemGray6)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header info salvadanaio
                    VStack(spacing: 12) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(salvadanaio.name)
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.primary)
                                
                                if !salvadanaio.category.isEmpty {
                                    Text(salvadanaio.category)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 4) {
                                Text("€\(String(format: "%.2f", salvadanaio.currentAmount))")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.primary)
                                
                                Text("\(transactions.count) transazioni")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemBackground))
                            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                    )
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                    
                    // Lista transazioni
                    if transactions.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "tray")
                                .font(.system(size: 50))
                                .foregroundColor(.secondary)
                            
                            Text("Nessuna transazione")
                                .font(.title3)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                            
                            Text("Non ci sono ancora transazioni associate a questo salvadanaio")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 32)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color(.systemBackground))
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(transactions.sorted { $0.date > $1.date }) { transaction in
                                    TransactionRowView(transaction: transaction)
                                        .padding(.horizontal, 16)
                                }
                            }
                            .padding(.vertical, 8)
                        }
                        .background(Color(.systemBackground))
                    }
                }
            }
            .navigationTitle("Transazioni")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Chiudi") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Compact Transaction Row per uso all'interno della card
struct CompactTransactionRowInCard: View {
    let transaction: TransactionModel
    
    private var transactionColor: Color {
        switch transaction.type {
        case "expense": return .red
        case "salary": return .blue
        case "distribution": return .purple
        default: return .green
        }
    }
    
    private var categoryEmoji: String {
        if let firstChar = transaction.category.first, firstChar.isEmoji {
            return String(firstChar)
        }
        return ""
    }
    
    var body: some View {
        HStack(spacing: 8) {
            // Emoji o icona piccola
            if !categoryEmoji.isEmpty {
                Text(categoryEmoji)
                    .font(.caption)
            } else {
                Image(systemName: transaction.type == "expense" ? "minus.circle.fill" : "plus.circle.fill")
                    .font(.caption)
                    .foregroundColor(transactionColor)
            }
            
            // Descrizione
            VStack(alignment: .leading, spacing: 1) {
                Text(transaction.descr)
                    .font(.caption)
                    .fontWeight(.medium)
                    .lineLimit(1)
                    .foregroundColor(.primary)
                
                Text(transaction.date, format: .dateTime.day().month(.abbreviated))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Importo
            Text("\(transaction.type == "expense" ? "-" : "+")€\(String(format: "%.0f", transaction.amount))")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(transactionColor)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(transactionColor.opacity(0.08))
        )
    }
}

// MARK: - Detailed Transaction Row per la vista completa
struct DetailedTransactionRowView: View {
    let transaction: TransactionModel
    
    private var transactionColor: Color {
        switch transaction.type {
        case "expense": return .red
        case "salary": return .blue
        case "distribution": return .purple
        default: return .green
        }
    }
    
    private var categoryEmoji: String {
        if let firstChar = transaction.category.first, firstChar.isEmoji {
            return String(firstChar)
        }
        return ""
    }
    
    private var cleanCategoryName: String {
        if let firstChar = transaction.category.first, firstChar.isEmoji {
            return String(transaction.category.dropFirst()).trimmingCharacters(in: .whitespaces)
        }
        return transaction.category
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Emoji o icona
            ZStack {
                Circle()
                    .fill(transactionColor.opacity(0.1))
                    .frame(width: 44, height: 44)
                
                if !categoryEmoji.isEmpty {
                    Text(categoryEmoji)
                        .font(.title3)
                } else {
                    Image(systemName: transaction.type == "expense" ? "minus.circle" : "plus.circle")
                        .font(.title3)
                        .foregroundColor(transactionColor)
                }
            }
            
            // Contenuto principale
            VStack(alignment: .leading, spacing: 6) {
                Text(transaction.descr)
                    .font(.headline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .lineLimit(2)
                
                HStack(spacing: 8) {
                    Text(cleanCategoryName)
                        .font(.subheadline)
                        .foregroundColor(transactionColor)
                        .fontWeight(.medium)
                    
                    Text("•")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(transaction.date, format: .dateTime.hour().minute())
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Info aggiuntiva se presente
                if transaction.type != "expense", !transaction.accountName.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "building.columns")
                            .font(.caption2)
                            .foregroundColor(.blue)
                        Text("da \(transaction.accountName)")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }
            }
            
            Spacer()
            
            // Importo
            Text("\(transaction.type == "expense" ? "-" : "+")€\(String(format: "%.2f", transaction.amount))")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(transactionColor)
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Vista completa delle transazioni per il salvadanaio
struct SalvadanaiTransactionsDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let salvadanaio: SalvadanaiModel
    let transactions: [TransactionModel]
    
    // Funzione per convertire string colore in Color
    private func getColor(from colorString: String) -> Color {
        switch colorString.lowercased() {
        case "blue": return .blue
        case "green": return .green
        case "red": return .red
        case "orange": return .orange
        case "purple": return .purple
        case "pink": return .pink
        case "yellow": return .yellow
        case "indigo": return .indigo
        case "mint": return .mint
        case "teal": return .teal
        case "cyan": return .cyan
        case "brown": return .brown
        default: return .blue
        }
    }
    
    private var groupedTransactions: [(String, [TransactionModel])] {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.locale = Locale(identifier: "it_IT")
        
        let grouped = Dictionary(grouping: transactions) { transaction in
            formatter.string(from: transaction.date)
        }
        
        return grouped.sorted { $0.key > $1.key }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background con colore del salvadanaio
                LinearGradient(
                    gradient: Gradient(colors: [
                        getColor(from: salvadanaio.color).opacity(0.05),
                        getColor(from: salvadanaio.color).opacity(0.02)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header con info salvadanaio
                    VStack(spacing: 16) {
                        HStack(spacing: 12) {
                            Circle()
                                .fill(getColor(from: salvadanaio.color))
                                .frame(width: 16, height: 16)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(salvadanaio.name)
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                
                                Text("€\(String(format: "%.2f", salvadanaio.currentAmount))")
                                    .font(.subheadline)
                                    .foregroundColor(salvadanaio.currentAmount >= 0 ? .green : .red)
                                    .fontWeight(.medium)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 2) {
                                Text("\(transactions.count)")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(getColor(from: salvadanaio.color))
                                
                                Text("transazioni")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(.ultraThinMaterial)
                            .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
                    )
                    .padding(.horizontal)
                    .padding(.bottom, 16)
                    
                    // Lista transazioni
                    if transactions.isEmpty {
                        VStack(spacing: 20) {
                            Spacer()
                            
                            Image(systemName: "creditcard")
                                .font(.system(size: 50))
                                .foregroundColor(.secondary)
                            
                            Text("Nessuna transazione")
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundColor(.secondary)
                            
                            Text("Le transazioni associate a questo salvadanaio appariranno qui")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                            
                            Spacer()
                        }
                    } else {
                        List {
                            ForEach(groupedTransactions, id: \.0) { dateString, dayTransactions in
                                Section {
                                    ForEach(dayTransactions, id: \.id) { transaction in
                                        DetailedTransactionRowView(transaction: transaction)
                                    }
                                } header: {
                                    HStack {
                                        Text(dateString)
                                            .font(.headline)
                                            .fontWeight(.semibold)
                                        
                                        Spacer()
                                        
                                        Text("\(dayTransactions.count)")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 3)
                                            .background(
                                                Capsule()
                                                    .fill(Color.gray.opacity(0.1))
                                            )
                                    }
                                }
                            }
                        }
                        .listStyle(PlainListStyle())
                        .background(Color.clear)
                    }
                }
            }
            .navigationTitle("Transazioni")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Chiudi") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Empty Salvadanai View
struct EmptySalvadanaiView: View {
    let action: () -> Void
    @State private var animateIcon = false
    
    var body: some View {
        VStack(spacing: 32) {
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        gradient: Gradient(colors: [Color.green.opacity(0.2), Color.mint.opacity(0.2)]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 120, height: 120)
                    .scaleEffect(animateIcon ? 1.1 : 1.0)
                    .animation(.easeInOut(duration: 2).repeatForever(), value: animateIcon)
                
                Image(systemName: "banknote.fill")
                    .font(.system(size: 50))
                    .foregroundStyle(LinearGradient(
                        gradient: Gradient(colors: [.green, .mint]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
            }
            
            VStack(spacing: 12) {
                Text("Nessun Salvadanaio")
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                Text("Crea il tuo primo salvadanaio per iniziare a risparmiare!")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            Button(action: action) {
                HStack {
                    Text("Crea Salvadanaio")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 32)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [.green, .mint]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: .green.opacity(0.3), radius: 10, x: 0, y: 5)
            }
        }
        .padding(40)
        .onAppear {
            animateIcon = true
        }
    }
}

// MARK: - No Accounts View
struct NoAccountsView: View {
    @State private var animateWarning = false
    
    var body: some View {
        VStack(spacing: 32) {
            ZStack {
                Circle()
                    .fill(Color.orange.opacity(0.2))
                    .frame(width: 120, height: 120)
                    .scaleEffect(animateWarning ? 1.1 : 1.0)
                    .animation(.easeInOut(duration: 1.5).repeatForever(), value: animateWarning)
                
                Image(systemName: "banknote.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.orange)
            }
            
            VStack(spacing: 16) {
                Text("Impossibile creare salvadanai")
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                Text("Prima di creare un salvadanaio, devi aggiungere almeno un conto nel tab 'Conti'")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            HStack(spacing: 12) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                
                Text("È necessario almeno un conto per utilizzare questa funzione")
                    .font(.caption)
                    .foregroundColor(.orange)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.orange.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .padding(40)
        .onAppear {
            animateWarning = true
        }
    }
}

// MARK: - Simple Modal View
struct SimpleModalView: View {
    @Environment(\.dismiss) private var dismiss
    let title: String
    let message: String
    let buttonText: String
    
    var body: some View {
        NavigationView {
            VStack(spacing: 32) {
                Spacer()
                
                Image(systemName: "building.columns.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.orange)
                
                VStack(spacing: 16) {
                    Text(title)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text(message)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                Spacer()
                
                Button(buttonText) {
                    dismiss()
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.orange)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding()
            .navigationTitle("Attenzione")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(content: {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Chiudi") {
                        dismiss()
                    }
                }
            })
        }
    }
}

// MARK: - Simple Salvadanaio Form View con Categoria Semplificata
struct SimpleSalvadanaiFormView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var dataManager: DataManager
    
    @State private var name = ""
    @State private var selectedType = "objective"
    @State private var targetAmount = 100.0
    @State private var targetDate = Date()
    @State private var monthlyRefill = 50.0
    @State private var selectedColor = "blue"
    @State private var selectedCategory = "" // Categoria selezionata
    @State private var isInfiniteObjective = false
    
    let salvadanaiTypes = [
        ("objective", "Obiettivo", "target"),
        ("glass", "Glass", "cup.and.saucer.fill")
    ]
    
    var isFormValid: Bool {
        if name.isEmpty { return false }
        if selectedCategory.isEmpty { return false } // Categoria obbligatoria
        if selectedType == "objective" && !isInfiniteObjective && targetAmount <= 0 { return false }
        if selectedType == "glass" && monthlyRefill <= 0 { return false }
        return true
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("Nome salvadanaio", text: $name)
                        .textInputAutocapitalization(.words)
                } header: {
                    Text("Informazioni di base")
                }
                
                // SEZIONE CATEGORIA SEMPLIFICATA (come nelle transazioni)
                Section {
                    Picker("Categoria", selection: $selectedCategory) {
                        Text("Seleziona categoria")
                            .tag("")
                            .foregroundColor(.secondary)
                        ForEach(dataManager.allSalvadanaiCategories, id: \.self) { category in
                            Text(category)
                                .tag(category)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                } header: {
                    HStack {
                        Image(systemName: "folder.fill")
                            .foregroundColor(.orange)
                        Text("Categoria")
                    }
                } footer: {
                    Text("Organizza i tuoi salvadanai per categoria. Gestisci le categorie nelle Impostazioni.")
                }
                
                Section {
                    ForEach(salvadanaiTypes, id: \.0) { type, displayName, icon in
                        Button(action: {
                            selectedType = type
                            if type == "glass" {
                                isInfiniteObjective = false
                            }
                        }) {
                            HStack {
                                Image(systemName: icon)
                                    .frame(width: 24)
                                    .foregroundColor(selectedType == type ? .blue : .secondary)
                                Text(displayName)
                                Spacer()
                                if selectedType == type {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.blue)
                                }
                            }
                            .padding(.vertical, 8)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(PlainButtonStyle())
                        .foregroundColor(selectedType == type ? .blue : .primary)
                    }
                } header: {
                    Text("Tipo di salvadanaio")
                }
                
                if selectedType == "objective" {
                    Section {
                        Toggle("Obiettivo infinito", isOn: $isInfiniteObjective)
                        
                        if !isInfiniteObjective {
                            HStack {
                                Text("Obiettivo")
                                Spacer()
                                TextField("100", value: $targetAmount, format: .currency(code: "EUR"))
                                    .multilineTextAlignment(.trailing)
                                    .keyboardType(.decimalPad)
                            }
                            
                            DatePicker("Scadenza", selection: $targetDate, displayedComponents: .date)
                        }
                    } header: {
                        Text("Dettagli obiettivo")
                    }
                } else {
                    Section {
                        HStack {
                            Text("Ricarica mensile")
                            Spacer()
                            TextField("50", value: $monthlyRefill, format: .currency(code: "EUR"))
                                .multilineTextAlignment(.trailing)
                                .keyboardType(.decimalPad)
                        }
                    } header: {
                        Text("Dettagli Glass")
                    }
                }
                
                Section {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 16) {
                        ForEach(getSalvadanaiColors(), id: \.name) { colorItem in
                            Circle()
                                .fill(colorItem.color)
                                .frame(width: 40, height: 40)
                                .overlay(
                                    Circle()
                                        .stroke(selectedColor == colorItem.name ? Color.primary : Color.clear, lineWidth: 3)
                                )
                                .onTapGesture {
                                    selectedColor = colorItem.name
                                }
                        }
                    }
                    .padding(.vertical, 8)
                } header: {
                    Text("Colore")
                }
                
                Section {
                    HStack {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(.blue)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Saldo iniziale: €0,00")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Text("Il salvadanaio inizierà sempre con saldo zero")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("Informazioni")
                }
            }
            .navigationTitle("Nuovo Salvadanaio")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(content: {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Annulla") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Salva") {
                        createSalvadanaio()
                    }
                    .disabled(!isFormValid)
                }
            })
        }
    }
    
    private func getSalvadanaiColors() -> [(name: String, color: Color)] {
        return [
            ("blue", Color.blue),
            ("green", Color.green),
            ("orange", Color.orange),
            ("purple", Color.purple),
            ("pink", Color.pink),
            ("red", Color.red),
            ("yellow", Color.yellow),
            ("indigo", Color.indigo),
            ("mint", Color.mint),
            ("teal", Color.teal),
            ("cyan", Color.cyan),
            ("brown", Color.brown)
        ]
    }
    
    private func createSalvadanaio() {
        dataManager.addSalvadanaio(
            name: name,
            type: selectedType,
            targetAmount: isInfiniteObjective ? 0 : (selectedType == "objective" ? targetAmount : 0),
            targetDate: isInfiniteObjective ? nil : (selectedType == "objective" ? targetDate : nil),
            monthlyRefill: selectedType == "glass" ? monthlyRefill : 0,
            color: selectedColor,
            category: selectedCategory,
            isInfinite: selectedType == "objective" ? isInfiniteObjective : false
        )
        dismiss()
    }
}

// MARK: - NUOVO: New Category View
struct NewCategoryView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var dataManager: DataManager
    
    let categoryType: String
    @State private var categoryName = ""
    @State private var selectedEmoji = "📁"
    @State private var useEmoji = true
    
    let commonEmojis = ["📁", "🏠", "✈️", "🚗", "🎓", "💊", "🎮", "💰", "🎁", "🔧", "💼", "🍽️", "👕", "📱", "🏋️", "🎵", "💒", "🐕", "📚", "🌱", "💡", "⭐", "🎯", "🔮"]
    
    var title: String {
        "Nuova Categoria Salvadanaio"
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [Color.green.opacity(0.05), Color.orange.opacity(0.05)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                Form {
                    // Anteprima
                    Section {
                        CategoryPreviewCard(
                            categoryName: categoryName.isEmpty ? "Nome categoria" : categoryName,
                            emoji: useEmoji ? selectedEmoji : "",
                            isEmpty: categoryName.isEmpty
                        )
                    }
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())
                    
                    // Nome categoria
                    Section {
                        TextField("Nome categoria", text: $categoryName)
                            .textInputAutocapitalization(.words)
                            .font(.headline)
                    } header: {
                        HStack {
                            Image(systemName: "textformat")
                                .foregroundColor(.green)
                            Text("Nome")
                        }
                    } footer: {
                        Text("Esempio: Sport e Palestra, Matrimonio, Fondo Emergenza")
                    }
                    
                    // Emoji toggle
                    Section {
                        Toggle("Usa emoji", isOn: $useEmoji)
                            .toggleStyle(SwitchToggleStyle(tint: .green))
                        
                        if useEmoji {
                            // Emoji selector migliorato
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Emoji selezionata: \(selectedEmoji)")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
                                    ForEach(commonEmojis, id: \.self) { emoji in
                                        Button(action: {
                                            selectedEmoji = emoji
                                        }) {
                                            Text(emoji)
                                                .font(.title2)
                                                .frame(width: 44, height: 44)
                                                .background(
                                                    Circle()
                                                        .fill(selectedEmoji == emoji ? Color.green.opacity(0.2) : Color.gray.opacity(0.1))
                                                        .overlay(
                                                            Circle()
                                                                .stroke(selectedEmoji == emoji ? Color.green : Color.clear, lineWidth: 2)
                                                        )
                                                )
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                }
                            }
                        }
                    } header: {
                        HStack {
                            Image(systemName: "face.smiling.fill")
                                .foregroundColor(.orange)
                            Text("Icona (opzionale)")
                        }
                    } footer: {
                        Text(useEmoji ? "Seleziona un'emoji per rendere la categoria più riconoscibile" : "La categoria userà solo testo senza emoji")
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Annulla") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Aggiungi") {
                        addCategory()
                    }
                    .disabled(categoryName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .fontWeight(.semibold)
                    .foregroundColor(categoryName.isEmpty ? .secondary : .green)
                }
            }
        }
    }
    
    private func addCategory() {
        let trimmedName = categoryName.trimmingCharacters(in: .whitespacesAndNewlines)
        let finalName = (useEmoji && !selectedEmoji.isEmpty) ? "\(selectedEmoji) \(trimmedName)" : trimmedName
        
        dataManager.addSalvadanaiCategory(finalName)
        dismiss()
    }
}


// MARK: - NUOVO: Category Picker View
struct CategoryPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var dataManager: DataManager
    @Binding var selectedCategory: String
    let onNewCategory: () -> Void
    
    @State private var searchText = ""
    
    private var filteredCategories: [String] {
        let allCategories = dataManager.allSalvadanaiCategories
        if searchText.isEmpty {
            return allCategories
        } else {
            return allCategories.filter { $0.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("Cerca categorie...", text: $searchText)
                        .textFieldStyle(PlainTextFieldStyle())
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.gray.opacity(0.1))
                )
                .padding()
                
                List {
                    // Categorie predefinite
                    Section {
                        ForEach(dataManager.defaultSalvadanaiCategories.filter { category in
                            searchText.isEmpty || category.localizedCaseInsensitiveContains(searchText)
                        }, id: \.self) { category in
                            CategoryRowView(
                                category: category,
                                isSelected: selectedCategory == category,
                                isCustom: false
                            ) {
                                selectedCategory = category
                                dismiss()
                            }
                        }
                    } header: {
                        Text("Categorie Predefinite")
                    }
                    
                    // Categorie personalizzate
                    if !dataManager.customSalvadanaiCategories.isEmpty {
                        Section {
                            ForEach(dataManager.customSalvadanaiCategories.filter { category in
                                searchText.isEmpty || category.localizedCaseInsensitiveContains(searchText)
                            }, id: \.self) { category in
                                CategoryRowView(
                                    category: category,
                                    isSelected: selectedCategory == category,
                                    isCustom: true
                                ) {
                                    selectedCategory = category
                                    dismiss()
                                }
                            }
                        } header: {
                            Text("Categorie Personalizzate")
                        }
                    }
                    
                    // Aggiungi nuova categoria
                    Section {
                        Button(action: {
                            onNewCategory()
                        }) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundColor(.green)
                                Text("Aggiungi nuova categoria")
                                    .foregroundColor(.green)
                                    .fontWeight(.medium)
                            }
                            .padding(.vertical, 8)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .listStyle(InsetGroupedListStyle())
            }
            .navigationTitle("Seleziona Categoria")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Chiudi") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - NUOVO: Category Row View
struct CategoryRowView: View {
    let category: String
    let isSelected: Bool
    let isCustom: Bool
    let action: () -> Void
    
    private var categoryEmoji: String {
        if let firstChar = category.first, firstChar.isEmoji {
            return String(firstChar)
        }
        return ""
    }
    
    private var categoryName: String {
        if let firstChar = category.first, firstChar.isEmoji {
            return String(category.dropFirst()).trimmingCharacters(in: .whitespaces)
        }
        return category
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                // Emoji o icona
                if !categoryEmoji.isEmpty {
                    Text(categoryEmoji)
                        .font(.title3)
                        .frame(width: 32, height: 32)
                        .background(
                            Circle()
                                .fill(Color.gray.opacity(0.1))
                        )
                } else {
                    Image(systemName: "folder.fill")
                        .font(.title3)
                        .foregroundColor(.orange)
                        .frame(width: 32, height: 32)
                        .background(
                            Circle()
                                .fill(Color.orange.opacity(0.1))
                        )
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(categoryName)
                        .font(.headline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    HStack {
                        Text(isCustom ? "Personalizzata" : "Predefinita")
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(
                                Capsule()
                                    .fill((isCustom ? Color.purple : Color.blue).opacity(0.1))
                            )
                            .foregroundColor(isCustom ? .purple : .blue)
                        
                        Spacer()
                    }
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.green)
                }
            }
            .padding(.vertical, 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Simple Salvadanaio Detail View
struct SimpleSalvadanaiDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var dataManager: DataManager
    let salvadanaio: SalvadanaiModel
    
    @State private var showingDeleteAlert = false
    
    var relatedTransactions: [TransactionModel] {
        dataManager.transactions.filter { $0.salvadanaiName == salvadanaio.name }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header Card
                    SalvadanaiCardView(salvadanaio: salvadanaio)
                    
                    // Transazioni correlate
                    if !relatedTransactions.isEmpty {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Transazioni")
                                .font(.title3)
                                .fontWeight(.bold)
                            
                            ForEach(relatedTransactions.sorted { $0.date > $1.date }, id: \.id) { transaction in
                                HStack(spacing: 12) {
                                    Image(systemName: transaction.type == "expense" ? "minus.circle.fill" : "plus.circle.fill")
                                        .foregroundColor(transaction.type == "expense" ? .red : .green)
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(transaction.descr)
                                            .font(.headline)
                                        Text(transaction.date, style: .date)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    Text("\(transaction.type == "expense" ? "-" : "+")€\(String(format: "%.2f", transaction.amount))")
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(transaction.type == "expense" ? .red : .green)
                                }
                                .padding(.vertical, 8)
                            }
                        }
                        .padding(20)
                        .background(Color.gray.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                }
                .padding()
            }
            .navigationTitle("Dettaglio")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(content: {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Chiudi") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(role: .destructive, action: {
                            showingDeleteAlert = true
                        }) {
                            HStack {
                                Image(systemName: "trash")
                                    .tint(.red)
                                Text("Elimina")
                                    .tint(.red)
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            })
        }
        .alert("Elimina Salvadanaio", isPresented: $showingDeleteAlert) {
            Button("Elimina", role: .destructive) {
                dataManager.deleteSalvadanaio(salvadanaio)
                dismiss()
            }
            Button("Annulla", role: .cancel) { }
        } message: {
            Text("Sei sicuro di voler eliminare questo salvadanaio? Questa azione non può essere annullata.")
        }
    }
}
