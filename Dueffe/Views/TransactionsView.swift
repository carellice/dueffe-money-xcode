import SwiftUI

// MARK: - TransactionsView - VERSIONE COMPLETA MODIFICATA
struct TransactionsView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var showingAddTransaction = false
    @State private var selectedFilter = "all"
    @State private var searchText = ""
    @State private var showingDeleteConfirmation = false
    @State private var showingReverseDistribution = false // NUOVO
    @State private var transactionToDelete: TransactionModel?
    
    // MODIFICATO: Filtro che esclude le distribuzioni
    private var availableFilterOptions: [(String, String, String)] {
        var filters: [(String, String, String)] = []
        
        // Filtra le transazioni escludendo le distribuzioni
        let filteredTransactions = dataManager.transactions.filter { $0.type != "distribution" }
        
        // Sempre mostra "Tutte" se ci sono transazioni (escludendo distribuzioni)
        if !filteredTransactions.isEmpty {
            filters.append(("all", "Tutte", "list.bullet"))
        }
        
        // Controllo per ogni tipo di transazione (escludendo distribuzioni)
        let transactionTypes = Set(filteredTransactions.map { $0.type })
        
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

        if transactionTypes.contains("transfer_salvadanai") {
            filters.append(("transfer_salvadanai", "Trasf. Salvadanai", "arrow.left.arrow.right.circle"))
        }
        
        return filters
    }
    
    // MODIFICATO: Filtro che esclude sempre le distribuzioni
    var filteredTransactions: [TransactionModel] {
        // Prima filtra le distribuzioni, poi applica gli altri filtri
        var transactions = dataManager.transactions.filter { $0.type != "distribution" }
        
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
                    } else if dataManager.transactions.filter({ $0.type != "distribution" }).isEmpty {
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
                            .padding(.vertical, 0)
                            
                            // Lista transazioni
                            List {
                                ForEach(groupedTransactions, id: \.0) { dateString, transactions in
                                    Section {
                                        ForEach(transactions, id: \.id) { transaction in
                                            TransactionRowView(transaction: transaction)
                                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
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
                    .disabled(dataManager.accounts.isEmpty)
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
        // NUOVO: Sheet per la distribuzione inversa
        .sheet(isPresented: $showingReverseDistribution) {
            if let transaction = transactionToDelete {
                ReverseSalaryDistributionView(
                    transaction: transaction,
                    onComplete: {
                        // Elimina definitivamente la transazione dopo la distribuzione inversa
                        withAnimation {
                            dataManager.transactions.removeAll { $0.id == transaction.id }
                        }
                        transactionToDelete = nil
                    }
                )
            }
        }
        // MODIFICATO: Alert per la conferma eliminazione
        .alert("Elimina Transazione", isPresented: $showingDeleteConfirmation) {
            Button("Elimina", role: .destructive) {
                if let transaction = transactionToDelete {
                    // NUOVO: Controlla se richiede distribuzione inversa
                    if dataManager.transactionRequiresReverseDistribution(transaction) {
                        showingReverseDistribution = true
                        showingDeleteConfirmation = false
                    } else {
                        // Eliminazione normale
                        withAnimation {
                            dataManager.deleteTransaction(transaction)
                        }
                        transactionToDelete = nil
                    }
                }
            }
            Button("Annulla", role: .cancel) {
                transactionToDelete = nil
            }
        } message: {
            if let transaction = transactionToDelete {
                // NUOVO: Messaggio diverso per transazioni che richiedono distribuzione inversa
                if dataManager.transactionRequiresReverseDistribution(transaction) {
                    Text("Eliminando '\(transaction.descr)' dovrai scegliere da quali salvadanai rimuovere \(transaction.amount.italianCurrency).\n\nVuoi continuare?")
                } else {
                    Text("Sei sicuro di voler eliminare '\(transaction.descr)'?\n\nQuesta azione non può essere annullata.")
                }
            } else {
                Text("Sei sicuro di voler eliminare questa transazione?")
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
    
    // MODIFICATO: Conteggio che esclude le distribuzioni
    private func getFilterCount(_ filter: String) -> Int {
        let nonDistributionTransactions = dataManager.transactions.filter { $0.type != "distribution" }
        
        if filter == "all" {
            return nonDistributionTransactions.count
        } else {
            return nonDistributionTransactions.filter { $0.type == filter }.count
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
                Text("\(amount.italianCurrency)")
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
// SOSTITUISCI LA TransactionRowView ESISTENTE CON QUESTA VERSIONE AGGIORNATA:

struct TransactionRowView: View {
    let transaction: TransactionModel
    @EnvironmentObject var dataManager: DataManager // AGGIUNTO
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
    
    // NUOVO: Indica se questa transazione richiede distribuzione inversa
    private var requiresReverseDistribution: Bool {
        dataManager.transactionRequiresReverseDistribution(transaction)
    }
    
    var body: some View {
        Button(action: {
            if showDetails {
                withAnimation(.easeOut(duration: 0.35)) {
                    showDetails = false
                }
            } else {
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
                                
                                // NUOVO: Indicatore per distribuzione inversa
                                if requiresReverseDistribution {
                                    Image(systemName: "exclamationmark.circle.fill")
                                        .font(.caption2)
                                        .foregroundColor(.yellow)
                                        .background(
                                            Circle()
                                                .fill(Color.white)
                                                .frame(width: 14, height: 14)
                                        )
                                        .offset(x: 16, y: -16)
                                }
                            }
                            
                            // Info principale
                            VStack(alignment: .leading, spacing: 4) {
                                // Descrizione
                                Text(transaction.descr)
                                    .font(showDetails ? .headline : .subheadline)
                                    .fontWeight(showDetails ? .semibold : .medium)
                                    .foregroundColor(.white)
                                    .lineLimit(showDetails ? 3 : 1)
                                    .fixedSize(horizontal: false, vertical: showDetails)
                                
                                // Categoria e orario (sempre visibili)
                                HStack(spacing: 8) {
                                    Text(cleanCategoryName)
                                        .font(showDetails ? .subheadline : .caption)
                                        .fontWeight(.medium)
                                        .foregroundColor(.white.opacity(0.9))
                                        .lineLimit(showDetails ? nil : 1)
                                        .fixedSize(horizontal: false, vertical: showDetails)
                                    
                                    if !showDetails {
                                        Circle()
                                            .fill(Color.white.opacity(0.6))
                                            .frame(width: 3, height: 3)
                                        
                                        Text(transaction.date, format: .dateTime.hour().minute())
                                            .font(.caption)
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
                                        .font(showDetails ? .title3 : .subheadline)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                    
                                    Text("\(transaction.amount.italianCurrency)")
                                        .font(showDetails ? .title2 : .callout)
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
                                        
                                        Text(transaction.amount.italianCurrency)
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.white)
                                    }
                                    
                                    // Conto utilizzato
                                    if !transaction.accountName.isEmpty && (transaction.type == "expense" || transaction.type == "income" || transaction.type == "salary") {
                                        HStack(spacing: 10) {
                                            Image(systemName: "building.columns")
                                                .font(.subheadline)
                                                .foregroundColor(.white.opacity(0.8))
                                                .frame(width: 20)
                                            
                                            Text("Conto: \(transaction.accountName)")
                                                .font(.subheadline)
                                                .foregroundColor(.white.opacity(0.9))
                                            
                                            Spacer()
                                        }
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
                                
                                // NUOVO: Avviso per distribuzione inversa
                                if requiresReverseDistribution {
                                    VStack(spacing: 0) {
                                        Rectangle()
                                            .fill(Color.white.opacity(0.1))
                                            .frame(height: 1)
                                            .padding(.horizontal, 16)
                                        
                                        HStack(spacing: 8) {
                                            Image(systemName: "info.circle.fill")
                                                .font(.caption)
                                                .foregroundColor(.yellow)
                                            
                                            Text("L'eliminazione richiederà distribuzione inversa dai salvadanai")
                                                .font(.caption2)
                                                .foregroundColor(.white.opacity(0.9))
                                                .fontWeight(.medium)
                                            
                                            Spacer()
                                        }
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(
                                            Color.yellow.opacity(0.1)
                                        )
                                    }
                                }
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
                                    Text(account.balance.italianCurrency)
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
                                    Text(account.balance.italianCurrency)
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
                                    Text("\(salvadanaio.currentAmount.italianCurrency)")
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
                                    Text("\(salvadanaio.currentAmount.italianCurrency)")
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
                                ForEach(dataManager.sortedSalvadanai, id: \.name) { salvadanaio in
                                    HStack {
                                        Text(salvadanaio.name)
                                        Spacer()
                                        Text("\(salvadanaio.currentAmount.italianCurrency)")
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
                            ForEach(dataManager.sortedAccounts, id: \.name) { account in
                                HStack {
                                    Text(account.name)
                                    Spacer()
                                    Text(account.balance.italianCurrency)
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
                            ForEach(dataManager.sortedAccounts, id: \.name) { account in
                                HStack {
                                    Text(account.name)
                                    Spacer()
                                    Text(account.balance.italianCurrency)
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
                    Text("-\(amount.italianCurrency)")
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
                    Text("+\(amount.italianCurrency)")
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

// MARK: - Reverse Salary Distribution View (Nuova Vista)
struct ReverseSalaryDistributionView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var dataManager: DataManager
    
    let transaction: TransactionModel
    let onComplete: () -> Void // Callback per eliminare definitivamente la transazione
    
    @State private var selectedSalvadanai: Set<String> = []
    @State private var customAmounts: [String: Double] = [:]
    @State private var distributionMode: DistributionMode = .equal
    @State private var showingAlert = false
    @State private var alertMessage = ""

    
    private var totalAvailableFunds: Double {
        dataManager.salvadanai.reduce(0) { total, salvadanaio in
            total + max(0, salvadanaio.currentAmount)
        }
    }
    
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
    
    private var totalToRemove: Double {
        switch distributionMode {
        case .equal:
            if selectedSalvadanai.isEmpty { return 0 }
            
            // NUOVO: Calcola il totale considerando i limiti dei salvadanai
            var total: Double = 0
            let equalAmountPerSalvadanaio = transaction.amount / Double(selectedSalvadanai.count)
            
            for salvadanaiName in selectedSalvadanai {
                if let salvadanaio = dataManager.salvadanai.first(where: { $0.name == salvadanaiName }) {
                    let maxRemovable = max(0, salvadanaio.currentAmount)
                    let actualAmount = min(equalAmountPerSalvadanaio, maxRemovable)
                    total += actualAmount
                }
            }
            return total
            
        case .custom:
            // NUOVO: Assicurati che gli importi personalizzati non superino i limiti
            var total: Double = 0
            for (salvadanaiName, amount) in customAmounts {
                if selectedSalvadanai.contains(salvadanaiName) {
                    if let salvadanaio = dataManager.salvadanai.first(where: { $0.name == salvadanaiName }) {
                        let maxRemovable = max(0, salvadanaio.currentAmount)
                        let actualAmount = min(amount, maxRemovable)
                        total += actualAmount
                    }
                }
            }
            return total
        }
    }

    
    private var remainingAmount: Double {
        transaction.amount - totalToRemove
    }
    
    private var isDistributionValid: Bool {
        guard !selectedSalvadanai.isEmpty else { return false }
        
        // NUOVO: Controlla che tutti i salvadanai selezionati abbiano fondi sufficienti
        for salvadanaiName in selectedSalvadanai {
            guard let salvadanaio = dataManager.salvadanai.first(where: { $0.name == salvadanaiName }) else { continue }
            
            let maxRemovable = max(0, salvadanaio.currentAmount)
            if maxRemovable <= 0 { return false }
            
            if distributionMode == .custom {
                let requestedAmount = customAmounts[salvadanaiName] ?? 0
                if requestedAmount > maxRemovable { return false }
            }
        }
        
        // Verifica che il totale sia uguale all'importo della transazione
        return abs(remainingAmount) < 0.01
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [Color.red.opacity(0.05), Color.orange.opacity(0.05)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header con riepilogo
                    ReverseDistributionHeaderView(
                        transaction: transaction,
                        totalToRemove: totalToRemove,
                        remainingAmount: remainingAmount
                    )
                    .padding(.horizontal)
                    .padding(.bottom, 16)
                    
                    if totalAvailableFunds < transaction.amount {
                        InsufficientFundsWarningCard(
                            transaction: transaction,
                            availableFunds: totalAvailableFunds
                        )
                        .padding(.horizontal)
                        .padding(.bottom, 16)
                    }
                    
                    Form {
                        // Modalità di distribuzione
                        Section {
                            ForEach(DistributionMode.allCases, id: \.self) { mode in
                                ReverseDistributionModeRow(
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
                            SectionHeader(icon: "gearshape.fill", title: "Modalità di Rimozione")
                        }
                        
                        // Lista salvadanai
                        Section {
                            if dataManager.salvadanai.isEmpty {
                                HStack {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundColor(.orange)
                                    Text("Nessun salvadanaio disponibile")
                                        .foregroundColor(.orange)
                                }
                                .padding(.vertical, 8)
                            } else {
                                ForEach(dataManager.salvadanai, id: \.id) { salvadanaio in
                                    ReverseSalvadanaiDistributionRow(
                                        salvadanaio: salvadanaio,
                                        isSelected: selectedSalvadanai.contains(salvadanaio.name),
                                        distributionMode: distributionMode,
                                        equalAmount: selectedSalvadanai.isEmpty ? 0 : transaction.amount / Double(selectedSalvadanai.count),
                                        customAmount: Binding(
                                            get: { customAmounts[salvadanaio.name] ?? 0 },
                                            set: { customAmounts[salvadanaio.name] = $0 }
                                        ),
                                        onToggle: {
                                            toggleSalvadanaio(salvadanaio.name)
                                        }
                                    )
                                }
                            }
                        } header: {
                            SectionHeader(icon: "minus.circle.fill", title: "Seleziona Salvadanai da cui Rimuovere")
                        } footer: {
                            if distributionMode == .custom && !selectedSalvadanai.isEmpty {
                                ReverseCustomDistributionFooterView(
                                    totalToRemove: totalToRemove,
                                    remainingAmount: remainingAmount,
                                    amount: transaction.amount
                                )
                            }
                        }
                        
                        // Azioni rapide per distribuzione personalizzata
                        if distributionMode == .custom && !selectedSalvadanai.isEmpty {
                            Section {
                                VStack(spacing: 12) {
                                    ReverseCustomDistributionQuickActionsView(
                                        selectedSalvadanai: selectedSalvadanai,
                                        totalAmount: transaction.amount,
                                        customAmounts: $customAmounts
                                    )
                                }
                            } header: {
                                SectionHeader(icon: "bolt.fill", title: "Azioni Rapide")
                            }
                        }
                    }
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("Rimuovi da Salvadanai")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Annulla") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Rimuovi e Elimina") {
                        performReverseDistribution()
                    }
                    .disabled(!isDistributionValid)
                    .fontWeight(.semibold)
                    .foregroundColor(isDistributionValid ? .red : .secondary)
                }
            }
        }
        .onAppear {
            setupInitialSelection()
        }
        .alert("Rimozione", isPresented: $showingAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
    }
    
    private func setupInitialSelection() {
        // NUOVO: Seleziona automaticamente solo i salvadanai che hanno fondi
        let salvadanaiWithFunds = dataManager.salvadanai.filter { $0.currentAmount > 0 }
        
        if salvadanaiWithFunds.count <= 3 {
            selectedSalvadanai = Set(salvadanaiWithFunds.map(\.name))
        } else {
            // Se ci sono molti salvadanai con fondi, seleziona i primi 3
            let firstThree = Array(salvadanaiWithFunds.prefix(3))
            selectedSalvadanai = Set(firstThree.map(\.name))
        }
    }

    
    private func toggleSalvadanaio(_ name: String) {
        if selectedSalvadanai.contains(name) {
            selectedSalvadanai.remove(name)
            customAmounts[name] = 0
        } else {
            selectedSalvadanai.insert(name)
            if distributionMode == .custom {
                customAmounts[name] = 0
            }
        }
    }
    
    private func performReverseDistribution() {
        guard isDistributionValid else {
            alertMessage = "La rimozione non è valida. Verifica che tutti i salvadanai abbiano fondi sufficienti e che l'importo totale sia corretto."
            showingAlert = true
            return
        }
        
        let finalAmounts: [String: Double]
        
        switch distributionMode {
        case .equal:
            let equalAmountPerSalvadanaio = transaction.amount / Double(selectedSalvadanai.count)
            var tempAmounts: [String: Double] = [:]
            
            for salvadanaiName in selectedSalvadanai {
                if let salvadanaio = dataManager.salvadanai.first(where: { $0.name == salvadanaiName }) {
                    let maxRemovable = max(0, salvadanaio.currentAmount)
                    let actualAmount = min(equalAmountPerSalvadanaio, maxRemovable)
                    if actualAmount > 0 {
                        tempAmounts[salvadanaiName] = actualAmount
                    }
                }
            }
            finalAmounts = tempAmounts
            
        case .custom:
            var tempAmounts: [String: Double] = [:]
            for (salvadanaiName, amount) in customAmounts {
                if selectedSalvadanai.contains(salvadanaiName) && amount > 0 {
                    if let salvadanaio = dataManager.salvadanai.first(where: { $0.name == salvadanaiName }) {
                        let maxRemovable = max(0, salvadanaio.currentAmount)
                        let actualAmount = min(amount, maxRemovable)
                        if actualAmount > 0 {
                            tempAmounts[salvadanaiName] = actualAmount
                        }
                    }
                }
            }
            finalAmounts = tempAmounts
        }
        
        // Verifica finale che il totale corrisponda
        let totalFinalAmount = finalAmounts.values.reduce(0, +)
        guard abs(transaction.amount - totalFinalAmount) < 0.01 else {
            alertMessage = "Errore: non è possibile rimuovere l'importo completo dai salvadanai selezionati. Alcuni salvadanai non hanno fondi sufficienti."
            showingAlert = true
            return
        }
        
        // Rimuovi dai salvadanai
        for (salvadanaiName, amount) in finalAmounts {
            if let index = dataManager.salvadanai.firstIndex(where: { $0.name == salvadanaiName }) {
                dataManager.salvadanai[index].currentAmount -= amount
            }
        }
        
        // Rimuovi dai conti
        if !transaction.accountName.isEmpty {
            dataManager.updateAccountBalance(accountName: transaction.accountName, amount: -transaction.amount)
        }
        
        // Chiama il callback per eliminare definitivamente la transazione
        onComplete()
        dismiss()
    }

}

// MARK: - Reverse Distribution Header View
struct ReverseDistributionHeaderView: View {
    let transaction: TransactionModel
    let totalToRemove: Double
    let remainingAmount: Double
    
    var body: some View {
        VStack(spacing: 20) {
            // Transazione da eliminare
            VStack(spacing: 8) {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text("ELIMINA:")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.red)
                    Text(transaction.amount.italianCurrency)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.red)
                }
                
                Text(transaction.descr)
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                HStack {
                    Image(systemName: "building.columns.fill")
                        .foregroundColor(.blue)
                    Text("dal conto \(transaction.accountName)")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                        .fontWeight(.medium)
                }
            }
            
            // Statistiche rimozione
            HStack(spacing: 20) {
                ReverseDistributionStatCard(
                    title: "Da Rimuovere",
                    amount: totalToRemove,
                    icon: "minus.circle.fill",
                    color: .red
                )
                
                ReverseDistributionStatCard(
                    title: "Rimanente",
                    amount: remainingAmount,
                    icon: remainingAmount > 0.01 ? "exclamationmark.circle.fill" : "checkmark.circle.fill",
                    color: remainingAmount > 0.01 ? .orange : .green
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

// MARK: - Reverse Distribution Stat Card
struct ReverseDistributionStatCard: View {
    let title: String
    let amount: Double
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(amount.italianCurrency)
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

// MARK: - Reverse Distribution Mode Row
struct ReverseDistributionModeRow: View {
    let mode: ReverseSalaryDistributionView.DistributionMode
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(isSelected ?
                              LinearGradient(gradient: Gradient(colors: [.red, .orange]), startPoint: .topLeading, endPoint: .bottomTrailing) :
                              LinearGradient(gradient: Gradient(colors: [Color.gray.opacity(0.1)]), startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                        .frame(width: 44, height: 44)
                        .shadow(color: isSelected ? .red.opacity(0.3) : .clear, radius: 6, x: 0, y: 3)
                    
                    Image(systemName: mode.icon)
                        .font(.title3)
                        .foregroundColor(isSelected ? .white : .secondary)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(mode.rawValue)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(isSelected ? .red : .primary)
                    
                    Text(mode.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.red)
                }
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(PlainButtonStyle())
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isSelected)
    }
}

// MARK: - Reverse Salvadanai Distribution Row
struct ReverseSalvadanaiDistributionRow: View {
    let salvadanaio: SalvadanaiModel
    let isSelected: Bool
    let distributionMode: ReverseSalaryDistributionView.DistributionMode
    let equalAmount: Double
    @Binding var customAmount: Double // Cambiato da let a @Binding
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
    
    // NUOVO: Calcola l'importo massimo che può essere rimosso
    private var maxRemovableAmount: Double {
        max(0, salvadanaio.currentAmount)
    }
    
    // NUOVO: Calcola l'importo sicuro per la distribuzione equa
    private var safeEqualAmount: Double {
        min(equalAmount, maxRemovableAmount)
    }
    
    private var displayAmount: Double {
        switch distributionMode {
        case .equal:
            return isSelected ? safeEqualAmount : 0
        case .custom:
            return min(customAmount, maxRemovableAmount)
        }
    }
    
    // NUOVO: Indica se l'importo è valido (non supera il saldo disponibile)
    private var isAmountValid: Bool {
        displayAmount <= maxRemovableAmount
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 16) {
                // Checkbox - MODIFICATO: disabilitato se il salvadanaio non ha fondi
                Button(action: {
                    if maxRemovableAmount > 0 {
                        onToggle()
                    }
                }) {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.title2)
                        .foregroundColor(
                            maxRemovableAmount > 0 ?
                            (isSelected ? .red : .secondary) :
                            .gray.opacity(0.5)
                        )
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(maxRemovableAmount <= 0)
                
                // Icona salvadanaio
                Circle()
                    .fill(getColor(from: salvadanaio.color))
                    .frame(width: 12, height: 12)
                    .opacity(maxRemovableAmount > 0 ? 1.0 : 0.5)
                
                // Info salvadanaio
                VStack(alignment: .leading, spacing: 4) {
                    Text(salvadanaio.name)
                        .font(.headline)
                        .fontWeight(.medium)
                        .foregroundColor(
                            maxRemovableAmount > 0 ?
                            (isSelected ? .primary : .secondary) :
                            .gray
                        )
                    
                    HStack {
                        // MODIFICATO: Mostra disponibile e massimo removibile
                        Text("Disponibile: \(salvadanaio.currentAmount.italianCurrency)")
                            .font(.caption)
                            .foregroundColor(salvadanaio.currentAmount >= 0 ? .green : .red)
                        
                        if maxRemovableAmount > 0 {
                            Text("• Max: \(maxRemovableAmount.italianCurrency)")
                                .font(.caption)
                                .foregroundColor(.blue)
                                .fontWeight(.medium)
                        }
                        
                        if salvadanaio.type == "objective" && !salvadanaio.isInfinite {
                            Text("• Obiettivo: \(salvadanaio.targetAmount.italianCurrency)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        } else if salvadanaio.type == "glass" {
                            Text("• Glass: \(salvadanaio.monthlyRefill.italianCurrency)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Spacer()
                
                // Campo importo per distribuzione personalizzata
                if distributionMode == .custom && isSelected && maxRemovableAmount > 0 {
                    VStack(spacing: 4) {
                        HStack {
                            Text("-")
                                .font(.subheadline)
                                .foregroundColor(.red)
                            
                            // MODIFICATO: TextField con validazione
                            TextField("0", value: Binding(
                                get: { customAmount },
                                set: { newValue in
                                    // NUOVO: Limita l'importo al massimo removibile
                                    customAmount = min(max(0, newValue), maxRemovableAmount)
                                }
                            ), format: .currency(code: "EUR"))
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(width: 80)
                            .keyboardType(.decimalPad)
                            .foregroundColor(isAmountValid ? .primary : .red)
                        }
                        
                        // NUOVO: Indicatore di validità
                        if !isAmountValid {
                            Text("Max: \(maxRemovableAmount.italianCurrency)")
                                .font(.caption2)
                                .foregroundColor(.red)
                        }
                    }
                } else if isSelected && displayAmount > 0 {
                    // Mostra importo per modalità equa
                    VStack(spacing: 4) {
                        Text("-\(displayAmount.italianCurrency)")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(isAmountValid ? .red : .orange)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill((isAmountValid ? Color.red : Color.orange).opacity(0.1))
                            )
                        
                        // NUOVO: Avviso se l'importo equo supera il disponibile
                        if distributionMode == .equal && equalAmount > maxRemovableAmount {
                            Text("Limitato a \(maxRemovableAmount.italianCurrency)")
                                .font(.caption2)
                                .foregroundColor(.orange)
                        }
                    }
                } else if maxRemovableAmount <= 0 {
                    // NUOVO: Indicatore per salvadanai senza fondi
                    Text("Nessun fondo")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(Color.gray.opacity(0.1))
                        )
                }
            }
            .padding(.vertical, 12)
            
            // Info saldo dopo rimozione
            if isSelected && displayAmount > 0 {
                let newBalance = salvadanaio.currentAmount - displayAmount
                VStack(alignment: .leading, spacing: 4) {
                    Divider()
                        .padding(.leading, 60)
                    
                    HStack {
                        Spacer()
                        VStack(alignment: .trailing, spacing: 2) {
                            // MODIFICATO: Sempre positivo o zero
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.caption2)
                                    .foregroundColor(.green)
                                Text("Saldo sicuro")
                                    .font(.caption2)
                                    .foregroundColor(.green)
                                    .fontWeight(.medium)
                            }
                            
                            Text("Nuovo saldo: \(newBalance.italianCurrency)")
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
        .opacity(maxRemovableAmount > 0 ? 1.0 : 0.6) // NUOVO: Opacità ridotta per salvadanai senza fondi
    }
}

// MARK: - Reverse Custom Distribution Footer
struct ReverseCustomDistributionFooterView: View {
    let totalToRemove: Double
    let remainingAmount: Double
    let amount: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Da rimuovere: \(totalToRemove.italianCurrency)")
                    .font(.caption)
                    .foregroundColor(.red)
                
                Spacer()
                
                Text("Rimanente: \(remainingAmount.italianCurrency)")
                    .font(.caption)
                    .foregroundColor(remainingAmount > 0.01 ? .orange : .green)
                    .fontWeight(.medium)
            }
            
            if abs(remainingAmount) > 0.01 {
                Text("⚠️ Rimozione incompleta. Assicurati che l'importo totale rimosso sia uguale all'importo della transazione.")
                    .font(.caption2)
                    .foregroundColor(.orange)
            } else {
                Text("✅ Rimozione completa!")
                    .font(.caption2)
                    .foregroundColor(.green)
            }
        }
    }
}

// MARK: - Reverse Custom Distribution Quick Actions
struct ReverseCustomDistributionQuickActionsView: View {
    let selectedSalvadanai: Set<String>
    let totalAmount: Double
    @Binding var customAmounts: [String: Double]
    
    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                // Distribuzione equa
                Button(action: {
                    let equalAmount = totalAmount / Double(selectedSalvadanai.count)
                    for name in selectedSalvadanai {
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
                    .background(Color.red.opacity(0.1))
                    .foregroundColor(.red)
                    .clipShape(Capsule())
                }
                
                // Reset
                Button(action: {
                    for name in selectedSalvadanai {
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
                    .background(Color.orange.opacity(0.1))
                    .foregroundColor(.orange)
                    .clipShape(Capsule())
                }
                
                Spacer()
            }
        }
    }
}

// MARK: - Insufficient Funds Warning Card
struct InsufficientFundsWarningCard: View {
    let transaction: TransactionModel
    let availableFunds: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                Text("Fondi Insufficienti")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.orange)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Importo da rimuovere:")
                    Spacer()
                    Text(transaction.amount.italianCurrency)
                        .fontWeight(.semibold)
                        .foregroundColor(.red)
                }
                
                HStack {
                    Text("Fondi disponibili:")
                    Spacer()
                    Text(availableFunds.italianCurrency)
                        .fontWeight(.semibold)
                        .foregroundColor(.green)
                }
                
                Divider()
                
                HStack {
                    Text("Mancano:")
                    Spacer()
                    Text((transaction.amount - availableFunds).italianCurrency)
                        .fontWeight(.bold)
                        .foregroundColor(.orange)
                }
            }
            
            Text("⚠️ Non è possibile eliminare questa transazione perché i salvadanai non hanno fondi sufficienti per coprire l'importo da rimuovere.")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.top, 8)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.orange.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                )
        )
    }
}
