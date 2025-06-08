import SwiftUI
import CoreData

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var dataManager = DataManager()
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Home - Panoramica
            HomeView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Home")
                }
                .tag(0)
            
            // Salvadanai
            SalvadanaiView()
                .tabItem {
                    Image(systemName: "banknote.fill")
                    Text("Salvadanai")
                }
                .tag(1)
            
            // Transazioni
            TransactionsView()
                .tabItem {
                    Image(systemName: "creditcard.fill")
                    Text("Transazioni")
                }
                .tag(2)
            
            // Conti
            AccountsView()
                .tabItem {
                    Image(systemName: "building.columns.fill")
                    Text("Conti")
                }
                .tag(3)
            
            // Impostazioni
            SettingsView()
                .tabItem {
                    Image(systemName: "gearshape.fill")
                    Text("Impostazioni")
                }
                .tag(4)
        }
        .environmentObject(dataManager)
        .accentColor(.blue)
    }
}

// MARK: - Home View
struct HomeView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var showingAddTransaction = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Saldo Totale
                    TotalBalanceCard()
                    
                    // Salvadanai Recenti
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("I Tuoi Salvadanai")
                                .font(.title2)
                                .fontWeight(.bold)
                            Spacer()
                            NavigationLink("Vedi Tutti", destination: SalvadanaiView())
                        }
                        
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 16) {
                            ForEach(dataManager.salvadanai.prefix(4), id: \.id) { salvadanaio in
                                SalvadanaiMiniCard(salvadanaio: salvadanaio)
                            }
                        }
                    }
                    
                    // Transazioni Recenti
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Transazioni Recenti")
                                .font(.title2)
                                .fontWeight(.bold)
                            Spacer()
                            NavigationLink("Vedi Tutte", destination: TransactionsView())
                        }
                        
                        ForEach(dataManager.recentTransactions.prefix(5), id: \.id) { transaction in
                            TransactionRowView(transaction: transaction)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Dueffe")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddTransaction = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                    }
                }
            }
        }
        .sheet(isPresented: $showingAddTransaction) {
            AddTransactionView()
        }
    }
}

// MARK: - Total Balance Card
struct TotalBalanceCard: View {
    @EnvironmentObject var dataManager: DataManager
    
    var body: some View {
        VStack(spacing: 8) {
            Text("Saldo Totale")
                .font(.headline)
                .foregroundColor(.secondary)
            
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("€")
                    .font(.title2)
                    .fontWeight(.medium)
                
                Text(String(format: "%.2f", dataManager.totalBalance))
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .contentTransition(.numericText())
            }
            .foregroundColor(.primary)
            
            HStack(spacing: 16) {
                VStack {
                    Text("In Salvadanai")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("€\(String(format: "%.2f", dataManager.totalSavings))")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.green)
                }
                
                Divider()
                    .frame(height: 30)
                
                VStack {
                    Text("Disponibile")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("€\(String(format: "%.2f", dataManager.availableBalance))")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.gray.opacity(0.1))
        )
        .animation(.easeInOut, value: dataManager.totalBalance)
    }
}

// MARK: - Salvadanaio Mini Card
struct SalvadanaiMiniCard: View {
    let salvadanaio: SalvadanaiModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Circle()
                    .fill(Color(salvadanaio.color))
                    .frame(width: 12, height: 12)
                
                Text(salvadanaio.name)
                    .font(.caption)
                    .fontWeight(.medium)
                    .lineLimit(1)
                
                Spacer()
            }
            
            Text("€\(String(format: "%.0f", salvadanaio.currentAmount))")
                .font(.title3)
                .fontWeight(.bold)
            
            if salvadanaio.type == "objective" {
                ProgressView(value: salvadanaio.currentAmount, total: salvadanaio.targetAmount)
                    .progressViewStyle(LinearProgressViewStyle(tint: Color(salvadanaio.color)))
                    .scaleEffect(y: 0.8)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.1))
        )
    }
}

// MARK: - Transaction Row View
struct TransactionRowView: View {
    let transaction: TransactionModel
    
    var body: some View {
        HStack(spacing: 12) {
            // Icona
            Image(systemName: transaction.type == "expense" ? "minus.circle.fill" : "plus.circle.fill")
                .font(.title2)
                .foregroundColor(transaction.type == "expense" ? .red : .green)
            
            // Dettagli
            VStack(alignment: .leading, spacing: 2) {
                Text(transaction.descr)
                    .font(.headline)
                    .lineLimit(1)
                
                HStack {
                    Text(transaction.category)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.1))
                        .foregroundColor(.blue)
                        .clipShape(Capsule())
                    
                    Spacer()
                    
                    Text(transaction.date, style: .date)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Importo
            Text("\(transaction.type == "expense" ? "-" : "+")€\(String(format: "%.2f", transaction.amount))")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(transaction.type == "expense" ? .red : .green)
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Preview Provider
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
            .environmentObject(DataManager())
    }
}
