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
                transaction.descr.localizedCaseInsensitiveContains(searchText) ||
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
                Text(transaction.descr)
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

// MARK: - Transaction Row View (for details)
struct TransactionRowView: View {
    let transaction: TransactionModel
    
    var body: some View {
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

// MARK: - Add Transaction View (con categorie personalizzabili)
struct AddTransactionView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var dataManager: DataManager
    
    @State private var amount = 0.0
    @State private var descr = ""
    @State private var selectedCategory = ""
    @State private var transactionType = "expense"
    @State private var selectedAccount = ""
    @State private var selectedSalvadanaio = ""
    @State private var showingSalaryDistribution = false
    @State private var showingAddCategory = false // Nuovo: mostra dialog per aggiungere categoria
    @State private var newCategoryText = "" // Nuovo: testo per nuova categoria
    
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
                                // Reset categoria quando cambia tipo, eccetto per stipendio
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
                
                // Categoria (solo per spese e entrate, non per stipendi)
                if transactionType != "salary" && !availableCategories.isEmpty {
                    Section {
                        VStack(spacing: 12) {
                            // Picker per categoria esistente
                            Picker("Categoria", selection: $selectedCategory) {
                                Text("Seleziona categoria")
                                    .tag("")
                                    .foregroundColor(.secondary)
                                ForEach(availableCategories, id: \.self) { category in
                                    Text(category).tag(category)
                                }
                            }
                            
                            // Bottone per aggiungere nuova categoria
                            Button(action: {
                                showingAddCategory = true
                            }) {
                                HStack {
                                    Image(systemName: "plus.circle.fill")
                                        .foregroundColor(.blue)
                                    Text("Aggiungi nuova categoria")
                                        .foregroundColor(.blue)
                                    Spacer()
                                }
                                .padding(.vertical, 8)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    } header: {
                        Text("Categoria")
                    } footer: {
                        Text("Seleziona una categoria esistente o creane una nuova")
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
                    } footer: {
                        Text("La categoria per gli stipendi è fissa")
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
                
                // Bottone distribuzione per tutte le entrate
                if (transactionType == "income" || transactionType == "salary") && !dataManager.salvadanai.isEmpty {
                    Section {
                        Button("Distribuisci ai Salvadanai") {
                            showingSalaryDistribution = true
                        }
                        .foregroundColor(.blue)
                    } footer: {
                        Text("Distribuisci automaticamente questa entrata nei tuoi salvadanai")
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
                    .disabled(amount <= 0 || descr.isEmpty || selectedAccount.isEmpty || (transactionType != "salary" && selectedCategory.isEmpty))
                }
            }
        }
        .onAppear(perform: setupDefaults)
        .sheet(isPresented: $showingSalaryDistribution) {
            SalaryDistributionView(
                salaryAmount: amount,
                accountName: selectedAccount,
                transactionType: transactionType,
                onDistribute: { amount, account, transactionType, salvadanaiAmounts in
                    dataManager.distributeIncomeWithCustomAmounts(
                        amount: amount,
                        salvadanaiAmounts: salvadanaiAmounts,
                        accountName: account,
                        transactionType: transactionType
                    )
                    dismiss()
                }
            )
        }
        .alert("Nuova Categoria", isPresented: $showingAddCategory) {
            TextField("Nome categoria", text: $newCategoryText)
            Button("Annulla", role: .cancel) {
                newCategoryText = ""
            }
            Button("Aggiungi") {
                addNewCategory()
            }
            .disabled(newCategoryText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        } message: {
            Text("Inserisci il nome della nuova categoria \(transactionType == "expense" ? "di spesa" : "di entrata")")
        }
    }
    
    private func setupDefaults() {
        // Auto-seleziona solo il primo conto se disponibile
        if selectedAccount.isEmpty && !dataManager.accounts.isEmpty {
            selectedAccount = dataManager.accounts.first!.name
        }
        
        // Auto-seleziona categoria solo per stipendi
        if transactionType == "salary" {
            selectedCategory = "💼 Stipendio"
        }
    }
    
    private func addNewCategory() {
        let categoryName = newCategoryText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !categoryName.isEmpty else { return }
        
        if transactionType == "expense" {
            dataManager.addExpenseCategory(categoryName)
        } else {
            dataManager.addIncomeCategory(categoryName)
        }
        
        // Seleziona automaticamente la nuova categoria
        selectedCategory = categoryName
        newCategoryText = ""
    }
    
    private func saveTransaction() {
        if transactionType == "salary" || transactionType == "income" {
            showingSalaryDistribution = true
        } else {
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
}

// MARK: - Custom Distribution Row
struct CustomDistributionRow: View {
    let salvadanaio: SalvadanaiModel
    let isSelected: Bool
    @Binding var customAmount: Double
    let onToggle: () -> Void
    
    var isAvailable: Bool {
        if salvadanaio.type == "glass" {
            return salvadanaio.currentAmount < salvadanaio.monthlyRefill
        } else {
            return salvadanaio.currentAmount < salvadanaio.targetAmount
        }
    }
    
    var body: some View {
        VStack(spacing: 12) {
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
                        HStack {
                            Text(salvadanaio.name)
                                .font(.headline)
                                .fontWeight(.medium)
                            
                            Image(systemName: salvadanaio.type == "glass" ? "drop.fill" : "target")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Text("€\(String(format: "%.0f", salvadanaio.currentAmount))")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            if salvadanaio.type == "glass" {
                                Text("/ €\(String(format: "%.0f", salvadanaio.monthlyRefill))")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            } else {
                                Text("/ €\(String(format: "%.0f", salvadanaio.targetAmount))")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    
                    Spacer()
                }
            }
            
            // Sezione importo personalizzabile (solo se selezionato)
            if isSelected {
                VStack(spacing: 8) {
                    Divider()
                    
                    HStack {
                        if salvadanaio.type == "glass" {
                            Text("Importo fisso:")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            Text("€\(String(format: "%.2f", customAmount))")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.green)
                        } else {
                            Text("Quanto vuoi aggiungere:")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            TextField("€", value: $customAmount, format: .currency(code: "EUR"))
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .keyboardType(.decimalPad)
                                .frame(width: 100)
                                .multilineTextAlignment(.trailing)
                        }
                    }
                    
                    if salvadanaio.type == "objective" {
                        HStack {
                            Button("€50") { customAmount = 50 }
                                .buttonStyle(PlainButtonStyle())
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.gray.opacity(0.2))
                                .clipShape(Capsule())
                            
                            Button("€100") { customAmount = 100 }
                                .buttonStyle(PlainButtonStyle())
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.gray.opacity(0.2))
                                .clipShape(Capsule())
                            
                            Button("Completa") {
                                customAmount = max(0, salvadanaio.targetAmount - salvadanaio.currentAmount)
                            }
                            .buttonStyle(PlainButtonStyle())
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.blue.opacity(0.2))
                            .clipShape(Capsule())
                            
                            Spacer()
                        }
                        .font(.caption)
                    }
                }
                .padding(.top, 8)
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
        .disabled(!isAvailable)
        .opacity(isAvailable ? 1.0 : 0.6)
    }
}

// MARK: - Salary Distribution View
struct SalaryDistributionView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var dataManager: DataManager
    
    let salaryAmount: Double
    let accountName: String
    let transactionType: String
    let onDistribute: (Double, String, String, [String: Double]) -> Void
    
    @State private var selectedSalvadanai: Set<String> = []
    @State private var customAmounts: [String: Double] = [:]
    @State private var showingAnimation = false
    
    var totalDistributionAmount: Double {
        dataManager.salvadanai
            .filter { selectedSalvadanai.contains($0.name) }
            .reduce(0) { total, salvadanaio in
                if let customAmount = customAmounts[salvadanaio.name] {
                    return total + customAmount
                } else if salvadanaio.type == "glass" {
                    return total + max(0, salvadanaio.monthlyRefill - salvadanaio.currentAmount)
                } else {
                    return total + min(100, max(0, salvadanaio.targetAmount - salvadanaio.currentAmount))
                }
            }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                if dataManager.salvadanai.isEmpty {
                    EmptyStateView(
                        icon: "banknote.fill",
                        title: "Nessun Salvadanaio",
                        subtitle: "Crea almeno un salvadanaio per utilizzare la distribuzione automatica",
                        buttonText: "Chiudi",
                        action: { dismiss() }
                    )
                } else {
                    ScrollView {
                        VStack(spacing: 20) {
                            // Header con info entrata
                            VStack(spacing: 12) {
                                Text("Distribuzione \(transactionType == "salary" ? "Stipendio" : "Entrata")")
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
                                
                                Text("Seleziona i salvadanai da ricaricare")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            
                            // Lista salvadanai
                            VStack(spacing: 12) {
                                ForEach(dataManager.salvadanai, id: \.id) { salvadanaio in
                                    CustomDistributionRow(
                                        salvadanaio: salvadanaio,
                                        isSelected: selectedSalvadanai.contains(salvadanaio.name),
                                        customAmount: customAmountBinding(for: salvadanaio)
                                    ) {
                                        toggleSalvadanaio(salvadanaio)
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
                            onDistribute(salaryAmount, accountName, transactionType, customAmounts.filter { selectedSalvadanai.contains($0.key) })
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
    
    private func defaultAmountFor(_ salvadanaio: SalvadanaiModel) -> Double {
        if salvadanaio.type == "glass" {
            return max(0, salvadanaio.monthlyRefill - salvadanaio.currentAmount)
        } else {
            return min(100, max(0, salvadanaio.targetAmount - salvadanaio.currentAmount))
        }
    }
    
    private func customAmountBinding(for salvadanaio: SalvadanaiModel) -> Binding<Double> {
        Binding(
            get: {
                customAmounts[salvadanaio.name] ?? defaultAmountFor(salvadanaio)
            },
            set: {
                customAmounts[salvadanaio.name] = $0
            }
        )
    }
    
    private func toggleSalvadanaio(_ salvadanaio: SalvadanaiModel) {
        if selectedSalvadanai.contains(salvadanaio.name) {
            selectedSalvadanai.remove(salvadanaio.name)
            customAmounts.removeValue(forKey: salvadanaio.name)
        } else {
            selectedSalvadanai.insert(salvadanaio.name)
            customAmounts[salvadanaio.name] = defaultAmountFor(salvadanaio)
        }
    }
}

// MARK: - Universal Distribution Row (compatibility)
struct UniversalDistributionRow: View {
    let salvadanaio: SalvadanaiModel
    let isSelected: Bool
    let onToggle: () -> Void
    
    var amountToAdd: Double {
        if salvadanaio.type == "glass" {
            return max(0, salvadanaio.monthlyRefill - salvadanaio.currentAmount)
        } else {
            return min(100, max(0, salvadanaio.targetAmount - salvadanaio.currentAmount))
        }
    }
    
    var isAvailable: Bool {
        if salvadanaio.type == "glass" {
            return amountToAdd > 0
        } else {
            return salvadanaio.currentAmount < salvadanaio.targetAmount
        }
    }
    
    var statusText: String {
        if salvadanaio.type == "glass" {
            return amountToAdd > 0 ? "da ricaricare" : "già pieno"
        } else {
            return salvadanaio.currentAmount < salvadanaio.targetAmount ? "obiettivo" : "completato"
        }
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
                    HStack {
                        Text(salvadanaio.name)
                            .font(.headline)
                            .fontWeight(.medium)
                        
                        Image(systemName: salvadanaio.type == "glass" ? "drop.fill" : "target")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("€\(String(format: "%.0f", salvadanaio.currentAmount))")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        if salvadanaio.type == "glass" {
                            Text("/ €\(String(format: "%.0f", salvadanaio.monthlyRefill))")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        } else {
                            Text("/ €\(String(format: "%.0f", salvadanaio.targetAmount))")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Spacer()
                
                if isAvailable {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("+€\(String(format: "%.0f", amountToAdd))")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.green)
                        
                        Text(statusText)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } else {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Completo")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.blue)
                        
                        Text(statusText)
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
        .disabled(!isAvailable)
        .opacity(isAvailable ? 1.0 : 0.6)
    }
}

// MARK: - Add Money to Salvadanaio View
struct AddMoneyToSalvadanaiView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var dataManager: DataManager
    let salvadanaio: SalvadanaiModel
    
    @State private var amount = 0.0
    @State private var selectedAccount = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    HStack {
                        Text("Importo")
                        Spacer()
                        TextField("0", value: $amount, format: .currency(code: "EUR"))
                            .multilineTextAlignment(.trailing)
                            .keyboardType(.decimalPad)
                    }
                } header: {
                    Text("Quanto vuoi aggiungere?")
                }
                
                if !dataManager.accounts.isEmpty {
                    Section {
                        Picker("Conto", selection: $selectedAccount) {
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
                        Text("Da quale conto?")
                    }
                }
            }
            .navigationTitle("Aggiungi Fondi")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Annulla") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Aggiungi") {
                        addMoney()
                    }
                    .disabled(amount <= 0 || selectedAccount.isEmpty)
                }
            }
        }
        .onAppear {
            if selectedAccount.isEmpty && !dataManager.accounts.isEmpty {
                selectedAccount = dataManager.accounts.first!.name
            }
        }
    }
    
    private func addMoney() {
        dataManager.addTransaction(
            amount: amount,
            descr: "Trasferimento a \(salvadanaio.name)",
            category: "💰 Trasferimento",
            type: "expense",
            accountName: selectedAccount,
            salvadanaiName: salvadanaio.name
        )
        dismiss()
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
            Image(systemName: "building.columns.fill")
                .font(.title)
                .foregroundColor(.blue)
                .frame(width: 48, height: 48)
                .background(Color.blue.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(account.name)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text("Creato \(account.createdAt, style: .date)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
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
        .background(Color.gray.opacity(0.1))
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
                    .background(Color.gray.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    
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
                        .background(Color.gray.opacity(0.1))
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

// MARK: - Settings View (versione aggiornata)
struct SettingsView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var showingCategoriesManagement = false
    
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
                    Button(action: {
                        showingCategoriesManagement = true
                    }) {
                        HStack {
                            Image(systemName: "tag.fill")
                                .foregroundColor(.purple)
                            Text("Gestisci Categorie")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .foregroundColor(.primary)
                } header: {
                    Text("Personalizzazione")
                } footer: {
                    Text("Aggiungi, modifica o elimina le categorie per spese e entrate")
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
                    
                    HStack {
                        Image(systemName: "tag.fill")
                            .foregroundColor(.purple)
                        Text("Categorie Personalizzate")
                        Spacer()
                        Text("\(dataManager.customExpenseCategories.count + dataManager.customIncomeCategories.count)")
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
        .sheet(isPresented: $showingCategoriesManagement) {
            CategoriesManagementView()
        }
    }
}

// MARK: - Empty State View
struct EmptyStateView: View {
    let icon: String
    let title: String
    let subtitle: String
    let buttonText: String
    let action: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: icon)
                .font(.system(size: 64))
                .foregroundColor(.secondary)
            
            VStack(spacing: 8) {
                Text(title)
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text(subtitle)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Button(action: action) {
                Text(buttonText)
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 12)
                    .background(.blue)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding(40)
    }
}

// MARK: - Categories Management View
struct CategoriesManagementView: View {
    @EnvironmentObject var dataManager: DataManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedTab = 0
    @State private var showingQuickAddExpense = false
    @State private var showingQuickAddIncome = false
    @State private var showingDeleteAlert = false
    @State private var categoryToDelete = ""
    
    var body: some View {
        NavigationView {
            VStack {
                // Tab Selector
                Picker("Tipo", selection: $selectedTab) {
                    Text("Spese").tag(0)
                    Text("Entrate").tag(1)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                // Categories List
                List {
                    if selectedTab == 0 {
                        // Expense Categories
                        Section {
                            ForEach(dataManager.defaultExpenseCategories, id: \.self) { category in
                                HStack {
                                    Text(category)
                                    Spacer()
                                    Text("Predefinita")
                                        .font(.caption)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 2)
                                        .background(Color.blue.opacity(0.1))
                                        .foregroundColor(.blue)
                                        .clipShape(Capsule())
                                }
                                .padding(.vertical, 2)
                            }
                        } header: {
                            HStack {
                                Text("Categorie Predefinite")
                                Spacer()
                                Text("\(dataManager.defaultExpenseCategories.count)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        if !dataManager.customExpenseCategories.isEmpty {
                            Section {
                                ForEach(dataManager.customExpenseCategories.sorted(), id: \.self) { category in
                                    HStack {
                                        Text(category)
                                        Spacer()
                                        Button(action: {
                                            categoryToDelete = category
                                            showingDeleteAlert = true
                                        }) {
                                            Image(systemName: "trash.circle.fill")
                                                .foregroundColor(.red)
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                    .padding(.vertical, 2)
                                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                        Button("Elimina", role: .destructive) {
                                            dataManager.deleteExpenseCategory(category)
                                        }
                                    }
                                }
                            } header: {
                                HStack {
                                    Text("Categorie Personalizzate")
                                    Spacer()
                                    Text("\(dataManager.customExpenseCategories.count)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            } footer: {
                                Text("Scorri verso sinistra per eliminare una categoria personalizzata")
                            }
                        }
                        
                        Section {
                            Button(action: {
                                showingQuickAddExpense = true
                            }) {
                                HStack {
                                    Image(systemName: "plus.circle.fill")
                                        .foregroundColor(.blue)
                                    Text("Aggiungi categoria spesa")
                                        .foregroundColor(.blue)
                                    Spacer()
                                }
                                .padding(.vertical, 8)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        
                    } else {
                        // Income Categories
                        Section {
                            ForEach(dataManager.defaultIncomeCategories, id: \.self) { category in
                                HStack {
                                    Text(category)
                                    Spacer()
                                    Text("Predefinita")
                                        .font(.caption)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 2)
                                        .background(Color.green.opacity(0.1))
                                        .foregroundColor(.green)
                                        .clipShape(Capsule())
                                }
                                .padding(.vertical, 2)
                            }
                        } header: {
                            HStack {
                                Text("Categorie Predefinite")
                                Spacer()
                                Text("\(dataManager.defaultIncomeCategories.count)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        if !dataManager.customIncomeCategories.isEmpty {
                            Section {
                                ForEach(dataManager.customIncomeCategories.sorted(), id: \.self) { category in
                                    HStack {
                                        Text(category)
                                        Spacer()
                                        Button(action: {
                                            categoryToDelete = category
                                            showingDeleteAlert = true
                                        }) {
                                            Image(systemName: "trash.circle.fill")
                                                .foregroundColor(.red)
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                    .padding(.vertical, 2)
                                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                        Button("Elimina", role: .destructive) {
                                            dataManager.deleteIncomeCategory(category)
                                        }
                                    }
                                }
                            } header: {
                                HStack {
                                    Text("Categorie Personalizzate")
                                    Spacer()
                                    Text("\(dataManager.customIncomeCategories.count)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            } footer: {
                                Text("Scorri verso sinistra per eliminare una categoria personalizzata")
                            }
                        }
                        
                        Section {
                            Button(action: {
                                showingQuickAddIncome = true
                            }) {
                                HStack {
                                    Image(systemName: "plus.circle.fill")
                                        .foregroundColor(.green)
                                    Text("Aggiungi categoria entrata")
                                        .foregroundColor(.green)
                                    Spacer()
                                }
                                .padding(.vertical, 8)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
                .listStyle(InsetGroupedListStyle())
            }
            .navigationTitle("Gestione Categorie")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Chiudi") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        if selectedTab == 0 {
                            showingQuickAddExpense = true
                        } else {
                            showingQuickAddIncome = true
                        }
                    }) {
                        Image(systemName: "plus.circle.fill")
                    }
                }
            }
        }
        .sheet(isPresented: $showingQuickAddExpense) {
            QuickCategoryAddView(categoryType: "expense")
        }
        .sheet(isPresented: $showingQuickAddIncome) {
            QuickCategoryAddView(categoryType: "income")
        }
        .alert("Elimina Categoria", isPresented: $showingDeleteAlert) {
            Button("Elimina", role: .destructive) {
                if selectedTab == 0 {
                    dataManager.deleteExpenseCategory(categoryToDelete)
                } else {
                    dataManager.deleteIncomeCategory(categoryToDelete)
                }
                categoryToDelete = ""
            }
            Button("Annulla", role: .cancel) {
                categoryToDelete = ""
            }
        } message: {
            Text("Sei sicuro di voler eliminare la categoria '\(categoryToDelete)'? Questa azione non può essere annullata.")
        }
    }
}

// MARK: - Quick Category Add View (versione corretta)
struct QuickCategoryAddView: View {
    @EnvironmentObject var dataManager: DataManager
    @Environment(\.dismiss) private var dismiss
    
    let categoryType: String // "expense" o "income"
    @State private var categoryName = ""
    @State private var selectedEmoji = "📝"
    
    let commonEmojis = ["📝", "💰", "🏠", "🚗", "🍕", "🎬", "👕", "🏥", "📚", "🎁", "💼", "📈", "💸", "🔄", "⚡", "🎮", "☕", "🛒", "💊", "🎯", "🎨", "🔧", "🎪", "⛽"]
    
    var title: String {
        categoryType == "expense" ? "Nuova Categoria Spesa" : "Nuova Categoria Entrata"
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    HStack {
                        Text("Emoji")
                        Spacer()
                        Text(selectedEmoji)
                            .font(.title2)
                    }
                    
                    // Griglia emoji con ScrollView
                    ScrollView(.horizontal, showsIndicators: false) {
                        LazyHGrid(rows: Array(repeating: GridItem(.fixed(50)), count: 2), spacing: 8) {
                            ForEach(Array(commonEmojis.enumerated()), id: \.offset) { index, emoji in
                                Button(action: {
                                    selectedEmoji = emoji
                                }) {
                                    Text(emoji)
                                        .font(.title2)
                                        .frame(width: 45, height: 45)
                                        .background(selectedEmoji == emoji ? Color.blue.opacity(0.2) : Color.gray.opacity(0.1))
                                        .clipShape(Circle())
                                        .overlay(
                                            Circle()
                                                .stroke(selectedEmoji == emoji ? Color.blue : Color.clear, lineWidth: 2)
                                        )
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.horizontal, 4)
                        .padding(.vertical, 8)
                    }
                    .frame(height: 110) // Altezza fissa per 2 righe
                    
                    // Opzione senza emoji
                    Button(action: {
                        selectedEmoji = ""
                    }) {
                        HStack {
                            Text("Nessuna emoji")
                                .foregroundColor(.secondary)
                            Spacer()
                            if selectedEmoji.isEmpty {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.blue)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                } header: {
                    Text("Icona (opzionale)")
                } footer: {
                    Text("Scorri orizzontalmente per vedere tutte le emoji disponibili")
                }
                
                Section {
                    TextField("Nome categoria", text: $categoryName)
                        .textInputAutocapitalization(.words)
                } header: {
                    Text("Nome")
                } footer: {
                    Text("Esempio: \(categoryType == "expense" ? "Benzina, Gaming, Farmaci" : "Cashback, Rimborsi, Vendite")")
                }
                
                Section {
                    HStack {
                        Text("Anteprima:")
                        Spacer()
                        Text(previewText)
                            .foregroundColor(categoryName.isEmpty ? .secondary : .primary)
                            .fontWeight(.medium)
                    }
                } header: {
                    Text("Risultato")
                }
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
                }
            }
        }
    }
    
    private var previewText: String {
        let name = categoryName.isEmpty ? "Nome categoria" : categoryName
        if selectedEmoji.isEmpty {
            return name
        } else {
            return "\(selectedEmoji) \(name)"
        }
    }
    
    private func addCategory() {
        let trimmedName = categoryName.trimmingCharacters(in: .whitespacesAndNewlines)
        let finalName = selectedEmoji.isEmpty ? trimmedName : "\(selectedEmoji) \(trimmedName)"
        
        if categoryType == "expense" {
            dataManager.addExpenseCategory(finalName)
        } else {
            dataManager.addIncomeCategory(finalName)
        }
        
        dismiss()
    }
}
