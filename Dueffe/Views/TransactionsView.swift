import SwiftUI

// MARK: - TransactionsView completamente riscritta
struct TransactionsView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var showingAddTransaction = false
    @State private var selectedFilter = "all"
    @State private var searchText = ""
    @State private var showingDeleteConfirmation = false
    @State private var transactionToDelete: TransactionModel?
    
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
    
    var totalExpenses: Double {
        dataManager.transactions.filter { $0.type == "expense" }.reduce(0) { $0 + $1.amount }
    }
    
    var totalIncome: Double {
        dataManager.transactions.filter { $0.type != "expense" }.reduce(0) { $0 + $1.amount }
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
                            // Header con statistiche (MODIFICATO - rimosso bilancio netto)
                            UltraCompactTransactionsHeader(
                                totalExpenses: totalExpenses,
                                totalIncome: totalIncome,
                                transactionCount: dataManager.transactions.count
                            )
                            .padding(.horizontal)
                            .padding(.bottom, 16)
                            
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
                            .padding(.vertical, 12)
                            
                            // Lista transazioni
                            List {
                                ForEach(groupedTransactions, id: \.0) { dateString, transactions in
                                    Section {
                                        ForEach(transactions, id: \.id) { transaction in
                                            TransactionRowView(transaction: transaction)
                                                .swipeActions(edge: .trailing, allowsFullSwipe: true) { // Cambiato a false per evitare eliminazione accidentale
                                                    Button(action: {
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

// MARK: - Transactions Stats Header (MODIFICATO - rimosso bilancio netto)
struct TransactionsStatsHeaderView: View {
    let totalExpenses: Double
    let totalIncome: Double
    let transactionCount: Int
    
    var body: some View {
        VStack(spacing: 20) {
            // Header titolo
            HStack {
                Image(systemName: "chart.bar.fill")
                    .foregroundColor(.purple)
                Text("Riepilogo Transazioni")
                    .font(.title3)
                    .fontWeight(.bold)
                Spacer()
            }
            
            // Solo le tre statistiche principali
            HStack(spacing: 20) {
                TransactionStatCardView(
                    title: "Entrate",
                    amount: totalIncome,
                    icon: "plus.circle.fill",
                    color: .green
                )
                
                TransactionStatCardView(
                    title: "Spese",
                    amount: totalExpenses,
                    icon: "minus.circle.fill",
                    color: .red
                )
                
                TransactionStatCardView(
                    title: "Transazioni",
                    amount: Double(transactionCount),
                    icon: "list.bullet.circle.fill",
                    color: .blue,
                    isCount: true
                )
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

// MARK: - Transaction Row View (VERSIONE PULITA E LEGGIBILE)
struct TransactionRowView: View {
    let transaction: TransactionModel
    
    private var transactionColor: Color {
        transaction.type == "expense" ? .red : .green
    }
    
    private var categoryEmoji: String {
        if let firstChar = transaction.category.first, firstChar.isEmoji {
            return String(firstChar)
        }
        return transaction.type == "expense" ? "💸" : "💰"
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Emoji semplice
            Text(categoryEmoji)
                .font(.title2)
                .frame(width: 44, height: 44)
                .background(Circle().fill(Color.gray.opacity(0.1)))
            
            // Contenuto principale
            VStack(alignment: .leading, spacing: 4) {
                // Nome transazione
                Text(transaction.descr)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .lineLimit(nil)  // Permette righe multiple
                    .multilineTextAlignment(.leading)  // Allineamento a sinistra
                    .fixedSize(horizontal: false, vertical: true)  // Espande in verticale se necessario
                
                // Data
                Text(transaction.date, style: .date)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                // Salvadanaio/Conto
                if transaction.type == "expense", let salvadanaiName = transaction.salvadanaiName {
                    HStack(spacing: 4) {
                        Image(systemName: "banknote")
                            .font(.caption)
                            .foregroundColor(.orange)
                        Text("da \(salvadanaiName)")
                            .font(.subheadline)
                            .foregroundColor(.orange)
                            .fontWeight(.medium)
                    }
                } else if transaction.type == "transfer", let salvadanaiName = transaction.salvadanaiName {
                    // NUOVO: Gestione speciale per i trasferimenti (distribuzioni stipendio)
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.caption)
                            .foregroundColor(.blue)
                        Text("verso \(salvadanaiName)")
                            .font(.subheadline)
                            .foregroundColor(.blue)
                            .fontWeight(.medium)
                    }
                } else if transaction.type != "expense" && transaction.type != "transfer" && !transaction.accountName.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "building.columns")
                            .font(.caption)
                            .foregroundColor(.green)
                        Text("su \(transaction.accountName)")
                            .font(.subheadline)
                            .foregroundColor(.green)
                            .fontWeight(.medium)
                    }
                }
            }
            
            Spacer()
            
            // Solo l'importo
            Text("\(transaction.type == "expense" ? "-" : "+")€\(String(format: "%.0f", transaction.amount))")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(transactionColor)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Versione ancora più semplice (OPZIONE B)
struct SuperSimpleTransactionRowView: View {
    let transaction: TransactionModel
    
    var body: some View {
        HStack {
            // Solo emoji o icona
            if let firstChar = transaction.category.first, firstChar.isEmoji {
                Text(String(firstChar))
                    .font(.title2)
            } else {
                Image(systemName: transaction.type == "expense" ? "minus.circle.fill" : "plus.circle.fill")
                    .font(.title2)
                    .foregroundColor(transaction.type == "expense" ? .red : .green)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                // Nome
                Text(transaction.descr)
                    .font(.headline)
                    .lineLimit(1)
                
                // Salvadanaio/Conto in piccolo
                if transaction.type == "expense", let salvadanaiName = transaction.salvadanaiName {
                    Text("da \(salvadanaiName)")
                        .font(.caption)
                        .foregroundColor(.orange)
                } else if transaction.type != "expense" && !transaction.accountName.isEmpty {
                    Text("su \(transaction.accountName)")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
            
            Spacer()
            
            // Importo
            Text("\(transaction.type == "expense" ? "-" : "+")€\(String(format: "%.0f", transaction.amount))")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(transaction.type == "expense" ? .red : .green)
        }
        .padding()
    }
}

// MARK: - Versione con solo essenziale (OPZIONE C)
struct EssentialTransactionRowView: View {
    let transaction: TransactionModel
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                // Descrizione
                Text(transaction.descr)
                    .font(.headline)
                    .fontWeight(.medium)
                
                Spacer()
                
                // Importo con colore
                Text("\(transaction.type == "expense" ? "-" : "+")€\(String(format: "%.0f", transaction.amount))")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(transaction.type == "expense" ? .red : .green)
            }
            
            HStack {
                // Data a sinistra
                Text(transaction.date, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                // Salvadanaio/Conto al centro
                if transaction.type == "expense", let salvadanaiName = transaction.salvadanaiName {
                    Text("da \(salvadanaiName)")
                        .font(.caption)
                        .foregroundColor(.orange)
                        .fontWeight(.medium)
                } else if transaction.type != "expense" && !transaction.accountName.isEmpty {
                    Text("su \(transaction.accountName)")
                        .font(.caption)
                        .foregroundColor(.blue)
                        .fontWeight(.medium)
                }
                
                Spacer()
                
                // Categoria a destra
                Text(transaction.category)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.gray.opacity(0.05))
        )
    }
}

// MARK: - Alternative: Versione ancora più minimalista
struct MinimalTransactionRowView: View {
    let transaction: TransactionModel
    @State private var animateAmount = false
    
    private var transactionColor: Color {
        switch transaction.type {
        case "expense": return .red
        case "salary": return .blue
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
            // Emoji o icona categoria
            ZStack {
                Circle()
                    .fill(transactionColor.opacity(0.1))
                    .frame(width: 48, height: 48)
                
                if !categoryEmoji.isEmpty {
                    Text(categoryEmoji)
                        .font(.title2)
                } else {
                    Image(systemName: transaction.type == "expense" ? "minus.circle" : "plus.circle")
                        .font(.title2)
                        .foregroundColor(transactionColor)
                }
            }
            
            // Contenuto
            VStack(alignment: .leading, spacing: 4) {
                // Descrizione principale
                Text(transaction.descr)
                    .font(.headline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                // Info secondarie
                HStack(spacing: 8) {
                    Text(cleanCategoryName)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("•")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(transaction.date, format: .dateTime.day().month(.abbreviated))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Importo
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(transaction.type == "expense" ? "-" : "+")€\(String(format: "%.0f", transaction.amount))")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(transactionColor)
                    .scaleEffect(animateAmount ? 1.05 : 1.0)
                    .animation(.easeInOut(duration: 0.3), value: animateAmount)
                
                Text(transaction.date, format: .dateTime.hour().minute())
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.02), radius: 4, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(.separator, lineWidth: 0.5)
        )
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                animateAmount = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    animateAmount = false
                }
            }
        }
    }
}

// MARK: - Versione con accento colorato laterale
struct AccentTransactionRowView: View {
    let transaction: TransactionModel
    @State private var animateAmount = false
    
    private var transactionColor: Color {
        switch transaction.type {
        case "expense": return .red
        case "salary": return .blue
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
        HStack(spacing: 0) {
            // Accento colorato laterale
            Rectangle()
                .fill(transactionColor)
                .frame(width: 4)
                .clipShape(
                    RoundedRectangle(cornerRadius: 2)
                )
            
            HStack(spacing: 16) {
                // Icona/Emoji
                if !categoryEmoji.isEmpty {
                    Text(categoryEmoji)
                        .font(.title2)
                        .frame(width: 40, height: 40)
                        .background(
                            Circle()
                                .fill(transactionColor.opacity(0.1))
                        )
                } else {
                    Image(systemName: transaction.type == "expense" ? "arrow.down.circle.fill" : "arrow.up.circle.fill")
                        .font(.title2)
                        .foregroundColor(transactionColor)
                        .frame(width: 40, height: 40)
                        .background(
                            Circle()
                                .fill(transactionColor.opacity(0.1))
                        )
                }
                
                // Contenuto principale
                VStack(alignment: .leading, spacing: 6) {
                    Text(transaction.descr)
                        .font(.headline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    HStack(spacing: 6) {
                        Text(cleanCategoryName)
                            .font(.subheadline)
                            .foregroundColor(transactionColor)
                            .fontWeight(.medium)
                        
                        Spacer()
                        
                        Text(transaction.date, format: .dateTime.day().month(.abbreviated).hour().minute())
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Importo
                Text("\(transaction.type == "expense" ? "-" : "+")€\(String(format: "%.0f", transaction.amount))")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(transactionColor)
                    .scaleEffect(animateAmount ? 1.05 : 1.0)
                    .animation(.easeInOut(duration: 0.3), value: animateAmount)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 3)
        )
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                animateAmount = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    animateAmount = false
                }
            }
        }
    }
}

// MARK: - Transaction Tag
struct TransactionTagView: View {
    let text: String
    let color: Color
    let icon: String
    
    var body: some View {
        HStack(spacing: 4) {
            if !icon.isEmpty {
                Image(systemName: icon)
                    .font(.caption2)
            }
            Text(text)
                .font(.caption)
                .lineLimit(1)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(color.opacity(0.1))
                .overlay(
                    Capsule()
                        .stroke(color.opacity(0.3), lineWidth: 0.5)
                )
        )
        .foregroundColor(color)
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

// MARK: - Simple Add Transaction View (AGGIORNATO CON DISTRIBUZIONE STIPENDIO)
// MARK: - Simple Add Transaction View (CORRETTO - GESTIONE CHIUSURA SHEET)
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
    
    let transactionTypes = [
        ("expense", "Spesa", "minus.circle"),
        ("income", "Entrata", "plus.circle"),
        ("salary", "Stipendio", "banknote")
    ]
    
    var availableCategories: [String] {
        switch transactionType {
        case "expense":
            return dataManager.expenseCategories
        default:
            return dataManager.incomeCategories
        }
    }
    
    var isFormValid: Bool {
        if transactionType == "expense" {
            // Per le spese: serve importo, descrizione e salvadanaio
            return amount > 0 &&
                   !descr.isEmpty &&
                   !selectedSalvadanaio.isEmpty &&
                   !selectedCategory.isEmpty
        } else if transactionType == "salary" {
            // Per gli stipendi: serve solo importo, descrizione e conto (la distribuzione avviene dopo)
            return amount > 0 &&
                   !descr.isEmpty &&
                   !selectedAccount.isEmpty
        } else {
            // Per entrate normali: serve importo, descrizione, categoria e conto
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
                            } else {
                                selectedCategory = ""
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
                
                // Dettagli base
                Section {
                    HStack {
                        Text("Importo")
                        Spacer()
                        TextField("0", value: $amount, format: .currency(code: "EUR"))
                            .multilineTextAlignment(.trailing)
                            .keyboardType(.decimalPad)
                    }
                    
                    TextField("Descrizione", text: $descr)
                        .textInputAutocapitalization(.sentences)
                } header: {
                    Text("Dettagli")
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
                        HStack {
                            Image(systemName: "banknote.fill")
                                .foregroundColor(.green)
                            Text("Salvadanaio")
                        }
                    } footer: {
                        if !selectedSalvadanaio.isEmpty {
                            let selectedSalv = dataManager.salvadanai.first { $0.name == selectedSalvadanaio }
                            if let salvadanaio = selectedSalv, salvadanaio.currentAmount < amount {
                                Text("⚠️ Attenzione: il salvadanaio non ha fondi sufficienti. Il saldo diventerà negativo.")
                                    .foregroundColor(.red)
                            } else {
                                Text("I soldi verranno prelevati da questo salvadanaio")
                                    .foregroundColor(.green)
                            }
                        } else {
                            Text("Scegli da quale salvadanaio prelevare i soldi per questa spesa")
                        }
                    }
                } else if transactionType == "expense" && dataManager.salvadanai.isEmpty {
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
                
                // Account per entrate e stipendi
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
                            Text("Lo stipendio verrà registrato su questo conto e poi potrai distribuirlo tra i salvadanai")
                        } else {
                            Text("L'entrata verrà aggiunta a questo conto")
                        }
                    }
                }
                
                // NUOVO: Info speciale per stipendi
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
                                    icon: "sparkles", // CAMBIATO: icona che esiste sicuramente
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
                    Button(transactionType == "salary" ? "Continua" : "Salva") {
                        saveTransaction()
                    }
                    .disabled(!isFormValid)
                    .fontWeight(.semibold)
                    .foregroundColor(isFormValid ? (transactionType == "salary" ? .orange : .blue) : .secondary)
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
                    // NUOVO: Callback che chiude il sheet principale
                    dismiss()
                }
            )
        }
    }
    
    private func getNavigationTitle() -> String {
        switch transactionType {
        case "expense": return "Nuova Spesa"
        case "salary": return "Nuovo Stipendio"
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
    }
    
    private func saveTransaction() {
        if transactionType == "expense" {
            // Per le spese: usa solo il salvadanaio
            dataManager.addTransaction(
                amount: amount,
                descr: descr,
                category: selectedCategory,
                type: transactionType,
                accountName: nil,
                salvadanaiName: selectedSalvadanaio
            )
            dismiss()
        } else if transactionType == "salary" {
            // Per gli stipendi: mostra la vista di distribuzione
            if dataManager.salvadanai.isEmpty {
                // Se non ci sono salvadanai, registra direttamente lo stipendio
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
                // Altrimenti, mostra la vista di distribuzione
                showingSalaryDistribution = true
            }
        } else {
            // Per entrate normali: usa solo il conto
            dataManager.addTransaction(
                amount: amount,
                descr: descr,
                category: selectedCategory,
                type: transactionType,
                accountName: selectedAccount,
                salvadanaiName: nil
            )
            dismiss()
        }
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

// MARK: - Compact Transactions Stats Header (MOLTO PIÙ COMPATTO)
struct CompactTransactionsStatsHeader: View {
    let totalExpenses: Double
    let totalIncome: Double
    let transactionCount: Int
    
    var body: some View {
        VStack(spacing: 10) {
            // Header titolo compatto
            HStack {
                Image(systemName: "chart.bar.fill")
                    .foregroundColor(.purple)
                    .font(.subheadline)
                Text("Riepilogo Transazioni")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            // Statistiche in riga orizzontale compatta
            HStack(spacing: 16) {
                CompactTransactionStatItem(
                    title: "Entrate",
                    amount: totalIncome,
                    icon: "plus.circle.fill",
                    color: .green
                )
                
                Divider()
                    .frame(height: 20)
                
                CompactTransactionStatItem(
                    title: "Spese",
                    amount: totalExpenses,
                    icon: "minus.circle.fill",
                    color: .red
                )
                
                Divider()
                    .frame(height: 20)
                
                CompactTransactionStatItem(
                    title: "Totali",
                    amount: Double(transactionCount),
                    icon: "list.bullet.circle.fill",
                    color: .blue,
                    isCount: true
                )
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12) // Ridotto da 24 a 12
        .background(
            RoundedRectangle(cornerRadius: 14) // Ridotto da 20 a 14
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 3) // Ridotta ombra
        )
    }
}

// MARK: - Compact Transaction Stat Item
struct CompactTransactionStatItem: View {
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
        VStack(spacing: 4) { // Ridotto da 8 a 4
            Image(systemName: icon)
                .font(.subheadline) // Ridotto da .title2 a .subheadline
                .foregroundColor(color)
            
            if isCount {
                Text("\(Int(amount))")
                    .font(.subheadline) // Ridotto da .headline a .subheadline
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
            } else {
                Text("€\(String(format: "%.0f", amount))")
                    .font(.subheadline) // Ridotto da .headline a .subheadline
                    .fontWeight(.bold)
                    .foregroundColor(color)
            }
            
            Text(title)
                .font(.caption2) // Ridotto da .caption a .caption2
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Versione minimale (stile AccountsView)
struct MinimalTransactionsStatsHeader: View {
    let totalExpenses: Double
    let totalIncome: Double
    let transactionCount: Int
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                // Entrate a sinistra
                VStack(alignment: .leading, spacing: 2) {
                    Text("Entrate Totali")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Text("€")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text(String(format: "%.0f", totalIncome))
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.green)
                    }
                }
                
                Spacer()
                
                // Spese e transazioni a destra
                VStack(alignment: .trailing, spacing: 2) {
                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Text("€")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(String(format: "%.0f", totalExpenses))
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundColor(.red)
                    }
                    
                    Text("\(transactionCount) transazioni")
                        .font(.caption2)
                        .foregroundColor(.blue)
                        .fontWeight(.medium)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 2)
        )
    }
}

// MARK: - Versione ultra-compatta (una sola riga)
struct UltraCompactTransactionsHeader: View {
    let totalExpenses: Double
    let totalIncome: Double
    let transactionCount: Int
    
    var body: some View {
        HStack {
            // Entrate
            HStack(spacing: 4) {
                Image(systemName: "plus.circle.fill")
                    .font(.caption)
                    .foregroundColor(.green)
                Text("€\(String(format: "%.0f", totalIncome))")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.green)
            }
            
            Spacer()
            
            // Numero transazioni al centro
            HStack(spacing: 4) {
                Image(systemName: "list.bullet.circle.fill")
                    .font(.caption)
                    .foregroundColor(.blue)
                Text("\(transactionCount)")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.blue)
            }
            
            Spacer()
            
            // Spese
            HStack(spacing: 4) {
                Image(systemName: "minus.circle.fill")
                    .font(.caption)
                    .foregroundColor(.red)
                Text("€\(String(format: "%.0f", totalExpenses))")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.red)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(.ultraThinMaterial)
        )
    }
}
