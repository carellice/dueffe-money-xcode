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
                                        ForEach(dataManager.sortedSalvadanai(filteredSalvadanai), id: \.id) { salvadanaio in
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
    @State private var showingEditSheet = false // NUOVO: Per la modifica
    @State private var showingDeleteAlert = false // NUOVO: Per l'eliminazione
    @State private var showingBreakAlert = false // NUOVO
    @State private var showingBreakSheet = false // NUOVO
    
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
            (transaction.salvadanaiName == salvadanaio.name ||
             (transaction.type == "transfer_salvadanai" && transaction.accountName == salvadanaio.name)) &&
            transaction.type != "distribution" // NUOVO: Esclude le distribuzioni
        }
    }
    
    var body: some View {
        // NUOVO: Context Menu aggiunto qui
        Button(action: {
            withAnimation(.easeInOut(duration: 0.4)) {
                isExpanded.toggle()
            }
        }) {
            VStack(spacing: 0) {
                // Il contenuto della card rimane identico...
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
                                
                                // Categoria del salvadanaio (sotto lo status)
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
                            }
                            
                            Spacer()
                            
                            // Importo principale
                            VStack(alignment: .trailing, spacing: 4) {
                                // Importo
                                HStack(alignment: .firstTextBaseline, spacing: 3) {
                                    Text("")
                                        .font(.subheadline)
                                        .foregroundColor(.white.opacity(0.8))
                                    
                                    Text(salvadanaio.currentAmount.italianCurrency)
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
                                            .animation(.easeOut(duration: 1.5).delay(0.5), value: animateProgress)
                                        
                                        // Shimmer effect
                                        if progress > 0 {
                                            RoundedRectangle(cornerRadius: 4)
                                                .fill(
                                                    LinearGradient(
                                                        gradient: Gradient(colors: [
                                                            Color.clear,
                                                            Color.white.opacity(0.8),
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
                                        Text("🏆 Fatto!")
                                            .font(.caption)
                                            .fontWeight(.medium)
                                            .foregroundColor(.white)
                                    } else {
                                        Text("di \((salvadanaio.type == "objective" ? salvadanaio.targetAmount : salvadanaio.monthlyRefill).italianCurrency)")
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
        // NUOVO: Context Menu aggiornato (da sostituire nel file SalvadanaiView.swift)
        .contextMenu {
            // Modifica nome
            Button(action: {
                showingEditSheet = true
            }) {
                Label("Modifica Nome", systemImage: "pencil")
            }
            .tint(.blue)
            
            // Visualizza transazioni
            if !relatedTransactions.isEmpty {
                Button(action: {
                    showingTransactions = true
                }) {
                    Label("Transazioni (\(relatedTransactions.count))", systemImage: "list.bullet")
                }
                .tint(.purple)
            }
            
            Divider()
            
            // NUOVO: Rompi salvadanaio
            Button(action: {
                showingBreakAlert = true
            }) {
                Label("Rompi Salvadanaio", systemImage: "hammer.fill")
            }
            .tint(.orange)
            
            // Elimina salvadanaio (metodo soft)
            Button(role: .destructive, action: {
                showingDeleteAlert = true
            }) {
                Label("Elimina Salvadanaio", systemImage: "trash")
            }
            .tint(.red)
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
        // NUOVO: Sheet per modifica nome
        .sheet(isPresented: $showingEditSheet) {
            EditSalvadanaiNameView(salvadanaio: salvadanaio)
        }
        .sheet(isPresented: $showingBreakSheet) {
            BreakSalvadanaiView(salvadanaio: salvadanaio)
        }
        .alert("Rompi Salvadanaio", isPresented: $showingBreakAlert) {
            Button("Rompi", role: .destructive) {
                showingBreakSheet = true
            }
            Button("Annulla", role: .cancel) { }
        } message: {
            if dataManager.canBreakSalvadanaiDirectly(salvadanaio) {
                Text("Vuoi rompere il salvadanaio '\(salvadanaio.name)'?\n\nIl salvadanaio e tutte le sue transazioni verranno eliminati definitivamente.\n\nQuesta azione non può essere annullata!")
            } else {
                Text("Vuoi rompere il salvadanaio '\(salvadanaio.name)'?\n\nDovrai prima trasferire \(salvadanaio.currentAmount.italianCurrency) ad altri salvadanai.\n\nIl salvadanaio e tutte le sue transazioni verranno eliminati definitivamente.")
            }
        }
        // NUOVO: Alert per eliminazione
        .alert("Elimina Salvadanaio", isPresented: $showingDeleteAlert) {
            Button("Elimina", role: .destructive) {
                withAnimation {
                    dataManager.deleteSalvadanaio(salvadanaio)
                }
            }
            Button("Annulla", role: .cancel) { }
        } message: {
            if relatedTransactions.isEmpty {
                Text("Sei sicuro di voler eliminare il salvadanaio '\(salvadanaio.name)'? Questa azione non può essere annullata.")
            } else {
                Text("Sei sicuro di voler eliminare il salvadanaio '\(salvadanaio.name)'?\n\nCi sono \(relatedTransactions.count) transazioni associate che verranno mantenute ma non saranno più collegate a questo salvadanaio.\n\nQuesta azione non può essere annullata.")
            }
        }
    }
}

struct EditSalvadanaiNameView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var dataManager: DataManager
    
    @State private var currentSalvadanaiName: String
    @State private var showingDeleteAlert = false
    private let salvadanaio: SalvadanaiModel
    private let originalSalvadanaiName: String
    
    init(salvadanaio: SalvadanaiModel) {
        self.salvadanaio = salvadanaio
        self.originalSalvadanaiName = salvadanaio.name
        self._currentSalvadanaiName = State(initialValue: salvadanaio.name)
    }
    
    private var hasChanges: Bool {
        currentSalvadanaiName.trimmingCharacters(in: .whitespacesAndNewlines) != originalSalvadanaiName
    }
    
    private var relatedTransactions: [TransactionModel] {
        dataManager.transactions.filter { transaction in
            (transaction.salvadanaiName == originalSalvadanaiName ||
             (transaction.type == "transfer_salvadanai" && transaction.accountName == originalSalvadanaiName)) &&
            transaction.type != "distribution"
        }
    }
    
    private var isDuplicateName: Bool {
        let trimmedName = currentSalvadanaiName.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmedName.isEmpty &&
               dataManager.salvadanai.contains { $0.name.lowercased() == trimmedName.lowercased() && $0.id != salvadanaio.id }
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
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [getColor(from: salvadanaio.color).opacity(0.05), Color.blue.opacity(0.05)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                Form {
                    // Anteprima del salvadanaio
                    Section {
                        VStack(spacing: 20) {
                            HStack {
                                Image(systemName: "eye.fill")
                                    .foregroundColor(.blue)
                                Text("Anteprima")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                Spacer()
                                
                                if hasChanges {
                                    Text("Modificato")
                                        .font(.caption)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 3)
                                        .background(
                                            Capsule()
                                                .fill(Color.orange.opacity(0.1))
                                        )
                                        .foregroundColor(.orange)
                                }
                            }
                            
                            HStack(spacing: 16) {
                                ZStack {
                                    Circle()
                                        .fill(LinearGradient(
                                            gradient: Gradient(colors: [getColor(from: salvadanaio.color), getColor(from: salvadanaio.color).opacity(0.7)]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ))
                                        .frame(width: 56, height: 56)
                                        .shadow(color: getColor(from: salvadanaio.color).opacity(0.3), radius: 8, x: 0, y: 4)
                                    
                                    Image(systemName: "banknote.fill")
                                        .font(.title2)
                                        .foregroundColor(.white)
                                }
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(currentSalvadanaiName.isEmpty ? "Nome del salvadanaio" : currentSalvadanaiName)
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(currentSalvadanaiName.isEmpty ? .secondary : .primary)
                                        .lineLimit(2)
                                    
                                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                                        Text(salvadanaio.currentAmount.italianCurrency)
                                            .font(.title2)
                                            .fontWeight(.bold)
                                            .foregroundColor(salvadanaio.currentAmount >= 0 ? .primary : .red)
                                    }

                                    HStack {
                                        Text(salvadanaio.category)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        
                                        Text("•")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        
                                        Text(salvadanaio.type == "objective" ? (salvadanaio.isInfinite ? "Infinito" : "Obiettivo") : "Glass")
                                            .font(.caption)
                                            .foregroundColor(getColor(from: salvadanaio.color))
                                            .fontWeight(.medium)
                                    }
                                }
                                
                                Spacer()
                            }
                        }
                        .padding(24)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(.ultraThinMaterial)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(hasChanges ? Color.orange.opacity(0.3) : getColor(from: salvadanaio.color).opacity(0.2), lineWidth: 1)
                                )
                                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                        )
                    }
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())
                    
                    // Modifica nome
                    Section {
                        HStack {
                            Image(systemName: "tag.fill")
                                .foregroundColor(getColor(from: salvadanaio.color))
                                .frame(width: 24)
                            
                            TextField("Nome del salvadanaio", text: $currentSalvadanaiName)
                                .textInputAutocapitalization(.words)
                                .font(.headline)
                        }
                        
                        // Validazione in tempo reale
                        if !currentSalvadanaiName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            HStack {
                                Image(systemName: isDuplicateName ? "exclamationmark.triangle.fill" : "checkmark.circle.fill")
                                    .foregroundColor(isDuplicateName ? .red : .green)
                                
                                Text(isDuplicateName ? "Nome già esistente" : "Nome disponibile")
                                    .font(.subheadline)
                                    .foregroundColor(isDuplicateName ? .red : .green)
                                    .fontWeight(.medium)
                                
                                Spacer()
                            }
                            .padding(.top, 8)
                        }
                    } header: {
                        HStack {
                            Image(systemName: "pencil")
                                .foregroundColor(.blue)
                            Text("Nome del Salvadanaio")
                        }
                    } footer: {
                        VStack(alignment: .leading, spacing: 4) {
                            if !relatedTransactions.isEmpty {
                                if hasChanges {
                                    Text("✅ Verranno aggiornate automaticamente \(relatedTransactions.count) transazioni associate")
                                        .foregroundColor(.green)
                                } else {
                                    Text("ℹ️ Ci sono \(relatedTransactions.count) transazioni associate a questo salvadanaio")
                                        .foregroundColor(.blue)
                                }
                            }
                            
                            // Messaggio di errore per duplicati
                            if isDuplicateName {
                                Text("⚠️ Questo nome è già utilizzato da un altro salvadanaio")
                                    .foregroundColor(.red)
                            }
                        }
                    }
                    
                    // Informazioni del salvadanaio
                    Section {
                        HStack {
                            Image(systemName: "calendar")
                                .foregroundColor(.secondary)
                                .frame(width: 24)
                            
                            Text("Data di creazione")
                            Spacer()
                            Text(salvadanaio.createdAt, style: .date)
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Image(systemName: "folder.fill")
                                .foregroundColor(getColor(from: salvadanaio.color))
                                .frame(width: 24)
                            
                            Text("Categoria")
                            Spacer()
                            Text(salvadanaio.category)
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Image(systemName: "paintbrush.fill")
                                .foregroundColor(getColor(from: salvadanaio.color))
                                .frame(width: 24)
                            
                            Text("Colore")
                            Spacer()
                            HStack {
                                Circle()
                                    .fill(getColor(from: salvadanaio.color))
                                    .frame(width: 16, height: 16)
                                Text(salvadanaio.color.capitalized)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        HStack {
                            Image(systemName: "list.bullet.circle")
                                .foregroundColor(.blue)
                                .frame(width: 24)
                            
                            Text("Transazioni associate")
                            Spacer()
                            Text("\(relatedTransactions.count)")
                                .foregroundColor(.blue)
                                .fontWeight(.semibold)
                        }
                        
                        if salvadanaio.type == "objective" && !salvadanaio.isInfinite {
                            HStack {
                                Image(systemName: "target")
                                    .foregroundColor(.purple)
                                    .frame(width: 24)
                                
                                Text("Obiettivo")
                                Spacer()
                                Text(salvadanaio.targetAmount.italianCurrency)
                                    .foregroundColor(.purple)
                                    .fontWeight(.semibold)
                            }
                            
                            if let targetDate = salvadanaio.targetDate {
                                HStack {
                                    Image(systemName: "calendar.badge.clock")
                                        .foregroundColor(.orange)
                                        .frame(width: 24)
                                    
                                    Text("Scadenza")
                                    Spacer()
                                    Text(targetDate, style: .date)
                                        .foregroundColor(.orange)
                                        .fontWeight(.medium)
                                }
                            }
                        } else if salvadanaio.type == "glass" {
                            HStack {
                                Image(systemName: "cup.and.saucer.fill")
                                    .foregroundColor(.cyan)
                                    .frame(width: 24)
                                
                                Text("Ricarica mensile")
                                Spacer()
                                Text(salvadanaio.monthlyRefill.italianCurrency)
                                    .foregroundColor(.cyan)
                                    .fontWeight(.semibold)
                            }
                        } else if salvadanaio.isInfinite {
                            HStack {
                                Image(systemName: "infinity")
                                    .foregroundColor(.mint)
                                    .frame(width: 24)
                                
                                Text("Tipo")
                                Spacer()
                                Text("Obiettivo Infinito")
                                    .foregroundColor(.mint)
                                    .fontWeight(.semibold)
                            }
                        }
                    } header: {
                        HStack {
                            Image(systemName: "info.circle.fill")
                                .foregroundColor(.purple)
                            Text("Informazioni")
                        }
                    }
                    
                    // Sezione di eliminazione (solo se non ci sono transazioni)
                    if relatedTransactions.isEmpty {
                        Section {
                            Button(action: {
                                showingDeleteAlert = true
                            }) {
                                HStack {
                                    Image(systemName: "trash.fill")
                                        .foregroundColor(.red)
                                        .frame(width: 24)
                                    
                                    Text("Elimina Salvadanaio")
                                        .foregroundColor(.red)
                                        .fontWeight(.medium)
                                    
                                    Spacer()
                                }
                            }
                        } header: {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.red)
                                Text("Zona Pericolosa")
                            }
                        } footer: {
                            Text("Eliminare il salvadanaio è un'azione irreversibile.")
                        }
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Modifica Salvadanaio")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Annulla") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Salva") {
                        saveChanges()
                    }
                    .disabled(!hasChanges || currentSalvadanaiName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isDuplicateName)
                    .fontWeight(.semibold)
                    .foregroundColor(hasChanges && !currentSalvadanaiName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isDuplicateName ? getColor(from: salvadanaio.color) : .secondary)
                }
            }
        }
        .alert("Elimina Salvadanaio", isPresented: $showingDeleteAlert) {
            Button("Elimina", role: .destructive) {
                dataManager.deleteSalvadanaio(salvadanaio)
                dismiss()
            }
            Button("Annulla", role: .cancel) { }
        } message: {
            Text("Sei sicuro di voler eliminare il salvadanaio '\(salvadanaio.name)'? Questa azione non può essere annullata.")
        }
    }
    
    private func saveChanges() {
        let newName = currentSalvadanaiName.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !newName.isEmpty else { return }
        guard newName != originalSalvadanaiName else { return }
        guard !isDuplicateName else { return }
        
        print("🚀 Avvio salvataggio modifiche salvadanaio")
        print("  - ID: \(salvadanaio.id)")
        print("  - Nome originale: '\(originalSalvadanaiName)'")
        print("  - Nuovo nome: '\(newName)'")
        
        // Chiama il metodo del DataManager per aggiornare tutto
        dataManager.updateSalvadanaiName(salvadanaio.id, oldName: originalSalvadanaiName, newName: newName)
        
        print("✅ Comando di aggiornamento inviato")
        
        dismiss()
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
                                Text(salvadanaio.currentAmount.italianCurrency)
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
            Text("\(transaction.type == "expense" ? "-" : "+")\(transaction.amount.italianCurrency)")
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
            Text("\(transaction.type == "expense" ? "-" : "+")\(transaction.amount.italianCurrency)")
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
                                
                                Text("\(salvadanaio.currentAmount.italianCurrency)")
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
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedName.isEmpty { return false }
        if selectedCategory.isEmpty { return false }
        if dataManager.salvadanai.contains { $0.name.lowercased() == trimmedName.lowercased() } { return false }
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
    @State private var showingEditSheet = false // NUOVO
    
    var relatedTransactions: [TransactionModel] {
        dataManager.transactions.filter {
            ($0.salvadanaiName == salvadanaio.name ||
             ($0.type == "transfer_salvadanai" && $0.accountName == salvadanaio.name)) &&
            $0.type != "distribution" // NUOVO: Esclude le distribuzioni
        }
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
                                    
                                    Text("\(transaction.type == "expense" ? "-" : "+")\(transaction.amount.italianCurrency)")
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
                        // NUOVO: Modifica nome
                        Button(action: {
                            showingEditSheet = true
                        }) {
                            Label("Modifica Nome", systemImage: "pencil")
                        }
                        .tint(.blue)
                        
                        Divider()
                        
                        Button(role: .destructive, action: {
                            showingDeleteAlert = true
                        }) {
                            Label("Elimina", systemImage: "trash")
                        }
                        .tint(.red)
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
            if relatedTransactions.isEmpty {
                Text("Sei sicuro di voler eliminare questo salvadanaio? Questa azione non può essere annullata.")
            } else {
                Text("Sei sicuro di voler eliminare questo salvadanaio?\n\nCi sono \(relatedTransactions.count) transazioni associate che verranno mantenute ma non saranno più collegate a questo salvadanaio.\n\nQuesta azione non può essere annullata.")
            }
        }
        // NUOVO: Sheet per modifica nome
        .sheet(isPresented: $showingEditSheet) {
            EditSalvadanaiNameView(salvadanaio: salvadanaio)
        }
    }
}

// MARK: - 3. NUOVA VISTA: BreakSalvadanaiView.swift
struct BreakSalvadanaiView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var dataManager: DataManager
    
    let salvadanaio: SalvadanaiModel
    @State private var selectedDestinations: Set<String> = []
    @State private var customAmounts: [String: Double] = [:]
    @State private var distributionMode: DistributionMode = .equal
    @State private var showingBreakAnimation = false
    @State private var isBreaking = false
    @State private var breakCompleted = false
    
    enum DistributionMode: String, CaseIterable {
        case equal = "Equa"
        case custom = "Personalizzata"
        
        var icon: String {
            switch self {
            case .equal: return "equal.circle.fill"
            case .custom: return "slider.horizontal.3"
            }
        }
        
        var description: String {
            switch self {
            case .equal: return "Dividi l'importo in parti uguali"
            case .custom: return "Specifica importi personalizzati"
            }
        }
    }
    
    private var availableDestinations: [SalvadanaiModel] {
        dataManager.getAvailableSalvadanaiForTransfer(excluding: salvadanaio)
    }
    
    private var totalToTransfer: Double {
        max(0, salvadanaio.currentAmount)
    }
    
    private var totalDistributed: Double {
        switch distributionMode {
        case .equal:
            return selectedDestinations.isEmpty ? 0 : totalToTransfer
        case .custom:
            return customAmounts.values.reduce(0, +)
        }
    }
    
    private var remainingAmount: Double {
        totalToTransfer - totalDistributed
    }
    
    private var canBreakDirectly: Bool {
        dataManager.canBreakSalvadanaiDirectly(salvadanaio)
    }
    
    private var isDistributionValid: Bool {
        if canBreakDirectly { return true }
        guard !selectedDestinations.isEmpty else { return false }
        return abs(remainingAmount) < 0.01
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
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [Color.orange.opacity(0.1), Color.red.opacity(0.1)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                if showingBreakAnimation {
                    BreakAnimationView(
                        salvadanaio: salvadanaio,
                        isBreaking: $isBreaking,
                        breakCompleted: $breakCompleted,
                        onAnimationComplete: {
                            dismiss()
                        }
                    )
                } else {
                    VStack(spacing: 0) {
                        // Header con info salvadanaio
                        BreakSalvadanaiHeaderView(
                            salvadanaio: salvadanaio,
                            totalToTransfer: totalToTransfer,
                            totalDistributed: totalDistributed,
                            remainingAmount: remainingAmount,
                            canBreakDirectly: canBreakDirectly
                        )
                        .padding(.horizontal)
                        .padding(.bottom, 16)
                        
                        if canBreakDirectly {
                            // Vista per rottura diretta (nessun saldo)
                            DirectBreakView(salvadanaio: salvadanaio)
                                .padding(.horizontal)
                        } else {
                            // Vista per distribuzione fondi
                            Form {
                                // Modalità di distribuzione
                                Section {
                                    ForEach(DistributionMode.allCases, id: \.self) { mode in
                                        BreakDistributionModeRow(
                                            mode: mode,
                                            isSelected: distributionMode == mode,
                                            action: {
                                                withAnimation(.spring()) {
                                                    distributionMode = mode
                                                }
                                            }
                                        )
                                    }
                                } header: {
                                    SectionHeader(icon: "gearshape.fill", title: "Come Distribuire i Soldi")
                                }
                                
                                // Lista salvadanai destinazione
                                if !availableDestinations.isEmpty {
                                    Section {
                                        ForEach(availableDestinations, id: \.id) { destination in
                                            BreakDestinationRow(
                                                destination: destination,
                                                isSelected: selectedDestinations.contains(destination.name),
                                                distributionMode: distributionMode,
                                                equalAmount: selectedDestinations.isEmpty ? 0 : totalToTransfer / Double(selectedDestinations.count),
                                                customAmount: Binding(
                                                    get: { customAmounts[destination.name] ?? 0 },
                                                    set: { customAmounts[destination.name] = $0 }
                                                ),
                                                onToggle: {
                                                    toggleDestination(destination.name)
                                                }
                                            )
                                        }
                                    } header: {
                                        SectionHeader(icon: "arrow.right.circle.fill", title: "Dove Spostare i Soldi")
                                    } footer: {
                                        if distributionMode == .custom && !selectedDestinations.isEmpty {
                                            BreakCustomDistributionFooterView(
                                                totalDistributed: totalDistributed,
                                                remainingAmount: remainingAmount,
                                                totalAmount: totalToTransfer
                                            )
                                        }
                                    }
                                } else {
                                    Section {
                                        HStack {
                                            Image(systemName: "exclamationmark.triangle.fill")
                                                .foregroundColor(.orange)
                                            Text("Nessun altro salvadanaio disponibile")
                                                .foregroundColor(.orange)
                                        }
                                        .padding(.vertical, 8)
                                    } footer: {
                                        Text("Non ci sono altri salvadanai dove trasferire i soldi. Crea almeno un altro salvadanaio prima di rompere questo.")
                                    }
                                }
                                
                                // Azioni rapide
                                if distributionMode == .custom && !selectedDestinations.isEmpty {
                                    Section {
                                        BreakQuickActionsView(
                                            selectedDestinations: selectedDestinations,
                                            totalAmount: totalToTransfer,
                                            customAmounts: $customAmounts
                                        )
                                    } header: {
                                        SectionHeader(icon: "bolt.fill", title: "Azioni Rapide")
                                    }
                                }
                            }
                            .scrollContentBackground(.hidden)
                        }
                    }
                }
            }
            .navigationTitle("💥 Rompi Salvadanaio")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Annulla") {
                        dismiss()
                    }
                    .disabled(isBreaking)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(canBreakDirectly ? "💥 Rompi" : "💥 Rompi e Trasferisci") {
                        startBreakProcess()
                    }
                    .disabled(!isDistributionValid || isBreaking)
                    .fontWeight(.bold)
                    .foregroundColor(isDistributionValid ? .red : .secondary)
                }
            }
        }
        .onAppear {
            setupInitialSelection()
        }
    }
    
    private func setupInitialSelection() {
        if !canBreakDirectly && availableDestinations.count <= 3 {
            selectedDestinations = Set(availableDestinations.map(\.name))
        }
    }
    
    private func toggleDestination(_ name: String) {
        if selectedDestinations.contains(name) {
            selectedDestinations.remove(name)
            customAmounts[name] = 0
        } else {
            selectedDestinations.insert(name)
            if distributionMode == .custom {
                customAmounts[name] = 0
            }
        }
    }
    
    private func startBreakProcess() {
        withAnimation(.easeInOut(duration: 0.5)) {
            showingBreakAnimation = true
            isBreaking = true
        }
        
        // Simula il processo di rottura con delay - Ottimizzato per l'animazione accelerata
        // L'animazione dura: 0.3s (primo colpo) + 1s + 2s + 0.4s (esplosione) + 1.8s (successo) = ~5.5s
        DispatchQueue.main.asyncAfter(deadline: .now() + 6.0) {
            performBreak()
        }
    }
    
    private func performBreak() {
        if canBreakDirectly {
            // Rottura diretta senza trasferimenti
            dataManager.breakSalvadanaio(salvadanaio)
        } else {
            // Rottura con trasferimenti
            let finalAmounts: [String: Double]
            
            switch distributionMode {
            case .equal:
                let perDestination = totalToTransfer / Double(selectedDestinations.count)
                finalAmounts = Dictionary(uniqueKeysWithValues: selectedDestinations.map { ($0, perDestination) })
            case .custom:
                finalAmounts = customAmounts.filter { selectedDestinations.contains($0.key) && $0.value > 0 }
            }
            
            dataManager.breakSalvadanaio(salvadanaio, transferredAmounts: finalAmounts)
        }
        
        // L'animazione ora è gestita internamente da BreakAnimationView
        // Non impostiamo più breakCompleted qui - viene gestito dall'animazione stessa
    }
}

// Header View
struct BreakSalvadanaiHeaderView: View {
    let salvadanaio: SalvadanaiModel
    let totalToTransfer: Double
    let totalDistributed: Double
    let remainingAmount: Double
    let canBreakDirectly: Bool
    
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
    
    var body: some View {
        VStack(spacing: 20) {
            // Salvadanaio da rompere
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: "hammer.fill")
                        .foregroundColor(.orange)
                    Text("Salvadanaio da Rompere")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.orange)
                    Spacer()
                }
                
                HStack(spacing: 16) {
                    Circle()
                        .fill(getColor(from: salvadanaio.color))
                        .frame(width: 20, height: 20)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(salvadanaio.name)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        Text(salvadanaio.category)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(salvadanaio.currentAmount.italianCurrency)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(salvadanaio.currentAmount >= 0 ? .primary : .red)
                        
                        if canBreakDirectly {
                            Text("Rottura diretta")
                                .font(.caption)
                                .foregroundColor(.green)
                                .fontWeight(.medium)
                        } else {
                            Text("Richiede trasferimento")
                                .font(.caption)
                                .foregroundColor(.orange)
                                .fontWeight(.medium)
                        }
                    }
                }
            }
            
            // Statistiche trasferimento (solo se necessario)
            if !canBreakDirectly {
                HStack(spacing: 20) {
                    BreakStatCard(
                        title: "Da Trasferire",
                        amount: totalToTransfer,
                        icon: "arrow.right.circle.fill",
                        color: .orange
                    )
                    
                    BreakStatCard(
                        title: "Distribuito",
                        amount: totalDistributed,
                        icon: "checkmark.circle.fill",
                        color: .green
                    )
                    
                    BreakStatCard(
                        title: "Rimanente",
                        amount: remainingAmount,
                        icon: remainingAmount > 0.01 ? "exclamationmark.circle.fill" : "checkmark.circle.fill",
                        color: remainingAmount > 0.01 ? .red : .green
                    )
                }
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.1), radius: 15, x: 0, y: 8)
        )
    }
}

// Stat Card
struct BreakStatCard: View {
    let title: String
    let amount: Double
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
            
            Text(amount.italianCurrency)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.primary)
                .minimumScaleFactor(0.8)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
}

// Vista per rottura diretta
struct DirectBreakView: View {
    let salvadanaio: SalvadanaiModel
    @State private var animateIcon = false
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // Icona animata
            ZStack {
                Circle()
                    .fill(Color.orange.opacity(0.2))
                    .frame(width: 120, height: 120)
                    .scaleEffect(animateIcon ? 1.1 : 1.0)
                    .animation(.easeInOut(duration: 1.5).repeatForever(), value: animateIcon)
                
                Image(systemName: "hammer.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.orange)
                    .rotationEffect(.degrees(animateIcon ? 5 : -5))
                    .animation(.easeInOut(duration: 1).repeatForever(autoreverses: true), value: animateIcon)
            }
            
            VStack(spacing: 16) {
                Text("Pronto per la Rottura! 💥")
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                Text(salvadanaio.currentAmount <= 0 ?
                     "Il salvadanaio non contiene soldi e può essere rotto immediatamente." :
                     "Il salvadanaio ha un saldo negativo e può essere rotto immediatamente.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                    Text("Attenzione")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.red)
                }
                
                Text("Rompere il salvadanaio eliminerà definitivamente:\n• Il salvadanaio stesso\n• Tutte le transazioni associate\n\nQuesta azione non può essere annullata!")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.red.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.red.opacity(0.3), lineWidth: 1)
                    )
            )
            
            Spacer()
        }
        .onAppear {
            animateIcon = true
        }
    }
}

// Distribution Mode Row
struct BreakDistributionModeRow: View {
    let mode: BreakSalvadanaiView.DistributionMode
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(isSelected ?
                              LinearGradient(gradient: Gradient(colors: [.orange, .red]), startPoint: .topLeading, endPoint: .bottomTrailing) :
                              LinearGradient(gradient: Gradient(colors: [Color.gray.opacity(0.1)]), startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                        .frame(width: 44, height: 44)
                        .shadow(color: isSelected ? .orange.opacity(0.3) : .clear, radius: 6, x: 0, y: 3)
                    
                    Image(systemName: mode.icon)
                        .font(.title3)
                        .foregroundColor(isSelected ? .white : .secondary)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(mode.rawValue)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(isSelected ? .orange : .primary)
                    
                    Text(mode.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.orange)
                }
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(PlainButtonStyle())
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isSelected)
    }
}

// Destination Row
struct BreakDestinationRow: View {
    let destination: SalvadanaiModel
    let isSelected: Bool
    let distributionMode: BreakSalvadanaiView.DistributionMode
    let equalAmount: Double
    @Binding var customAmount: Double
    let onToggle: () -> Void
    
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
    
    private var displayAmount: Double {
        switch distributionMode {
        case .equal:
            return isSelected ? equalAmount : 0
        case .custom:
            return customAmount
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 16) {
                // Checkbox
                Button(action: onToggle) {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.title2)
                        .foregroundColor(isSelected ? .orange : .secondary)
                }
                .buttonStyle(PlainButtonStyle())
                
                // Icona salvadanaio
                Circle()
                    .fill(getColor(from: destination.color))
                    .frame(width: 12, height: 12)
                
                // Info salvadanaio
                VStack(alignment: .leading, spacing: 4) {
                    Text(destination.name)
                        .font(.headline)
                        .fontWeight(.medium)
                        .foregroundColor(isSelected ? .primary : .secondary)
                    
                    HStack {
                        Text("Attuale: \(destination.currentAmount.italianCurrency)")
                            .font(.caption)
                            .foregroundColor(destination.currentAmount >= 0 ? .green : .red)
                        
                        Text("• \(destination.category)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Campo importo per distribuzione personalizzata
                if distributionMode == .custom && isSelected {
                    HStack {
                        Text("+")
                            .font(.subheadline)
                            .foregroundColor(.green)
                        
                        TextField("0", value: $customAmount, format: .currency(code: "EUR"))
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(width: 80)
                            .keyboardType(.decimalPad)
                    }
                } else if isSelected && displayAmount > 0 {
                    // Mostra importo per modalità equa
                    Text("+\(displayAmount.italianCurrency)")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.green)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(Color.green.opacity(0.1))
                        )
                }
            }
            .padding(.vertical, 12)
            
            // Anteprima saldo dopo trasferimento
            if isSelected && displayAmount > 0 {
                VStack(alignment: .leading, spacing: 4) {
                    Divider()
                        .padding(.leading, 60)
                    
                    HStack {
                        Spacer()
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("Nuovo saldo: \((destination.currentAmount + displayAmount).italianCurrency)")
                                .font(.caption2)
                                .foregroundColor(.green)
                                .fontWeight(.medium)
                        }
                    }
                    .padding(.leading, 60)
                    .padding(.bottom, 8)
                }
            }
        }
    }
}

// Custom Distribution Footer
struct BreakCustomDistributionFooterView: View {
    let totalDistributed: Double
    let remainingAmount: Double
    let totalAmount: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Distribuito: \(totalDistributed.italianCurrency)")
                    .font(.caption)
                    .foregroundColor(.green)
                
                Spacer()
                
                Text("Rimanente: \(remainingAmount.italianCurrency)")
                    .font(.caption)
                    .foregroundColor(remainingAmount > 0.01 ? .orange : .green)
                    .fontWeight(.medium)
            }
            
            if abs(remainingAmount) > 0.01 {
                Text("⚠️ Distribuzione incompleta. Assicurati che tutto l'importo sia distribuito.")
                    .font(.caption2)
                    .foregroundColor(.orange)
            } else {
                Text("✅ Distribuzione completa! Pronto per rompere il salvadanaio.")
                    .font(.caption2)
                    .foregroundColor(.green)
            }
        }
    }
}

// Quick Actions
struct BreakQuickActionsView: View {
    let selectedDestinations: Set<String>
    let totalAmount: Double
    @Binding var customAmounts: [String: Double]
    
    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                // Distribuzione equa
                Button(action: {
                    let equalAmount = totalAmount / Double(selectedDestinations.count)
                    for name in selectedDestinations {
                        customAmounts[name] = equalAmount
                    }
                }) {
                    HStack {
                        Image(systemName: "equal.circle.fill")
                        Text("Equa")
                            .font(.caption)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.orange.opacity(0.1))
                    .foregroundColor(.orange)
                    .clipShape(Capsule())
                }
                
                // Reset
                Button(action: {
                    for name in selectedDestinations {
                        customAmounts[name] = 0
                    }
                }) {
                    HStack {
                        Image(systemName: "arrow.counterclockwise.circle.fill")
                        Text("Reset")
                            .font(.caption)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.red.opacity(0.1))
                    .foregroundColor(.red)
                    .clipShape(Capsule())
                }
                
                Spacer()
            }
        }
    }
}

// MARK: - 5. ANIMAZIONE ROTTURA SALVADANAIO MIGLIORATA
struct BreakAnimationView: View {
    let salvadanaio: SalvadanaiModel
    @Binding var isBreaking: Bool
    @Binding var breakCompleted: Bool
    let onAnimationComplete: () -> Void
    
    // Stati per l'animazione del martello
    @State private var hammerRotation: Double = -45
    @State private var hammerOffset: CGPoint = CGPoint(x: -120, y: -120)
    @State private var hammerScale: Double = 1.0
    @State private var isHammerMoving = false
    
    // Stati per il salvadanaio
    @State private var salvadanaiScale: Double = 1.0
    @State private var salvadanaiOpacity: Double = 1.0
    @State private var salvadanaiRotation: Double = 0
    @State private var salvadanaiOffset: CGPoint = .zero
    
    // Stati per le crepe progressive
    @State private var crackPhase1Opacity: Double = 0.0
    @State private var crackPhase2Opacity: Double = 0.0
    @State private var crackPhase3Opacity: Double = 0.0
    @State private var crackPhase4Opacity: Double = 0.0
    
    // Stati per l'esplosione e particelle
    @State private var explosionScale: Double = 0.0
    @State private var particlesOpacity: Double = 0.0
    @State private var fragmentsOpacity: Double = 0.0
    @State private var coinsOpacity: Double = 0.0
    @State private var dustOpacity: Double = 0.0
    @State private var flashOpacity: Double = 0.0
    
    // Altri stati
    @State private var showSuccessMessage = false
    @State private var impactCount = 0
    @State private var screenShake: Double = 0
    
    var body: some View {
        ZStack {
            // Background
            Color.black.opacity(0.9)
                .ignoresSafeArea()
            
            // Flash di luce bianca per l'impatto finale
            Rectangle()
                .fill(Color.white)
                .opacity(flashOpacity)
                .ignoresSafeArea()
            
            VStack(spacing: 40) {
                Spacer()
                
                // Area di animazione principale
                ZStack {
                    // Effetti particellari
                    ParticleEffectsView(
                        salvadanaio: salvadanaio,
                        explosionScale: explosionScale,
                        particlesOpacity: particlesOpacity,
                        fragmentsOpacity: fragmentsOpacity,
                        coinsOpacity: coinsOpacity,
                        dustOpacity: dustOpacity
                    )
                    
                    // Salvadanaio con crepe
                    PiggyBankView(
                        salvadanaio: salvadanaio,
                        salvadanaiScale: salvadanaiScale,
                        salvadanaiOpacity: salvadanaiOpacity,
                        salvadanaiRotation: salvadanaiRotation,
                        salvadanaiOffset: salvadanaiOffset,
                        crackPhase1Opacity: crackPhase1Opacity,
                        crackPhase2Opacity: crackPhase2Opacity,
                        crackPhase3Opacity: crackPhase3Opacity,
                        crackPhase4Opacity: crackPhase4Opacity
                    )
                    
                    // Martello
                    HammerView(
                        rotation: hammerRotation,
                        offset: hammerOffset,
                        scale: hammerScale
                    )
                }
                .frame(width: 350, height: 350)
                .offset(x: screenShake, y: 0)
                
                // Messaggio di stato
                StatusMessageView(
                    breakCompleted: breakCompleted,
                    showSuccessMessage: showSuccessMessage,
                    impactCount: impactCount,
                    salvadanaiName: salvadanaio.name
                )
                
                Spacer()
            }
        }
        .onAppear {
            startEnhancedBreakAnimation()
        }
        .onChange(of: breakCompleted) { completed in
            // breakCompleted ora viene gestito internamente dall'animazione
            // Non serve più chiamare showEnhancedSuccessAnimation() qui
        }
    }
    
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
    
    private func startEnhancedBreakAnimation() {
        // FASE 1: Primo colpo del martello (più veloce)
        performHammerStrike(delay: 0.3, intensity: 0.3) {
            impactCount = 1
            // Prime crepe sottili
            withAnimation(.easeIn(duration: 0.15)) {
                crackPhase1Opacity = 1.0
            }
            
            // Leggero tremolio
            withAnimation(.easeInOut(duration: 0.08).repeatCount(3, autoreverses: true)) {
                salvadanaiScale = 1.05
                screenShake = 2
            }
        }
        
        // FASE 2: Secondo colpo più forte (ridotto da 2.0s a 1.0s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            performHammerStrike(delay: 0.0, intensity: 0.6) {
                impactCount = 2
                // Crepe più profonde
                withAnimation(.easeIn(duration: 0.2)) {
                    crackPhase2Opacity = 1.0
                }
                
                // Tremolio più intenso
                withAnimation(.easeInOut(duration: 0.06).repeatCount(5, autoreverses: true)) {
                    salvadanaiScale = 1.1
                    salvadanaiRotation = 3
                    screenShake = 5
                }
                
                // Haptic feedback medio
                let impactMedium = UIImpactFeedbackGenerator(style: .medium)
                impactMedium.impactOccurred()
            }
        }
        
        // FASE 3: Terzo colpo finale e devastante (ridotto da 4.0s a 2.0s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            performHammerStrike(delay: 0.0, intensity: 1.0) {
                impactCount = 3
                // Tutte le crepe
                withAnimation(.easeIn(duration: 0.1)) {
                    crackPhase3Opacity = 1.0
                }
                
                withAnimation(.easeIn(duration: 0.15).delay(0.05)) {
                    crackPhase4Opacity = 1.0
                }
                
                // Tremolio finale intenso
                withAnimation(.easeInOut(duration: 0.04).repeatCount(8, autoreverses: true)) {
                    salvadanaiScale = 1.15
                    salvadanaiRotation = 8
                    screenShake = 10
                }
                
                // Haptic feedback forte
                let impactHeavy = UIImpactFeedbackGenerator(style: .heavy)
                impactHeavy.impactOccurred()
                
                // Avvia esplosione dopo una pausa più breve (ridotto da 0.8s a 0.4s)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    triggerFinalExplosion()
                    
                    // Imposta breakCompleted per far sapere al sistema esterno che l'animazione è finita (ridotto da 1.5s a 0.8s)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                        breakCompleted = true
                    }
                }
            }
        }
    }
    
    private func performHammerStrike(delay: Double, intensity: Double, completion: @escaping () -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            // Movimento del martello dall'alto (più veloce)
            withAnimation(.easeIn(duration: 0.2)) {
                hammerOffset = CGPoint(x: -40, y: -40)
                hammerRotation = -10
                hammerScale = 1.2
            }
            
            // Impatto (ridotto da 0.3s a 0.2s)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                // Flash di impatto
                withAnimation(.easeOut(duration: 0.08)) {
                    flashOpacity = intensity * 0.3
                }
                withAnimation(.easeOut(duration: 0.15).delay(0.08)) {
                    flashOpacity = 0
                }
                
                // Rimbalzo del martello (più veloce)
                withAnimation(.easeOut(duration: 0.25)) {
                    hammerOffset = CGPoint(x: -120, y: -120)
                    hammerRotation = -45
                    hammerScale = 1.0
                }
                
                completion()
                
                // Haptic feedback leggero
                let impactLight = UIImpactFeedbackGenerator(style: .light)
                impactLight.impactOccurred()
            }
        }
    }
    
    private func triggerFinalExplosion() {
        // Flash finale intenso
        withAnimation(.easeOut(duration: 0.1)) {
            flashOpacity = 0.8
        }
        withAnimation(.easeOut(duration: 0.3).delay(0.1)) {
            flashOpacity = 0
        }
        
        // Esplosione del salvadanaio
        withAnimation(.easeOut(duration: 0.6)) {
            salvadanaiOpacity = 0.0
            explosionScale = 1.0
            particlesOpacity = 1.0
            fragmentsOpacity = 1.0
            coinsOpacity = 1.0
            dustOpacity = 0.8
        }
        
        // Haptic feedback esplosivo
        let impactHeavy = UIImpactFeedbackGenerator(style: .heavy)
        impactHeavy.impactOccurred()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            let impactHeavy2 = UIImpactFeedbackGenerator(style: .heavy)
            impactHeavy2.impactOccurred()
        }
        
        // Avvia la sequenza di successo
        showEnhancedSuccessAnimation()
    }
    
    private func showEnhancedSuccessAnimation() {
        // Particelle si espandono e svaniscono (più veloce)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.easeOut(duration: 0.8)) {
                particlesOpacity = 0.0
                fragmentsOpacity = 0.0
                explosionScale = 2.5
            }
            
            withAnimation(.easeOut(duration: 1.0)) {
                coinsOpacity = 0.0
                dustOpacity = 0.0
            }
        }
        
        // Mostra messaggio di successo (più veloce)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                showSuccessMessage = true
            }
        }
        
        // Reset shake screen (più veloce)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.easeOut(duration: 0.3)) {
                screenShake = 0
            }
        }
        
        // Chiudi la vista (ridotto da 3.5s a 1.8s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
            onAnimationComplete()
        }
    }
}

// MARK: - Componenti Separati per Evitare Errori di Compilazione

struct ParticleEffectsView: View {
    let salvadanaio: SalvadanaiModel
    let explosionScale: Double
    let particlesOpacity: Double
    let fragmentsOpacity: Double
    let coinsOpacity: Double
    let dustOpacity: Double
    
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
    
    var body: some View {
        ZStack {
            // Nuvola di polvere
            DustCloudView(dustOpacity: dustOpacity, explosionScale: explosionScale)
            
            // Frammenti del salvadanaio
            FragmentsView(
                color: getColor(from: salvadanaio.color),
                fragmentsOpacity: fragmentsOpacity,
                explosionScale: explosionScale
            )
            
            // Monete che volano via
            CoinsView(coinsOpacity: coinsOpacity, explosionScale: explosionScale)
            
            // Particelle esplosive principali
            ExplosionParticlesView(
                color: getColor(from: salvadanaio.color),
                particlesOpacity: particlesOpacity,
                explosionScale: explosionScale
            )
        }
    }
}

struct DustCloudView: View {
    let dustOpacity: Double
    let explosionScale: Double
    
    var body: some View {
        ForEach(0..<6, id: \.self) { index in
            Circle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: CGFloat.random(in: 30...60), height: CGFloat.random(in: 30...60))
                .offset(
                    x: CGFloat.random(in: -80...80),
                    y: CGFloat.random(in: -40...40)
                )
                .opacity(dustOpacity)
                .blur(radius: 8)
                .scaleEffect(explosionScale * 1.5)
        }
    }
}

struct FragmentsView: View {
    let color: Color
    let fragmentsOpacity: Double
    let explosionScale: Double
    
    var body: some View {
        ForEach(0..<12, id: \.self) { index in
            let angle = Double(index) * .pi / 6
            RoundedRectangle(cornerRadius: 3)
                .fill(color.opacity(0.8))
                .frame(
                    width: CGFloat.random(in: 8...20),
                    height: CGFloat.random(in: 15...35)
                )
                .rotationEffect(.degrees(Double.random(in: 0...360)))
                .offset(
                    x: cos(angle) * explosionScale * 120,
                    y: sin(angle) * explosionScale * 120
                )
                .opacity(fragmentsOpacity)
                .scaleEffect(explosionScale)
        }
    }
}

struct CoinsView: View {
    let coinsOpacity: Double
    let explosionScale: Double
    
    var body: some View {
        ForEach(0..<8, id: \.self) { index in
            let angle = Double(index) * .pi / 4
            Image(systemName: "eurosign.circle.fill")
                .font(.title2)
                .foregroundColor(.yellow)
                .rotationEffect(.degrees(Double(index) * 45 + explosionScale * 180))
                .offset(
                    x: cos(angle) * explosionScale * 100,
                    y: sin(angle) * explosionScale * 80 + explosionScale * 50
                )
                .opacity(coinsOpacity)
                .scaleEffect(0.8 + explosionScale * 0.4)
        }
    }
}

struct ExplosionParticlesView: View {
    let color: Color
    let particlesOpacity: Double
    let explosionScale: Double
    
    var body: some View {
        ForEach(0..<16, id: \.self) { index in
            let angle = Double(index) * .pi / 8
            Circle()
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            color,
                            color.opacity(0.3)
                        ]),
                        startPoint: .center,
                        endPoint: .trailing
                    )
                )
                .frame(width: CGFloat.random(in: 8...16), height: CGFloat.random(in: 8...16))
                .offset(
                    x: cos(angle) * explosionScale * 140,
                    y: sin(angle) * explosionScale * 140
                )
                .opacity(particlesOpacity)
                .scaleEffect(explosionScale * 0.5)
        }
    }
}

struct PiggyBankView: View {
    let salvadanaio: SalvadanaiModel
    let salvadanaiScale: Double
    let salvadanaiOpacity: Double
    let salvadanaiRotation: Double
    let salvadanaiOffset: CGPoint
    let crackPhase1Opacity: Double
    let crackPhase2Opacity: Double
    let crackPhase3Opacity: Double
    let crackPhase4Opacity: Double
    
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
    
    var body: some View {
        ZStack {
            // Ombra del salvadanaio
            Circle()
                .fill(Color.black.opacity(0.3))
                .frame(width: 130, height: 130)
                .offset(x: 5, y: 5)
                .scaleEffect(salvadanaiScale * 0.95)
                .opacity(salvadanaiOpacity * 0.5)
            
            // Corpo principale del salvadanaio
            Circle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: [
                            getColor(from: salvadanaio.color).opacity(0.9),
                            getColor(from: salvadanaio.color),
                            getColor(from: salvadanaio.color).opacity(0.7)
                        ]),
                        center: .topLeading,
                        startRadius: 20,
                        endRadius: 80
                    )
                )
                            .frame(width: 120, height: 120)
            .scaleEffect(salvadanaiScale)
            .opacity(salvadanaiOpacity)
            .rotationEffect(.degrees(salvadanaiRotation))
            .offset(x: salvadanaiOffset.x, y: salvadanaiOffset.y)
            
            // Icona salvadanaio
            Image(systemName: "banknote.fill")
                .font(.system(size: 40))
                .foregroundColor(.white)
                            .scaleEffect(salvadanaiScale)
            .opacity(salvadanaiOpacity)
            .rotationEffect(.degrees(salvadanaiRotation))
            .offset(x: salvadanaiOffset.x, y: salvadanaiOffset.y)
            .shadow(color: .black.opacity(0.3), radius: 2, x: 1, y: 1)
            
            // Sistema di crepe progressive
            CracksView(
                crackPhase1Opacity: crackPhase1Opacity,
                crackPhase2Opacity: crackPhase2Opacity,
                crackPhase3Opacity: crackPhase3Opacity,
                crackPhase4Opacity: crackPhase4Opacity,
                salvadanaiScale: salvadanaiScale,
                salvadanaiOpacity: salvadanaiOpacity,
                salvadanaiRotation: salvadanaiRotation,
                salvadanaiOffset: salvadanaiOffset
            )
        }
    }
}

struct CracksView: View {
    let crackPhase1Opacity: Double
    let crackPhase2Opacity: Double
    let crackPhase3Opacity: Double
    let crackPhase4Opacity: Double
    let salvadanaiScale: Double
    let salvadanaiOpacity: Double
    let salvadanaiRotation: Double
    let salvadanaiOffset: CGPoint
    
    var body: some View {
        ZStack {
            // Fase 1: Prime crepe sottili
            Group {
                Rectangle()
                    .fill(Color.black.opacity(0.8))
                    .frame(width: 1.5, height: 60)
                    .rotationEffect(.degrees(45))
                
                Rectangle()
                    .fill(Color.black.opacity(0.8))
                    .frame(width: 1.5, height: 40)
                    .rotationEffect(.degrees(-30))
            }
            .opacity(crackPhase1Opacity)
            
            // Fase 2: Crepe più profonde
            Group {
                Rectangle()
                    .fill(Color.black.opacity(0.9))
                    .frame(width: 2.5, height: 80)
                    .rotationEffect(.degrees(45))
                
                Rectangle()
                    .fill(Color.black.opacity(0.9))
                    .frame(width: 2.5, height: 55)
                    .rotationEffect(.degrees(-30))
                
                Rectangle()
                    .fill(Color.black.opacity(0.9))
                    .frame(width: 2, height: 50)
                    .rotationEffect(.degrees(120))
            }
            .opacity(crackPhase2Opacity)
            
            // Fase 3: Crepe che si estendono
            Group {
                Rectangle()
                    .fill(Color.black)
                    .frame(width: 3, height: 100)
                    .rotationEffect(.degrees(45))
                
                Rectangle()
                    .fill(Color.black)
                    .frame(width: 3, height: 75)
                    .rotationEffect(.degrees(-30))
                
                Rectangle()
                    .fill(Color.black)
                    .frame(width: 2.5, height: 70)
                    .rotationEffect(.degrees(120))
                
                Rectangle()
                    .fill(Color.black)
                    .frame(width: 2, height: 60)
                    .rotationEffect(.degrees(0))
            }
            .opacity(crackPhase3Opacity)
            
            // Fase 4: Crepe finali prima della rottura
            Group {
                Rectangle()
                    .fill(Color.black)
                    .frame(width: 4, height: 120)
                    .rotationEffect(.degrees(45))
                
                Rectangle()
                    .fill(Color.black)
                    .frame(width: 4, height: 95)
                    .rotationEffect(.degrees(-30))
                
                Rectangle()
                    .fill(Color.black)
                    .frame(width: 3.5, height: 90)
                    .rotationEffect(.degrees(120))
                
                Rectangle()
                    .fill(Color.black)
                    .frame(width: 3, height: 80)
                    .rotationEffect(.degrees(0))
                
                Rectangle()
                    .fill(Color.black)
                    .frame(width: 2.5, height: 70)
                    .rotationEffect(.degrees(75))
            }
            .opacity(crackPhase4Opacity)
        }
        .scaleEffect(salvadanaiScale)
        .opacity(salvadanaiOpacity)
        .rotationEffect(.degrees(salvadanaiRotation))
        .offset(x: salvadanaiOffset.x, y: salvadanaiOffset.y)
    }
}

struct HammerView: View {
    let rotation: Double
    let offset: CGPoint
    let scale: Double
    
    var body: some View {
        Image(systemName: "hammer.fill")
            .font(.system(size: 70))
            .foregroundColor(.orange)
                    .rotationEffect(.degrees(rotation))
        .scaleEffect(scale)
        .offset(x: offset.x, y: offset.y)
        .shadow(color: .orange.opacity(0.5), radius: 10, x: 5, y: 5)
    }
}

struct StatusMessageView: View {
    let breakCompleted: Bool
    let showSuccessMessage: Bool
    let impactCount: Int
    let salvadanaiName: String
    
    var body: some View {
        VStack(spacing: 16) {
            if breakCompleted {
                Text("💥 Salvadanaio Rotto!")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .opacity(showSuccessMessage ? 1.0 : 0.0)
                    .scaleEffect(showSuccessMessage ? 1.0 : 0.8)
                
                Text("Il salvadanaio '\(salvadanaiName)' è stato eliminato definitivamente")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .opacity(showSuccessMessage ? 1.0 : 0.0)
            } else {
                VStack(spacing: 8) {
                    Text("Rompendo il salvadanaio...")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                }
                
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.5)
            }
        }
    }
}
