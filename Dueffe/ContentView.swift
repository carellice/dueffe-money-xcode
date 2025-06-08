import SwiftUI

struct ContentView: View {
    @StateObject private var dataManager = DataManager()
    
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
        .environmentObject(dataManager)
    }
}

// MARK: - Home View
struct HomeView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var showingAddTransaction = false
    @State private var showingAddSalvadanaio = false
    
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
            ScrollView {
                VStack(spacing: 24) {
                    // Header finanziario
                    VStack(spacing: 20) {
                        HStack {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Patrimonio Totale")
                                    .font(.headline)
                                    .foregroundColor(.secondary)
                                
                                HStack(alignment: .firstTextBaseline, spacing: 4) {
                                    Text("€")
                                        .font(.title)
                                        .fontWeight(.medium)
                                        .foregroundColor(.secondary)
                                    Text(String(format: "%.2f", totalBalance + totalSavings))
                                        .font(.largeTitle)
                                        .fontWeight(.bold)
                                        .contentTransition(.numericText())
                                }
                            }
                            
                            Spacer()
                            
                            VStack(spacing: 12) {
                                Button(action: { showingAddTransaction = true }) {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.title2)
                                        .foregroundColor(.blue)
                                }
                                
                                Button(action: { showingAddSalvadanaio = true }) {
                                    Image(systemName: "banknote.circle.fill")
                                        .font(.title2)
                                        .foregroundColor(.green)
                                }
                            }
                        }
                        
                        // Breakdown
                        HStack(spacing: 20) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Conti")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text("€\(String(format: "%.2f", totalBalance))")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.blue)
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Salvadanai")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text("€\(String(format: "%.2f", totalSavings))")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.green)
                            }
                            
                            Spacer()
                        }
                    }
                    .padding(24)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.gray.opacity(0.1))
                    )
                    
                    // Salvadanai Overview
                    if !dataManager.salvadanai.isEmpty {
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Text("I Tuoi Salvadanai")
                                    .font(.title3)
                                    .fontWeight(.bold)
                                
                                Spacer()
                                
                                NavigationLink(destination: SalvadanaiView()) {
                                    Text("Vedi tutti")
                                        .font(.subheadline)
                                        .foregroundColor(.blue)
                                }
                            }
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 16) {
                                    ForEach(Array(dataManager.salvadanai.prefix(3)), id: \.id) { salvadanaio in
                                        SalvadanaiHomeCard(salvadanaio: salvadanaio)
                                    }
                                }
                                .padding(.horizontal, 2)
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    
                    // Transazioni Recenti
                    if !recentTransactions.isEmpty {
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Text("Transazioni Recenti")
                                    .font(.title3)
                                    .fontWeight(.bold)
                                
                                Spacer()
                                
                                NavigationLink(destination: TransactionsView()) {
                                    Text("Vedi tutte")
                                        .font(.subheadline)
                                        .foregroundColor(.blue)
                                }
                            }
                            
                            VStack(spacing: 12) {
                                ForEach(recentTransactions, id: \.id) { transaction in
                                    HomeTransactionRow(transaction: transaction)
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    
                    // Quick Actions
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Azioni Rapide")
                            .font(.title3)
                            .fontWeight(.bold)
                            .padding(.horizontal, 20)
                        
                        HStack(spacing: 16) {
                            QuickActionCard(
                                title: "Nuova Spesa",
                                icon: "minus.circle.fill",
                                color: .red,
                                action: { showingAddTransaction = true }
                            )
                            
                            QuickActionCard(
                                title: "Nuovo Salvadanaio",
                                icon: "banknote.fill",
                                color: .green,
                                action: { showingAddSalvadanaio = true }
                            )
                        }
                        .padding(.horizontal, 20)
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Ciao! 👋")
            .refreshable {
                // Placeholder per refresh
            }
        }
        .sheet(isPresented: $showingAddTransaction) {
            AddTransactionView()
        }
        .sheet(isPresented: $showingAddSalvadanaio) {
            AddSalvadanaiView()
        }
    }
}

// MARK: - Salvadanaio Home Card (versione aggiornata)
struct SalvadanaiHomeCard: View {
    let salvadanaio: SalvadanaiModel
    
    var progress: Double {
        if salvadanaio.type == "objective" {
            guard salvadanaio.targetAmount > 0 else { return 0 }
            if salvadanaio.currentAmount < 0 { return 0 }
            return min(salvadanaio.currentAmount / salvadanaio.targetAmount, 1.0)
        } else {
            guard salvadanaio.monthlyRefill > 0 else { return 0 }
            if salvadanaio.currentAmount < 0 { return 0 }
            return min(salvadanaio.currentAmount / salvadanaio.monthlyRefill, 1.0)
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Circle()
                    .fill(Color(salvadanaio.color))
                    .frame(width: 12, height: 12)
                
                Text(salvadanaio.name)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .lineLimit(1)
                
                Spacer()
                
                if salvadanaio.currentAmount < 0 {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundColor(.red)
                } else {
                    Image(systemName: salvadanaio.type == "objective" ? "target" : "drop.fill")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("€\(String(format: "%.0f", salvadanaio.currentAmount))")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(salvadanaio.currentAmount < 0 ? .red : .primary)
                
                if salvadanaio.currentAmount < 0 {
                    Text("In rosso")
                        .font(.caption)
                        .foregroundColor(.red)
                        .fontWeight(.medium)
                } else if salvadanaio.type == "objective" {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("di €\(String(format: "%.0f", salvadanaio.targetAmount))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        ProgressView(value: progress)
                            .progressViewStyle(LinearProgressViewStyle(tint: Color(salvadanaio.color)))
                            .scaleEffect(y: 0.8)
                    }
                } else {
                    Text("/ €\(String(format: "%.0f", salvadanaio.monthlyRefill))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(16)
        .frame(width: 180)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(salvadanaio.currentAmount < 0 ? Color.red.opacity(0.05) : Color.gray.opacity(0.1))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(salvadanaio.currentAmount < 0 ? Color.red.opacity(0.3) : Color.clear, lineWidth: 1)
        )
    }
}

// MARK: - Home Transaction Row
struct HomeTransactionRow: View {
    let transaction: TransactionModel
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: transaction.type == "expense" ? "minus.circle.fill" : "plus.circle.fill")
                .font(.title3)
                .foregroundColor(transaction.type == "expense" ? .red : .green)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(transaction.descr)
                    .font(.headline)
                    .lineLimit(1)
                
                HStack(spacing: 4) {
                    Text(transaction.category)
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.gray.opacity(0.2))
                        .clipShape(Capsule())
                    
                    Text("• \(transaction.accountName)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(transaction.type == "expense" ? "-" : "+")€\(String(format: "%.2f", transaction.amount))")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(transaction.type == "expense" ? .red : .green)
                
                Text(transaction.date, style: .time)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Quick Action Card
struct QuickActionCard: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 28))
                    .foregroundColor(color)
                
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.gray.opacity(0.1))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}
