import SwiftUI

// MARK: - SalvadanaiView completamente riscritta
struct SalvadanaiView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var showingAddSalvadanaio = false
    @State private var selectedSalvadanaio: SalvadanaiModel?
    @State private var searchText = ""
    
    var filteredSalvadanai: [SalvadanaiModel] {
        if searchText.isEmpty {
            return dataManager.salvadanai
        } else {
            return dataManager.salvadanai.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
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
                            // Header con statistiche (MODIFICATO - rimosso totale risparmiato)
                            CompactSalvadanaiStatsView(salvadanai: dataManager.salvadanai)
                                .padding(.horizontal)
                                .padding(.bottom, 16)
                            
                            // Lista salvadanai
                            ScrollView {
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

// MARK: - Improved Salvadanai Stats Header (COMPATTO CON ICONA CORRETTA)
struct SalvadanaiStatsView: View {
    let salvadanai: [SalvadanaiModel]
    
    private var completedGoals: Int {
        salvadanai.filter { salvadanaio in
            if salvadanaio.type == "objective" && !salvadanaio.isInfinite {
                return salvadanaio.currentAmount >= salvadanaio.targetAmount
            } else if salvadanaio.type == "glass" {
                return salvadanaio.currentAmount >= salvadanaio.monthlyRefill
            }
            return false
        }.count
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Header titolo più compatto
            HStack(spacing: 12) {
                // Icona salvadanai corretta
                ZStack {
                    Circle()
                        .fill(LinearGradient(
                            gradient: Gradient(colors: [Color.green, Color.green.opacity(0.8)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 36, height: 36)
                        .shadow(color: .green.opacity(0.3), radius: 6, x: 0, y: 3)
                    
                    Image(systemName: "dollarsign.circle.fill")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                }
                
                Text("I Tuoi Salvadanai")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Spacer()
            }
            
            // Statistiche compatte
            HStack(spacing: 16) {
                // Salvadanai totali con icona corretta
                VStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(Color.green.opacity(0.15))
                            .frame(width: 48, height: 48)
                        
                        Image(systemName: "dollarsign.circle.fill")
                            .font(.title2)
                            .foregroundColor(.green)
                    }
                    
                    VStack(spacing: 2) {
                        Text("\(salvadanai.count)")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        Text("Salvadanai")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity)
                
                // Completati
                VStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(Color.blue.opacity(0.15))
                            .frame(width: 48, height: 48)
                        
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.blue)
                    }
                    
                    VStack(spacing: 2) {
                        Text("\(completedGoals)")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        Text("Completati")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity)
                
                // In corso
                VStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(Color.orange.opacity(0.15))
                            .frame(width: 48, height: 48)
                        
                        Image(systemName: "clock.circle.fill")
                            .font(.title2)
                            .foregroundColor(.orange)
                    }
                    
                    VStack(spacing: 2) {
                        Text("\(salvadanai.count - completedGoals)")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        Text("In corso")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 6)
        )
    }
}

// MARK: - Versione alternativa ancora più compatta
struct CompactSalvadanaiStatsView: View {
    let salvadanai: [SalvadanaiModel]
    
    private var completedGoals: Int {
        salvadanai.filter { salvadanaio in
            if salvadanaio.type == "objective" && !salvadanaio.isInfinite {
                return salvadanaio.currentAmount >= salvadanaio.targetAmount
            } else if salvadanaio.type == "glass" {
                return salvadanaio.currentAmount >= salvadanaio.monthlyRefill
            }
            return false
        }.count
    }
    
    var body: some View {
        VStack(spacing: 12) {
            // Header super compatto
            HStack(spacing: 10) {
                Image(systemName: "dollarsign.circle.fill")
                    .font(.title3)
                    .foregroundColor(.green)
                
                Text("I Tuoi Salvadanai")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Spacer()
            }
            
            // Statistiche in riga orizzontale compatta
            HStack(spacing: 20) {
                // Totali
                HStack(spacing: 8) {
                    Image(systemName: "dollarsign.circle.fill")
                        .font(.subheadline)
                        .foregroundColor(.green)
                        .frame(width: 20, height: 20)
                    
                    VStack(alignment: .leading, spacing: 1) {
                        Text("\(salvadanai.count)")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        Text("Totali")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                
                Divider()
                    .frame(height: 30)
                
                // Completati
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                        .frame(width: 20, height: 20)
                    
                    VStack(alignment: .leading, spacing: 1) {
                        Text("\(completedGoals)")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        Text("Fatti")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                
                Divider()
                    .frame(height: 30)
                
                // In corso
                HStack(spacing: 8) {
                    Image(systemName: "clock.circle.fill")
                        .font(.subheadline)
                        .foregroundColor(.orange)
                        .frame(width: 20, height: 20)
                    
                    VStack(alignment: .leading, spacing: 1) {
                        Text("\(salvadanai.count - completedGoals)")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        Text("In corso")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
        )
    }
}

// MARK: - Stat View
struct StatView: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Sostituisci SalvadanaiCardView nel file SalvadanaiView.swift
struct SalvadanaiCardView: View {
    let salvadanaio: SalvadanaiModel
    @EnvironmentObject var dataManager: DataManager
    @State private var animateProgress = false
    @State private var animateGlow = false
    @State private var animateFloating = false
    @State private var showDetails = false
    @State private var showTransactionsSheet = false
    
    private var progress: Double {
        if salvadanaio.type == "objective" && !salvadanaio.isInfinite {
            guard salvadanaio.targetAmount > 0 else { return 0 }
            if salvadanaio.currentAmount < 0 { return 0 }
            return min(salvadanaio.currentAmount / salvadanaio.targetAmount, 1.0)
        } else if salvadanaio.type == "glass" {
            guard salvadanaio.monthlyRefill > 0 else { return 0 }
            if salvadanaio.currentAmount < 0 { return 0 }
            return min(salvadanaio.currentAmount / salvadanaio.monthlyRefill, 1.0)
        }
        return 0
    }
    
    // Transazioni associate a questo salvadanaio
    private var relatedTransactions: [TransactionModel] {
        dataManager.transactions.filter { transaction in
            transaction.salvadanaiName == salvadanaio.name
        }.sorted { $0.date > $1.date }
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
    
    // Status dell'obiettivo
    private var statusInfo: (String, Color, String) {
        if salvadanaio.currentAmount < 0 {
            return ("In Rosso", .red, "exclamationmark.triangle.fill")
        } else if progress >= 1.0 && !salvadanaio.isInfinite {
            return ("Completato!", .green, "checkmark.seal.fill")
        } else if progress >= 0.8 && !salvadanaio.isInfinite {
            return ("Quasi fatto!", .orange, "flame.fill")
        } else if salvadanaio.isInfinite {
            return ("Infinito", getColor(from: salvadanaio.color), "infinity")
        } else {
            return ("In corso", getColor(from: salvadanaio.color), "arrow.up.circle.fill")
        }
    }
    
    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                showDetails.toggle()
            }
        }) {
            VStack(spacing: 0) {
                // Header compatto con gradiente colorato
                ZStack {
                    // Background gradiente animato
                    LinearGradient(
                        gradient: Gradient(colors: [
                            getColor(from: salvadanaio.color),
                            getColor(from: salvadanaio.color).opacity(0.7)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .frame(height: 70)
                    .overlay(
                        // Effetto shimmer animato
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.clear,
                                Color.white.opacity(animateGlow ? 0.3 : 0.1),
                                Color.clear
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: animateGlow)
                    )
                    
                    HStack(spacing: 12) {
                        // Icona tipo animata con floating effect
                        ZStack {
                            Circle()
                                .fill(Color.white.opacity(0.25))
                                .frame(width: 44, height: 44)
                                .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                            
                            Image(systemName: salvadanaio.type == "objective" ? (salvadanaio.isInfinite ? "infinity" : "target") : "cup.and.saucer.fill")
                                .font(.title2)
                                .foregroundColor(.white)
                                .fontWeight(.semibold)
                        }
                        .scaleEffect(animateFloating ? 1.1 : 1.0)
                        .animation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true), value: animateFloating)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(salvadanaio.name)
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .lineLimit(1)
                            
                            Text(salvadanaio.type == "objective" ? (salvadanaio.isInfinite ? "Obiettivo Infinito" : "Obiettivo") : "Glass Mensile")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.9))
                                .fontWeight(.medium)
                        }
                        
                        Spacer()
                        
                        // Status badge animato
                        VStack(spacing: 2) {
                            Image(systemName: statusInfo.2)
                                .font(.subheadline)
                                .foregroundColor(.white)
                            
                            Text(statusInfo.0)
                                .font(.caption2)
                                .foregroundColor(.white.opacity(0.9))
                                .fontWeight(.medium)
                        }
                        .scaleEffect(statusInfo.0 == "Completato!" ? (animateFloating ? 1.2 : 1.0) : 1.0)
                        .animation(.spring(response: 0.6, dampingFraction: 0.5).repeatForever(autoreverses: true), value: animateFloating)
                    }
                    .padding(.horizontal, 16)
                }
                
                // Body con informazioni compatte
                VStack(spacing: 12) {
                    // Importo principale con animazione numerica
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Saldo Attuale")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .fontWeight(.medium)
                            
                            HStack(alignment: .firstTextBaseline, spacing: 2) {
                                Text("€")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                Text(String(format: "%.2f", abs(salvadanaio.currentAmount)))
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(salvadanaio.currentAmount < 0 ? .red : .primary)
                                    .contentTransition(.numericText())
                            }
                        }
                        
                        Spacer()
                        
                        // Info obiettivo compatta
                        if !salvadanaio.isInfinite {
                            VStack(alignment: .trailing, spacing: 2) {
                                if salvadanaio.type == "objective" {
                                    Text("Obiettivo")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                    Text("€\(String(format: "%.0f", salvadanaio.targetAmount))")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(getColor(from: salvadanaio.color))
                                } else {
                                    Text("Glass Mensile")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                    Text("€\(String(format: "%.0f", salvadanaio.monthlyRefill))")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(getColor(from: salvadanaio.color))
                                }
                            }
                        }
                    }
                    
                    // Progress bar animata (solo se non infinito e non negativo) - CORRETTA
                    if !salvadanaio.isInfinite && salvadanaio.currentAmount >= 0 {
                        VStack(spacing: 6) {
                            HStack {
                                Text("\(Int(progress * 100))%")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(getColor(from: salvadanaio.color))
                                
                                Spacer()
                                
                                if progress >= 1.0 {
                                    Text("🎉 Completato!")
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .foregroundColor(.green)
                                } else {
                                    Text("Mancano €\(String(format: "%.0f", (salvadanaio.type == "objective" ? salvadanaio.targetAmount : salvadanaio.monthlyRefill) - salvadanaio.currentAmount))")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            // PROGRESS BAR CORRETTA - Usa GeometryReader per width dinamica
                            GeometryReader { geometry in
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(Color.gray.opacity(0.15))
                                        .frame(height: 8)
                                    
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(
                                            LinearGradient(
                                                gradient: Gradient(colors: [
                                                    getColor(from: salvadanaio.color),
                                                    getColor(from: salvadanaio.color).opacity(0.7),
                                                    getColor(from: salvadanaio.color)
                                                ]),
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .frame(width: max(0, geometry.size.width * (animateProgress ? progress : 0)), height: 8)
                                        .shadow(color: getColor(from: salvadanaio.color).opacity(0.4), radius: 3, x: 0, y: 1)
                                        .animation(.easeOut(duration: 1.5).delay(0.3), value: animateProgress)
                                    
                                    // Effetto shimmer sulla progress bar
                                    if progress > 0 {
                                        RoundedRectangle(cornerRadius: 6)
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
                                            .frame(width: max(0, geometry.size.width * progress), height: 8)
                                            .opacity(animateGlow ? 0.8 : 0.0)
                                            .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: animateGlow)
                                    }
                                }
                            }
                            .frame(height: 8)
                        }
                    }
                    
                    // Info dettagliata (condizionale e compatta) + TRANSAZIONI
                    if showDetails {
                        VStack(spacing: 8) {
                            Divider()
                            
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Image(systemName: "calendar")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                        Text("Creato")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                    Text(salvadanaio.createdAt, style: .date)
                                        .font(.caption)
                                        .fontWeight(.medium)
                                }
                                
                                Spacer()
                                
                                if salvadanaio.type == "objective" && !salvadanaio.isInfinite, let targetDate = salvadanaio.targetDate {
                                    VStack(alignment: .trailing, spacing: 4) {
                                        HStack {
                                            Text("Scadenza")
                                                .font(.caption2)
                                                .foregroundColor(.secondary)
                                            Image(systemName: "flag.checkered")
                                                .font(.caption2)
                                                .foregroundColor(.secondary)
                                        }
                                        
                                        let daysRemaining = Calendar.current.dateComponents([.day], from: Date(), to: targetDate).day ?? 0
                                        
                                        if daysRemaining > 0 {
                                            Text("\(daysRemaining) giorni")
                                                .font(.caption)
                                                .fontWeight(.medium)
                                                .foregroundColor(daysRemaining < 30 ? .orange : .primary)
                                        } else {
                                            Text("Scaduto")
                                                .font(.caption)
                                                .fontWeight(.medium)
                                                .foregroundColor(.red)
                                        }
                                    }
                                }
                            }
                            
                            // NUOVA SEZIONE: Transazioni correlate
                            if !relatedTransactions.isEmpty {
                                VStack(spacing: 8) {
                                    Divider()
                                    
                                    HStack {
                                        HStack(spacing: 6) {
                                            Image(systemName: "creditcard.fill")
                                                .font(.caption)
                                                .foregroundColor(.blue)
                                            Text("Transazioni Recenti")
                                                .font(.caption)
                                                .fontWeight(.semibold)
                                                .foregroundColor(.blue)
                                        }
                                        
                                        Spacer()
                                        
                                        if relatedTransactions.count > 3 {
                                            Button(action: {
                                                showTransactionsSheet = true
                                            }) {
                                                HStack(spacing: 4) {
                                                    Text("Vedi tutte (\(relatedTransactions.count))")
                                                        .font(.caption2)
                                                        .fontWeight(.medium)
                                                    Image(systemName: "chevron.right")
                                                        .font(.caption2)
                                                }
                                                .foregroundColor(.blue)
                                            }
                                            .buttonStyle(PlainButtonStyle())
                                        } else {
                                            Text("\(relatedTransactions.count) totali")
                                                .font(.caption2)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    
                                    // Mostra ultime 3 transazioni
                                    VStack(spacing: 6) {
                                        ForEach(Array(relatedTransactions.prefix(3)), id: \.id) { transaction in
                                            CompactTransactionRowInCard(transaction: transaction)
                                        }
                                        
                                        if relatedTransactions.count > 3 {
                                            HStack {
                                                Image(systemName: "ellipsis")
                                                    .font(.caption2)
                                                    .foregroundColor(.secondary)
                                                Text("e altre \(relatedTransactions.count - 3)")
                                                    .font(.caption2)
                                                    .foregroundColor(.secondary)
                                                Spacer()
                                                
                                                Button("Vedi tutte") {
                                                    showTransactionsSheet = true
                                                }
                                                .font(.caption2)
                                                .foregroundColor(.blue)
                                                .buttonStyle(PlainButtonStyle())
                                            }
                                            .padding(.top, 4)
                                        }
                                    }
                                }
                            } else {
                                VStack(spacing: 8) {
                                    Divider()
                                    
                                    HStack {
                                        Image(systemName: "info.circle")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        Text("Nessuna transazione ancora")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        Spacer()
                                    }
                                }
                            }
                        }
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .move(edge: .top)),
                            removal: .opacity.combined(with: .move(edge: .top))
                        ))
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color(.systemBackground))
            }
        }
        .buttonStyle(PlainButtonStyle())
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: getColor(from: salvadanaio.color).opacity(0.2), radius: animateGlow ? 12 : 6, x: 0, y: animateGlow ? 6 : 3)
        .scaleEffect(showDetails ? 1.02 : 1.0)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: showDetails)
        .animation(.easeInOut(duration: 3).repeatForever(autoreverses: true), value: animateGlow)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            getColor(from: salvadanaio.color).opacity(0.3),
                            getColor(from: salvadanaio.color).opacity(0.1)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                animateProgress = true
                animateGlow = true
                animateFloating = true
            }
        }
        .sheet(isPresented: $showTransactionsSheet) {
            SalvadanaiTransactionsDetailView(
                salvadanaio: salvadanaio,
                transactions: relatedTransactions
            )
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

// MARK: - Card Salvadanai Compatta Alternativa (se vuoi ancora più compatta)
struct MiniSalvadanaiCardView: View {
    let salvadanaio: SalvadanaiModel
    @State private var animateValue = false
    @State private var animateGlow = false
    
    private var progress: Double {
        if salvadanaio.type == "objective" && !salvadanaio.isInfinite {
            guard salvadanaio.targetAmount > 0 else { return 0 }
            return min(max(salvadanaio.currentAmount / salvadanaio.targetAmount, 0), 1.0)
        } else if salvadanaio.type == "glass" {
            guard salvadanaio.monthlyRefill > 0 else { return 0 }
            return min(max(salvadanaio.currentAmount / salvadanaio.monthlyRefill, 0), 1.0)
        }
        return 0
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
    
    var body: some View {
        HStack(spacing: 12) {
            // Indicatore di progresso circolare animato
            ZStack {
                Circle()
                    .stroke(getColor(from: salvadanaio.color).opacity(0.2), lineWidth: 4)
                    .frame(width: 50, height: 50)
                
                Circle()
                    .trim(from: 0, to: animateValue ? progress : 0)
                    .stroke(
                        AngularGradient(
                            gradient: Gradient(colors: [
                                getColor(from: salvadanaio.color),
                                getColor(from: salvadanaio.color).opacity(0.7),
                                getColor(from: salvadanaio.color)
                            ]),
                            center: .center,
                            startAngle: .degrees(-90),
                            endAngle: .degrees(270)
                        ),
                        style: StrokeStyle(lineWidth: 4, lineCap: .round)
                    )
                    .frame(width: 50, height: 50)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeOut(duration: 1.5), value: animateValue)
                
                // Icona centrale
                Image(systemName: salvadanaio.type == "objective" ? (salvadanaio.isInfinite ? "infinity" : "target") : "cup.and.saucer.fill")
                    .font(.subheadline)
                    .foregroundColor(getColor(from: salvadanaio.color))
                    .fontWeight(.semibold)
            }
            
            // Informazioni compatte
            VStack(alignment: .leading, spacing: 2) {
                Text(salvadanaio.name)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .lineLimit(1)
                
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text("€")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(String(format: "%.2f", abs(salvadanaio.currentAmount)))
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(salvadanaio.currentAmount < 0 ? .red : .primary)
                }
                
                if !salvadanaio.isInfinite {
                    Text("di €\(String(format: "%.0f", salvadanaio.type == "objective" ? salvadanaio.targetAmount : salvadanaio.monthlyRefill))")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                } else {
                    Text("Infinito")
                        .font(.caption2)
                        .foregroundColor(getColor(from: salvadanaio.color))
                }
            }
            
            Spacer()
            
            // Percentuale o status
            VStack(alignment: .trailing, spacing: 2) {
                if !salvadanaio.isInfinite && salvadanaio.currentAmount >= 0 {
                    Text("\(Int(progress * 100))%")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(getColor(from: salvadanaio.color))
                } else if salvadanaio.currentAmount < 0 {
                    Text("⚠️")
                        .font(.title3)
                } else {
                    Text("∞")
                        .font(.title3)
                        .foregroundColor(getColor(from: salvadanaio.color))
                }
                
                Text(salvadanaio.type == "objective" ? "Obiettivo" : "Glass")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(getColor(from: salvadanaio.color).opacity(0.3), lineWidth: 1)
                )
        )
        .shadow(color: getColor(from: salvadanaio.color).opacity(animateGlow ? 0.3 : 0.1), radius: animateGlow ? 8 : 4, x: 0, y: 2)
        .animation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true), value: animateGlow)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                animateValue = true
                animateGlow = true
            }
        }
    }
}

// MARK: - Salvadanaio Status View
struct SalvadanaiStatusView: View {
    let salvadanaio: SalvadanaiModel
    
    var body: some View {
        Group {
            if salvadanaio.currentAmount < 0 {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.title2)
                    .foregroundColor(.red)
                    .background(
                        Circle()
                            .fill(.red.opacity(0.1))
                            .frame(width: 32, height: 32)
                    )
            } else if salvadanaio.type == "objective" && salvadanaio.isInfinite {
                Image(systemName: "infinity")
                    .font(.title2)
                    .foregroundColor(Color(salvadanaio.color))
                    .background(
                        Circle()
                            .fill(Color(salvadanaio.color).opacity(0.1))
                            .frame(width: 32, height: 32)
                    )
            } else if isCompleted {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(.green)
                    .background(
                        Circle()
                            .fill(.green.opacity(0.1))
                            .frame(width: 32, height: 32)
                    )
            } else {
                Image(systemName: salvadanaio.type == "objective" ? "target" : "cup.and.saucer.fill")
                    .font(.title2)
                    .foregroundColor(Color(salvadanaio.color))
                    .background(
                        Circle()
                            .fill(Color(salvadanaio.color).opacity(0.1))
                            .frame(width: 32, height: 32)
                    )
            }
        }
    }
    
    private var isCompleted: Bool {
        if salvadanaio.type == "objective" && !salvadanaio.isInfinite {
            return salvadanaio.currentAmount >= salvadanaio.targetAmount
        } else if salvadanaio.type == "glass" {
            return salvadanaio.currentAmount >= salvadanaio.monthlyRefill
        }
        return false
    }
}

// MARK: - Salvadanaio Infinite View
struct SalvadanaiInfiniteView: View {
    let salvadanaio: SalvadanaiModel
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "infinity")
                    .foregroundColor(Color(salvadanaio.color))
                
                Text("Obiettivo senza limiti")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(Color(salvadanaio.color))
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(salvadanaio.color).opacity(0.1))
            )
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Creato il")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(salvadanaio.createdAt, style: .date)
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                
                Spacer()
                
                if salvadanaio.currentAmount >= 0 {
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Continua a risparmiare!")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        HStack {
                            Image(systemName: "arrow.up.circle.fill")
                                .font(.subheadline)
                                .foregroundColor(.green)
                            Text("Crescita")
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                    }
                } else {
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Da recuperare")
                            .font(.caption)
                            .foregroundColor(.red)
                        Text("€\(String(format: "%.2f", abs(salvadanaio.currentAmount)))")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.red)
                    }
                }
            }
        }
    }
}

// MARK: - Salvadanaio Objective View
struct SalvadanaiObjectiveView: View {
    let salvadanaio: SalvadanaiModel
    let progress: Double
    
    var daysRemaining: Int {
        guard let targetDate = salvadanaio.targetDate else { return 0 }
        return Calendar.current.dateComponents([.day], from: Date(), to: targetDate).day ?? 0
    }
    
    var body: some View {
        VStack(spacing: 12) {
            // Progress Bar (solo se non negativo)
            if salvadanaio.currentAmount >= 0 {
                VStack(spacing: 8) {
                    HStack {
                        Text("Progresso")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text("\(Int(progress * 100))%")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(Color(salvadanaio.color))
                    }
                    
                    ProgressView(value: progress)
                        .progressViewStyle(LinearProgressViewStyle(tint: Color(salvadanaio.color)))
                        .scaleEffect(y: 1.5)
                }
            }
            
            // Info obiettivo
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Obiettivo")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("€\(String(format: "%.0f", salvadanaio.targetAmount))")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                
                Spacer()
                
                if salvadanaio.currentAmount < 0 {
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Da recuperare")
                            .font(.caption)
                            .foregroundColor(.red)
                        Text("€\(String(format: "%.2f", abs(salvadanaio.currentAmount)))")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.red)
                    }
                } else if daysRemaining > 0 {
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Giorni rimasti")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(daysRemaining)")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(daysRemaining < 30 ? .orange : .primary)
                    }
                } else {
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Scaduto")
                            .font(.caption)
                            .foregroundColor(.red)
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.red)
                    }
                }
            }
        }
    }
}

// MARK: - Salvadanaio Glass View
struct SalvadanaiGlassView: View {
    let salvadanaio: SalvadanaiModel
    
    var fillPercentage: Double {
        guard salvadanaio.monthlyRefill > 0 else { return 0 }
        if salvadanaio.currentAmount < 0 {
            return 0
        }
        return min(salvadanaio.currentAmount / salvadanaio.monthlyRefill, 1.0)
    }
    
    var body: some View {
        VStack(spacing: 12) {
            // Glass visual indicator
            HStack(spacing: 8) {
                Text("Ricarica mensile:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("€\(String(format: "%.0f", salvadanaio.monthlyRefill))")
                    .font(.caption)
                    .fontWeight(.semibold)
            }
            
            // Visual glass
            HStack {
                // Glass container
                RoundedRectangle(cornerRadius: 6)
                    .stroke(salvadanaio.currentAmount < 0 ? Color.red : Color(salvadanaio.color), lineWidth: 2)
                    .background(
                        GeometryReader { geometry in
                            VStack {
                                Spacer()
                                if salvadanaio.currentAmount >= 0 {
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color(salvadanaio.color).opacity(0.3))
                                        .frame(height: geometry.size.height * fillPercentage)
                                } else {
                                    // Pattern per saldo negativo
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color.red.opacity(0.2))
                                        .frame(height: geometry.size.height * 0.2)
                                }
                            }
                        }
                    )
                    .frame(width: 40, height: 30)
                    .animation(.easeInOut(duration: 0.5), value: fillPercentage)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(salvadanaio.currentAmount < 0 ? "Saldo negativo" : "Disponibile questo mese")
                        .font(.caption)
                        .foregroundColor(salvadanaio.currentAmount < 0 ? .red : .secondary)
                    
                    HStack {
                        Text("€\(String(format: "%.2f", salvadanaio.currentAmount))")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(salvadanaio.currentAmount < 0 ? .red : .primary)
                        
                        Text("/ €\(String(format: "%.0f", salvadanaio.monthlyRefill))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
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

// MARK: - Simple Salvadanaio Form View
struct SimpleSalvadanaiFormView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var dataManager: DataManager
    
    @State private var name = ""
    @State private var selectedType = "objective"
    @State private var targetAmount = 100.0
    @State private var targetDate = Date()
    @State private var monthlyRefill = 50.0
    @State private var selectedColor = "blue"
    @State private var isInfiniteObjective = false
    
    let salvadanaiTypes = [
        ("objective", "Obiettivo", "target"),
        ("glass", "Glass", "cup.and.saucer.fill")
    ]
    
    var isFormValid: Bool {
        if name.isEmpty { return false }
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
                
                // RIMOSSO: Sezione conto di riferimento
                // RIMOSSO: Sezione saldo iniziale
                
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
                
                // NUOVO: Info su saldo iniziale
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
        // MODIFICATO: Nessun conto di riferimento, sempre saldo 0
        dataManager.addSalvadanaio(
            name: name,
            type: selectedType,
            targetAmount: isInfiniteObjective ? 0 : (selectedType == "objective" ? targetAmount : 0),
            targetDate: isInfiniteObjective ? nil : (selectedType == "objective" ? targetDate : nil),
            monthlyRefill: selectedType == "glass" ? monthlyRefill : 0,
            color: selectedColor,
            isInfinite: selectedType == "objective" ? isInfiniteObjective : false
        )
        dismiss()
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
