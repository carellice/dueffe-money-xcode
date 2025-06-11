import SwiftUI

// MARK: - TransactionsView completamente riscritta
struct TransactionsView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var showingAddTransaction = false
    @State private var selectedFilter = "all"
    @State private var searchText = ""
    @State private var showingDeleteConfirmation = false
    @State private var transactionToDelete: TransactionModel?
    
    // MARK: - AGGIORNARE IN TransactionsView.swift

    private var availableFilterOptions: [(String, String, String)] {
        var filters: [(String, String, String)] = []
        
        // Sempre mostra "Tutte" se ci sono transazioni
        if !dataManager.transactions.isEmpty {
            filters.append(("all", "Tutte", "list.bullet"))
        }
        
        // Controllo per ogni tipo di transazione
        let transactionTypes = Set(dataManager.transactions.map { $0.type })
        
        if transactionTypes.contains("expense") {
            filters.append(("expense", "Spese", "minus.circle"))
        }
        
        if transactionTypes.contains("income") {
            filters.append(("income", "Entrate", "plus.circle"))
        }
        
        if transactionTypes.contains("salary") {
            filters.append(("salary", "Stipendi", "banknote"))
        }
        
        if transactionTypes.contains("transfer") {
            filters.append(("transfer", "Trasf. Conti", "arrow.left.arrow.right.circle"))
        }

        // NUOVO: Filtro per trasferimenti tra salvadanai
        if transactionTypes.contains("transfer_salvadanai") {
            filters.append(("transfer_salvadanai", "Trasf. Salvadanai", "arrow.left.arrow.right.circle"))
        }

        if transactionTypes.contains("distribution") {
            filters.append(("distribution", "Distribuzioni", "arrow.branch.circle"))
        }
        
        return filters
    }
    
    var filteredTransactions: [TransactionModel] {
        var transactions = dataManager.transactions
        
        if selectedFilter != "all" {
            transactions = transactions.filter { $0.type == selectedFilter }
        }
        
        if !searchText.isEmpty {
            transactions = transactions.filter { transaction in
                transaction.descr.localizedCaseInsensitiveContains(searchText) ||
                transaction.category.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return transactions.sorted { $0.date > $1.date }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [Color.purple.opacity(0.05), Color.blue.opacity(0.05)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack {
                    if dataManager.accounts.isEmpty {
                        NoAccountsTransactionsView()
                    } else if dataManager.transactions.isEmpty {
                        EmptyTransactionsView(action: { showingAddTransaction = true })
                    } else {
                        VStack(spacing: 0) {
                            // Filtri
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(availableFilterOptions, id: \.0) { filter, title, icon in
                                        TransactionFilterButton(
                                            title: title,
                                            icon: icon,
                                            isSelected: selectedFilter == filter,
                                            count: getFilterCount(filter)
                                        ) {
                                            withAnimation(.spring()) {
                                                selectedFilter = filter
                                            }
                                        }
                                    }
                                }
                                .padding(.horizontal)
                            }
                            .padding(.vertical, 16)
                            
                            // Lista transazioni
                            List {
                                ForEach(groupedTransactions, id: \.0) { dateString, transactions in
                                    Section {
                                        ForEach(transactions, id: \.id) { transaction in
                                            TransactionRowView(transaction: transaction)
                                                .swipeActions(edge: .trailing, allowsFullSwipe: true) { // Cambiato a false per evitare eliminazione accidentale
                                                    Button(role: .destructive, action: {
                                                        transactionToDelete = transaction
                                                        showingDeleteConfirmation = true
                                                    }) {
                                                        Label("Elimina", systemImage: "trash.fill")
                                                    }
                                                    .tint(.red)
                                                }
                                        }
                                    } header: {
                                        TransactionSectionHeaderView(
                                            dateString: dateString,
                                            transactionCount: transactions.count
                                        )
                                    }
                                }
                            }
                            .searchable(text: $searchText, prompt: "Cerca transazioni...")
                            .listStyle(PlainListStyle())
                            .background(Color.clear)
                        }
                    }
                }
            }
            .navigationTitle("Transazioni")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddTransaction = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(.purple)
                    }
                    .disabled(dataManager.accounts.isEmpty) // Non serve cambiare qui perché controlleremo nel sheet
                }
            }
            .alert("Elimina Transazione", isPresented: $showingDeleteConfirmation) {
                Button("Elimina", role: .destructive) {
                    if let transaction = transactionToDelete {
                        withAnimation {
                            dataManager.deleteTransaction(transaction)
                        }
                    }
                    transactionToDelete = nil
                }
                Button("Annulla", role: .cancel) {
                    transactionToDelete = nil
                }
            } message: {
                if let transaction = transactionToDelete {
                    Text("Sei sicuro di voler eliminare '\(transaction.descr)'?\n\nQuesta azione non può essere annullata.")
                } else {
                    Text("Sei sicuro di voler eliminare questa transazione?")
                }
            }
        }
        .sheet(isPresented: $showingAddTransaction) {
            if dataManager.accounts.isEmpty {
                SimpleModalView(
                    title: "Nessun conto disponibile",
                    message: "Prima di procedere, devi creare almeno un conto nel tab 'Conti' per poter registrare entrate",
                    buttonText: "Ho capito"
                )
            } else {
                SimpleAddTransactionView()
            }
        }
    }
    
    private var groupedTransactions: [(String, [TransactionModel])] {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.locale = Locale(identifier: "it_IT")
        
        let grouped = Dictionary(grouping: filteredTransactions) { transaction in
            formatter.string(from: transaction.date)
        }
        
        return grouped.sorted { $0.key > $1.key }
    }
    
    private func getFilterCount(_ filter: String) -> Int {
        if filter == "all" {
            return dataManager.transactions.count
        } else {
            return dataManager.transactions.filter { $0.type == filter }.count
        }
    }
}

// MARK: - Transaction Stat Card
struct TransactionStatCardView: View {
    let title: String
    let amount: Double
    let icon: String
    let color: Color
    let isCount: Bool
    
    init(title: String, amount: Double, icon: String, color: Color, isCount: Bool = false) {
        self.title = title
        self.amount = amount
        self.icon = icon
        self.color = color
        self.isCount = isCount
    }
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            if isCount {
                Text("\(Int(amount))")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
            } else {
                Text("€\(String(format: "%.0f", amount))")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(color)
            }
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Transaction Filter Button
struct TransactionFilterButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let count: Int
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.subheadline)
                
                Text(title)
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
                          LinearGradient(gradient: Gradient(colors: [.blue, .purple]), startPoint: .leading, endPoint: .trailing) :
                          LinearGradient(gradient: Gradient(colors: [Color.gray.opacity(0.15)]), startPoint: .leading, endPoint: .trailing)
                    )
                    .shadow(color: isSelected ? .blue.opacity(0.3) : .clear, radius: 8, x: 0, y: 4)
            )
            .foregroundColor(isSelected ? .white : .primary)
        }
        .buttonStyle(PlainButtonStyle())
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isSelected)
    }
}

// MARK: - Transaction Section Header
struct TransactionSectionHeaderView: View {
    let dateString: String
    let transactionCount: Int
    
    var body: some View {
        HStack {
            Text(dateString)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            Spacer()
            
            Text("\(transactionCount) transazioni")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(
                    Capsule()
                        .fill(Color.gray.opacity(0.1))
                )
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color.clear)
    }
}

// MARK: - Enhanced Transaction Row View - Fluida e Bilanciata
struct TransactionRowView: View {
    let transaction: TransactionModel
    @State private var animateAmount = false
    @State private var animateGlow = false
    @State private var animateIcon = false
    @State private var isPressed = false
    @State private var showDetails = false
    
    private var transactionColor: Color {
        switch transaction.type {
        case "expense": return .red
        case "salary": return .blue
        case "transfer": return .orange
        case "transfer_salvadanai": return .purple
        case "distribution": return .mint
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
    
    private var iconName: String {
        switch transaction.type {
        case "expense": return "minus.circle.fill"
        case "salary": return "banknote.fill"
        case "transfer": return "arrow.left.arrow.right.circle.fill"
        case "transfer_salvadanai": return "arrow.triangle.swap"
        case "distribution": return "arrow.branch.circle.fill"
        default: return "plus.circle.fill"
        }
    }
    
    private var gradientColors: [Color] {
        switch transaction.type {
        case "expense":
            return [Color.red.opacity(0.8), Color.orange.opacity(0.6)]
        case "salary":
            return [Color.blue.opacity(0.8), Color.indigo.opacity(0.6)]
        case "transfer", "transfer_salvadanai":
            return [Color.orange.opacity(0.8), Color.yellow.opacity(0.6)]
        case "distribution":
            return [Color.mint.opacity(0.8), Color.teal.opacity(0.6)]
        default:
            return [Color.green.opacity(0.8), Color.cyan.opacity(0.6)]
        }
    }
    
    private var sourceDestinationInfo: (String, String) {
        if transaction.type == "expense", let salvadanaiName = transaction.salvadanaiName {
            return ("banknote", "da \(salvadanaiName)")
        } else if transaction.type == "transfer", let toAccount = transaction.salvadanaiName {
            return ("building.columns", "\(transaction.accountName) → \(toAccount)")
        } else if transaction.type == "transfer_salvadanai", let toSalvadanaio = transaction.salvadanaiName {
            return ("arrow.triangle.swap", "\(transaction.accountName) → \(toSalvadanaio)")
        } else if transaction.type == "distribution", let salvadanaiName = transaction.salvadanaiName {
            return ("arrow.branch", "verso \(salvadanaiName)")
        } else if transaction.type != "expense" && !transaction.accountName.isEmpty {
            return ("building.columns", "su \(transaction.accountName)")
        } else {
            return ("", "")
        }
    }
    
    var body: some View {
        Button(action: {
            if showDetails {
                // Animazione di chiusura più controllata per evitare overflow
                withAnimation(.easeOut(duration: 0.35)) {
                    showDetails = false
                }
            } else {
                // Animazione di apertura
                withAnimation(.easeInOut(duration: 0.4)) {
                    showDetails = true
                }
            }
        }) {
            VStack(spacing: 0) {
                ZStack {
                    // Background con gradiente
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: gradientColors),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(
                            color: transactionColor.opacity(animateGlow ? 0.25 : 0.12),
                            radius: animateGlow ? 8 : 4,
                            x: 0,
                            y: 2
                        )
                        .animation(.easeInOut(duration: 3).repeatForever(autoreverses: true), value: animateGlow)
                    
                    // Overlay decorativo leggero
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.white.opacity(0.15),
                                    Color.clear
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    // Contenuto principale
                    VStack(spacing: 0) {
                        // Contenuto sempre visibile
                        HStack(spacing: 16) {
                            // Icona principale
                            ZStack {
                                Circle()
                                    .fill(Color.white.opacity(0.25))
                                    .frame(width: 44, height: 44)
                                
                                if !categoryEmoji.isEmpty {
                                    Text(categoryEmoji)
                                        .font(.title3)
                                        .scaleEffect(animateIcon ? 1.08 : 1.0)
                                        .animation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true), value: animateIcon)
                                } else {
                                    Image(systemName: iconName)
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundColor(.white)
                                        .scaleEffect(animateIcon ? 1.08 : 1.0)
                                        .animation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true), value: animateIcon)
                                }
                            }
                            
                            // Info principale
                            VStack(alignment: .leading, spacing: 4) {
                                // Descrizione
                                Text(transaction.descr)
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                                    .lineLimit(showDetails ? 3 : 1)
                                    .fixedSize(horizontal: false, vertical: showDetails)
                                
                                // Categoria e orario (sempre visibili)
                                HStack(spacing: 8) {
                                    Text(cleanCategoryName)
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundColor(.white.opacity(0.9))
                                        .lineLimit(showDetails ? nil : 1)
                                        .fixedSize(horizontal: false, vertical: showDetails)
                                    
                                    if !showDetails {
                                        Circle()
                                            .fill(Color.white.opacity(0.6))
                                            .frame(width: 3, height: 3)
                                        
                                        Text(transaction.date, format: .dateTime.hour().minute())
                                            .font(.subheadline)
                                            .foregroundColor(.white.opacity(0.8))
                                    }
                                }
                            }
                            
                            Spacer()
                            
                            // Importo e freccia
                            VStack(alignment: .trailing, spacing: 6) {
                                // Importo
                                HStack(alignment: .firstTextBaseline, spacing: 2) {
                                    Text(transaction.type == "expense" ? "-" : "+")
                                        .font(.title3)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                    
                                    Text("€\(String(format: "%.0f", transaction.amount))")
                                        .font(.title2)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                        .scaleEffect(animateAmount ? 1.02 : 1.0)
                                        .shadow(color: .white.opacity(0.3), radius: 2)
                                }
                                
                                // Freccia espansione
                                Image(systemName: showDetails ? "chevron.up" : "chevron.down")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white.opacity(0.7))
                                    .rotationEffect(.degrees(showDetails ? 180 : 0))
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        
                        // Contenuto espandibile
                        if showDetails {
                            VStack(spacing: 0) {
                                // Separatore
                                Rectangle()
                                    .fill(Color.white.opacity(0.2))
                                    .frame(height: 1)
                                    .padding(.horizontal, 16)
                                
                                // Dettagli espansi
                                VStack(alignment: .leading, spacing: 12) {
                                    // Data completa
                                    HStack(spacing: 10) {
                                        Image(systemName: "calendar")
                                            .font(.subheadline)
                                            .foregroundColor(.white.opacity(0.8))
                                            .frame(width: 20)
                                        
                                        Text(transaction.date, format: .dateTime.weekday(.wide).day().month(.wide).year())
                                            .font(.subheadline)
                                            .foregroundColor(.white.opacity(0.9))
                                        
                                        Spacer()
                                        
                                        Text("€\(String(format: "%.2f", transaction.amount))")
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.white)
                                    }
                                    
                                    // Tipo transazione
                                    HStack(spacing: 10) {
                                        Image(systemName: "tag")
                                            .font(.subheadline)
                                            .foregroundColor(.white.opacity(0.8))
                                            .frame(width: 20)
                                        
                                        Text(getTransactionTypeLabel())
                                            .font(.subheadline)
                                            .foregroundColor(.white.opacity(0.9))
                                        
                                        Spacer()
                                    }
                                    
                                    // Fonte/Destinazione se presente
                                    if !sourceDestinationInfo.0.isEmpty {
                                        HStack(spacing: 10) {
                                            Image(systemName: sourceDestinationInfo.0)
                                                .font(.subheadline)
                                                .foregroundColor(.white.opacity(0.8))
                                                .frame(width: 20)
                                            
                                            Text(sourceDestinationInfo.1)
                                                .font(.subheadline)
                                                .foregroundColor(.white.opacity(0.9))
                                            
                                            Spacer()
                                        }
                                    }
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 14)
                            }
                            .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 16))
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
            let delay = Double.random(in: 0.1...0.4)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                withAnimation(.easeInOut(duration: 0.8)) {
                    animateAmount = true
                }
                withAnimation(.easeInOut(duration: 1.5)) {
                    animateGlow = true
                }
                withAnimation(.easeInOut(duration: 2.0)) {
                    animateIcon = true
                }
            }
        }
    }
    
    private func getTransactionTypeLabel() -> String {
        switch transaction.type {
        case "expense": return "Spesa"
        case "salary": return "Stipendio"
        case "transfer": return "Trasferimento tra conti"
        case "transfer_salvadanai": return "Trasferimento tra salvadanai"
        case "distribution": return "Distribuzione automatica"
        default: return "Entrata"
        }
    }
}

// MARK: - Empty Transactions View
struct EmptyTransactionsView: View {
    let action: () -> Void
    @State private var animateIcon = false
    @EnvironmentObject var dataManager: DataManager
    
    var body: some View {
        VStack(spacing: 32) {
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        gradient: Gradient(colors: [Color.purple.opacity(0.2), Color.blue.opacity(0.2)]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 120, height: 120)
                    .scaleEffect(animateIcon ? 1.1 : 1.0)
                    .animation(.easeInOut(duration: 2).repeatForever(), value: animateIcon)
                
                Image(systemName: "creditcard.fill")
                    .font(.system(size: 50))
                    .foregroundStyle(LinearGradient(
                        gradient: Gradient(colors: [.purple, .blue]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
            }
            
            VStack(spacing: 12) {
                Text("Nessuna Transazione")
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                Text("Inizia aggiungendo le tue prime spese o entrate")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            // NUOVO: Avviso se mancano salvadanai per le spese
            if dataManager.salvadanai.isEmpty {
                HStack(spacing: 12) {
                    Image(systemName: "info.circle.fill")
                        .foregroundColor(.blue)
                    
                    Text("Suggerimento: crea almeno un salvadanaio per registrare le spese")
                        .font(.caption)
                        .foregroundColor(.blue)
                        .fontWeight(.medium)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.blue.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                        )
                )
            }
            
            Button(action: action) {
                HStack {
                    Text("Aggiungi Transazione")
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
                        gradient: Gradient(colors: [.purple, .blue]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: .purple.opacity(0.3), radius: 10, x: 0, y: 5)
            }
        }
        .padding(40)
        .onAppear {
            animateIcon = true
        }
    }
}

// MARK: - No Accounts Transactions View
struct NoAccountsTransactionsView: View {
    @State private var animateWarning = false
    
    var body: some View {
        VStack(spacing: 32) {
            ZStack {
                Circle()
                    .fill(Color.orange.opacity(0.2))
                    .frame(width: 120, height: 120)
                    .scaleEffect(animateWarning ? 1.1 : 1.0)
                    .animation(.easeInOut(duration: 1.5).repeatForever(), value: animateWarning)
                
                Image(systemName: "creditcard.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.orange)
            }
            
            VStack(spacing: 16) {
                Text("Impossibile aggiungere transazioni")
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                Text("Prima di registrare una transazione, devi aggiungere almeno un conto nel tab 'Conti'")
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

// MARK: - Extensions
extension Character {
    var isEmoji: Bool {
        guard let scalar = unicodeScalars.first else { return false }
        return scalar.properties.isEmoji && (scalar.value >= 0x238d || unicodeScalars.count > 1)
    }
}

struct SimpleAddTransactionView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var dataManager: DataManager
    
    @State private var amount = 0.0
    @State private var descr = ""
    @State private var selectedCategory = ""
    @State private var transactionType = "expense"
    @State private var selectedAccount = ""
    @State private var selectedSalvadanaio = ""
    @State private var showingSalaryDistribution = false
    @State private var showingIncomeDistribution = false
    
    // Per i trasferimenti tra conti
    @State private var fromAccount = ""
    @State private var toAccount = ""
    
    // NUOVO: Per i trasferimenti tra salvadanai
    @State private var fromSalvadanaio = ""
    @State private var toSalvadanaio = ""
    @State private var transferType = "account" // "account" o "salvadanaio"
    
    let transactionTypes = [
        ("expense", "Spesa", "minus.circle"),
        ("income", "Entrata", "plus.circle"),
        ("salary", "Stipendio", "banknote"),
        ("transfer", "Trasferimento", "arrow.left.arrow.right")
    ]
    
    // NUOVO: Opzioni per il tipo di trasferimento
    let transferTypes = [
        ("account", "Tra Conti", "building.columns"),
        ("salvadanaio", "Tra Salvadanai", "banknote")
    ]
    
    var availableCategories: [String] {
        switch transactionType {
        case "expense":
            return dataManager.expenseCategories
        default:
            return dataManager.incomeCategories
        }
    }
    
    var availableFromAccounts: [AccountModel] {
        dataManager.accounts.filter { $0.name != toAccount }
    }
    
    var availableToAccounts: [AccountModel] {
        dataManager.accounts.filter { $0.name != fromAccount }
    }
    
    // NUOVO: Salvadanai disponibili per trasferimenti
    var availableFromSalvadanai: [SalvadanaiModel] {
        dataManager.salvadanai.filter { $0.name != toSalvadanaio }
    }
    
    var availableToSalvadanai: [SalvadanaiModel] {
        dataManager.salvadanai.filter { $0.name != fromSalvadanaio }
    }
    
    var isFormValid: Bool {
        if transactionType == "expense" {
            return amount > 0 &&
                   !descr.isEmpty &&
                   !selectedSalvadanaio.isEmpty &&
                   !selectedCategory.isEmpty &&
                   !selectedAccount.isEmpty
        } else if transactionType == "salary" {
            return amount > 0 &&
                   !descr.isEmpty &&
                   !selectedAccount.isEmpty
        } else if transactionType == "transfer" {
            if transferType == "account" {
                return amount > 0 &&
                       !descr.isEmpty &&
                       !fromAccount.isEmpty &&
                       !toAccount.isEmpty &&
                       fromAccount != toAccount
            } else { // transferType == "salvadanaio"
                return amount > 0 &&
                       !descr.isEmpty &&
                       !fromSalvadanaio.isEmpty &&
                       !toSalvadanaio.isEmpty &&
                       fromSalvadanaio != toSalvadanaio
            }
        } else {
            return amount > 0 &&
                   !descr.isEmpty &&
                   !selectedAccount.isEmpty &&
                   !selectedCategory.isEmpty
        }
    }
    
    var body: some View {
        NavigationView {
            Form {
                // Tipo transazione
                Section {
                    ForEach(transactionTypes, id: \.0) { type, title, icon in
                        Button(action: {
                            transactionType = type
                            if type == "salary" {
                                selectedCategory = "💼 Stipendio"
                            } else if type == "transfer" {
                                selectedCategory = "🔄 Trasferimento"
                                descr = getDefaultTransferDescription()
                                // Reset transfer type to account by default
                                transferType = "account"
                            } else {
                                selectedCategory = ""
                                if type != "transfer" {
                                    descr = ""
                                }
                            }
                        }) {
                            HStack {
                                Image(systemName: icon)
                                    .frame(width: 24)
                                Text(title)
                                Spacer()
                                if transactionType == type {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.blue)
                                }
                            }
                            .padding(.vertical, 8)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(PlainButtonStyle())
                        .foregroundColor(transactionType == type ? .blue : .primary)
                    }
                } header: {
                    Text("Tipo di transazione")
                }
                
                // NUOVO: Selezione tipo di trasferimento
                if transactionType == "transfer" {
                    Section {
                        ForEach(transferTypes, id: \.0) { type, title, icon in
                            Button(action: {
                                transferType = type
                                descr = getDefaultTransferDescription()
                                // Reset selections when changing transfer type
                                resetTransferSelections()
                            }) {
                                HStack {
                                    Image(systemName: icon)
                                        .frame(width: 24)
                                        .foregroundColor(transferType == type ? .blue : .secondary)
                                    Text(title)
                                    Spacer()
                                    if transferType == type {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.blue)
                                    }
                                }
                                .padding(.vertical, 8)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(PlainButtonStyle())
                            .foregroundColor(transferType == type ? .blue : .primary)
                        }
                    } header: {
                        Text("Tipo di trasferimento")
                    } footer: {
                        if transferType == "account" {
                            Text("Trasferisci denaro fisico da un conto all'altro")
                        } else {
                            Text("Sposta denaro logicamente da un salvadanaio all'altro")
                        }
                    }
                }
                
                // Dettagli base
                Section {
                    HStack {
                        Text("Importo")
                        Spacer()
                        TextField("0", value: $amount, format: .currency(code: "EUR"))
                            .multilineTextAlignment(.trailing)
                            .keyboardType(.decimalPad)
                    }
                    
                    if transactionType == "transfer" {
                        TextField("Descrizione (opzionale)", text: $descr)
                            .textInputAutocapitalization(.sentences)
                    } else {
                        TextField("Descrizione", text: $descr)
                            .textInputAutocapitalization(.sentences)
                    }
                } header: {
                    Text("Dettagli")
                }
                
                // Sezione per trasferimenti tra conti
                if transactionType == "transfer" && transferType == "account" {
                    Section {
                        // Conto di origine
                        Picker("Da quale conto", selection: $fromAccount) {
                            Text("Seleziona conto di origine").tag("")
                            ForEach(availableFromAccounts, id: \.name) { account in
                                HStack {
                                    Text(account.name)
                                    Spacer()
                                    Text("€\(String(format: "%.2f", account.balance))")
                                        .foregroundColor(account.balance >= 0 ? .green : .red)
                                }
                                .tag(account.name)
                            }
                        }
                        
                        // Conto di destinazione
                        Picker("A quale conto", selection: $toAccount) {
                            Text("Seleziona conto di destinazione").tag("")
                            ForEach(availableToAccounts, id: \.name) { account in
                                HStack {
                                    Text(account.name)
                                    Spacer()
                                    Text("€\(String(format: "%.2f", account.balance))")
                                        .foregroundColor(.secondary)
                                }
                                .tag(account.name)
                            }
                        }
                        
                        // Anteprima trasferimento conti
                        if !fromAccount.isEmpty && !toAccount.isEmpty && amount > 0 {
                            TransferPreviewCard(
                                fromName: fromAccount,
                                toName: toAccount,
                                amount: amount,
                                transferType: "conti",
                                availableFunds: dataManager.accounts.first { $0.name == fromAccount }?.balance ?? 0,
                                color: .blue
                            )
                        }
                        
                    } header: {
                        HStack {
                            Image(systemName: "arrow.left.arrow.right.circle.fill")
                                .foregroundColor(.blue)
                            Text("Trasferimento tra Conti")
                        }
                    } footer: {
                        if dataManager.accounts.count < 2 {
                            Text("⚠️ Hai bisogno di almeno 2 conti per effettuare un trasferimento")
                                .foregroundColor(.orange)
                        } else {
                            Text("Trasferisci denaro fisico da un conto all'altro")
                        }
                    }
                }
                
                // NUOVO: Sezione per trasferimenti tra salvadanai
                if transactionType == "transfer" && transferType == "salvadanaio" {
                    Section {
                        // Salvadanaio di origine
                        Picker("Da quale salvadanaio", selection: $fromSalvadanaio) {
                            Text("Seleziona salvadanaio di origine").tag("")
                            ForEach(availableFromSalvadanai, id: \.name) { salvadanaio in
                                HStack {
                                    Text(salvadanaio.name)
                                    Spacer()
                                    Text("€\(String(format: "%.2f", salvadanaio.currentAmount))")
                                        .foregroundColor(salvadanaio.currentAmount >= 0 ? .green : .red)
                                }
                                .tag(salvadanaio.name)
                            }
                        }
                        
                        // Salvadanaio di destinazione
                        Picker("A quale salvadanaio", selection: $toSalvadanaio) {
                            Text("Seleziona salvadanaio di destinazione").tag("")
                            ForEach(availableToSalvadanai, id: \.name) { salvadanaio in
                                HStack {
                                    Text(salvadanaio.name)
                                    Spacer()
                                    Text("€\(String(format: "%.2f", salvadanaio.currentAmount))")
                                        .foregroundColor(.secondary)
                                }
                                .tag(salvadanaio.name)
                            }
                        }
                        
                        // Anteprima trasferimento salvadanai
                        if !fromSalvadanaio.isEmpty && !toSalvadanaio.isEmpty && amount > 0 {
                            TransferPreviewCard(
                                fromName: fromSalvadanaio,
                                toName: toSalvadanaio,
                                amount: amount,
                                transferType: "salvadanai",
                                availableFunds: dataManager.salvadanai.first { $0.name == fromSalvadanaio }?.currentAmount ?? 0,
                                color: .green
                            )
                        }
                        
                    } header: {
                        HStack {
                            Image(systemName: "arrow.left.arrow.right.circle.fill")
                                .foregroundColor(.green)
                            Text("Trasferimento tra Salvadanai")
                        }
                    } footer: {
                        if dataManager.salvadanai.count < 2 {
                            Text("⚠️ Hai bisogno di almeno 2 salvadanai per effettuare un trasferimento")
                                .foregroundColor(.orange)
                        } else {
                            Text("Sposta denaro logicamente da un salvadanaio all'altro. Non modifica i conti fisici.")
                        }
                    }
                }
                
                // Categoria (solo per spese ed entrate normali)
                if transactionType == "expense" || (transactionType == "income" && !availableCategories.isEmpty) {
                    Section {
                        Picker("Categoria", selection: $selectedCategory) {
                            Text("Seleziona categoria")
                                .tag("")
                                .foregroundColor(.secondary)
                            ForEach(availableCategories, id: \.self) { category in
                                Text(category).tag(category)
                            }
                        }
                    } header: {
                        Text("Categoria")
                    }
                }
                
                // SALVADANAIO (SOLO PER LE SPESE)
                if transactionType == "expense" {
                    if !dataManager.salvadanai.isEmpty {
                        Section {
                            Picker("Salvadanaio", selection: $selectedSalvadanaio) {
                                Text("Seleziona salvadanaio")
                                    .tag("")
                                    .foregroundColor(.secondary)
                                ForEach(dataManager.salvadanai, id: \.name) { salvadanaio in
                                    HStack {
                                        Text(salvadanaio.name)
                                        Spacer()
                                        Text("€\(String(format: "%.2f", salvadanaio.currentAmount))")
                                            .foregroundColor(salvadanaio.currentAmount >= 0 ? .green : .red)
                                    }
                                    .tag(salvadanaio.name)
                                }
                            }
                        } header: {
                            HStack {
                                Image(systemName: "banknote.fill")
                                    .foregroundColor(.green)
                                Text("Salvadanaio (logico)")
                            }
                        } footer: {
                            if !selectedSalvadanaio.isEmpty {
                                let selectedSalv = dataManager.salvadanai.first { $0.name == selectedSalvadanaio }
                                if let salvadanaio = selectedSalv, salvadanaio.currentAmount < amount {
                                    Text("⚠️ Attenzione: il salvadanaio non ha fondi sufficienti. Il saldo diventerà negativo.")
                                        .foregroundColor(.red)
                                } else {
                                    Text("I soldi verranno sottratti logicamente da questo salvadanaio")
                                        .foregroundColor(.green)
                                }
                            } else {
                                Text("Scegli da quale salvadanaio sottrarre logicamente i soldi per questa spesa")
                            }
                        }
                    } else {
                        Section {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.orange)
                                Text("Nessun salvadanaio disponibile")
                                    .foregroundColor(.orange)
                            }
                            .padding(.vertical, 8)
                        } footer: {
                            Text("Per registrare una spesa devi prima creare almeno un salvadanaio nel tab 'Salvadanai'")
                        }
                    }
                }
                
                // CONTO per spese (DA QUALE CONTO TOGLIERE I SOLDI FISICAMENTE)
                if transactionType == "expense" && !dataManager.accounts.isEmpty {
                    Section {
                        Picker("Da quale conto", selection: $selectedAccount) {
                            Text("Seleziona conto").tag("")
                            ForEach(dataManager.accounts, id: \.name) { account in
                                HStack {
                                    Text(account.name)
                                    Spacer()
                                    Text("€\(String(format: "%.2f", account.balance))")
                                        .foregroundColor(account.balance >= 0 ? .green : .red)
                                }
                                .tag(account.name)
                            }
                        }
                        
                        // Verifica fondi
                        if !selectedAccount.isEmpty && amount > 0 {
                            if let selectedAcc = dataManager.accounts.first(where: { $0.name == selectedAccount }) {
                                HStack {
                                    if selectedAcc.balance >= amount {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.green)
                                        Text("Fondi sufficienti")
                                            .foregroundColor(.green)
                                    } else {
                                        Image(systemName: "exclamationmark.triangle.fill")
                                            .foregroundColor(.orange)
                                        Text("Fondi insufficienti. Il conto andrà in rosso.")
                                            .foregroundColor(.orange)
                                    }
                                    Spacer()
                                }
                                .font(.caption)
                                .padding(.top, 4)
                            }
                        }
                    } header: {
                        HStack {
                            Image(systemName: "building.columns.fill")
                                .foregroundColor(.red)
                            Text("Conto (fisico)")
                        }
                    } footer: {
                        Text("I soldi verranno sottratti fisicamente da questo conto")
                    }
                }
                
                // Account per entrate e stipendi (NON per trasferimenti)
                if (transactionType == "income" || transactionType == "salary") && !dataManager.accounts.isEmpty {
                    Section {
                        Picker("A quale conto", selection: $selectedAccount) {
                            Text("Seleziona conto").tag("")
                            ForEach(dataManager.accounts, id: \.name) { account in
                                HStack {
                                    Text(account.name)
                                    Spacer()
                                    Text("€\(String(format: "%.2f", account.balance))")
                                        .foregroundColor(.secondary)
                                }
                                .tag(account.name)
                            }
                        }
                    } header: {
                        HStack {
                            Image(systemName: "building.columns.fill")
                                .foregroundColor(.blue)
                            Text("Conto di destinazione")
                        }
                    } footer: {
                        if transactionType == "salary" {
                            Text("Lo stipendio verrà registrato su questo conto e poi potrai distribuirlo tra i tuoi salvadanai")
                        } else {
                            Text("L'entrata verrà aggiunta a questo conto e poi potrai distribuirla tra i salvadanai")
                        }
                    }
                }
                
                // Info per entrate
                if transactionType == "income" && !dataManager.salvadanai.isEmpty {
                    Section {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "info.circle.fill")
                                    .foregroundColor(.green)
                                Text("Distribuzione Entrata")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.green)
                            }
                            
                            Text("Dopo aver salvato l'entrata, potrai distribuirla tra i tuoi salvadanai utilizzando diverse modalità:")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            VStack(alignment: .leading, spacing: 8) {
                                DistributionInfoRow(
                                    icon: "equal.circle.fill",
                                    title: "Distribuzione Equa",
                                    description: "Dividi in parti uguali tra i salvadanai selezionati",
                                    color: .green
                                )
                                
                                DistributionInfoRow(
                                    icon: "slider.horizontal.3",
                                    title: "Distribuzione Personalizzata",
                                    description: "Specifica importi personalizzati per ogni salvadanaio",
                                    color: .purple
                                )
                                
                                DistributionInfoRow(
                                    icon: "sparkles",
                                    title: "Distribuzione Automatica",
                                    description: "Algoritmo intelligente basato su priorità e necessità",
                                    color: .orange
                                )
                            }
                        }
                        .padding(.vertical, 8)
                    } header: {
                        HStack {
                            Image(systemName: "lightbulb.fill")
                                .foregroundColor(.yellow)
                            Text("Come funziona")
                        }
                    }
                }
                
                // Info per stipendi
                if transactionType == "salary" {
                    Section {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "info.circle.fill")
                                    .foregroundColor(.blue)
                                Text("Distribuzione Stipendio")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.blue)
                            }
                            
                            Text("Dopo aver salvato lo stipendio, potrai distribuirlo tra i tuoi salvadanai utilizzando diverse modalità:")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            VStack(alignment: .leading, spacing: 8) {
                                DistributionInfoRow(
                                    icon: "equal.circle.fill",
                                    title: "Distribuzione Equa",
                                    description: "Dividi in parti uguali tra i salvadanai selezionati",
                                    color: .blue
                                )
                                
                                DistributionInfoRow(
                                    icon: "slider.horizontal.3",
                                    title: "Distribuzione Personalizzata",
                                    description: "Specifica importi personalizzati per ogni salvadanaio",
                                    color: .purple
                                )
                                
                                DistributionInfoRow(
                                    icon: "sparkles",
                                    title: "Distribuzione Automatica",
                                    description: "Algoritmo intelligente basato su priorità e necessità",
                                    color: .orange
                                )
                            }
                        }
                        .padding(.vertical, 8)
                    } header: {
                        HStack {
                            Image(systemName: "lightbulb.fill")
                                .foregroundColor(.yellow)
                            Text("Come funziona")
                        }
                    }
                }
            }
            .navigationTitle(getNavigationTitle())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(content: {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Annulla") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(getButtonText()) {
                        saveTransaction()
                    }
                    .disabled(!isFormValid)
                    .fontWeight(.semibold)
                    .foregroundColor(isFormValid ? getButtonColor() : .secondary)
                }
            })
        }
        .onAppear(perform: setupDefaults)
        .sheet(isPresented: $showingSalaryDistribution) {
            SalaryDistributionView(
                amount: amount,
                descr: descr,
                transactionType: transactionType,
                selectedAccount: selectedAccount,
                onComplete: {
                    dismiss()
                }
            )
        }
        .sheet(isPresented: $showingIncomeDistribution) {
            SalaryDistributionView(
                amount: amount,
                descr: descr,
                transactionType: transactionType,
                selectedAccount: selectedAccount,
                onComplete: {
                    dismiss()
                }
            )
        }
    }
    
    // NUOVO: Funzione per ottenere la descrizione di default del trasferimento
    private func getDefaultTransferDescription() -> String {
        if transferType == "account" {
            return fromAccount.isEmpty || toAccount.isEmpty ? "Trasferimento tra conti" : "Trasferimento da \(fromAccount) a \(toAccount)"
        } else {
            return fromSalvadanaio.isEmpty || toSalvadanaio.isEmpty ? "Trasferimento tra salvadanai" : "Trasferimento da \(fromSalvadanaio) a \(toSalvadanaio)"
        }
    }
    
    // NUOVO: Funzione per resettare le selezioni quando si cambia tipo trasferimento
    private func resetTransferSelections() {
        fromAccount = ""
        toAccount = ""
        fromSalvadanaio = ""
        toSalvadanaio = ""
    }
    
    private func getButtonText() -> String {
        if transactionType == "salary" {
            return "Distribuisci Stipendio"
        } else if transactionType == "income" && !dataManager.salvadanai.isEmpty {
            return "Distribuisci Entrata"
        } else if transactionType == "transfer" {
            return transferType == "account" ? "Trasferisci tra Conti" : "Trasferisci tra Salvadanai"
        } else {
            return "Salva"
        }
    }
    
    private func getButtonColor() -> Color {
        switch transactionType {
        case "salary": return .blue
        case "income": return .green
        case "transfer": return transferType == "account" ? .blue : .green
        default: return .blue
        }
    }
    
    private func getNavigationTitle() -> String {
        switch transactionType {
        case "expense": return "Nuova Spesa"
        case "salary": return "Nuovo Stipendio"
        case "transfer": return transferType == "account" ? "Trasferimento Conti" : "Trasferimento Salvadanai"
        default: return "Nuova Entrata"
        }
    }
    
    private func setupDefaults() {
        if selectedAccount.isEmpty && !dataManager.accounts.isEmpty && (transactionType == "income" || transactionType == "salary") {
            selectedAccount = dataManager.accounts.first!.name
        }
        
        if transactionType == "salary" {
            selectedCategory = "💼 Stipendio"
        }
        
        // Seleziona automaticamente il primo salvadanaio per le spese
        if selectedSalvadanaio.isEmpty && !dataManager.salvadanai.isEmpty && transactionType == "expense" {
            selectedSalvadanaio = dataManager.salvadanai.first!.name
        }
        
        // Setup per trasferimenti tra conti
        if transactionType == "transfer" && transferType == "account" {
            if fromAccount.isEmpty && !dataManager.accounts.isEmpty {
                fromAccount = dataManager.accounts.first!.name
            }
            if toAccount.isEmpty && dataManager.accounts.count > 1 {
                toAccount = dataManager.accounts.filter { $0.name != fromAccount }.first?.name ?? ""
            }
        }
        
        // NUOVO: Setup per trasferimenti tra salvadanai
        if transactionType == "transfer" && transferType == "salvadanaio" {
            if fromSalvadanaio.isEmpty && !dataManager.salvadanai.isEmpty {
                fromSalvadanaio = dataManager.salvadanai.first!.name
            }
            if toSalvadanaio.isEmpty && dataManager.salvadanai.count > 1 {
                toSalvadanaio = dataManager.salvadanai.filter { $0.name != fromSalvadanaio }.first?.name ?? ""
            }
        }
        
        // Setup default per conto spese
        if selectedAccount.isEmpty && !dataManager.accounts.isEmpty && transactionType == "expense" {
            selectedAccount = dataManager.accounts.first!.name
        }
    }
    
    private func saveTransaction() {
        if transactionType == "expense" {
            dataManager.addTransaction(
                amount: amount,
                descr: descr,
                category: selectedCategory,
                type: transactionType,
                accountName: selectedAccount,
                salvadanaiName: selectedSalvadanaio
            )
            dismiss()
        } else if transactionType == "salary" {
            if dataManager.salvadanai.isEmpty {
                dataManager.addTransaction(
                    amount: amount,
                    descr: descr,
                    category: selectedCategory,
                    type: transactionType,
                    accountName: selectedAccount,
                    salvadanaiName: nil
                )
                dismiss()
            } else {
                showingSalaryDistribution = true
            }
        } else if transactionType == "income" {
            if dataManager.salvadanai.isEmpty {
                dataManager.addTransaction(
                    amount: amount,
                    descr: descr,
                    category: selectedCategory,
                    type: transactionType,
                    accountName: selectedAccount,
                    salvadanaiName: nil
                )
                dismiss()
            } else {
                showingIncomeDistribution = true
            }
        } else if transactionType == "transfer" {
            if transferType == "account" {
                performAccountTransfer()
            } else {
                performSalvadanaiTransfer()
            }
            dismiss()
        }
    }
    
    // Funzione esistente per trasferimenti tra conti
    private func performAccountTransfer() {
        // Aggiorna direttamente l'array accounts
        if let fromIndex = dataManager.accounts.firstIndex(where: { $0.name == fromAccount }) {
            dataManager.accounts[fromIndex].balance -= amount
        }
        
        if let toIndex = dataManager.accounts.firstIndex(where: { $0.name == toAccount }) {
            dataManager.accounts[toIndex].balance += amount
        }
        
        // Registra la transazione
        let finalDescription = descr.isEmpty ? "Trasferimento da \(fromAccount) a \(toAccount)" : descr
        let transferTransaction = TransactionModel(
            amount: amount,
            descr: finalDescription,
            category: "🔄 Trasferimento Conti",
            type: "transfer",
            date: Date(),
            accountName: fromAccount,
            salvadanaiName: toAccount
        )
        
        dataManager.transactions.append(transferTransaction)
    }
    
    // NUOVO: Funzione per trasferimenti tra salvadanai
    private func performSalvadanaiTransfer() {
        // Aggiorna i saldi dei salvadanai
        if let fromIndex = dataManager.salvadanai.firstIndex(where: { $0.name == fromSalvadanaio }) {
            dataManager.salvadanai[fromIndex].currentAmount -= amount
        }
        
        if let toIndex = dataManager.salvadanai.firstIndex(where: { $0.name == toSalvadanaio }) {
            dataManager.salvadanai[toIndex].currentAmount += amount
        }
        
        // Registra la transazione
        let finalDescription = descr.isEmpty ? "Trasferimento da \(fromSalvadanaio) a \(toSalvadanaio)" : descr
        let transferTransaction = TransactionModel(
            amount: amount,
            descr: finalDescription,
            category: "🔄 Trasferimento Salvadanai",
            type: "transfer_salvadanai", // Nuovo tipo per distinguere dai trasferimenti tra conti
            date: Date(),
            accountName: fromSalvadanaio,
            salvadanaiName: toSalvadanaio
        )
        
        dataManager.transactions.append(transferTransaction)
    }
}

// MARK: - Distribution Info Row
struct DistributionInfoRow: View {
    let icon: String
    let title: String
    let description: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundColor(color)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            Spacer()
        }
    }
}

// MARK: - Transfer Preview Card Component
struct TransferPreviewCard: View {
    let fromName: String
    let toName: String
    let amount: Double
    let transferType: String
    let availableFunds: Double
    let color: Color
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "info.circle.fill")
                    .foregroundColor(color)
                Text("Anteprima Trasferimento")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(color)
            }
            
            VStack(spacing: 8) {
                HStack {
                    Text("Da:")
                    Text(fromName)
                        .fontWeight(.semibold)
                    Spacer()
                    Text("-€\(String(format: "%.2f", amount))")
                        .fontWeight(.semibold)
                        .foregroundColor(.red)
                }
                
                Image(systemName: "arrow.down")
                    .foregroundColor(color)
                
                HStack {
                    Text("A:")
                    Text(toName)
                        .fontWeight(.semibold)
                    Spacer()
                    Text("+€\(String(format: "%.2f", amount))")
                        .fontWeight(.semibold)
                        .foregroundColor(.green)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(color.opacity(0.1))
            )
            
            // Verifica fondi
            HStack {
                if availableFunds >= amount {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Trasferimento possibile")
                        .font(.caption)
                        .foregroundColor(.green)
                } else {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    if transferType == "conti" {
                        Text("Il conto di origine non ha fondi sufficienti. Il saldo diventerà negativo.")
                            .font(.caption)
                            .foregroundColor(.orange)
                    } else {
                        Text("Il salvadanaio di origine non ha fondi sufficienti. Il saldo diventerà negativo.")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
            }
        }
        .padding(.vertical, 8)
    }
}
