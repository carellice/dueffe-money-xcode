import SwiftUI

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
        
        // Filtro per tipo
        if selectedFilter != "all" {
            transactions = transactions.filter { $0.type == selectedFilter }
        }
        
        // Filtro per ricerca
        if !searchText.isEmpty {
            transactions = transactions.filter { transaction in
                transaction.descr.localizedCaseInsensitiveContains(searchText) ||  // Cambiato da description a descr
                transaction.category.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return transactions.sorted { $0.date > $1.date }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                if dataManager.transactions.isEmpty {
                    EmptyStateView(
                        icon: "creditcard.fill",
                        title: "Nessuna Transazione",
                        subtitle: "Inizia aggiungendo le tue prime spese o entrate",
                        buttonText: "Aggiungi Transazione",
                        action: { showingAddTransaction = true }
                    )
                } else {
                    VStack(spacing: 0) {
                        // Filtri
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(filterOptions, id: \.0) { filter, title, icon in
                                    FilterButton(
                                        title: title,
                                        icon: icon,
                                        isSelected: selectedFilter == filter
                                    ) {
                                        selectedFilter = filter
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                        .padding(.vertical, 8)
                        
                        // Lista transazioni
                        List {
                            ForEach(groupedTransactions, id: \.0) { dateString, transactions in
                                Section(dateString) {
                                    ForEach(transactions, id: \.id) { transaction in
                                        TransactionDetailRow(transaction: transaction)
                                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                                Button("Elimina", role: .destructive) {
                                                    dataManager.deleteTransaction(transaction)
                                                }
                                            }
                                    }
                                }
                            }
                        }
                        .searchable(text: $searchText, prompt: "Cerca transazioni...")
                        .listStyle(PlainListStyle())
                    }
                }
            }
            .navigationTitle("Transazioni")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddTransaction = true }) {
                        Image(systemName: "plus.circle.fill")
                    }
                }
            }
        }
        .sheet(isPresented: $showingAddTransaction) {
            AddTransactionView()
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
}

// MARK: - Filter Button
struct FilterButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                Text(title)
            }
            .font(.subheadline)
            .fontWeight(.medium)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(isSelected ? Color.blue : Color.gray.opacity(0.15))
            .foregroundColor(isSelected ? .white : .primary)
            .clipShape(Capsule())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Transaction Detail Row
struct TransactionDetailRow: View {
    let transaction: TransactionModel
    
    var body: some View {
        HStack(spacing: 12) {
            // Icona tipo transazione
            Image(systemName: iconForTransaction)
                .font(.title2)
                .foregroundColor(colorForTransaction)
                .frame(width: 32, height: 32)
                .background(colorForTransaction.opacity(0.1))
                .clipShape(Circle())
            
            // Dettagli transazione
            VStack(alignment: .leading, spacing: 4) {
                Text(transaction.descr)  // Cambiato da description a descr
                    .font(.headline)
                    .lineLimit(1)
                
                HStack(spacing: 8) {
                    // Categoria
                    Text(transaction.category)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(colorForTransaction.opacity(0.1))
                        .foregroundColor(colorForTransaction)
                        .clipShape(Capsule())
                    
                    // Account
                    Text("• \(transaction.accountName)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if let salvadanaiName = transaction.salvadanaiName {
                        Text("• \(salvadanaiName)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Text(transaction.date, style: .time)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Importo
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(transaction.type == "expense" ? "-" : "+")€\(String(format: "%.2f", transaction.amount))")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(colorForTransaction)
                
                if transaction.type == "expense" {
                    Text("Spesa")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                } else {
                    Text(transaction.type == "salary" ? "Stipendio" : "Entrata")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    private var iconForTransaction: String {
        switch transaction.type {
        case "expense":
            return "minus.circle.fill"
        case "salary":
            return "banknote.fill"
        default:
            return "plus.circle.fill"
        }
    }
    
    private var colorForTransaction: Color {
        switch transaction.type {
        case "expense":
            return .red
        case "salary":
            return .blue
        default:
            return .green
        }
    }
}

// MARK: - Add Transaction View
struct AddTransactionView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var dataManager: DataManager
    
    @State private var amount = 0.0
    @State private var descr = ""  // Cambiato da description a descr
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
    
    var body: some View {
        NavigationView {
            Form {
                // Tipo transazione
                Section {
                    VStack(spacing: 12) {
                        ForEach(transactionTypes, id: \.0) { type, title, icon in
                            Button(action: {
                                transactionType = type
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
                    
                    TextField("Descrizione", text: $descr)  // Cambiato da description a descr
                        .textInputAutocapitalization(.sentences)
                } header: {
                    Text("Dettagli")
                }
                
                // Categoria
                if !availableCategories.isEmpty {
                    Section {
                        Picker("Categoria", selection: $selectedCategory) {
                            Text("Seleziona categoria").tag("")
                            ForEach(availableCategories, id: \.self) { category in
                                Text(category).tag(category)
                            }
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
                
                // Bottone speciale per stipendio
                if transactionType == "salary" {
                    Section {
                        Button("Gestisci Distribuzione Automatica") {
                            showingSalaryDistribution = true
                        }
                        .foregroundColor(.blue)
                    } footer: {
                        Text("Configura come distribuire automaticamente lo stipendio nei salvadanai Glass")
                    }
                }
            }
            .navigationTitle(transactionType == "expense" ? "Nuova Spesa" : (transactionType == "salary" ? "Nuovo Stipendio" : "Nuova Entrata"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Annulla") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Salva") {
                        saveTransaction()
                    }
                    .disabled(amount <= 0 || descr.isEmpty || selectedCategory.isEmpty || selectedAccount.isEmpty)  // Cambiato da description a descr
                }
            }
        }
        .onAppear(perform: setupDefaults)
        .sheet(isPresented: $showingSalaryDistribution) {
            SalaryDistributionView(
                salaryAmount: amount,
                accountName: selectedAccount,
                onDistribute: { amount, account, selectedSalvadanai in
                    dataManager.distributeSalary(
                        amount: amount,
                        toSalvadanai: selectedSalvadanai,
                        accountName: account
                    )
                    dismiss()
                }
            )
        }
    }
    
    private func setupDefaults() {
        if selectedAccount.isEmpty && !dataManager.accounts.isEmpty {
            selectedAccount = dataManager.accounts.first!.name
        }
        if selectedCategory.isEmpty && !availableCategories.isEmpty {
            selectedCategory = availableCategories.first!
        }
    }
    
    private func saveTransaction() {
        if transactionType == "salary" {
            showingSalaryDistribution = true
        } else {
            dataManager.addTransaction(
                amount: amount,
                descr: descr,  // Cambiato da description a descr
                category: selectedCategory,
                type: transactionType,
                accountName: selectedAccount,
                salvadanaiName: selectedSalvadanaio.isEmpty ? nil : selectedSalvadanaio
            )
            dismiss()
        }
    }
}

// MARK: - Salary Distribution View
struct SalaryDistributionView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var dataManager: DataManager
    
    let salaryAmount: Double
    let accountName: String
    let onDistribute: (Double, String, [String]) -> Void
    
    @State private var selectedSalvadanai: Set<String> = []
    @State private var showingAnimation = false
    
    var glassSalvadanai: [SalvadanaiModel] {
        dataManager.salvadanai.filter { $0.type == "glass" }
    }
    
    var totalDistributionAmount: Double {
        glassSalvadanai
            .filter { selectedSalvadanai.contains($0.name) }
            .reduce(0) { total, salvadanaio in
                total + max(0, salvadanaio.monthlyRefill - salvadanaio.currentAmount)
            }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                if glassSalvadanai.isEmpty {
                    EmptyStateView(
                        icon: "drop.fill",
                        title: "Nessun Salvadanaio Glass",
                        subtitle: "Crea almeno un salvadanaio Glass per utilizzare la distribuzione automatica",
                        buttonText: "Chiudi",
                        action: { dismiss() }
                    )
                } else {
                    ScrollView {
                        VStack(spacing: 20) {
                            // Header con info stipendio
                            VStack(spacing: 12) {
                                Text("Distribuzione Stipendio")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                
                                HStack(alignment: .firstTextBaseline, spacing: 4) {
                                    Text("€")
                                        .font(.title2)
                                        .foregroundColor(.secondary)
                                    Text(String(format: "%.2f", salaryAmount))
                                        .font(.largeTitle)
                                        .fontWeight(.bold)
                                }
                                
                                Text("Seleziona i salvadanai Glass da ricaricare")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            
                            // Lista salvadanai Glass
                            VStack(spacing: 12) {
                                ForEach(glassSalvadanai, id: \.id) { salvadanaio in
                                    GlassDistributionRow(
                                        salvadanaio: salvadanaio,
                                        isSelected: selectedSalvadanai.contains(salvadanaio.name)
                                    ) {
                                        if selectedSalvadanai.contains(salvadanaio.name) {
                                            selectedSalvadanai.remove(salvadanaio.name)
                                        } else {
                                            selectedSalvadanai.insert(salvadanaio.name)
                                        }
                                    }
                                }
                            }
                            
                            // Riepilogo distribuzione
                            if !selectedSalvadanai.isEmpty {
                                VStack(spacing: 16) {
                                    Divider()
                                    
                                    VStack(spacing: 8) {
                                        Text("Riepilogo Distribuzione")
                                            .font(.headline)
                                            .fontWeight(.semibold)
                                        
                                        HStack {
                                            Text("Totale da distribuire:")
                                            Spacer()
                                            Text("€\(String(format: "%.2f", totalDistributionAmount))")
                                                .fontWeight(.semibold)
                                                .foregroundColor(.blue)
                                        }
                                        
                                        HStack {
                                            Text("Rimanente disponibile:")
                                            Spacer()
                                            Text("€\(String(format: "%.2f", max(0, salaryAmount - totalDistributionAmount)))")
                                                .fontWeight(.semibold)
                                                .foregroundColor(.green)
                                        }
                                    }
                                    .padding()
                                    .background(Color.gray.opacity(0.1))
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Distribuzione")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Annulla") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Distribuisci") {
                        withAnimation {
                            showingAnimation = true
                        }
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                            onDistribute(salaryAmount, accountName, Array(selectedSalvadanai))
                        }
                    }
                    .disabled(selectedSalvadanai.isEmpty || totalDistributionAmount > salaryAmount)
                }
            }
        }
        .overlay {
            if showingAnimation {
                MoneyFlowAnimation(
                    fromAccount: accountName,
                    toSalvadanaio: "\(selectedSalvadanai.count) salvadanai",
                    amount: totalDistributionAmount
                )
            }
        }
    }
}

// MARK: - Glass Distribution Row
struct GlassDistributionRow: View {
    let salvadanaio: SalvadanaiModel
    let isSelected: Bool
    let onToggle: () -> Void
    
    var amountToAdd: Double {
        max(0, salvadanaio.monthlyRefill - salvadanaio.currentAmount)
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Checkbox
            Button(action: onToggle) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(isSelected ? .blue : .secondary)
            }
            .buttonStyle(PlainButtonStyle())
            
            // Info salvadanaio
            HStack(spacing: 12) {
                Circle()
                    .fill(Color(salvadanaio.color))
                    .frame(width: 16, height: 16)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(salvadanaio.name)
                        .font(.headline)
                        .fontWeight(.medium)
                    
                    HStack {
                        Text("€\(String(format: "%.0f", salvadanaio.currentAmount))")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Text("/ €\(String(format: "%.0f", salvadanaio.monthlyRefill))")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                if amountToAdd > 0 {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("+€\(String(format: "%.2f", amountToAdd))")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.green)
                        
                        Text("da aggiungere")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } else {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Completo")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.blue)
                        
                        Text("già pieno")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(isSelected ? Color.blue.opacity(0.1) : Color.gray.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
        )
        .onTapGesture {
            onToggle()
        }
        .disabled(amountToAdd <= 0)
        .opacity(amountToAdd > 0 ? 1.0 : 0.6)
    }
}

// MARK: - Accounts View
struct AccountsView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var showingAddAccount = false
    @State private var selectedAccount: AccountModel?
    
    var body: some View {
        NavigationView {
            VStack {
                if dataManager.accounts.isEmpty {
                    EmptyStateView(
                        icon: "building.columns.fill",
                        title: "Nessun Conto",
                        subtitle: "Aggiungi i tuoi conti correnti e carte per tenere traccia dei tuoi soldi",
                        buttonText: "Aggiungi Conto",
                        action: { showingAddAccount = true }
                    )
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(dataManager.accounts, id: \.id) { account in
                                AccountCard(account: account)
                                    .onTapGesture {
                                        selectedAccount = account
                                    }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Conti")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddAccount = true }) {
                        Image(systemName: "plus.circle.fill")
                    }
                }
            }
        }
        .sheet(isPresented: $showingAddAccount) {
            AddAccountView()
        }
        .sheet(item: $selectedAccount) { account in
            AccountDetailView(account: account)
        }
    }
}

// MARK: - Account Card
struct AccountCard: View {
    let account: AccountModel
    @State private var isPressed = false
    
    var body: some View {
        HStack(spacing: 16) {
            // Icona conto
            Image(systemName: "building.columns.fill")
                .font(.title)
                .foregroundColor(.blue)
                .frame(width: 48, height: 48)
                .background(Color.blue.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            
            // Dettagli conto
            VStack(alignment: .leading, spacing: 4) {
                Text(account.name)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text("Creato \(account.createdAt, style: .date)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Saldo
            VStack(alignment: .trailing, spacing: 2) {
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text("€")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text(String(format: "%.2f", account.balance))
                        .font(.title2)
                        .fontWeight(.bold)
                }
                
                Text("Saldo")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(20)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.easeInOut(duration: 0.1)) {
                    isPressed = false
                }
            }
        }
    }
}

// MARK: - Add Account View
struct AddAccountView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var dataManager: DataManager
    
    @State private var name = ""
    @State private var initialBalance = 0.0
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("Nome del conto", text: $name)
                        .textInputAutocapitalization(.words)
                } header: {
                    Text("Informazioni del conto")
                }
                
                Section {
                    HStack {
                        Text("Saldo iniziale")
                        Spacer()
                        TextField("0", value: $initialBalance, format: .currency(code: "EUR"))
                            .multilineTextAlignment(.trailing)
                            .keyboardType(.decimalPad)
                    }
                } header: {
                    Text("Saldo")
                } footer: {
                    Text("Inserisci il saldo attuale del conto")
                }
            }
            .navigationTitle("Nuovo Conto")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Annulla") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Salva") {
                        dataManager.addAccount(name: name, initialBalance: initialBalance)
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
}

// MARK: - Account Detail View
struct AccountDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var dataManager: DataManager
    let account: AccountModel
    
    @State private var showingDeleteAlert = false
    
    var accountTransactions: [TransactionModel] {
        dataManager.transactions
            .filter { $0.accountName == account.name }
            .sorted { $0.date > $1.date }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header del conto
                    VStack(spacing: 16) {
                        Image(systemName: "building.columns.fill")
                            .font(.system(size: 48))
                            .foregroundColor(.blue)
                        
                        Text(account.name)
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text("€")
                                .font(.title)
                                .foregroundColor(.secondary)
                            Text(String(format: "%.2f", account.balance))
                                .font(.largeTitle)
                                .fontWeight(.bold)
                        }
                        
                        Text("Saldo attuale")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(24)
                    .background(.regularMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    
                    // Transazioni del conto
                    if !accountTransactions.isEmpty {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Transazioni")
                                .font(.title3)
                                .fontWeight(.bold)
                            
                            ForEach(accountTransactions.prefix(10), id: \.id) { transaction in
                                TransactionDetailRow(transaction: transaction)
                            }
                            
                            if accountTransactions.count > 10 {
                                Text("... e altre \(accountTransactions.count - 10) transazioni")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .padding(.top, 8)
                            }
                        }
                        .padding(20)
                        .background(.regularMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                }
                .padding()
            }
            .navigationTitle("Dettagli Conto")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Chiudi") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button("Elimina", systemImage: "trash", role: .destructive) {
                            showingDeleteAlert = true
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
        .alert("Elimina Conto", isPresented: $showingDeleteAlert) {
            Button("Elimina", role: .destructive) {
                dataManager.deleteAccount(account)
                dismiss()
            }
            Button("Annulla", role: .cancel) { }
        } message: {
            Text("Sei sicuro di voler eliminare questo conto? Tutte le transazioni associate verranno mantenute ma non saranno più collegate a questo conto.")
        }
    }
}

// MARK: - Settings View
struct SettingsView: View {
    @EnvironmentObject var dataManager: DataManager
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    HStack {
                        Image(systemName: "app.badge.fill")
                            .foregroundColor(.blue)
                        Text("Dueffe")
                        Spacer()
                        Text("v1.0")
                            .foregroundColor(.secondary)
                    }
                } header: {
                    Text("App")
                }
                
                Section {
                    HStack {
                        Image(systemName: "banknote.fill")
                            .foregroundColor(.green)
                        Text("Totale Salvadanai")
                        Spacer()
                        Text("\(dataManager.salvadanai.count)")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Image(systemName: "creditcard.fill")
                            .foregroundColor(.orange)
                        Text("Totale Transazioni")
                        Spacer()
                        Text("\(dataManager.transactions.count)")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Image(systemName: "building.columns.fill")
                            .foregroundColor(.blue)
                        Text("Conti Configurati")
                        Spacer()
                        Text("\(dataManager.accounts.count)")
                            .foregroundColor(.secondary)
                    }
                } header: {
                    Text("Statistiche")
                }
                
                Section {
                    Text("Sviluppato con ❤️ per aiutarti a risparmiare")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                } footer: {
                    Text("Dueffe ti aiuta a gestire i tuoi salvadanai e a raggiungere i tuoi obiettivi finanziari")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                        .padding(.top)
                }
            }
            .navigationTitle("Impostazioni")
        }
    }
}
