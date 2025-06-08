import SwiftUI

struct SalvadanaiView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var showingAddSalvadanaio = false
    @State private var selectedSalvadanaio: SalvadanaiModel?
    
    var body: some View {
        NavigationView {
            VStack {
                if dataManager.salvadanai.isEmpty {
                    EmptyStateView(
                        icon: "banknote.fill",
                        title: "Nessun Salvadanaio",
                        subtitle: "Crea il tuo primo salvadanaio per iniziare a risparmiare!",
                        buttonText: "Crea Salvadanaio",
                        action: { showingAddSalvadanaio = true }
                    )
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(dataManager.salvadanai, id: \.id) { salvadanaio in
                                SalvadanaiCard(salvadanaio: salvadanaio)
                                    .onTapGesture {
                                        selectedSalvadanaio = salvadanaio
                                    }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Salvadanai")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddSalvadanaio = true }) {
                        Image(systemName: "plus.circle.fill")
                    }
                }
            }
        }
        .sheet(isPresented: $showingAddSalvadanaio) {
            AddSalvadanaiView()
        }
        .sheet(item: $selectedSalvadanaio) { salvadanaio in
            SalvadanaiDetailView(salvadanaio: salvadanaio)
        }
    }
}

// MARK: - Salvadanaio Card
struct SalvadanaiCard: View {
    let salvadanaio: SalvadanaiModel
    @State private var isPressed = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                HStack(spacing: 12) {
                    Circle()
                        .fill(Color(salvadanaio.color))
                        .frame(width: 20, height: 20)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(salvadanaio.name)
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Text(salvadanaio.type == "objective" ? "Obiettivo" : "Glass")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Image(systemName: salvadanaio.type == "objective" ? "target" : "drop.fill")
                    .font(.title2)
                    .foregroundColor(Color(salvadanaio.color))
            }
            
            // Importo
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("€")
                    .font(.title2)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                
                Text(String(format: "%.2f", salvadanaio.currentAmount))
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .contentTransition(.numericText())
            }
            
            // Progress/Info specifiche
            if salvadanaio.type == "objective" {
                ObjectiveProgressView(salvadanaio: salvadanaio)
            } else {
                GlassInfoView(salvadanaio: salvadanaio)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.gray.opacity(0.1))
                .shadow(color: Color.black.opacity(isPressed ? 0.1 : 0.05), radius: isPressed ? 2 : 8, x: 0, y: isPressed ? 1 : 4)
        )
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

// MARK: - Objective Progress View
struct ObjectiveProgressView: View {
    let salvadanaio: SalvadanaiModel
    
    var progress: Double {
        guard salvadanaio.targetAmount > 0 else { return 0 }
        return min(salvadanaio.currentAmount / salvadanaio.targetAmount, 1.0)
    }
    
    var daysRemaining: Int {
        guard let targetDate = salvadanaio.targetDate else { return 0 }
        return Calendar.current.dateComponents([.day], from: Date(), to: targetDate).day ?? 0
    }
    
    var body: some View {
        VStack(spacing: 12) {
            // Progress Bar
            VStack(spacing: 8) {
                HStack {
                    Text("Progresso")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("\(Int(progress * 100))%")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(Color(salvadanaio.color))
                }
                
                ProgressView(value: progress)
                    .progressViewStyle(LinearProgressViewStyle(tint: Color(salvadanaio.color)))
                    .scaleEffect(y: 1.5)
            }
            
            // Info obiettivo
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Obiettivo")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("€\(String(format: "%.0f", salvadanaio.targetAmount))")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                
                Spacer()
                
                if daysRemaining > 0 {
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Giorni rimasti")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(daysRemaining)")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(daysRemaining < 30 ? .orange : .primary)
                    }
                } else {
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Scaduto")
                            .font(.caption)
                            .foregroundColor(.red)
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.red)
                    }
                }
            }
        }
    }
}

// MARK: - Glass Info View
struct GlassInfoView: View {
    let salvadanaio: SalvadanaiModel
    
    var fillPercentage: Double {
        guard salvadanaio.monthlyRefill > 0 else { return 0 }
        return min(salvadanaio.currentAmount / salvadanaio.monthlyRefill, 1.0)
    }
    
    var body: some View {
        VStack(spacing: 12) {
            // Glass visual indicator
            HStack(spacing: 8) {
                Text("Ricarica mensile:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("€\(String(format: "%.0f", salvadanaio.monthlyRefill))")
                    .font(.caption)
                    .fontWeight(.semibold)
            }
            
            // Visual glass
            HStack {
                // Glass container
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color(salvadanaio.color), lineWidth: 2)
                    .background(
                        GeometryReader { geometry in
                            VStack {
                                Spacer()
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color(salvadanaio.color).opacity(0.3))
                                    .frame(height: geometry.size.height * fillPercentage)
                            }
                        }
                    )
                    .frame(width: 40, height: 30)
                    .animation(.easeInOut(duration: 0.5), value: fillPercentage)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Disponibile questo mese")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        Text("€\(String(format: "%.2f", salvadanaio.currentAmount))")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        
                        Text("/ €\(String(format: "%.0f", salvadanaio.monthlyRefill))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
            }
        }
    }
}

// MARK: - Add Salvadanaio View
struct AddSalvadanaiView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var dataManager: DataManager
    
    @State private var name = ""
    @State private var selectedType = "objective"
    @State private var targetAmount = 0.0
    @State private var targetDate = Date()
    @State private var monthlyRefill = 0.0
    @State private var selectedColor = "blue"
    
    let salvadanaiTypes = [
        ("objective", "Obiettivo", "target"),
        ("glass", "Glass", "drop.fill")
    ]
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("Nome salvadanaio", text: $name)
                        .textInputAutocapitalization(.words)
                } header: {
                    Text("Informazioni di base")
                }
                
                Section {
                    Picker("Tipo", selection: $selectedType) {
                        ForEach(salvadanaiTypes, id: \.0) { type, displayName, icon in
                            HStack {
                                Image(systemName: icon)
                                Text(displayName)
                            }
                            .tag(type)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                } header: {
                    Text("Tipo di salvadanaio")
                } footer: {
                    Text(selectedType == "objective"
                         ? "Un obiettivo ha un importo target e una scadenza"
                         : "Un salvadanaio Glass si ricarica automaticamente ogni mese")
                }
                
                if selectedType == "objective" {
                    Section {
                        HStack {
                            Text("Obiettivo")
                            Spacer()
                            TextField("0", value: $targetAmount, format: .currency(code: "EUR"))
                                .multilineTextAlignment(.trailing)
                                .keyboardType(.decimalPad)
                        }
                        
                        DatePicker("Scadenza", selection: $targetDate, displayedComponents: .date)
                    } header: {
                        Text("Dettagli obiettivo")
                    }
                } else {
                    Section {
                        HStack {
                            Text("Ricarica mensile")
                            Spacer()
                            TextField("0", value: $monthlyRefill, format: .currency(code: "EUR"))
                                .multilineTextAlignment(.trailing)
                                .keyboardType(.decimalPad)
                        }
                    } header: {
                        Text("Dettagli Glass")
                    } footer: {
                        Text("Questo importo verrà aggiunto automaticamente ogni volta che inserisci lo stipendio")
                    }
                }
                
                Section {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 16) {
                        ForEach(dataManager.salvadanaiColors, id: \.self) { color in
                            Circle()
                                .fill(Color(color))
                                .frame(width: 40, height: 40)
                                .overlay(
                                    Circle()
                                        .stroke(selectedColor == color ? Color.primary : Color.clear, lineWidth: 3)
                                )
                                .onTapGesture {
                                    selectedColor = color
                                }
                        }
                    }
                    .padding(.vertical, 8)
                } header: {
                    Text("Colore")
                }
            }
            .navigationTitle("Nuovo Salvadanaio")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Annulla") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Salva") {
                        createSalvadanaio()
                    }
                    .disabled(name.isEmpty || (selectedType == "objective" && targetAmount <= 0) || (selectedType == "glass" && monthlyRefill <= 0))
                }
            }
        }
    }
    
    private func createSalvadanaio() {
        dataManager.addSalvadanaio(
            name: name,
            type: selectedType,
            targetAmount: selectedType == "objective" ? targetAmount : 0,
            targetDate: selectedType == "objective" ? targetDate : nil,
            monthlyRefill: selectedType == "glass" ? monthlyRefill : 0,
            color: selectedColor
        )
        dismiss()
    }
}

// MARK: - Salvadanaio Detail View
struct SalvadanaiDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var dataManager: DataManager
    let salvadanaio: SalvadanaiModel
    
    @State private var showingEditView = false
    @State private var showingDeleteAlert = false
    @State private var showingAddMoneyView = false
    
    var relatedTransactions: [TransactionModel] {
        dataManager.transactions.filter { $0.salvadanaiName == salvadanaio.name }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header Card
                    VStack(spacing: 20) {
                        HStack {
                            Circle()
                                .fill(Color(salvadanaio.color))
                                .frame(width: 24, height: 24)
                            
                            Text(salvadanaio.name)
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Spacer()
                            
                            Image(systemName: salvadanaio.type == "objective" ? "target" : "drop.fill")
                                .font(.title)
                                .foregroundColor(Color(salvadanaio.color))
                        }
                        
                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text("€")
                                .font(.title)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                            
                            Text(String(format: "%.2f", salvadanaio.currentAmount))
                                .font(.largeTitle)
                                .fontWeight(.bold)
                        }
                        
                        if salvadanaio.type == "objective" {
                            ObjectiveProgressView(salvadanaio: salvadanaio)
                        } else {
                            GlassInfoView(salvadanaio: salvadanaio)
                        }
                    }
                    .padding(24)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(.regularMaterial)
                    )
                    
                    // Actions
                    HStack(spacing: 16) {
                        Button(action: { showingAddMoneyView = true }) {
                            Label("Aggiungi", systemImage: "plus.circle.fill")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color(salvadanaio.color))
                                .foregroundColor(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        
                        Button(action: { showingEditView = true }) {
                            Label("Modifica", systemImage: "pencil.circle.fill")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(.regularMaterial)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                    
                    // Transazioni correlate
                    if !relatedTransactions.isEmpty {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Transazioni")
                                .font(.title3)
                                .fontWeight(.bold)
                            
                            ForEach(relatedTransactions.sorted { $0.date > $1.date }, id: \.id) { transaction in
                                TransactionRowView(transaction: transaction)
                            }
                        }
                        .padding(20)
                        .background(Color.gray.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                }
                .padding()
            }
            .navigationTitle("Dettagli")
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
            EditSalvadanaiView(salvadanaio: salvadanaio)
        }
        .sheet(isPresented: $showingAddMoneyView) {
            AddMoneyToSalvadanaiView(salvadanaio: salvadanaio)
        }
        .alert("Elimina Salvadanaio", isPresented: $showingDeleteAlert) {
            Button("Elimina", role: .destructive) {
                dataManager.deleteSalvadanaio(salvadanaio)
                dismiss()
            }
            Button("Annulla", role: .cancel) { }
        } message: {
            Text("Sei sicuro di voler eliminare questo salvadanaio? Questa azione non può essere annullata.")
        }
    }
}

// MARK: - Edit Salvadanaio View
struct EditSalvadanaiView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var dataManager: DataManager
    
    @State private var salvadanaio: SalvadanaiModel
    
    init(salvadanaio: SalvadanaiModel) {
        _salvadanaio = State(initialValue: salvadanaio)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Nome") {
                    TextField("Nome salvadanaio", text: $salvadanaio.name)
                }
                
                if salvadanaio.type == "objective" {
                    Section("Obiettivo") {
                        HStack {
                            Text("Importo obiettivo")
                            Spacer()
                            TextField("0", value: $salvadanaio.targetAmount, format: .currency(code: "EUR"))
                                .multilineTextAlignment(.trailing)
                                .keyboardType(.decimalPad)
                        }
                        
                        DatePicker("Scadenza", selection: Binding($salvadanaio.targetDate)!, displayedComponents: .date)
                    }
                } else {
                    Section("Glass") {
                        HStack {
                            Text("Ricarica mensile")
                            Spacer()
                            TextField("0", value: $salvadanaio.monthlyRefill, format: .currency(code: "EUR"))
                                .multilineTextAlignment(.trailing)
                                .keyboardType(.decimalPad)
                        }
                    }
                }
                
                Section("Colore") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 16) {
                        ForEach(dataManager.salvadanaiColors, id: \.self) { color in
                            Circle()
                                .fill(Color(color))
                                .frame(width: 40, height: 40)
                                .overlay(
                                    Circle()
                                        .stroke(salvadanaio.color == color ? Color.primary : Color.clear, lineWidth: 3)
                                )
                                .onTapGesture {
                                    salvadanaio.color = color
                                }
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
            .navigationTitle("Modifica Salvadanaio")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Annulla") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Salva") {
                        dataManager.updateSalvadanaio(salvadanaio)
                        dismiss()
                    }
                }
            }
        }
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
                    Section("Da quale conto?") {
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
        // Crea una transazione di trasferimento
        dataManager.addTransaction(
            amount: amount,
            descr: "Trasferimento a \(salvadanaio.name)",  // Cambiato da description a descr
            category: "💰 Trasferimento",
            type: "expense",
            accountName: selectedAccount,
            salvadanaiName: salvadanaio.name
        )
        
        // Aggiungi i soldi al salvadanaio (viene fatto automaticamente nella addTransaction)
        dismiss()
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
