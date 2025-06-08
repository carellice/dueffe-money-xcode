import SwiftUI

// MARK: - Enhanced Accounts View
struct AccountsView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var showingAddAccount = false
    @State private var selectedAccount: AccountModel?
    @State private var searchText = ""
    
    var filteredAccounts: [AccountModel] {
        if searchText.isEmpty {
            return dataManager.accounts
        } else {
            return dataManager.accounts.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    var totalBalance: Double {
        dataManager.accounts.reduce(0) { $0 + $1.balance }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [Color.blue.opacity(0.05), Color.indigo.opacity(0.05)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
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
                        VStack(spacing: 0) {
                            // Header con statistiche
                            AccountsStatsHeader(
                                totalBalance: totalBalance,
                                accountCount: dataManager.accounts.count,
                                accounts: dataManager.accounts
                            )
                            .padding(.horizontal)
                            .padding(.bottom, 16)
                            
                            // Lista conti
                            ScrollView {
                                LazyVStack(spacing: 16) {
                                    ForEach(filteredAccounts, id: \.id) { account in
                                        EnhancedAccountCard(account: account)
                                            .onTapGesture {
                                                selectedAccount = account
                                            }
                                    }
                                }
                                .padding()
                            }
                            .searchable(text: $searchText, prompt: "Cerca conti...")
                        }
                    }
                }
            }
            .navigationTitle("Conti")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    FloatingActionButton(
                        icon: "plus.circle.fill",
                        color: .blue,
                        action: { showingAddAccount = true }
                    )
                }
            }
        }
        .sheet(isPresented: $showingAddAccount) {
            EnhancedAddAccountView()
        }
        .sheet(item: $selectedAccount) { account in
            EnhancedAccountDetailView(account: account)
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

// MARK: - Accounts Stats Header
struct AccountsStatsHeader: View {
    let totalBalance: Double
    let accountCount: Int
    let accounts: [AccountModel]
    
    private var positiveAccounts: Int {
        accounts.filter { $0.balance > 0 }.count
    }
    
    private var negativeAccounts: Int {
        accounts.filter { $0.balance < 0 }.count
    }
    
    private var averageBalance: Double {
        guard !accounts.isEmpty else { return 0 }
        return totalBalance / Double(accounts.count)
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Bilancio totale
            VStack(spacing: 8) {
                Text("Bilancio Totale")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text("€")
                        .font(.title)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    Text(String(format: "%.2f", totalBalance))
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(totalBalance >= 0 ? .primary : .red)
                        .contentTransition(.numericText())
                }
                
                Text(totalBalance >= 0 ? "Patrimonio positivo" : "Attenzione al bilancio")
                    .font(.caption)
                    .foregroundColor(totalBalance >= 0 ? .green : .red)
                    .fontWeight(.medium)
            }
            
            // Statistiche dettagliate
            HStack(spacing: 16) {
                AccountStatCard(
                    title: "Conti Totali",
                    value: "\(accountCount)",
                    icon: "building.columns.fill",
                    color: .blue
                )
                
                AccountStatCard(
                    title: "In Positivo",
                    value: "\(positiveAccounts)",
                    icon: "checkmark.circle.fill",
                    color: .green
                )
                
                AccountStatCard(
                    title: "Media",
                    value: "€\(String(format: "%.0f", averageBalance))",
                    icon: "chart.bar.fill",
                    color: .orange
                )
                
                if negativeAccounts > 0 {
                    AccountStatCard(
                        title: "In Rosso",
                        value: "\(negativeAccounts)",
                        icon: "exclamationmark.triangle.fill",
                        color: .red
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

// MARK: - Account Stat Card
struct AccountStatCard: View {
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
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }
}

// MARK: - Enhanced Account Card
struct EnhancedAccountCard: View {
    let account: AccountModel
    @EnvironmentObject var dataManager: DataManager
    @State private var isPressed = false
    
    private var relatedTransactions: [TransactionModel] {
        dataManager.transactions.filter { $0.accountName == account.name }
    }
    
    private var lastTransactionDate: Date? {
        relatedTransactions.max(by: { $0.date < $1.date })?.date
    }
    
    private var accountIcon: String {
        // Determina l'icona basata sul nome del conto
        let name = account.name.lowercased()
        if name.contains("carta") || name.contains("prepagata") {
            return "creditcard.fill"
        } else if name.contains("risparmio") {
            return "banknote.circle.fill"
        } else if name.contains("contanti") || name.contains("cash") {
            return "dollarsign.circle.fill"
        } else {
            return "building.columns.fill"
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header migliorato
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(LinearGradient(
                            gradient: Gradient(colors: [.blue, .indigo]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 56, height: 56)
                        .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
                    
                    Image(systemName: accountIcon)
                        .font(.title2)
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(account.name)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .lineLimit(2)
                    
                    HStack {
                        Image(systemName: "calendar")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("Creato \(account.createdAt, style: .date)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Status indicator
                VStack(alignment: .trailing, spacing: 4) {
                    if account.balance >= 0 {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.green)
                    } else {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.title2)
                            .foregroundColor(.red)
                    }
                    
                    Text(account.balance >= 0 ? "Attivo" : "In rosso")
                        .font(.caption2)
                        .foregroundColor(account.balance >= 0 ? .green : .red)
                        .fontWeight(.medium)
                }
            }
            
            // Saldo migliorato
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text("€")
                        .font(.title2)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    
                    Text(String(format: "%.2f", account.balance))
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(account.balance >= 0 ? .primary : .red)
                        .contentTransition(.numericText())
                }
                
                Text("Saldo disponibile")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            // Informazioni aggiuntive
            VStack(spacing: 12) {
                Divider()
                
                HStack {
                    // Ultima transazione
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Ultima attività")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        if let lastDate = lastTransactionDate {
                            HStack {
                                Image(systemName: "clock")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                                Text(lastDate, style: .relative)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                            }
                        } else {
                            HStack {
                                Image(systemName: "minus.circle")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                Text("Nessuna transazione")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    
                    Spacer()
                    
                    // Numero transazioni
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Transazioni")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        HStack {
                            Text("\(relatedTransactions.count)")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.blue)
                            Image(systemName: "list.bullet")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .shadow(color: account.balance < 0 ? .red.opacity(0.2) : .blue.opacity(0.1), radius: 12, x: 0, y: 6)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(account.balance < 0 ? Color.red.opacity(0.3) : Color.blue.opacity(0.2), lineWidth: 1)
        )
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
        .onTapGesture {
            withAnimation(.spring(response: 0.2, dampingFraction: 0.8)) {
                isPressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.2, dampingFraction: 0.8)) {
                    isPressed = false
                }
            }
        }
    }
}

// MARK: - Enhanced Add Account View
struct EnhancedAddAccountView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var dataManager: DataManager
    
    @State private var name = ""
    @State private var initialBalance = 0.0
    @State private var selectedAccountType = "checking"
    
    let accountTypes = [
        ("checking", "Conto Corrente", "building.columns.fill", Color.blue),
        ("savings", "Conto Risparmio", "banknote.circle.fill", Color.green),
        ("card", "Carta Prepagata", "creditcard.fill", Color.purple),
        ("cash", "Contanti", "dollarsign.circle.fill", Color.orange)
    ]
    
    var isFormValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [Color.blue.opacity(0.05), Color.indigo.opacity(0.05)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                Form {
                    // Tipo di conto
                    Section {
                        VStack(spacing: 16) {
                            ForEach(accountTypes, id: \.0) { type, title, icon, color in
                                AccountTypeCard(
                                    type: type,
                                    title: title,
                                    icon: icon,
                                    color: color,
                                    isSelected: selectedAccountType == type
                                ) {
                                    withAnimation(.spring()) {
                                        selectedAccountType = type
                                    }
                                }
                            }
                        }
                    } header: {
                        HStack {
                            Image(systemName: "list.bullet.circle.fill")
                                .foregroundColor(.blue)
                            Text("Tipo di conto")
                        }
                    }
                    .listRowBackground(Color.clear)
                    
                    // Informazioni del conto
                    Section {
                        HStack {
                            Image(systemName: "tag.fill")
                                .foregroundColor(.blue)
                                .frame(width: 24)
                            TextField("Nome del conto", text: $name)
                                .textInputAutocapitalization(.words)
                        }
                    } header: {
                        HStack {
                            Image(systemName: "info.circle.fill")
                                .foregroundColor(.blue)
                            Text("Informazioni del conto")
                        }
                    }
                    
                    // Saldo iniziale
                    Section {
                        HStack {
                            Image(systemName: "eurosign.circle.fill")
                                .foregroundColor(.green)
                                .frame(width: 24)
                            Text("Saldo iniziale")
                            Spacer()
                            TextField("0", value: $initialBalance, format: .currency(code: "EUR"))
                                .multilineTextAlignment(.trailing)
                                .keyboardType(.decimalPad)
                                .font(.headline)
                        }
                    } header: {
                        HStack {
                            Image(systemName: "banknote.circle.fill")
                                .foregroundColor(.green)
                            Text("Saldo")
                        }
                    } footer: {
                        Text("Inserisci il saldo attuale del conto. Puoi inserire un valore negativo se il conto è in rosso.")
                    }
                    
                    // Anteprima
                    Section {
                        HStack {
                            Image(systemName: getCurrentAccountIcon())
                                .foregroundColor(getCurrentAccountColor())
                                .frame(width: 24)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(name.isEmpty ? "Nome del conto" : name)
                                    .font(.headline)
                                    .foregroundColor(name.isEmpty ? .secondary : .primary)
                                
                                Text(getCurrentAccountType())
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 2) {
                                Text("€\(String(format: "%.2f", initialBalance))")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(initialBalance >= 0 ? .primary : .red)
                                
                                Text("Saldo")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 8)
                    } header: {
                        HStack {
                            Image(systemName: "eye.circle.fill")
                                .foregroundColor(.purple)
                            Text("Anteprima")
                        }
                    }
                }
                .scrollContentBackground(.hidden)
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
                        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
                        let finalName = "\(getCurrentAccountType()) - \(trimmedName)"
                        dataManager.addAccount(name: finalName, initialBalance: initialBalance)
                        dismiss()
                    }
                    .disabled(!isFormValid)
                    .fontWeight(.semibold)
                    .foregroundColor(isFormValid ? .blue : .secondary)
                }
            }
        }
    }
    
    private func getCurrentAccountIcon() -> String {
        accountTypes.first { $0.0 == selectedAccountType }?.2 ?? "building.columns.fill"
    }
    
    private func getCurrentAccountColor() -> Color {
        accountTypes.first { $0.0 == selectedAccountType }?.3 ?? .blue
    }
    
    private func getCurrentAccountType() -> String {
        accountTypes.first { $0.0 == selectedAccountType }?.1 ?? "Conto Corrente"
    }
}

// MARK: - Account Type Card
struct AccountTypeCard: View {
    let type: String
    let title: String
    let icon: String
    let color: Color
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(isSelected ?
                              LinearGradient(gradient: Gradient(colors: [color, color.opacity(0.7)]), startPoint: .topLeading, endPoint: .bottomTrailing) :
                              LinearGradient(gradient: Gradient(colors: [color.opacity(0.1)]), startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                        .frame(width: 50, height: 50)
                        .shadow(color: isSelected ? color.opacity(0.3) : .clear, radius: 8, x: 0, y: 4)
                    
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundColor(isSelected ? .white : color)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text(getDescription())
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(color)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? color.opacity(0.1) : Color.gray.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(isSelected ? color : Color.clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isSelected)
    }
    
    private func getDescription() -> String {
        switch type {
        case "checking": return "Conto principale per operazioni quotidiane"
        case "savings": return "Conto dedicato al risparmio"
        case "card": return "Carta prepagata o di debito"
        case "cash": return "Denaro contante"
        default: return "Altro tipo di conto"
        }
    }
}

// MARK: - Enhanced Account Detail View
struct EnhancedAccountDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var dataManager: DataManager
    let account: AccountModel
    
    @State private var showingDeleteAlert = false
    @State private var showingEditView = false
    
    var accountTransactions: [TransactionModel] {
        dataManager.transactions
            .filter { $0.accountName == account.name }
            .sorted { $0.date > $1.date }
    }
    
    var accountIcon: String {
        let name = account.name.lowercased()
        if name.contains("carta") || name.contains("prepagata") {
            return "creditcard.fill"
        } else if name.contains("risparmio") {
            return "banknote.circle.fill"
        } else if name.contains("contanti") || name.contains("cash") {
            return "dollarsign.circle.fill"
        } else {
            return "building.columns.fill"
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [Color.blue.opacity(0.05), Color.indigo.opacity(0.05)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 28) {
                        // Header principale
                        VStack(spacing: 24) {
                            ZStack {
                                Circle()
                                    .fill(LinearGradient(
                                        gradient: Gradient(colors: [.blue, .indigo]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ))
                                    .frame(width: 80, height: 80)
                                    .shadow(color: .blue.opacity(0.3), radius: 15, x: 0, y: 8)
                                
                                Image(systemName: accountIcon)
                                    .font(.system(size: 36))
                                    .foregroundColor(.white)
                            }
                            
                            VStack(spacing: 8) {
                                Text(account.name)
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .multilineTextAlignment(.center)
                                
                                HStack {
                                    Image(systemName: "calendar")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text("Creato il \(account.createdAt, style: .date)")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            // Saldo principale
                            VStack(spacing: 8) {
                                HStack(alignment: .firstTextBaseline, spacing: 6) {
                                    Text("€")
                                        .font(.title)
                                        .foregroundColor(.secondary)
                                    Text(String(format: "%.2f", account.balance))
                                        .font(.largeTitle)
                                        .fontWeight(.bold)
                                        .foregroundColor(account.balance >= 0 ? .primary : .red)
                                }
                                
                                Text("Saldo attuale")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                // Status badge
                                HStack {
                                    Image(systemName: account.balance >= 0 ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                                        .foregroundColor(account.balance >= 0 ? .green : .red)
                                    Text(account.balance >= 0 ? "Conto in positivo" : "Conto in rosso")
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .foregroundColor(account.balance >= 0 ? .green : .red)
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    Capsule()
                                        .fill((account.balance >= 0 ? Color.green : Color.red).opacity(0.1))
                                )
                            }
                        }
                        .padding(28)
                        .background(
                            RoundedRectangle(cornerRadius: 24)
                                .fill(.ultraThinMaterial)
                                .shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: 10)
                        )
                        
                        // Statistiche del conto
                        AccountStatisticsCard(account: account, transactions: accountTransactions)
                        
                        // Actions rapide
                        AccountActionsCard(account: account)
                        
                        // Transazioni recenti
                        if !accountTransactions.isEmpty {
                            AccountTransactionsCard(transactions: accountTransactions)
                        }
                    }
                    .padding()
                }
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
                        Button("Modifica", systemImage: "pencil") {
                            showingEditView = true
                        }
                        
                        Divider()
                        
                        Button("Elimina", systemImage: "trash", role: .destructive) {
                            showingDeleteAlert = true
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
        .sheet(isPresented: $showingEditView) {
            EditAccountView(account: account)
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

// MARK: - Account Statistics Card
struct AccountStatisticsCard: View {
    let account: AccountModel
    let transactions: [TransactionModel]
    
    private var totalExpenses: Double {
        transactions.filter { $0.type == "expense" }.reduce(0) { $0 + $1.amount }
    }
    
    private var totalIncome: Double {
        transactions.filter { $0.type != "expense" }.reduce(0) { $0 + $1.amount }
    }
    
    private var averageTransaction: Double {
        guard !transactions.isEmpty else { return 0 }
        return transactions.reduce(0) { $0 + $1.amount } / Double(transactions.count)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .foregroundColor(.blue)
                Text("Statistiche del Conto")
                    .font(.title3)
                    .fontWeight(.bold)
            }
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                AccountStatCard(
                    title: "Transazioni",
                    value: "\(transactions.count)",
                    icon: "list.bullet.circle.fill",
                    color: Color.blue
                )
                
                AccountStatCard(
                    title: "Entrate Totali",
                    value: "€\(String(format: "%.0f", totalIncome))",
                    icon: "plus.circle.fill",
                    color: Color.green
                )
                
                AccountStatCard(
                    title: "Spese Totali",
                    value: "€\(String(format: "%.0f", totalExpenses))",
                    icon: "minus.circle.fill",
                    color: Color.red
                )
                
                AccountStatCard(
                    title: "Media Trans.",
                    value: "€\(String(format: "%.0f", averageTransaction))",
                    icon: "chart.line.uptrend.xyaxis.circle.fill",
                    color: Color.orange
                )
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
        )
    }
}

// MARK: - Account Actions Card
struct AccountActionsCard: View {
    let account: AccountModel
    @State private var showingAddTransaction = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Image(systemName: "bolt.fill")
                    .foregroundColor(.orange)
                Text("Azioni Rapide")
                    .font(.title3)
                    .fontWeight(.bold)
            }
            
            HStack(spacing: 16) {
                AccountActionButton(
                    title: "Aggiungi Spesa",
                    icon: "minus.circle.fill",
                    colors: [.red, .pink],
                    action: { showingAddTransaction = true }
                )
                
                AccountActionButton(
                    title: "Aggiungi Entrata",
                    icon: "plus.circle.fill",
                    colors: [.green, .mint],
                    action: { showingAddTransaction = true }
                )
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
        )
        .sheet(isPresented: $showingAddTransaction) {
            SimpleAddTransactionView()
        }
    }
}

// MARK: - Account Action Button
struct AccountActionButton: View {
    let title: String
    let icon: String
    let colors: [Color]
    let action: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(LinearGradient(
                            gradient: Gradient(colors: colors),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 50, height: 50)
                        .shadow(color: colors.first?.opacity(0.3) ?? .clear, radius: 6, x: 0, y: 3)
                    
                    Image(systemName: icon)
                        .font(.title3)
                        .foregroundColor(.white)
                }
                
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.gray.opacity(0.05))
            )
        }
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }) {
            // Action eseguita nel button action
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Account Transactions Card
struct AccountTransactionsCard: View {
    let transactions: [TransactionModel]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Image(systemName: "creditcard.fill")
                    .foregroundColor(.purple)
                Text("Transazioni Recenti")
                    .font(.title3)
                    .fontWeight(.bold)
                
                Spacer()
                
                Text("\(transactions.count) totali")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color.gray.opacity(0.1))
                    )
            }
            
            VStack(spacing: 12) {
                ForEach(Array(transactions.prefix(5).enumerated()), id: \.element.id) { index, transaction in
                    CompactTransactionRow(transaction: transaction, isLast: index == min(4, transactions.count - 1))
                }
                
                if transactions.count > 5 {
                    HStack {
                        Image(systemName: "ellipsis")
                            .foregroundColor(.secondary)
                        Text("e altre \(transactions.count - 5) transazioni")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    .padding(.top, 8)
                }
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
        )
    }
}

// MARK: - Compact Transaction Row
struct CompactTransactionRow: View {
    let transaction: TransactionModel
    let isLast: Bool
    
    private var transactionColor: Color {
        switch transaction.type {
        case "expense": return .red
        case "salary": return .blue
        default: return .green
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Image(systemName: transaction.type == "expense" ? "minus.circle.fill" : "plus.circle.fill")
                    .foregroundColor(transactionColor)
                    .frame(width: 20)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(transaction.descr)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .lineLimit(1)
                    
                    HStack {
                        Text(transaction.category)
                            .font(.caption2)
                            .foregroundColor(transactionColor)
                        
                        Text("•")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        
                        Text(transaction.date, style: .date)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Text("\(transaction.type == "expense" ? "-" : "+")€\(String(format: "%.2f", transaction.amount))")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(transactionColor)
            }
            .padding(.vertical, 8)
            
            if !isLast {
                Divider()
                    .padding(.leading, 32)
            }
        }
    }
}

// MARK: - Edit Account View
struct EditAccountView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var dataManager: DataManager
    
    @State private var account: AccountModel
    
    init(account: AccountModel) {
        _account = State(initialValue: account)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("Nome del conto", text: $account.name)
                        .textInputAutocapitalization(.words)
                } header: {
                    Text("Nome")
                }
                
                Section {
                    HStack {
                        Text("Saldo attuale")
                        Spacer()
                        TextField("0", value: $account.balance, format: .currency(code: "EUR"))
                            .multilineTextAlignment(.trailing)
                            .keyboardType(.decimalPad)
                    }
                } header: {
                    Text("Saldo")
                } footer: {
                    Text("Modifica il saldo attuale del conto. Attenzione: questa modifica influenzerà il bilancio totale.")
                }
                
                Section {
                    HStack {
                        Text("Data di creazione")
                        Spacer()
                        Text(account.createdAt, style: .date)
                            .foregroundColor(.secondary)
                    }
                } header: {
                    Text("Informazioni")
                }
            }
            .navigationTitle("Modifica Conto")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Annulla") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Salva") {
                        if let index = dataManager.accounts.firstIndex(where: { $0.id == account.id }) {
                            dataManager.accounts[index] = account
                        }
                        dismiss()
                    }
                }
            }
        }
    }
}
