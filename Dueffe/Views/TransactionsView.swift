import SwiftUI

// MARK: - TransactionsView completamente riscritta
struct TransactionsView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var showingAddTransaction = false
    @State private var selectedFilter = "all"
    @State private var searchText = ""
    
    let filterOptions = [
        ("all", "Tutte", "list.bullet"),
        ("expense", "Spese", "minus.circle"),
        ("income", "Entrate", "plus.circle"),
        ("salary", "Stipendi", "banknote")
    ]
    
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
                            // Header con statistiche
                            TransactionsStatsHeaderView(
                                totalExpenses: totalExpenses,
                                totalIncome: totalIncome,
                                transactionCount: dataManager.transactions.count
                            )
                            .padding(.horizontal)
                            .padding(.bottom, 16)
                            
                            // Filtri
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(filterOptions, id: \.0) { filter, title, icon in
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
                                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                                    Button("Elimina", role: .destructive) {
                                                        withAnimation {
                                                            dataManager.deleteTransaction(transaction)
                                                        }
                                                    }
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
                    message: "Prima di procedere, devi creare almeno un conto nel tab 'Conti'",
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

// MARK: - Transactions Stats Header
struct TransactionsStatsHeaderView: View {
    let totalExpenses: Double
    let totalIncome: Double
    let transactionCount: Int
    
    private var netBalance: Double {
        totalIncome - totalExpenses
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Bilancio netto
            VStack(spacing: 8) {
                Text("Bilancio Netto")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text("€")
                        .font(.title)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    Text(String(format: "%.2f", netBalance))
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(netBalance >= 0 ? .green : .red)
                        .contentTransition(.numericText())
                }
                
                Text(netBalance >= 0 ? "In positivo" : "In negativo")
                    .font(.caption)
                    .foregroundColor(netBalance >= 0 ? .green : .red)
                    .fontWeight(.medium)
            }
            
            // Statistiche dettagliate
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

// MARK: - Transaction Row View
struct TransactionRowView: View {
    let transaction: TransactionModel
    @State private var animateAmount = false
    
    private var transactionColor: Color {
        switch transaction.type {
        case "expense": return .red
        case "salary": return .blue
        default: return .green
        }
    }
    
    private var iconName: String {
        switch transaction.type {
        case "expense": return "minus.circle.fill"
        case "salary": return "banknote.fill"
        default: return "plus.circle.fill"
        }
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Icona migliorata con animazione
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        gradient: Gradient(colors: [transactionColor, transactionColor.opacity(0.7)]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 48, height: 48)
                    .shadow(color: transactionColor.opacity(0.3), radius: 6, x: 0, y: 3)
                
                Image(systemName: iconName)
                    .font(.title3)
                    .foregroundColor(.white)
            }
            
            // Dettagli transazione
            VStack(alignment: .leading, spacing: 8) {
                Text(transaction.descr)
                    .font(.headline)
                    .fontWeight(.medium)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                // Tags
                HStack(spacing: 8) {
                    TransactionTagView(
                        text: transaction.category,
                        color: transactionColor,
                        icon: getCategoryIcon(transaction.category)
                    )
                    
                    TransactionTagView(
                        text: transaction.accountName,
                        color: .blue,
                        icon: "building.columns"
                    )
                    
                    if let salvadanaiName = transaction.salvadanaiName {
                        TransactionTagView(
                            text: salvadanaiName,
                            color: .green,
                            icon: "banknote"
                        )
                    }
                }
                
                HStack {
                    Text(transaction.date, style: .time)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(getTransactionTypeText())
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Importo
            VStack(alignment: .trailing, spacing: 6) {
                Text("\(transaction.type == "expense" ? "-" : "+")€\(String(format: "%.2f", transaction.amount))")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(transactionColor)
                    .scaleEffect(animateAmount ? 1.05 : 1.0)
                    .animation(.easeInOut(duration: 0.3), value: animateAmount)
                
                // Indicatore visivo del tipo
                Image(systemName: transaction.type == "expense" ? "arrow.down.circle.fill" : "arrow.up.circle.fill")
                    .font(.caption)
                    .foregroundColor(transactionColor.opacity(0.7))
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
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
    
    private func getCategoryIcon(_ category: String) -> String {
        // Estrae l'emoji dalla categoria se presente
        if let firstChar = category.first, firstChar.isEmoji {
            return ""
        }
        
        // Fallback icons basati sul tipo
        switch transaction.type {
        case "expense": return "cart"
        case "salary": return "banknote"
        default: return "plus"
        }
    }
    
    private func getTransactionTypeText() -> String {
        switch transaction.type {
        case "expense": return "Spesa"
        case "salary": return "Stipendio"
        default: return "Entrata"
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

// MARK: - Simple Add Transaction View
struct SimpleAddTransactionView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var dataManager: DataManager
    
    @State private var amount = 0.0
    @State private var descr = ""
    @State private var selectedCategory = ""
    @State private var transactionType = "expense"
    @State private var selectedAccount = ""
    @State private var selectedSalvadanaio = ""
    
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
        return amount > 0 &&
               !descr.isEmpty &&
               !selectedAccount.isEmpty &&
               (transactionType == "salary" || !selectedCategory.isEmpty)
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
                
                // Categoria
                if transactionType != "salary" && !availableCategories.isEmpty {
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
                } else if transactionType == "salary" {
                    Section {
                        HStack {
                            Text("Categoria")
                            Spacer()
                            Text("💼 Stipendio")
                                .foregroundColor(.secondary)
                        }
                    } header: {
                        Text("Categoria")
                    }
                }
                
                // Account
                if !dataManager.accounts.isEmpty {
                    Section {
                        Picker("Da quale conto", selection: $selectedAccount) {
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
                        Text("Conto")
                    }
                }
                
                // Salvadanaio (solo per spese)
                if transactionType == "expense" && !dataManager.salvadanai.isEmpty {
                    Section {
                        Picker("Da quale salvadanaio", selection: $selectedSalvadanaio) {
                            Text("Seleziona salvadanaio").tag("")
                            ForEach(dataManager.salvadanai, id: \.name) { salvadanaio in
                                HStack {
                                    Circle()
                                        .fill(Color(salvadanaio.color))
                                        .frame(width: 12, height: 12)
                                    Text(salvadanaio.name)
                                    Spacer()
                                    Text("€\(String(format: "%.2f", salvadanaio.currentAmount))")
                                        .foregroundColor(.secondary)
                                }
                                .tag(salvadanaio.name)
                            }
                        }
                    } header: {
                        Text("Salvadanaio")
                    } footer: {
                        Text("Opzionale: scegli da quale salvadanaio prelevare i soldi")
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
                    Button("Salva") {
                        saveTransaction()
                    }
                    .disabled(!isFormValid)
                }
            })
        }
        .onAppear(perform: setupDefaults)
    }
    
    private func getNavigationTitle() -> String {
        switch transactionType {
        case "expense": return "Nuova Spesa"
        case "salary": return "Nuovo Stipendio"
        default: return "Nuova Entrata"
        }
    }
    
    private func setupDefaults() {
        if selectedAccount.isEmpty && !dataManager.accounts.isEmpty {
            selectedAccount = dataManager.accounts.first!.name
        }
        
        if transactionType == "salary" {
            selectedCategory = "💼 Stipendio"
        }
    }
    
    private func saveTransaction() {
        dataManager.addTransaction(
            amount: amount,
            descr: descr,
            category: selectedCategory,
            type: transactionType,
            accountName: selectedAccount,
            salvadanaiName: selectedSalvadanaio.isEmpty ? nil : selectedSalvadanaio
        )
        dismiss()
    }
}
