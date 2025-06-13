import SwiftUI

// MARK: - Enhanced Accounts View (sezione da aggiornare)
// MARK: - Enhanced Accounts View (aggiornato per rimuovere context menu)
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
                            MinimalAccountsStatsHeader(
                                totalBalance: totalBalance,
                                accountCount: dataManager.accounts.count,
                                accounts: dataManager.accounts
                            )
                            .padding(.horizontal)
                            .padding(.bottom, 16)
                            
                            // Lista conti
                            ScrollView {
                                LazyVStack(spacing: 16) {
                                    ForEach(dataManager.sortedAccounts(filteredAccounts), id: \.id) { account in
                                        // MODIFICATO: Usa la nuova card con menu button, rimuovi onTapGesture per i dettagli
                                        EnhancedAccountCard(account: account)
                                            .onTapGesture {
                                                // Tap sulla card apre i dettagli
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

// MARK: - Versione alternativa ancora più minimalista
struct MinimalAccountsStatsHeader: View {
    let totalBalance: Double
    let accountCount: Int
    let accounts: [AccountModel]
    
    private var positiveAccounts: Int {
        accounts.filter { $0.balance > 0 }.count
    }
    
    private var negativeAccounts: Int {
        accounts.filter { $0.balance < 0 }.count
    }
    
    var body: some View {
        VStack(spacing: 8) {
            // Solo bilancio - RIMOSSO numero conti
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Bilancio Totale")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Text("")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text(totalBalance.italianCurrency)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(totalBalance >= 0 ? .primary : .red)
                    }
                }
                
                Spacer()
                
                // Solo statistiche positivi/negativi - RIMOSSO contatore totale
                VStack(alignment: .trailing, spacing: 2) {
                    if positiveAccounts > 0 && negativeAccounts > 0 {
                        HStack(spacing: 8) {
                            Text("\(positiveAccounts)+ ")
                                .font(.caption)
                                .foregroundColor(.green)
                                .fontWeight(.medium)
                            
                            Text("\(negativeAccounts)-")
                                .font(.caption)
                                .foregroundColor(.red)
                                .fontWeight(.medium)
                        }
                    } else if positiveAccounts > 0 {
                        Text("\(positiveAccounts) in positivo")
                            .font(.caption)
                            .foregroundColor(.green)
                            .fontWeight(.medium)
                    } else if negativeAccounts > 0 {
                        Text("\(negativeAccounts) in rosso")
                            .font(.caption)
                            .foregroundColor(.red)
                            .fontWeight(.medium)
                    }
                    
                    Text(totalBalance >= 0 ? "Situazione buona" : "Attenzione")
                        .font(.caption2)
                        .foregroundColor(totalBalance >= 0 ? .green : .red)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        )
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

// MARK: - Enhanced Account Card con supporto chiusura
struct EnhancedAccountCard: View {
    let account: AccountModel
    @EnvironmentObject var dataManager: DataManager
    @State private var isPressed = false
    @State private var showingDeleteAlert = false
    @State private var showingEditSheet = false
    @State private var showingCloseSheet = false // NUOVO
    @State private var animateBalance = false
    @State private var animateGlow = false
    @State private var animateIcon = false
    
    private var relatedTransactions: [TransactionModel] {
        dataManager.transactions.filter { $0.accountName == account.name }
    }
    
    private var accountIcon: String {
        let name = account.name.lowercased()
        if name.contains("carta") || name.contains("prepagata") {
            return "creditcard.fill"
        } else if name.contains("risparmio") {
            return "dollarsign.circle.fill"
        } else if name.contains("contanti") || name.contains("cash") {
            return "banknote.fill"
        } else {
            return "building.columns.fill"
        }
    }
    
    private var cardGradient: LinearGradient {
        if account.isClosed {
            // Gradiente grigio per conti chiusi
            return LinearGradient(
                gradient: Gradient(colors: [
                    Color.gray.opacity(0.6),
                    Color.secondary.opacity(0.5),
                    Color.gray.opacity(0.4)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else if account.balance >= 0 {
            return LinearGradient(
                gradient: Gradient(colors: [
                    Color.blue.opacity(0.8),
                    Color.indigo.opacity(0.9),
                    Color.purple.opacity(0.7)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            return LinearGradient(
                gradient: Gradient(colors: [
                    Color.red.opacity(0.8),
                    Color.orange.opacity(0.9),
                    Color.pink.opacity(0.7)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
    
    private var statusInfo: (String, Color, String) {
        if account.isClosed {
            return ("🔒 Chiuso", .gray, "lock.fill")
        } else if account.balance < 0 {
            return ("In Rosso", .red, "exclamationmark.triangle.fill")
        } else if account.balance >= 10000 {
            return ("Eccellente", .green, "star.fill")
        } else if account.balance >= 1000 {
            return ("Buono", .blue, "checkmark.circle.fill")
        } else {
            return ("In Crescita", .orange, "arrow.up.circle.fill")
        }
    }
    
    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                // Azione tap - apri dettagli
            }
        }) {
            ZStack {
                // Background card con gradiente animato
                RoundedRectangle(cornerRadius: 20)
                    .fill(cardGradient)
                    .frame(height: 140)
                    .shadow(
                        color: account.isClosed ? .gray.opacity(0.2) :
                               (account.balance >= 0 ? .blue.opacity(animateGlow ? 0.4 : 0.2) : .red.opacity(animateGlow ? 0.4 : 0.2)),
                        radius: animateGlow && !account.isClosed ? 15 : 8,
                        x: 0,
                        y: animateGlow && !account.isClosed ? 8 : 4
                    )
                    .animation(account.isClosed ? .none : .easeInOut(duration: 3).repeatForever(autoreverses: true), value: animateGlow)
                
                // Overlay pattern decorativo
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        RadialGradient(
                            gradient: Gradient(colors: [
                                Color.white.opacity(account.isClosed ? 0.1 : 0.25),
                                Color.clear,
                                Color.black.opacity(0.1)
                            ]),
                            center: .topTrailing,
                            startRadius: 20,
                            endRadius: 150
                        )
                    )
                    .frame(height: 140)
                
                // NUOVO: Simbolo lucchetto per conti chiusi
                if account.isClosed {
                    VStack {
                        HStack {
                            Spacer()
                            Image(systemName: "lock.fill")
                                .font(.title)
                                .foregroundColor(.white.opacity(0.3))
                                .padding(.top, 16)
                                .padding(.trailing, 20)
                        }
                        Spacer()
                    }
                }
                
                // Elementi decorativi fluttuanti (solo per conti aperti)
                if !account.isClosed {
                    GeometryReader { geometry in
                        ZStack {
                            // Cerchi decorativi piccoli
                            Circle()
                                .fill(Color.white.opacity(0.15))
                                .frame(width: 60, height: 60)
                                .position(x: geometry.size.width * 0.85, y: geometry.size.height * 0.25)
                                .scaleEffect(animateBalance ? 1.2 : 0.8)
                                .animation(.easeInOut(duration: 4).repeatForever(autoreverses: true), value: animateBalance)
                            
                            Circle()
                                .fill(Color.white.opacity(0.08))
                                .frame(width: 40, height: 40)
                                .position(x: geometry.size.width * 0.15, y: geometry.size.height * 0.75)
                                .scaleEffect(animateBalance ? 0.6 : 1.1)
                                .animation(.easeInOut(duration: 3.5).repeatForever(autoreverses: true), value: animateBalance)
                            
                            // Stelline decorative
                            Image(systemName: "sparkles")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.6))
                                .position(x: geometry.size.width * 0.2, y: geometry.size.height * 0.3)
                                .scaleEffect(animateGlow ? 1.3 : 0.7)
                                .animation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true), value: animateGlow)
                        }
                    }
                    .frame(height: 140)
                }
                
                // Contenuto principale compatto
                HStack(spacing: 16) {
                    // Icona account animata
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(account.isClosed ? 0.15 : 0.25))
                            .frame(width: 50, height: 50)
                            .blur(radius: animateGlow && !account.isClosed ? 1 : 0)
                        
                        if account.isClosed {
                            // Icona lucchetto per conti chiusi
                            Image(systemName: "lock.fill")
                                .font(.title3)
                                .foregroundColor(.white.opacity(0.7))
                        } else {
                            Image(systemName: accountIcon)
                                .font(.title2)
                                .foregroundColor(.white)
                                .rotationEffect(.degrees(animateIcon ? 2 : -2))
                                .animation(.easeInOut(duration: 3).repeatForever(autoreverses: true), value: animateIcon)
                        }
                    }
                    
                    // Informazioni conto compatte
                    VStack(alignment: .leading, spacing: 6) {
                        // Nome conto con possibile indicatore chiuso
                        HStack {
                            Text(account.name)
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                            
                            if account.isClosed {
                                Image(systemName: "lock.fill")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.7))
                            }
                        }
                        
                        // Saldo con animazione (solo per conti aperti)
                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text("")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.8))
                            
                            Text(account.balance.italianCurrency)
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .contentTransition(.numericText())
                                .scaleEffect(animateBalance && !account.isClosed ? 1.02 : 1.0)
                                .shadow(color: .white.opacity(0.5), radius: animateGlow && !account.isClosed ? 6 : 2)
                        }
                        
                        // Status e transazioni in una riga compatta
                        HStack(spacing: 12) {
                            // Status badge
                            HStack(spacing: 4) {
                                Image(systemName: statusInfo.2)
                                    .font(.caption2)
                                    .foregroundColor(account.isClosed ? .white.opacity(0.7) : statusInfo.1)
                                
                                Text(statusInfo.0)
                                    .font(.caption2)
                                    .fontWeight(.medium)
                                    .foregroundColor(.white.opacity(0.9))
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(
                                Capsule()
                                    .fill(Color.white.opacity(account.isClosed ? 0.1 : 0.2))
                            )
                            
                            // Transazioni count compatto
                            HStack(spacing: 4) {
                                Image(systemName: account.isClosed ? "lock.circle" : "list.bullet.circle")
                                    .font(.caption2)
                                    .foregroundColor(.white.opacity(0.8))
                                
                                Text("\(relatedTransactions.count)")
                                    .font(.caption2)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white.opacity(0.9))
                            }
                        }
                    }
                    
                    Spacer()
                    
                    // Menu compatto e data
                    VStack(spacing: 8) {
                        // Menu button compatto con opzioni diverse per conti chiusi/aperti
                        Menu {
                            if !account.isClosed {
                                // Menu per conti aperti
                                Button(action: {
                                    showingEditSheet = true
                                }) {
                                    Label("Modifica", systemImage: "pencil")
                                }
                                .tint(.primary)
                                
                                Button(action: {
                                    showingCloseSheet = true
                                }) {
                                    Label("Chiudi Conto", systemImage: "lock")
                                }
                                .tint(.orange)
                                
                                if relatedTransactions.isEmpty {
                                    Divider()
                                    Button(role: .destructive, action: {
                                        showingDeleteAlert = true
                                    }) {
                                        Label("Elimina", systemImage: "trash")
                                    }
                                    .tint(.red)
                                }
                            } else {
                                // Menu per conti chiusi
                                Button(action: {
                                    reopenAccount()
                                }) {
                                    Label("Riapri Conto", systemImage: "lock.open")
                                }
                                .tint(.green)
                            }
                        } label: {
                            Image(systemName: "ellipsis")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.white.opacity(0.8))
                                .frame(width: 32, height: 32)
                                .background(
                                    Circle()
                                        .fill(Color.white.opacity(account.isClosed ? 0.1 : 0.2))
                                )
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        // Data di creazione compatta
                        VStack(spacing: 2) {
                            Text("Creato")
                                .font(.caption2)
                                .foregroundColor(.white.opacity(0.7))
                            
                            Text(account.createdAt, format: .dateTime.day().month(.abbreviated))
                                .font(.caption2)
                                .fontWeight(.medium)
                                .foregroundColor(.white.opacity(0.9))
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }) {
            // Long press action
        }
        .onAppear {
            if !account.isClosed {
                withAnimation(.easeInOut(duration: 0.8).delay(0.2)) {
                    animateBalance = true
                }
                withAnimation(.easeInOut(duration: 1.2).delay(0.1)) {
                    animateGlow = true
                }
                withAnimation(.easeInOut(duration: 1.5).delay(0.3)) {
                    animateIcon = true
                }
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            EditAccountView(account: account)
        }
        .sheet(isPresented: $showingCloseSheet) {
            CloseAccountView(account: account)
        }
        .alert("Elimina Conto", isPresented: $showingDeleteAlert) {
            Button("Elimina", role: .destructive) {
                withAnimation {
                    dataManager.deleteAccount(account)
                }
            }
            Button("Annulla", role: .cancel) { }
        } message: {
            Text("Sei sicuro di voler eliminare il conto '\(account.name)'? Questa azione non può essere annullata.")
        }
    }
    
    // NUOVO: Funzione per riaprire un conto
    private func reopenAccount() {
        withAnimation {
            let success = dataManager.reopenAccount(account)
            if !success {
                // Potresti aggiungere un alert di errore qui se necessario
                print("Errore nella riapertura del conto")
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
        ("savings", "Conto Risparmio", "dollarsign.circle.fill", Color.green),
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
                                Text("€0,00")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primary)
                                
                                Text("Saldo iniziale")
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
                        dataManager.addAccount(name: finalName, initialBalance: 0.0)
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
            return "dollarsign.circle.fill"
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
                            
                            // Saldo principale con stato
                            VStack(spacing: 8) {
                                HStack(alignment: .firstTextBaseline, spacing: 6) {
                                    Text("")
                                        .font(.title)
                                        .foregroundColor(.secondary)
                                    Text(account.balance.italianCurrency)
                                        .font(.largeTitle)
                                        .fontWeight(.bold)
                                        .foregroundColor(account.balance >= 0 ? .primary : .red)
                                    
                                    // NUOVO: Indicatore per conto chiuso
                                    if account.isClosed {
                                        Image(systemName: "lock.fill")
                                            .font(.title2)
                                            .foregroundColor(.orange)
                                    }
                                }
                                
                                Text("Saldo attuale")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                // Status badge aggiornato
                                HStack {
                                    if account.isClosed {
                                        Image(systemName: "lock.fill")
                                            .foregroundColor(.orange)
                                        Text("Conto chiuso")
                                            .font(.caption)
                                            .fontWeight(.medium)
                                            .foregroundColor(.orange)
                                    } else {
                                        Image(systemName: account.balance >= 0 ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                                            .foregroundColor(account.balance >= 0 ? .green : .red)
                                        Text(account.balance >= 0 ? "Conto in positivo" : "Conto in rosso")
                                            .font(.caption)
                                            .fontWeight(.medium)
                                            .foregroundColor(account.balance >= 0 ? .green : .red)
                                    }
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    Capsule()
                                        .fill((account.isClosed ? Color.orange : (account.balance >= 0 ? Color.green : Color.red)).opacity(0.1))
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
                    value: "\(totalIncome.italianCurrency)",
                    icon: "plus.circle.fill",
                    color: Color.green
                )
                
                AccountStatCard(
                    title: "Spese Totali",
                    value: "\(totalExpenses.italianCurrency)",
                    icon: "minus.circle.fill",
                    color: Color.red
                )
                
                AccountStatCard(
                    title: "Media Trans.",
                    value: "\(averageTransaction.italianCurrency)",
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
                
                Text("\(transaction.type == "expense" ? "-" : "+")\(transaction.amount.italianCurrency)")
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

// MARK: - Edit Account View CORRETTA
struct EditAccountView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var dataManager: DataManager
    
    @State private var currentAccountName: String
    @State private var showingDeleteAlert = false
    private let account: AccountModel
    private let originalAccountName: String
    
    init(account: AccountModel) {
        self.account = account
        self.originalAccountName = account.name
        self._currentAccountName = State(initialValue: account.name)
    }
    
    private var hasChanges: Bool {
        currentAccountName.trimmingCharacters(in: .whitespacesAndNewlines) != originalAccountName
    }
    
    private var relatedTransactions: [TransactionModel] {
        dataManager.transactions.filter { transaction in
            transaction.accountName == originalAccountName ||
            (transaction.type == "transfer" && transaction.salvadanaiName == originalAccountName)
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
                
                Form {
                    // Anteprima del conto
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
                                            gradient: Gradient(colors: [.blue, .indigo]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ))
                                        .frame(width: 56, height: 56)
                                        .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
                                    
                                    Image(systemName: "building.columns.fill")
                                        .font(.title2)
                                        .foregroundColor(.white)
                                }
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(currentAccountName.isEmpty ? "Nome del conto" : currentAccountName)
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(currentAccountName.isEmpty ? .secondary : .primary)
                                        .lineLimit(2)
                                    
                                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                                        Text("")
                                            .font(.title3)
                                            .foregroundColor(.secondary)
                                        
                                        Text(account.balance.italianCurrency)
                                            .font(.title2)
                                            .fontWeight(.bold)
                                            .foregroundColor(account.balance >= 0 ? .primary : .red)
                                    }

                                    Text("Il saldo viene gestito tramite le transazioni")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
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
                                        .stroke(hasChanges ? Color.orange.opacity(0.3) : Color.blue.opacity(0.2), lineWidth: 1)
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
                                .foregroundColor(.blue)
                                .frame(width: 24)
                            
                            TextField("Nome del conto", text: $currentAccountName)
                                .textInputAutocapitalization(.words)
                                .font(.headline)
                        }
                    } header: {
                        HStack {
                            Image(systemName: "pencil")
                                .foregroundColor(.blue)
                            Text("Nome del Conto")
                        }
                    } footer: {
                        if !relatedTransactions.isEmpty {
                            VStack(alignment: .leading, spacing: 4) {
                                if hasChanges {
                                    Text("✅ Verranno aggiornate automaticamente \(relatedTransactions.count) transazioni associate")
                                        .foregroundColor(.green)
                                } else {
                                    Text("ℹ️ Ci sono \(relatedTransactions.count) transazioni associate a questo conto")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                    }
                    
                    // Informazioni del conto
                    Section {
                        HStack {
                            Image(systemName: "calendar")
                                .foregroundColor(.secondary)
                                .frame(width: 24)
                            
                            Text("Data di creazione")
                            Spacer()
                            Text(account.createdAt, style: .date)
                                .foregroundColor(.secondary)
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
                    } header: {
                        HStack {
                            Image(systemName: "info.circle.fill")
                                .foregroundColor(.purple)
                            Text("Informazioni")
                        }
                    }
                    
                    // Debug info (rimuovere in produzione)
                    if hasChanges {
                        Section {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("🔄 Debug Info:")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                
                                Text("Nome originale: '\(originalAccountName)'")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                
                                Text("Nome nuovo: '\(currentAccountName.trimmingCharacters(in: .whitespacesAndNewlines))'")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                
                                Text("Transazioni da aggiornare: \(relatedTransactions.count)")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 8)
                        } header: {
                            Text("Debug (solo per test)")
                        }
                    }
                    
                    // Sezione di eliminazione
                    if relatedTransactions.isEmpty {
                        Section {
                            Button(action: {
                                showingDeleteAlert = true
                            }) {
                                HStack {
                                    Image(systemName: "trash.fill")
                                        .foregroundColor(.red)
                                        .frame(width: 24)
                                    
                                    Text("Elimina Conto")
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
                            Text("Eliminare il conto è un'azione irreversibile.")
                        }
                    }
                }
                .scrollContentBackground(.hidden)
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
                        saveChanges()
                    }
                    .disabled(!hasChanges || currentAccountName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .fontWeight(.semibold)
                    .foregroundColor(hasChanges && !currentAccountName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .blue : .secondary)
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
            Text("Sei sicuro di voler eliminare il conto '\(account.name)'? Questa azione non può essere annullata.")
        }
    }
    
    private func saveChanges() {
        let newName = currentAccountName.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !newName.isEmpty else { return }
        guard newName != originalAccountName else { return }
        
        print("🚀 Avvio salvataggio modifiche conto")
        print("  - ID: \(account.id)")
        print("  - Nome originale: '\(originalAccountName)'")
        print("  - Nuovo nome: '\(newName)'")
        
        // Chiama il metodo del DataManager per aggiornare tutto
        dataManager.updateAccountName(account.id, oldName: originalAccountName, newName: newName)
        
        print("✅ Comando di aggiornamento inviato")
        
        dismiss()
    }
}

// MARK: - Account Preview Card
struct AccountPreviewCard: View {
    let account: AccountModel
    let balanceChange: Double
    let hasChanges: Bool
    
    private var accountIcon: String {
        let name = account.name.lowercased()
        if name.contains("carta") || name.contains("prepagata") {
            return "creditcard.fill"
        } else if name.contains("risparmio") {
            return "dollarsign.circle.fill"
        } else if name.contains("contanti") || name.contains("cash") {
            return "dollarsign.circle.fill"
        } else {
            return "building.columns.fill"
        }
    }
    
    var body: some View {
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
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(account.name.isEmpty ? "Nome del conto" : account.name)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(account.name.isEmpty ? .secondary : .primary)
                        .lineLimit(2)
                    
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("")
                            .font(.title3)
                            .foregroundColor(.secondary)
                        
                        Text(account.balance.italianCurrency)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(account.balance >= 0 ? .primary : .red)
                    }

                    Text("Il saldo viene gestito tramite le transazioni")
                        .font(.caption)
                        .foregroundColor(.secondary)
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
                        .stroke(hasChanges ? Color.orange.opacity(0.3) : Color.blue.opacity(0.2), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
        )
    }
}

// MARK: - Close Account View
struct CloseAccountView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var dataManager: DataManager
    
    let account: AccountModel
    @State private var selectedDestinationAccount: AccountModel?
    @State private var showingConfirmation = false
    @State private var showingSuccessAlert = false
    @State private var showingErrorAlert = false
    @State private var errorMessage = ""
    
    private var availableDestinationAccounts: [AccountModel] {
        dataManager.openAccounts.filter { $0.id != account.id }
    }
    
    private var canCloseWithoutTransfer: Bool {
        !account.hasNonZeroBalance
    }
    
    private var relatedTransactions: [TransactionModel] {
        dataManager.transactions.filter { transaction in
            transaction.accountName == account.name ||
            (transaction.type == "transfer" && transaction.salvadanaiName == account.name)
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [Color.orange.opacity(0.05), Color.red.opacity(0.05)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                Form {
                    // Account Info
                    Section {
                        AccountClosePreviewCard(account: account)
                    }
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())
                    
                    // Saldo e trasferimento
                    if account.hasNonZeroBalance {
                        Section {
                            VStack(alignment: .leading, spacing: 16) {
                                HStack {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundColor(.orange)
                                    Text("Saldo da trasferire")
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.orange)
                                }
                                
                                HStack {
                                    Text("Saldo attuale:")
                                    Spacer()
                                    Text(account.balance.italianCurrency)
                                        .font(.title2)
                                        .fontWeight(.bold)
                                        .foregroundColor(account.balance >= 0 ? .green : .red)
                                }
                                .padding(.vertical, 8)
                                .padding(.horizontal, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.orange.opacity(0.1))
                                )
                                
                                Text("Il saldo deve essere trasferito ad un altro conto prima della chiusura.")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        } header: {
                            HStack {
                                Image(systemName: "eurosign.circle.fill")
                                    .foregroundColor(.orange)
                                Text("Trasferimento Obbligatorio")
                            }
                        }
                        
                        // Selezione conto di destinazione
                        if !availableDestinationAccounts.isEmpty {
                            Section {
                                ForEach(availableDestinationAccounts, id: \.id) { destinationAccount in
                                    Button(action: {
                                        selectedDestinationAccount = destinationAccount
                                    }) {
                                        HStack {
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(destinationAccount.name)
                                                    .font(.headline)
                                                    .fontWeight(.medium)
                                                    .foregroundColor(.primary)
                                                
                                                Text("Saldo: \(destinationAccount.balance.italianCurrency)")
                                                    .font(.subheadline)
                                                    .foregroundColor(.secondary)
                                            }
                                            
                                            Spacer()
                                            
                                            if selectedDestinationAccount?.id == destinationAccount.id {
                                                Image(systemName: "checkmark.circle.fill")
                                                    .foregroundColor(.blue)
                                                    .font(.title2)
                                            }
                                        }
                                        .padding(.vertical, 4)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            } header: {
                                HStack {
                                    Image(systemName: "arrow.right.circle.fill")
                                        .foregroundColor(.blue)
                                    Text("Seleziona Conto di Destinazione")
                                }
                            } footer: {
                                if let selected = selectedDestinationAccount {
                                    Text("Il saldo di \(account.balance.italianCurrency) verrà trasferito a '\(selected.name)'")
                                        .foregroundColor(.blue)
                                }
                            }
                        } else {
                            Section {
                                HStack {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundColor(.red)
                                    Text("Nessun conto disponibile per il trasferimento")
                                        .foregroundColor(.red)
                                }
                                .padding(.vertical, 8)
                            } footer: {
                                Text("Devi avere almeno un altro conto aperto per trasferire il saldo.")
                                    .foregroundColor(.red)
                            }
                        }
                    } else {
                        // Conto con saldo zero
                        Section {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                    Text("Saldo Zero")
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.green)
                                }
                                
                                Text("Il conto ha saldo zero e può essere chiuso immediatamente.")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        } header: {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text("Pronto per la Chiusura")
                            }
                        }
                    }
                    
                    // Informazioni sulle transazioni
                    Section {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "lock.fill")
                                    .foregroundColor(.orange)
                                Text("Effetti della Chiusura")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                            }
                            
                            VStack(alignment: .leading, spacing: 8) {
                                EffectInfoRow(
                                    icon: "lock.circle.fill",
                                    text: "Il conto verrà contrassegnato come chiuso",
                                    color: .orange
                                )
                                
                                EffectInfoRow(
                                    icon: "creditcard.fill",
                                    text: "\(relatedTransactions.count) transazioni verranno bloccate",
                                    color: .red
                                )
                                
                                EffectInfoRow(
                                    icon: "trash.slash.fill",
                                    text: "Le transazioni bloccate non potranno essere eliminate",
                                    color: .red
                                )
                                
                                EffectInfoRow(
                                    icon: "eye.fill",
                                    text: "Tutto rimarrà visibile con il simbolo del lucchetto",
                                    color: .blue
                                )
                                
                                if account.hasNonZeroBalance {
                                    EffectInfoRow(
                                        icon: "arrow.right.circle.fill",
                                        text: "Il saldo verrà trasferito automaticamente",
                                        color: .green
                                    )
                                }
                            }
                        }
                    } header: {
                        HStack {
                            Image(systemName: "info.circle.fill")
                                .foregroundColor(.blue)
                            Text("Cosa Succede")
                        }
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Chiudi Conto")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Annulla") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Chiudi Conto") {
                        showingConfirmation = true
                    }
                    .disabled(!canProceedWithClosure)
                    .fontWeight(.semibold)
                    .foregroundColor(canProceedWithClosure ? .red : .secondary)
                }
            }
        }
        .alert("Conferma Chiusura", isPresented: $showingConfirmation) {
            Button("Chiudi", role: .destructive) {
                closeAccount()
            }
            Button("Annulla", role: .cancel) { }
        } message: {
            if account.hasNonZeroBalance {
                Text("Stai per chiudere il conto '\(account.name)' e trasferire \(account.balance.italianCurrency) a '\(selectedDestinationAccount?.name ?? "")'. Questa azione bloccherà \(relatedTransactions.count) transazioni. Vuoi continuare?")
            } else {
                Text("Stai per chiudere il conto '\(account.name)'. Questa azione bloccherà \(relatedTransactions.count) transazioni. Vuoi continuare?")
            }
        }
        .alert("Successo", isPresented: $showingSuccessAlert) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text("Il conto '\(account.name)' è stato chiuso con successo.")
        }
        .alert("Errore", isPresented: $showingErrorAlert) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private var canProceedWithClosure: Bool {
        if account.hasNonZeroBalance {
            return selectedDestinationAccount != nil && !availableDestinationAccounts.isEmpty
        } else {
            return true
        }
    }
    
    private func closeAccount() {
        if account.hasNonZeroBalance {
            guard let destination = selectedDestinationAccount else {
                errorMessage = "Seleziona un conto di destinazione per il trasferimento"
                showingErrorAlert = true
                return
            }
            
            let success = dataManager.closeAccount(account, transferingBalanceTo: destination)
            if success {
                showingSuccessAlert = true
            } else {
                errorMessage = "Errore durante la chiusura del conto"
                showingErrorAlert = true
            }
        } else {
            let success = dataManager.closeAccountWithZeroBalance(account)
            if success {
                showingSuccessAlert = true
            } else {
                errorMessage = "Errore durante la chiusura del conto"
                showingErrorAlert = true
            }
        }
    }
}

// MARK: - Account Close Preview Card
struct AccountClosePreviewCard: View {
    let account: AccountModel
    
    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Image(systemName: "lock.fill")
                    .foregroundColor(.orange)
                Text("Chiusura Conto")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.orange)
                Spacer()
            }
            
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(LinearGradient(
                            gradient: Gradient(colors: [.orange, .red]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 56, height: 56)
                        .shadow(color: .orange.opacity(0.3), radius: 8, x: 0, y: 4)
                    
                    Image(systemName: "building.columns.fill")
                        .font(.title2)
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(account.name)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                        .lineLimit(2)
                    
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text(account.balance.italianCurrency)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(account.balance >= 0 ? .green : .red)
                    }
                    
                    Text("Creato il \(account.createdAt, style: .date)")
                        .font(.caption)
                        .foregroundColor(.secondary)
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
                        .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
        )
    }
}

// MARK: - Effect Info Row
struct EffectInfoRow: View {
    let icon: String
    let text: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundColor(color)
                .frame(width: 20)
            
            Text(text)
                .font(.subheadline)
                .foregroundColor(.primary)
            
            Spacer()
        }
    }
}
