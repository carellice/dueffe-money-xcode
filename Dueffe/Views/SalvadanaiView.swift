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
    @State private var targetAmount = 100.0  // Valore di default
    @State private var targetDate = Date()
    @State private var monthlyRefill = 50.0  // Valore di default
    @State private var selectedColor = "blue"
    @State private var selectedAccount = ""
    
    let salvadanaiTypes = [
        ("objective", "Obiettivo", "target"),
        ("glass", "Glass", "drop.fill")
    ]
    
    var isFormValid: Bool {
        // Nome non deve essere vuoto
        if name.isEmpty { return false }
        
        // Deve esserci almeno un conto disponibile
        if dataManager.accounts.isEmpty { return false }
        
        // Deve essere selezionato un conto
        if selectedAccount.isEmpty { return false }
        
        // Validazione specifica per tipo
        if selectedType == "objective" && targetAmount <= 0 { return false }
        if selectedType == "glass" && monthlyRefill <= 0 { return false }
        
        return true
    }
    
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
                    VStack(spacing: 12) {
                        ForEach(salvadanaiTypes, id: \.0) { type, displayName, icon in
                            Button(action: {
                                selectedType = type
                            }) {
                                HStack {
                                    Image(systemName: icon)
                                        .frame(width: 24)
                                        .foregroundColor(selectedType == type ? .blue : .secondary)
                                    Text(displayName)
                                    Spacer()
                                    if selectedType == type {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.blue)
                                    }
                                }
                                .padding(.vertical, 8)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(PlainButtonStyle())
                            .foregroundColor(selectedType == type ? .blue : .primary)
                        }
                    }
                } header: {
                    Text("Tipo di salvadanaio")
                } footer: {
                    Text(selectedType == "objective"
                         ? "Un obiettivo ha un importo target e una scadenza"
                         : "Un salvadanaio Glass si ricarica automaticamente ogni mese")
                }
                
                // Selezione conto
                Section {
                    if dataManager.accounts.isEmpty {
                        VStack(spacing: 12) {
                            Text("⚠️ Nessun conto disponibile")
                                .foregroundColor(.orange)
                                .fontWeight(.medium)
                            
                            Text("Vai nel tab 'Conti' e crea almeno un conto prima di creare un salvadanaio")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding()
                    } else {
                        VStack(alignment: .leading, spacing: 12) {
                            if !selectedAccount.isEmpty {
                                Text("✅ Conto selezionato: \(selectedAccount)")
                                    .font(.caption)
                                    .foregroundColor(.green)
                            } else {
                                Text("❌ Nessun conto selezionato")
                                    .font(.caption)
                                    .foregroundColor(.red)
                            }
                            
                            ForEach(dataManager.accounts, id: \.name) { account in
                                Button(action: {
                                    selectedAccount = account.name
                                    print("🔄 Conto selezionato: \(account.name)")
                                }) {
                                    HStack {
                                        Image(systemName: selectedAccount == account.name ? "checkmark.circle.fill" : "circle")
                                            .foregroundColor(selectedAccount == account.name ? .blue : .secondary)
                                        
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(account.name)
                                                .font(.headline)
                                            Text("€\(String(format: "%.2f", account.balance))")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                        
                                        Spacer()
                                    }
                                    .padding(.vertical, 8)
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(PlainButtonStyle())
                                .foregroundColor(selectedAccount == account.name ? .blue : .primary)
                            }
                        }
                    }
                } header: {
                    Text("Conto di riferimento")
                } footer: {
                    Text("I soldi di questo salvadanaio saranno collegati al conto selezionato")
                }
                
                if selectedType == "objective" {
                    Section {
                        HStack {
                            Text("Obiettivo")
                            Spacer()
                            TextField("100", value: $targetAmount, format: .currency(code: "EUR"))
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
                            TextField("50", value: $monthlyRefill, format: .currency(code: "EUR"))
                                .multilineTextAlignment(.trailing)
                                .keyboardType(.decimalPad)
                        }
                    } header: {
                        Text("Dettagli Glass")
                    } footer: {
                        Text("Questo importo verrà aggiunto automaticamente quando inserisci entrate")
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
                
                // Sezione Debug (rimuovere dopo il test)
                Section {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("🐛 DEBUG INFO:")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.purple)
                        
                        Text("Nome: '\(name)' (vuoto: \(name.isEmpty))")
                            .font(.caption2)
                        Text("Conto: '\(selectedAccount)' (vuoto: \(selectedAccount.isEmpty))")
                            .font(.caption2)
                        Text("Conti disponibili: \(dataManager.accounts.count)")
                            .font(.caption2)
                        Text("Tipo: \(selectedType)")
                            .font(.caption2)
                        Text("Target: €\(String(format: "%.2f", targetAmount))")
                            .font(.caption2)
                        Text("Refill: €\(String(format: "%.2f", monthlyRefill))")
                            .font(.caption2)
                        Text("Form valido: \(isFormValid ? "✅" : "❌")")
                            .font(.caption2)
                            .foregroundColor(isFormValid ? .green : .red)
                    }
                } header: {
                    Text("Debug (rimuovi dopo test)")
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
                    .disabled(!isFormValid)
                }
            }
        }
        .onAppear {
            setupDefaults()
        }
    }
    
    private func setupDefaults() {
        // Auto-seleziona il primo conto se disponibile
        if selectedAccount.isEmpty && !dataManager.accounts.isEmpty {
            selectedAccount = dataManager.accounts.first!.name
            print("🔄 Auto-selezionato primo conto: \(selectedAccount)")
        }
        
        print("=== SETUP DEFAULTS ===")
        print("Conti disponibili: \(dataManager.accounts.count)")
        print("Conto auto-selezionato: '\(selectedAccount)'")
        print("Form valido dopo setup: \(isFormValid)")
        print("======================")
    }
    
    private func createSalvadanaio() {
        print("🚀 Creando salvadanaio...")
        dataManager.addSalvadanaio(
            name: name,
            type: selectedType,
            targetAmount: selectedType == "objective" ? targetAmount : 0,
            targetDate: selectedType == "objective" ? targetDate : nil,
            monthlyRefill: selectedType == "glass" ? monthlyRefill : 0,
            color: selectedColor,
            accountName: selectedAccount
        )
        print("✅ Salvadanaio creato con successo!")
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
                            .fill(Color.gray.opacity(0.1))
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
                                .background(Color.gray.opacity(0.1))
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
    @State private var targetDate: Date
    
    init(salvadanaio: SalvadanaiModel) {
        _salvadanaio = State(initialValue: salvadanaio)
        _targetDate = State(initialValue: salvadanaio.targetDate ?? Date())
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("Nome salvadanaio", text: $salvadanaio.name)
                } header: {
                    Text("Nome")
                }
                
                if salvadanaio.type == "objective" {
                    Section {
                        HStack {
                            Text("Importo obiettivo")
                            Spacer()
                            TextField("0", value: $salvadanaio.targetAmount, format: .currency(code: "EUR"))
                                .multilineTextAlignment(.trailing)
                                .keyboardType(.decimalPad)
                        }
                        
                        DatePicker("Scadenza", selection: $targetDate, displayedComponents: .date)
                    } header: {
                        Text("Obiettivo")
                    }
                } else {
                    Section {
                        HStack {
                            Text("Ricarica mensile")
                            Spacer()
                            TextField("0", value: $salvadanaio.monthlyRefill, format: .currency(code: "EUR"))
                                .multilineTextAlignment(.trailing)
                                .keyboardType(.decimalPad)
                        }
                    } header: {
                        Text("Glass")
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
                                        .stroke(salvadanaio.color == color ? Color.primary : Color.clear, lineWidth: 3)
                                )
                                .onTapGesture {
                                    salvadanaio.color = color
                                }
                        }
                    }
                    .padding(.vertical, 8)
                } header: {
                    Text("Colore")
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
                        salvadanaio.targetDate = targetDate
                        dataManager.updateSalvadanaio(salvadanaio)
                        dismiss()
                    }
                }
            }
        }
    }
}
