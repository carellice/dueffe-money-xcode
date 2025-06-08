import SwiftUI

// MARK: - SalvadanaiView completamente riscritta
struct SalvadanaiView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var showingAddSalvadanaio = false
    @State private var selectedSalvadanaio: SalvadanaiModel?
    @State private var searchText = ""
    
    var filteredSalvadanai: [SalvadanaiModel] {
        if searchText.isEmpty {
            return dataManager.salvadanai
        } else {
            return dataManager.salvadanai.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [Color.green.opacity(0.05), Color.blue.opacity(0.05)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack {
                    if dataManager.accounts.isEmpty {
                        NoAccountsView()
                    } else if dataManager.salvadanai.isEmpty {
                        EmptySalvadanaiView(action: { showingAddSalvadanaio = true })
                    } else {
                        VStack(spacing: 0) {
                            // Header con statistiche (MODIFICATO - rimosso totale risparmiato)
                            SalvadanaiStatsView(salvadanai: dataManager.salvadanai)
                                .padding(.horizontal)
                                .padding(.bottom, 16)
                            
                            // Lista salvadanai
                            ScrollView {
                                LazyVStack(spacing: 16) {
                                    ForEach(filteredSalvadanai, id: \.id) { salvadanaio in
                                        SalvadanaiCardView(salvadanaio: salvadanaio)
                                            .onTapGesture {
                                                selectedSalvadanaio = salvadanaio
                                            }
                                    }
                                }
                                .padding()
                            }
                            .searchable(text: $searchText, prompt: "Cerca salvadanai...")
                        }
                    }
                }
            }
            .navigationTitle("Salvadanai")
            .toolbar(content: {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddSalvadanaio = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(.blue)
                    }
                    .disabled(dataManager.accounts.isEmpty)
                }
            })
        }
        .sheet(isPresented: $showingAddSalvadanaio) {
            if dataManager.accounts.isEmpty {
                SimpleModalView(
                    title: "Nessun conto disponibile",
                    message: "Prima di procedere, devi creare almeno un conto nel tab 'Conti'",
                    buttonText: "Ho capito"
                )
            } else {
                SimpleSalvadanaiFormView()
            }
        }
        .sheet(item: $selectedSalvadanaio) { salvadanaio in
            SimpleSalvadanaiDetailView(salvadanaio: salvadanaio)
        }
    }
}

// MARK: - Salvadanai Stats Header (MODIFICATO - rimosso totale risparmiato)
struct SalvadanaiStatsView: View {
    let salvadanai: [SalvadanaiModel]
    
    private var completedGoals: Int {
        salvadanai.filter { salvadanaio in
            if salvadanaio.type == "objective" && !salvadanaio.isInfinite {
                return salvadanaio.currentAmount >= salvadanaio.targetAmount
            } else if salvadanaio.type == "glass" {
                return salvadanaio.currentAmount >= salvadanaio.monthlyRefill
            }
            return false
        }.count
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Header titolo
            HStack {
                Image(systemName: "banknote.circle.fill")
                    .foregroundColor(.green)
                Text("I Tuoi Salvadanai")
                    .font(.title3)
                    .fontWeight(.bold)
                Spacer()
            }
            
            // Solo le tre statistiche principali
            HStack(spacing: 24) {
                StatView(
                    title: "Salvadanai",
                    value: "\(salvadanai.count)",
                    icon: "banknote.circle.fill",
                    color: .green
                )
                
                StatView(
                    title: "Completati",
                    value: "\(completedGoals)",
                    icon: "checkmark.circle.fill",
                    color: .blue
                )
                
                StatView(
                    title: "In corso",
                    value: "\(salvadanai.count - completedGoals)",
                    icon: "clock.circle.fill",
                    color: .orange
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

// MARK: - Stat View
struct StatView: View {
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
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Salvadanaio Card View
struct SalvadanaiCardView: View {
    let salvadanaio: SalvadanaiModel
    @State private var isPressed = false
    @State private var animateProgress = false
    
    private var progress: Double {
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
        VStack(alignment: .leading, spacing: 20) {
            // Header
            HStack {
                HStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(LinearGradient(
                                gradient: Gradient(colors: [Color(salvadanaio.color), Color(salvadanaio.color).opacity(0.7)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                            .frame(width: 28, height: 28)
                            .shadow(color: Color(salvadanaio.color).opacity(0.3), radius: 4, x: 0, y: 2)
                        
                        Image(systemName: getTypeIcon())
                            .font(.caption)
                            .foregroundColor(.white)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(salvadanaio.name)
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Text(getTypeDisplayName())
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Status indicator
                SalvadanaiStatusView(salvadanaio: salvadanaio)
            }
            
            // Importo
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text("€")
                        .font(.title2)
                        .fontWeight(.medium)
                        .foregroundColor(salvadanaio.currentAmount < 0 ? .red : .secondary)
                    
                    Text(String(format: "%.2f", salvadanaio.currentAmount))
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(salvadanaio.currentAmount < 0 ? .red : .primary)
                        .contentTransition(.numericText())
                }
                
                // Avviso se in negativo
                if salvadanaio.currentAmount < 0 {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.red)
                        Text("Salvadanaio in rosso")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.red)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.red.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
            
            // Progress/Info specifiche
            if salvadanaio.type == "objective" {
                if salvadanaio.isInfinite {
                    SalvadanaiInfiniteView(salvadanaio: salvadanaio)
                } else {
                    SalvadanaiObjectiveView(salvadanaio: salvadanaio, progress: progress)
                }
            } else {
                SalvadanaiGlassView(salvadanaio: salvadanaio)
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .shadow(color: salvadanaio.currentAmount < 0 ? .red.opacity(0.2) : Color(salvadanaio.color).opacity(0.2), radius: 12, x: 0, y: 6)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(salvadanaio.currentAmount < 0 ? Color.red.opacity(0.3) : Color(salvadanaio.color).opacity(0.3), lineWidth: 1)
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
        .onAppear {
            animateProgress = true
        }
    }
    
    private func getTypeDisplayName() -> String {
        if salvadanaio.type == "objective" {
            return salvadanaio.isInfinite ? "Obiettivo Infinito" : "Obiettivo"
        } else {
            return "Glass"
        }
    }
    
    private func getTypeIcon() -> String {
        if salvadanaio.type == "objective" {
            return salvadanaio.isInfinite ? "infinity" : "target"
        } else {
            return "drop.fill"
        }
    }
}

// MARK: - Salvadanaio Status View
struct SalvadanaiStatusView: View {
    let salvadanaio: SalvadanaiModel
    
    var body: some View {
        Group {
            if salvadanaio.currentAmount < 0 {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.title2)
                    .foregroundColor(.red)
                    .background(
                        Circle()
                            .fill(.red.opacity(0.1))
                            .frame(width: 32, height: 32)
                    )
            } else if salvadanaio.type == "objective" && salvadanaio.isInfinite {
                Image(systemName: "infinity")
                    .font(.title2)
                    .foregroundColor(Color(salvadanaio.color))
                    .background(
                        Circle()
                            .fill(Color(salvadanaio.color).opacity(0.1))
                            .frame(width: 32, height: 32)
                    )
            } else if isCompleted {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(.green)
                    .background(
                        Circle()
                            .fill(.green.opacity(0.1))
                            .frame(width: 32, height: 32)
                    )
            } else {
                Image(systemName: salvadanaio.type == "objective" ? "target" : "drop.fill")
                    .font(.title2)
                    .foregroundColor(Color(salvadanaio.color))
                    .background(
                        Circle()
                            .fill(Color(salvadanaio.color).opacity(0.1))
                            .frame(width: 32, height: 32)
                    )
            }
        }
    }
    
    private var isCompleted: Bool {
        if salvadanaio.type == "objective" && !salvadanaio.isInfinite {
            return salvadanaio.currentAmount >= salvadanaio.targetAmount
        } else if salvadanaio.type == "glass" {
            return salvadanaio.currentAmount >= salvadanaio.monthlyRefill
        }
        return false
    }
}

// MARK: - Salvadanaio Infinite View
struct SalvadanaiInfiniteView: View {
    let salvadanaio: SalvadanaiModel
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "infinity")
                    .foregroundColor(Color(salvadanaio.color))
                
                Text("Obiettivo senza limiti")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(Color(salvadanaio.color))
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(salvadanaio.color).opacity(0.1))
            )
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Creato il")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(salvadanaio.createdAt, style: .date)
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                
                Spacer()
                
                if salvadanaio.currentAmount >= 0 {
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Continua a risparmiare!")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        HStack {
                            Image(systemName: "arrow.up.circle.fill")
                                .font(.subheadline)
                                .foregroundColor(.green)
                            Text("Crescita")
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                    }
                } else {
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Da recuperare")
                            .font(.caption)
                            .foregroundColor(.red)
                        Text("€\(String(format: "%.2f", abs(salvadanaio.currentAmount)))")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.red)
                    }
                }
            }
        }
    }
}

// MARK: - Salvadanaio Objective View
struct SalvadanaiObjectiveView: View {
    let salvadanaio: SalvadanaiModel
    let progress: Double
    
    var daysRemaining: Int {
        guard let targetDate = salvadanaio.targetDate else { return 0 }
        return Calendar.current.dateComponents([.day], from: Date(), to: targetDate).day ?? 0
    }
    
    var body: some View {
        VStack(spacing: 12) {
            // Progress Bar (solo se non negativo)
            if salvadanaio.currentAmount >= 0 {
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
                
                if salvadanaio.currentAmount < 0 {
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Da recuperare")
                            .font(.caption)
                            .foregroundColor(.red)
                        Text("€\(String(format: "%.2f", abs(salvadanaio.currentAmount)))")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.red)
                    }
                } else if daysRemaining > 0 {
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

// MARK: - Salvadanaio Glass View
struct SalvadanaiGlassView: View {
    let salvadanaio: SalvadanaiModel
    
    var fillPercentage: Double {
        guard salvadanaio.monthlyRefill > 0 else { return 0 }
        if salvadanaio.currentAmount < 0 {
            return 0
        }
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
                    .stroke(salvadanaio.currentAmount < 0 ? Color.red : Color(salvadanaio.color), lineWidth: 2)
                    .background(
                        GeometryReader { geometry in
                            VStack {
                                Spacer()
                                if salvadanaio.currentAmount >= 0 {
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color(salvadanaio.color).opacity(0.3))
                                        .frame(height: geometry.size.height * fillPercentage)
                                } else {
                                    // Pattern per saldo negativo
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color.red.opacity(0.2))
                                        .frame(height: geometry.size.height * 0.2)
                                }
                            }
                        }
                    )
                    .frame(width: 40, height: 30)
                    .animation(.easeInOut(duration: 0.5), value: fillPercentage)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(salvadanaio.currentAmount < 0 ? "Saldo negativo" : "Disponibile questo mese")
                        .font(.caption)
                        .foregroundColor(salvadanaio.currentAmount < 0 ? .red : .secondary)
                    
                    HStack {
                        Text("€\(String(format: "%.2f", salvadanaio.currentAmount))")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(salvadanaio.currentAmount < 0 ? .red : .primary)
                        
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

// MARK: - Empty Salvadanai View
struct EmptySalvadanaiView: View {
    let action: () -> Void
    @State private var animateIcon = false
    
    var body: some View {
        VStack(spacing: 32) {
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        gradient: Gradient(colors: [Color.green.opacity(0.2), Color.mint.opacity(0.2)]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 120, height: 120)
                    .scaleEffect(animateIcon ? 1.1 : 1.0)
                    .animation(.easeInOut(duration: 2).repeatForever(), value: animateIcon)
                
                Image(systemName: "banknote.fill")
                    .font(.system(size: 50))
                    .foregroundStyle(LinearGradient(
                        gradient: Gradient(colors: [.green, .mint]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
            }
            
            VStack(spacing: 12) {
                Text("Nessun Salvadanaio")
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                Text("Crea il tuo primo salvadanaio per iniziare a risparmiare!")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            Button(action: action) {
                HStack {
                    Text("Crea Salvadanaio")
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
                        gradient: Gradient(colors: [.green, .mint]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: .green.opacity(0.3), radius: 10, x: 0, y: 5)
            }
        }
        .padding(40)
        .onAppear {
            animateIcon = true
        }
    }
}

// MARK: - No Accounts View
struct NoAccountsView: View {
    @State private var animateWarning = false
    
    var body: some View {
        VStack(spacing: 32) {
            ZStack {
                Circle()
                    .fill(Color.orange.opacity(0.2))
                    .frame(width: 120, height: 120)
                    .scaleEffect(animateWarning ? 1.1 : 1.0)
                    .animation(.easeInOut(duration: 1.5).repeatForever(), value: animateWarning)
                
                Image(systemName: "banknote.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.orange)
            }
            
            VStack(spacing: 16) {
                Text("Impossibile creare salvadanai")
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                Text("Prima di creare un salvadanaio, devi aggiungere almeno un conto nel tab 'Conti'")
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

// MARK: - Simple Modal View
struct SimpleModalView: View {
    @Environment(\.dismiss) private var dismiss
    let title: String
    let message: String
    let buttonText: String
    
    var body: some View {
        NavigationView {
            VStack(spacing: 32) {
                Spacer()
                
                Image(systemName: "building.columns.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.orange)
                
                VStack(spacing: 16) {
                    Text(title)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text(message)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                Spacer()
                
                Button(buttonText) {
                    dismiss()
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.orange)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding()
            .navigationTitle("Attenzione")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(content: {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Chiudi") {
                        dismiss()
                    }
                }
            })
        }
    }
}

// MARK: - Simple Salvadanaio Form View
struct SimpleSalvadanaiFormView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var dataManager: DataManager
    
    @State private var name = ""
    @State private var selectedType = "objective"
    @State private var targetAmount = 100.0
    @State private var targetDate = Date()
    @State private var monthlyRefill = 50.0
    @State private var selectedColor = "blue"
    @State private var selectedAccount = ""
    @State private var initialAmount = 0.0
    @State private var isInfiniteObjective = false
    
    let salvadanaiTypes = [
        ("objective", "Obiettivo", "target"),
        ("glass", "Glass", "drop.fill")
    ]
    
    var isFormValid: Bool {
        if name.isEmpty { return false }
        if dataManager.accounts.isEmpty { return false }
        if selectedAccount.isEmpty { return false }
        
        if selectedType == "objective" && !isInfiniteObjective && targetAmount <= 0 { return false }
        if selectedType == "glass" && monthlyRefill <= 0 { return false }
        
        return true
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("Nome salvadanaio", text: $name)
                        .textInputAutocapitalization(.words)
                    
                    HStack {
                        Text("Saldo iniziale")
                        Spacer()
                        TextField("0", value: $initialAmount, format: .currency(code: "EUR"))
                            .multilineTextAlignment(.trailing)
                            .keyboardType(.decimalPad)
                    }
                } header: {
                    Text("Informazioni di base")
                }
                
                Section {
                    ForEach(salvadanaiTypes, id: \.0) { type, displayName, icon in
                        Button(action: {
                            selectedType = type
                            if type == "glass" {
                                isInfiniteObjective = false
                            }
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
                } header: {
                    Text("Tipo di salvadanaio")
                }
                
                Section {
                    if dataManager.accounts.isEmpty {
                        Text("Nessun conto disponibile")
                            .foregroundColor(.orange)
                    } else {
                        Picker("Conto di riferimento", selection: $selectedAccount) {
                            Text("Seleziona conto")
                                .tag("")
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
                        .pickerStyle(MenuPickerStyle())
                        
                        if !selectedAccount.isEmpty {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text("Conto selezionato: \(selectedAccount)")
                                    .font(.caption)
                                    .foregroundColor(.green)
                                Spacer()
                            }
                            .padding(.top, 8)
                        }
                    }
                } header: {
                    Text("Conto di riferimento")
                }
                
                if selectedType == "objective" {
                    Section {
                        Toggle("Obiettivo infinito", isOn: $isInfiniteObjective)
                        
                        if !isInfiniteObjective {
                            HStack {
                                Text("Obiettivo")
                                Spacer()
                                TextField("100", value: $targetAmount, format: .currency(code: "EUR"))
                                    .multilineTextAlignment(.trailing)
                                    .keyboardType(.decimalPad)
                            }
                            
                            DatePicker("Scadenza", selection: $targetDate, displayedComponents: .date)
                        }
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
                    }
                }
                
                Section {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 16) {
                        ForEach(getSalvadanaiColors(), id: \.name) { colorItem in
                            Circle()
                                .fill(colorItem.color)
                                .frame(width: 40, height: 40)
                                .overlay(
                                    Circle()
                                        .stroke(selectedColor == colorItem.name ? Color.primary : Color.clear, lineWidth: 3)
                                )
                                .onTapGesture {
                                    selectedColor = colorItem.name
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
            .toolbar(content: {
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
            })
        }
        .onAppear {
            setupDefaults()
        }
    }
    
    private func getSalvadanaiColors() -> [(name: String, color: Color)] {
        return [
            ("blue", Color.blue),
            ("green", Color.green),
            ("orange", Color.orange),
            ("purple", Color.purple),
            ("pink", Color.pink),
            ("red", Color.red),
            ("yellow", Color.yellow),
            ("indigo", Color.indigo),
            ("mint", Color.mint),
            ("teal", Color.teal),
            ("cyan", Color.cyan),
            ("brown", Color.brown)
        ]
    }
    
    private func setupDefaults() {
        if selectedAccount.isEmpty && !dataManager.accounts.isEmpty {
            selectedAccount = dataManager.accounts.first!.name
        }
    }
    
    private func createSalvadanaio() {
        dataManager.addSalvadanaio(
            name: name,
            type: selectedType,
            targetAmount: isInfiniteObjective ? 0 : (selectedType == "objective" ? targetAmount : 0),
            targetDate: isInfiniteObjective ? nil : (selectedType == "objective" ? targetDate : nil),
            monthlyRefill: selectedType == "glass" ? monthlyRefill : 0,
            color: selectedColor,
            accountName: selectedAccount,
            initialAmount: initialAmount,
            isInfinite: selectedType == "objective" ? isInfiniteObjective : false
        )
        dismiss()
    }
}

// MARK: - Simple Salvadanaio Detail View
struct SimpleSalvadanaiDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var dataManager: DataManager
    let salvadanaio: SalvadanaiModel
    
    @State private var showingDeleteAlert = false
    
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
                            if salvadanaio.isInfinite {
                                Text("Obiettivo infinito")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            } else {
                                VStack(spacing: 8) {
                                    Text("Obiettivo: €\(String(format: "%.0f", salvadanaio.targetAmount))")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    
                                    if salvadanaio.targetAmount > 0 {
                                        ProgressView(value: min(salvadanaio.currentAmount / salvadanaio.targetAmount, 1.0))
                                            .progressViewStyle(LinearProgressViewStyle(tint: Color(salvadanaio.color)))
                                    }
                                }
                            }
                        } else {
                            Text("Glass: €\(String(format: "%.0f", salvadanaio.monthlyRefill)) mensili")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(24)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.gray.opacity(0.1))
                    )
                    
                    // Transazioni correlate
                    if !relatedTransactions.isEmpty {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Transazioni")
                                .font(.title3)
                                .fontWeight(.bold)
                            
                            ForEach(relatedTransactions.sorted { $0.date > $1.date }, id: \.id) { transaction in
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
                        .padding(20)
                        .background(Color.gray.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                }
                .padding()
            }
            .navigationTitle("Dettagli")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(content: {
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
            })
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
