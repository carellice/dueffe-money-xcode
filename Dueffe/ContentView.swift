import SwiftUI

struct ContentView: View {
    @StateObject private var dataManager = DataManager()
    
    var body: some View {
        Group {
            if dataManager.accounts.isEmpty {
                // Mostra onboarding se non ci sono conti
                FirstAccountOnboardingView()
                    .environmentObject(dataManager)
            } else {
                // Mostra l'app normale se c'è almeno un conto
                MainTabView()
                    .environmentObject(dataManager)
            }
        }
    }
}

// MARK: - Main Tab View con grafica migliorata
struct MainTabView: View {
    @EnvironmentObject var dataManager: DataManager
    
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Home")
                }
            
            SalvadanaiView()
                .tabItem {
                    Image(systemName: "banknote.fill")
                    Text("Salvadanai")
                }
            
            TransactionsView()
                .tabItem {
                    Image(systemName: "creditcard.fill")
                    Text("Transazioni")
                }
            
            AccountsView()
                .tabItem {
                    Image(systemName: "building.columns.fill")
                    Text("Conti")
                }
            
            SettingsView()
                .tabItem {
                    Image(systemName: "gear")
                    Text("Impostazioni")
                }
        }
        .tint(.blue)
    }
}

// MARK: - First Account Onboarding migliorato
struct FirstAccountOnboardingView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var accountName = ""
    @State private var initialBalance = 0.0
    @State private var showingValidationError = false
    @State private var animateIcon = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 40) {
                        Spacer(minLength: 60)
                        
                        // Header migliorato
                        VStack(spacing: 30) {
                            ZStack {
                                Circle()
                                    .fill(LinearGradient(
                                        gradient: Gradient(colors: [Color.blue, Color.purple]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ))
                                    .frame(width: 120, height: 120)
                                    .shadow(color: .blue.opacity(0.3), radius: 20, x: 0, y: 10)
                                
                                Image(systemName: "building.columns.fill")
                                    .font(.system(size: 50))
                                    .foregroundColor(.white)
                                    .scaleEffect(animateIcon ? 1.1 : 1.0)
                                    .animation(.easeInOut(duration: 2).repeatForever(), value: animateIcon)
                            }
                            
                            VStack(spacing: 16) {
                                Text("Benvenuto in Dueffe! 👋")
                                    .font(.largeTitle)
                                    .fontWeight(.bold)
                                    .multilineTextAlignment(.center)
                                    .foregroundStyle(LinearGradient(
                                        gradient: Gradient(colors: [.blue, .purple]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    ))
                                
                                Text("Per iniziare, aggiungi il tuo primo conto")
                                    .font(.title3)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                        }
                        
                        // Form migliorato
                        VStack(spacing: 24) {
                            VStack(spacing: 20) {
                                // Campo nome conto
                                VStack(alignment: .leading, spacing: 12) {
                                    HStack {
                                        Image(systemName: "tag.fill")
                                            .foregroundColor(.blue)
                                        Text("Nome del conto")
                                            .font(.headline)
                                            .fontWeight(.semibold)
                                    }
                                    
                                    TextField("es. Conto Principale, Carta Prepagata...", text: $accountName)
                                        .textFieldStyle(ModernTextFieldStyle())
                                        .textInputAutocapitalization(.words)
                                }
                                
                                // Campo saldo
                                VStack(alignment: .leading, spacing: 12) {
                                    HStack {
                                        Image(systemName: "euroSign.circle.fill")
                                            .foregroundColor(.green)
                                        Text("Saldo attuale")
                                            .font(.headline)
                                            .fontWeight(.semibold)
                                    }
                                    
                                    HStack {
                                        Text("€")
                                            .font(.title2)
                                            .foregroundColor(.secondary)
                                            .padding(.leading, 16)
                                        
                                        TextField("0,00", value: $initialBalance, format: .currency(code: "EUR"))
                                            .textFieldStyle(ModernTextFieldStyle())
                                            .keyboardType(.decimalPad)
                                            .multilineTextAlignment(.trailing)
                                    }
                                }
                            }
                            .padding(28)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(.ultraThinMaterial)
                                    .shadow(color: .black.opacity(0.1), radius: 15, x: 0, y: 5)
                            )
                            
                            // Esempi migliorati
                            VStack(alignment: .leading, spacing: 16) {
                                HStack {
                                    Image(systemName: "lightbulb.fill")
                                        .foregroundColor(.orange)
                                    Text("💡 Esempi di conti:")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.primary)
                                }
                                
                                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                                    ExampleAccountCard(name: "Conto Corrente", icon: "building.columns", color: .blue)
                                    ExampleAccountCard(name: "Carta Prepagata", icon: "creditcard", color: .purple)
                                    ExampleAccountCard(name: "Conto Risparmio", icon: "banknote", color: .green)
                                    ExampleAccountCard(name: "Contanti", icon: "dollarsign.circle", color: .orange)
                                }
                            }
                        }
                        
                        Spacer(minLength: 40)
                        
                        // Bottone migliorato
                        VStack(spacing: 16) {
                            Button(action: {
                                createFirstAccount()
                            }) {
                                HStack {
                                    Text("Crea il mio primo conto")
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                    
                                    Image(systemName: "arrow.right.circle.fill")
                                        .font(.title2)
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(
                                    Group {
                                        if accountName.isEmpty {
                                            Color.gray
                                        } else {
                                            LinearGradient(
                                                gradient: Gradient(colors: [.blue, .purple]),
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        }
                                    }
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .shadow(color: accountName.isEmpty ? .clear : .blue.opacity(0.3), radius: 10, x: 0, y: 5)
                            }
                            .disabled(accountName.isEmpty)
                            .animation(.spring(response: 0.5, dampingFraction: 0.6), value: accountName.isEmpty)
                            
                            Text("Potrai aggiungere altri conti in seguito")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                    .padding()
                }
            }
            .navigationBarHidden(true)
        }
        .onAppear {
            animateIcon = true
        }
        .alert("Errore", isPresented: $showingValidationError) {
            Button("OK") { }
        } message: {
            Text("Inserisci un nome valido per il conto")
        }
    }
    
    private func createFirstAccount() {
        let trimmedName = accountName.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedName.isEmpty else {
            showingValidationError = true
            return
        }
        
        dataManager.addAccount(name: trimmedName, initialBalance: initialBalance)
        
        // Animazione di successo
        withAnimation(.spring()) {
            // L'app si aggiornerà automaticamente mostrando la TabView
        }
    }
}

// MARK: - Modern Text Field Style
struct ModernTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                    )
            )
    }
}

// MARK: - Example Account Card migliorato
struct ExampleAccountCard: View {
    let name: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
                .frame(width: 32, height: 32)
                .background(color.opacity(0.1))
                .clipShape(Circle())
            
            Text(name)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
                .lineLimit(1)
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.8))
                .shadow(color: color.opacity(0.2), radius: 5, x: 0, y: 2)
        )
    }
}

// MARK: - Home View migliorata
struct HomeView: View {
    @EnvironmentObject var dataManager: DataManager
    
    var totalBalance: Double {
        dataManager.accounts.reduce(0) { $0 + $1.balance }
    }
    
    var totalSavings: Double {
        dataManager.salvadanai.reduce(0) { $0 + $1.currentAmount }
    }
    
    var recentTransactions: [TransactionModel] {
        Array(dataManager.transactions.sorted { $0.date > $1.date }.prefix(5))
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient più sottile per far risaltare la card
                LinearGradient(
                    gradient: Gradient(colors: [Color.gray.opacity(0.02), Color.blue.opacity(0.02)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 28) {
                        // 🌟 NUOVA Enhanced Wealth Card
                        EnhancedWealthCard(
                            totalBalance: totalBalance,
                            totalSavings: totalSavings
                        )
                        
                        // Salvadanai Overview migliorato
                        if !dataManager.salvadanai.isEmpty {
                            VStack(alignment: .leading, spacing: 20) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("I Tuoi Salvadanai")
                                            .font(.title2)
                                            .fontWeight(.bold)
                                        Text("\(dataManager.salvadanai.count) salvadanai attivi")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    NavigationLink(destination: SalvadanaiView()) {
                                        HStack {
                                            Text("Vedi tutti")
                                                .font(.subheadline)
                                                .fontWeight(.medium)
                                            Image(systemName: "chevron.right")
                                                .font(.caption)
                                        }
                                        .foregroundColor(.blue)
                                    }
                                }
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 16) {
                                        ForEach(Array(dataManager.salvadanai.prefix(3)), id: \.id) { salvadanaio in
                                            ImprovedSalvadanaiHomeCard(salvadanaio: salvadanaio)
                                        }
                                    }
                                    .padding(.horizontal, 2)
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                        
                        // Transazioni Recenti migliorato
                        if !recentTransactions.isEmpty {
                            VStack(alignment: .leading, spacing: 20) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Transazioni Recenti")
                                            .font(.title2)
                                            .fontWeight(.bold)
                                        Text("Ultime \(recentTransactions.count) transazioni")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    NavigationLink(destination: TransactionsView()) {
                                        HStack {
                                            Text("Vedi tutte")
                                                .font(.subheadline)
                                                .fontWeight(.medium)
                                            Image(systemName: "chevron.right")
                                                .font(.caption)
                                        }
                                        .foregroundColor(.blue)
                                    }
                                }
                                
                                VStack(spacing: 12) {
                                    ForEach(recentTransactions, id: \.id) { transaction in
                                        ImprovedHomeTransactionRow(transaction: transaction)
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                        
                        // Navigazione rapida alle sezioni
                        VStack(alignment: .leading, spacing: 20) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Navigazione Rapida")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                Text("Accedi velocemente alle funzioni principali")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.horizontal, 20)
                            
                            VStack(spacing: 12) {
                                QuickNavigationCard(
                                    title: "Gestisci Salvadanai",
                                    subtitle: "Visualizza e modifica i tuoi obiettivi di risparmio",
                                    icon: "banknote.fill",
                                    colors: [.green, .mint],
                                    destination: AnyView(SalvadanaiView())
                                )
                                
                                QuickNavigationCard(
                                    title: "Tutte le Transazioni",
                                    subtitle: "Consulta lo storico completo delle operazioni",
                                    icon: "creditcard.fill",
                                    colors: [.purple, .blue],
                                    destination: AnyView(TransactionsView())
                                )
                                
                                QuickNavigationCard(
                                    title: "Gestisci Conti",
                                    subtitle: "Visualizza e modifica i tuoi conti correnti",
                                    icon: "building.columns.fill",
                                    colors: [.blue, .indigo],
                                    destination: AnyView(AccountsView())
                                )
                            }
                            .padding(.horizontal, 20)
                        }
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("Ciao! 👋")
            .refreshable {
                // Placeholder per refresh
            }
        }
    }
}

// MARK: - Quick Navigation Card
struct QuickNavigationCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let colors: [Color]
    let destination: AnyView
    @State private var isPressed = false
    
    var body: some View {
        NavigationLink(destination: destination) {
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
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
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }) {
            // Navigation gestita da NavigationLink
        }
    }
}

// MARK: - Floating Action Button
struct FloatingActionButton: View {
    let icon: String
    let color: Color
    let action: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.white)
                .frame(width: 50, height: 50)
                .background(
                    Circle()
                        .fill(LinearGradient(
                            gradient: Gradient(colors: [color, color.opacity(0.8)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .shadow(color: color.opacity(0.4), radius: 8, x: 0, y: 4)
                )
        }
        .scaleEffect(isPressed ? 0.9 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }) {
            // Action eseguita nel button action
        }
    }
}

// MARK: - Balance Breakdown Card
struct BalanceBreakdownCard: View {
    let title: String
    let amount: Double
    let color: Color
    let icon: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(color)
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text("€\(String(format: "%.2f", amount))")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(color)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(color.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

// MARK: - Improved Salvadanaio Home Card
struct ImprovedSalvadanaiHomeCard: View {
    let salvadanaio: SalvadanaiModel
    @State private var animateProgress = false
    
    var progress: Double {
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
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Circle()
                    .fill(LinearGradient(
                        gradient: Gradient(colors: [Color(salvadanaio.color), Color(salvadanaio.color).opacity(0.7)]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 16, height: 16)
                
                Text(salvadanaio.name)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .lineLimit(1)
                
                Spacer()
                
                if salvadanaio.currentAmount < 0 {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundColor(.red)
                } else if salvadanaio.type == "objective" && salvadanaio.isInfinite {
                    Image(systemName: "infinity")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    Image(systemName: salvadanaio.type == "objective" ? "target" : "drop.fill")
                        .font(.caption)
                        .foregroundColor(Color(salvadanaio.color))
                }
            }
            
            VStack(alignment: .leading, spacing: 12) {
                Text("€\(String(format: "%.0f", salvadanaio.currentAmount))")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(salvadanaio.currentAmount < 0 ? .red : .primary)
                
                if salvadanaio.currentAmount < 0 {
                    Text("In rosso")
                        .font(.caption)
                        .foregroundColor(.red)
                        .fontWeight(.medium)
                } else if salvadanaio.type == "objective" && salvadanaio.isInfinite {
                    Text("Obiettivo infinito")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else if salvadanaio.type == "objective" {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("di €\(String(format: "%.0f", salvadanaio.targetAmount))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.gray.opacity(0.2))
                                .frame(height: 6)
                            
                            RoundedRectangle(cornerRadius: 4)
                                .fill(LinearGradient(
                                    gradient: Gradient(colors: [Color(salvadanaio.color), Color(salvadanaio.color).opacity(0.7)]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ))
                                .frame(width: animateProgress ? progress * 140 : 0, height: 6)
                                .animation(.easeInOut(duration: 1.0), value: animateProgress)
                        }
                        .frame(width: 140)
                    }
                } else {
                    Text("/ €\(String(format: "%.0f", salvadanaio.monthlyRefill))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(20)
        .frame(width: 200)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .shadow(color: salvadanaio.currentAmount < 0 ? .red.opacity(0.2) : Color(salvadanaio.color).opacity(0.2), radius: 10, x: 0, y: 5)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(salvadanaio.currentAmount < 0 ? Color.red.opacity(0.3) : Color(salvadanaio.color).opacity(0.3), lineWidth: 1)
        )
        .onAppear {
            animateProgress = true
        }
    }
}

// MARK: - Improved Home Transaction Row
struct ImprovedHomeTransactionRow: View {
    let transaction: TransactionModel
    
    private var transactionColor: Color {
        switch transaction.type {
        case "expense": return .red
        case "salary": return .blue
        default: return .green
        }
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Icona migliorata
            ZStack {
                Circle()
                    .fill(transactionColor.opacity(0.1))
                    .frame(width: 44, height: 44)
                
                Image(systemName: transaction.type == "expense" ? "minus.circle.fill" : "plus.circle.fill")
                    .font(.title3)
                    .foregroundColor(transactionColor)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text(transaction.descr)
                    .font(.headline)
                    .fontWeight(.medium)
                    .lineLimit(1)
                
                HStack(spacing: 8) {
                    Text(transaction.category)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(transactionColor.opacity(0.1))
                        .foregroundColor(transactionColor)
                        .clipShape(Capsule())
                    
                    Text("• \(transaction.accountName)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(transaction.type == "expense" ? "-" : "+")€\(String(format: "%.2f", transaction.amount))")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(transactionColor)
                
                Text(transaction.date, style: .time)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.8))
                .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        )
    }
}

// MARK: - Improved Quick Action Card
struct ImprovedQuickActionCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let colors: [Color]
    let action: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(LinearGradient(
                            gradient: Gradient(colors: colors),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 60, height: 60)
                        .shadow(color: colors.first?.opacity(0.3) ?? .clear, radius: 8, x: 0, y: 4)
                    
                    Image(systemName: icon)
                        .font(.system(size: 28))
                        .foregroundColor(.white)
                }
                
                VStack(spacing: 4) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThinMaterial)
                    .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
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

// MARK: - Enhanced Wealth Card
struct EnhancedWealthCard: View {
    let totalBalance: Double
    let totalSavings: Double
    @State private var animateBalance = false
    @State private var animateGlow = false
    
    private var totalWealth: Double {
        totalBalance + totalSavings
    }
    
    private var wealthStatus: (String, Color, String) {
        if totalWealth >= 10000 {
            return ("Eccellente! 🚀", .green, "star.fill")
        } else if totalWealth >= 5000 {
            return ("Ottimo lavoro! 💪", .blue, "checkmark.seal.fill")
        } else if totalWealth >= 1000 {
            return ("Buon inizio! 📈", .orange, "arrow.up.circle.fill")
        } else if totalWealth >= 0 {
            return ("Inizia a risparmiare! 💡", .purple, "lightbulb.fill")
        } else {
            return ("Attenzione al bilancio! ⚠️", .red, "exclamationmark.triangle.fill")
        }
    }
    
    var body: some View {
        ZStack {
            // Background con gradiente avanzato
            RoundedRectangle(cornerRadius: 28)
                .fill(
                    LinearGradient(
                        gradient: Gradient(stops: [
                            .init(color: Color.blue.opacity(0.8), location: 0.0),
                            .init(color: Color.purple.opacity(0.9), location: 0.3),
                            .init(color: Color.indigo.opacity(0.7), location: 0.7),
                            .init(color: Color.blue.opacity(0.8), location: 1.0)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: .blue.opacity(0.3), radius: animateGlow ? 25 : 15, x: 0, y: animateGlow ? 15 : 10)
                .animation(.easeInOut(duration: 3).repeatForever(autoreverses: true), value: animateGlow)
            
            // Overlay pattern decorativo
            RoundedRectangle(cornerRadius: 28)
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: [
                            Color.white.opacity(0.3),
                            Color.clear,
                            Color.black.opacity(0.1)
                        ]),
                        center: .topTrailing,
                        startRadius: 20,
                        endRadius: 200
                    )
                )
            
            // Elementi decorativi fluttuanti
            GeometryReader { geometry in
                ZStack {
                    // Cerchi decorativi
                    Circle()
                        .fill(Color.white.opacity(0.1))
                        .frame(width: 120, height: 120)
                        .position(x: geometry.size.width * 0.85, y: geometry.size.height * 0.2)
                        .scaleEffect(animateBalance ? 1.1 : 0.9)
                        .animation(.easeInOut(duration: 4).repeatForever(autoreverses: true), value: animateBalance)
                    
                    Circle()
                        .fill(Color.white.opacity(0.05))
                        .frame(width: 80, height: 80)
                        .position(x: geometry.size.width * 0.15, y: geometry.size.height * 0.8)
                        .scaleEffect(animateBalance ? 0.8 : 1.2)
                        .animation(.easeInOut(duration: 3).repeatForever(autoreverses: true), value: animateBalance)
                    
                    // Stelle decorative
                    Image(systemName: "sparkles")
                        .font(.title2)
                        .foregroundColor(.white.opacity(0.6))
                        .position(x: geometry.size.width * 0.2, y: geometry.size.height * 0.3)
                        .scaleEffect(animateGlow ? 1.2 : 0.8)
                        .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: animateGlow)
                    
                    Image(systemName: "star.fill")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.4))
                        .position(x: geometry.size.width * 0.8, y: geometry.size.height * 0.7)
                        .scaleEffect(animateGlow ? 0.8 : 1.2)
                        .animation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true), value: animateGlow)
                }
            }
            
            // Contenuto principale
            VStack(spacing: 24) {
                // Header con icona animata
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            ZStack {
                                Circle()
                                    .fill(Color.white.opacity(0.2))
                                    .frame(width: 44, height: 44)
                                    .blur(radius: animateGlow ? 2 : 0)
                                    .scaleEffect(animateGlow ? 1.1 : 1.0)
                                
                                Image(systemName: "crown.fill")
                                    .font(.title2)
                                    .foregroundColor(.yellow)
                                    .rotationEffect(.degrees(animateBalance ? 5 : -5))
                                    .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: animateBalance)
                            }
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Il Tuo Patrimonio")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white.opacity(0.9))
                                
                                HStack {
                                    Image(systemName: wealthStatus.2)
                                        .font(.caption)
                                        .foregroundColor(wealthStatus.1)
                                    Text(wealthStatus.0)
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .foregroundColor(.white.opacity(0.8))
                                }
                            }
                        }
                        
                        Spacer()
                    }
                    
                    Spacer()
                }
                
                // Importo principale con effetto wow
                VStack(spacing: 12) {
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text("€")
                            .font(.title)
                            .fontWeight(.medium)
                            .foregroundColor(.white.opacity(0.7))
                        
                        Text(String(format: "%.2f", totalWealth))
                            .font(.system(size: 42, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .contentTransition(.numericText())
                            .scaleEffect(animateBalance ? 1.05 : 1.0)
                            .shadow(color: .white.opacity(0.5), radius: animateGlow ? 10 : 5)
                    }
                    
                    // Sottotitolo dinamico
                    Text(totalWealth >= 0 ? "Patrimonio disponibile" : "Situazione da monitorare")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                }
                
                // Breakdown animato
                HStack(spacing: 20) {
                    WealthBreakdownItem(
                        title: "Conti",
                        amount: totalBalance,
                        icon: "building.columns.fill",
                        color: Color.white.opacity(0.9),
                        animate: animateBalance
                    )
                    
                    // Separatore animato
                    Rectangle()
                        .fill(Color.white.opacity(0.3))
                        .frame(width: 1, height: 40)
                        .scaleEffect(y: animateGlow ? 1.2 : 0.8)
                    
                    WealthBreakdownItem(
                        title: "Salvadanai",
                        amount: totalSavings,
                        icon: "banknote.fill",
                        color: Color.white.opacity(0.9),
                        animate: animateBalance
                    )
                }
            }
            .padding(28)
        }
        .padding(.horizontal, 20) // 🎯 MARGINI LATERALI AGGIUNTI
        .onAppear {
            withAnimation(.easeInOut(duration: 0.8)) {
                animateBalance = true
            }
            withAnimation(.easeInOut(duration: 1.2)) {
                animateGlow = true
            }
        }
    }
}

// MARK: - Wealth Breakdown Item
struct WealthBreakdownItem: View {
    let title: String
    let amount: Double
    let icon: String
    let color: Color
    let animate: Bool
    @State private var itemAnimate = false
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
                .scaleEffect(itemAnimate ? 1.1 : 1.0)
                .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: itemAnimate)
            
            Text("€\(String(format: "%.0f", amount))")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(color)
                .contentTransition(.numericText())
            
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(color.opacity(0.8))
        }
        .frame(maxWidth: .infinity)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                itemAnimate = true
            }
        }
    }
}
