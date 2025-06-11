import SwiftUI

struct ContentView: View {
    var body: some View {
        OnboardingWrapperView()
    }
}

struct OnboardingWrapperView: View {
    @StateObject private var dataManager = DataManager()
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @AppStorage("hasCreatedFirstSalvadanaio") private var hasCreatedFirstSalvadanaio = false
    @AppStorage("hasAddedInitialBalance") private var hasAddedInitialBalance = false
    
    var body: some View {
        Group {
            if !hasSeenOnboarding {
                // Mostra onboarding completo
                AppOnboardingView()
                    .environmentObject(dataManager)
                    .onAppear {
                    }
            } else if dataManager.accounts.isEmpty {
                // Mostra creazione primo conto (STEP 1)
                FirstAccountOnboardingView()
                    .environmentObject(dataManager)
            } else if !hasCreatedFirstSalvadanaio {
                // NUOVO: Mostra creazione primo salvadanaio (STEP 2)
                FirstSalvadanaiOnboardingView()
                    .environmentObject(dataManager)
            } else if !hasAddedInitialBalance {
                // NUOVO: Mostra aggiunta saldo iniziale (STEP 3)
                InitialBalanceOnboardingView()
                    .environmentObject(dataManager)
            } else {
                // Mostra app normale
                MainTabView()
                    .environmentObject(dataManager)
            }
        }
    }
}

struct AppOnboardingView: View {
    @EnvironmentObject var dataManager: DataManager
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @State private var currentPage = 0
    @State private var animateElements = false
    
    let onboardingPages = [
        OnboardingPage(
            title: "Benvenuto in Dueffe! 👋",
            subtitle: "La tua app per il risparmio intelligente",
            description: "Gestisci i tuoi soldi, crea salvadanai e raggiungi i tuoi obiettivi finanziari con facilità",
            icon: "star.fill",
            color: .blue,
            features: [
                "💰 Gestione completa dei tuoi soldi",
                "🎯 Salvadanai intelligenti per ogni obiettivo",
                "📊 Statistiche dettagliate e intuitive"
            ]
        ),
        OnboardingPage(
            title: "Crea i tuoi Conti 🏛️",
            subtitle: "Il punto di partenza",
            description: "Aggiungi i tuoi conti correnti, carte prepagate e contanti per avere tutto sotto controllo",
            icon: "building.columns.fill",
            color: .indigo,
            features: [
                "🏦 Conti correnti e carte",
                "💵 Gestione contanti",
                "🔄 Trasferimenti tra conti",
                "📈 Bilancio totale sempre aggiornato"
            ]
        ),
        OnboardingPage(
            title: "Salvadanai Intelligenti 🎯",
            subtitle: "Raggiungi i tuoi obiettivi",
            description: "Crea salvadanai per ogni tuo obiettivo: vacanze, casa, emergenze... Dueffe ti aiuta a risparmiare!",
            icon: "target",
            color: .green,
            features: [
                "🎯 Obiettivi con scadenza",
                "🥤 Glass: budget mensili",
                "♾️ Salvadanai infiniti",
                "🤖 Distribuzione automatica intelligente"
            ]
        ),
        OnboardingPage(
            title: "Gestisci le Transazioni 💳",
            subtitle: "Ogni movimento conta",
            description: "Registra spese, entrate e stipendi. Distribuisci automaticamente i tuoi guadagni nei salvadanai",
            icon: "creditcard.fill",
            color: .purple,
            features: [
                "💸 Spese dai salvadanai",
                "💰 Entrate e stipendi sui conti",
                "🔄 Distribuzione intelligente",
                "📊 Statistiche dettagliate"
            ]
        ),
        OnboardingPage(
            title: "Tutto Pronto! 🚀",
            subtitle: "Inizia il tuo viaggio verso l'obiettivo",
            description: "Ora hai tutti gli strumenti per gestire i tuoi soldi in modo intelligente. Iniziamo!",
            icon: "checkmark.seal.fill",
            color: .orange,
            features: [
                "🎉 Sei pronto per iniziare",
                "💡 Suggerimenti integrati nell'app",
                "🏆 Raggiungi i tuoi obiettivi",
                "🔒 I tuoi dati sono sempre al sicuro"
            ]
        )
    ]
    
    var body: some View {
        // CORRETTO: GeometryReader per full screen
        GeometryReader { geometry in
            ZStack {
                // Background gradient dinamico - FULL SCREEN
                LinearGradient(
                    gradient: Gradient(colors: [
                        onboardingPages[currentPage].color.opacity(0.1),
                        onboardingPages[currentPage].color.opacity(0.05)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea(.all) // AGGIUNTO: ignora tutte le safe area
                .animation(.easeInOut(duration: 0.8), value: currentPage)
                
                VStack(spacing: 0) {
                    // Header con indicatori di pagina - CORRETTO
                    HStack {
                        // Skip button
                        if currentPage < onboardingPages.count - 1 {
                            Button("Salta") {
                                completeOnboarding()
                            }
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        } else {
                            Spacer().frame(width: 50)
                        }
                        
                        Spacer()
                        
                        // Page indicators
                        HStack(spacing: 8) {
                            ForEach(0..<onboardingPages.count, id: \.self) { index in
                                Circle()
                                    .fill(index == currentPage ? onboardingPages[currentPage].color : Color.gray.opacity(0.3))
                                    .frame(width: 8, height: 8)
                                    .scaleEffect(index == currentPage ? 1.2 : 1.0)
                                    .animation(.spring(response: 0.5, dampingFraction: 0.8), value: currentPage)
                            }
                        }
                        
                        Spacer()
                        
                        Spacer().frame(width: 50)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, geometry.safeAreaInsets.top + 20) // CORRETTO: usa safe area
                    
                    // Content - CORRETTO: usa tutto lo spazio disponibile
                    TabView(selection: $currentPage) {
                        ForEach(0..<onboardingPages.count, id: \.self) { index in
                            OnboardingPageView(
                                page: onboardingPages[index],
                                isActive: currentPage == index,
                                animateElements: animateElements
                            )
                            .tag(index)
                        }
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                    .frame(height: geometry.size.height * 0.75) // CORRETTO: usa 75% dell'altezza
                    .onChange(of: currentPage) { _ in
                        triggerAnimation()
                    }
                    
                    // Bottom action - CORRETTO
                    VStack(spacing: 16) {
                        if currentPage < onboardingPages.count - 1 {
                            // Next button
                            Button(action: {
                                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                                    currentPage += 1
                                }
                            }) {
                                HStack {
                                    Text("Continua")
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                    
                                    Image(systemName: "arrow.right.circle.fill")
                                        .font(.title2)
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            onboardingPages[currentPage].color,
                                            onboardingPages[currentPage].color.opacity(0.8)
                                        ]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .shadow(color: onboardingPages[currentPage].color.opacity(0.3), radius: 10, x: 0, y: 5)
                            }
                            .animation(.easeInOut(duration: 0.3), value: currentPage)
                        } else {
                            // Start button
                            Button(action: {
                                completeOnboarding()
                            }) {
                                HStack {
                                    Text("Inizia ora!")
                                        .font(.headline)
                                        .fontWeight(.bold)
                                    
                                    Image(systemName: "arrow.up.circle.fill")
                                        .font(.title2)
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(
                                    LinearGradient(
                                        gradient: Gradient(colors: [.orange, .red]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .shadow(color: .orange.opacity(0.4), radius: 15, x: 0, y: 8)
                                .scaleEffect(animateElements ? 1.05 : 1.0)
                                .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: animateElements)
                            }
                        }
                        
                        // Info aggiuntiva
                        if currentPage == onboardingPages.count - 1 {
                            Text("🔒 I tuoi dati rimangono sempre sul tuo dispositivo")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .opacity(animateElements ? 1.0 : 0.7)
                                .animation(.easeInOut(duration: 2.0), value: animateElements)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, geometry.safeAreaInsets.bottom + 20) // CORRETTO: usa safe area bottom
                }
            }
        }
        .onAppear {
            triggerAnimation()
        }
    }
    
    private func triggerAnimation() {
        animateElements = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.easeOut(duration: 0.8)) {
                animateElements = true
            }
        }
    }
    
    private func completeOnboarding() {
        withAnimation(.spring()) {
            hasSeenOnboarding = true
        }
    }
}

// 3. NUOVO: OnboardingPage model
struct OnboardingPage {
    let title: String
    let subtitle: String
    let description: String
    let icon: String
    let color: Color
    let features: [String]
}

// 4. NUOVO: OnboardingPageView - Singola pagina
struct OnboardingPageView: View {
    let page: OnboardingPage
    let isActive: Bool
    let animateElements: Bool
    
    var body: some View {
        VStack(spacing: 24) { // RIDOTTO: meno spacing per far entrare tutto
            // Icon animata - RIDOTTA
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            gradient: Gradient(colors: [
                                page.color.opacity(0.3),
                                page.color.opacity(0.1),
                                page.color.opacity(0.05)
                            ]),
                            center: .center,
                            startRadius: 15,
                            endRadius: 60
                        )
                    )
                    .frame(width: 120, height: 120) // RIDOTTO da 160
                    .scaleEffect(animateElements ? 1.1 : 0.9)
                    .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: animateElements)
                
                ZStack {
                    Circle()
                        .fill(LinearGradient(
                            gradient: Gradient(colors: [page.color, page.color.opacity(0.7)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 80, height: 80) // RIDOTTO da 100
                        .shadow(color: page.color.opacity(0.4), radius: 15, x: 0, y: 8)
                    
                    Image(systemName: page.icon)
                        .font(.system(size: 32, weight: .bold)) // RIDOTTO da 40
                        .foregroundColor(.white)
                        .scaleEffect(animateElements ? 1.0 : 0.8)
                        .animation(.spring(response: 0.8, dampingFraction: 0.6), value: animateElements)
                }
            }
            
            // Text content - COMPATTATO
            VStack(spacing: 12) { // RIDOTTO da 16
                Text(page.title)
                    .font(.title) // RIDOTTO da largeTitle
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(LinearGradient(
                        gradient: Gradient(colors: [page.color, page.color.opacity(0.7)]),
                        startPoint: .leading,
                        endPoint: .trailing
                    ))
                    .opacity(animateElements ? 1.0 : 0.0)
                    .offset(y: animateElements ? 0 : 20)
                    .animation(.easeOut(duration: 0.8).delay(0.2), value: animateElements)
                
                Text(page.subtitle)
                    .font(.title3) // RIDOTTO da title2
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .opacity(animateElements ? 1.0 : 0.0)
                    .offset(y: animateElements ? 0 : 20)
                    .animation(.easeOut(duration: 0.8).delay(0.4), value: animateElements)
                
                Text(page.description)
                    .font(.subheadline) // RIDOTTO da body
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(3) // LIMITATO a 3 righe
                    .opacity(animateElements ? 1.0 : 0.0)
                    .offset(y: animateElements ? 0 : 20)
                    .animation(.easeOut(duration: 0.8).delay(0.6), value: animateElements)
            }
            .padding(.horizontal, 24)
            
            // Features list - COMPATTATE
            VStack(spacing: 10) { // RIDOTTO da 16
                ForEach(Array(page.features.enumerated()), id: \.offset) { index, feature in
                    OnboardingFeatureRow(
                        text: feature,
                        color: page.color,
                        delay: 0.8 + Double(index) * 0.1,
                        animateElements: animateElements
                    )
                }
            }
            .padding(.horizontal, 24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity) // AGGIUNTO: occupa tutto lo spazio
    }
}

// 5. NUOVO: OnboardingFeatureRow - Singola feature
struct OnboardingFeatureRow: View {
    let text: String
    let color: Color
    let delay: Double
    let animateElements: Bool
    
    var body: some View {
        HStack(spacing: 12) { // RIDOTTO da 16
            ZStack {
                Circle()
                    .fill(color.opacity(0.1))
                    .frame(width: 28, height: 28) // RIDOTTO da 32
                
                Image(systemName: "checkmark")
                    .font(.system(size: 12, weight: .bold)) // RIDOTTO da 14
                    .foregroundColor(color)
            }
            
            Text(text)
                .font(.caption) // RIDOTTO da subheadline
                .foregroundColor(.primary)
                .multilineTextAlignment(.leading)
            
            Spacer()
        }
        .padding(.horizontal, 16) // RIDOTTO da 20
        .padding(.vertical, 8) // RIDOTTO da 12
        .background(
            RoundedRectangle(cornerRadius: 12) // RIDOTTO da 16
                .fill(.regularMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(color.opacity(0.2), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 3) // RIDOTTA ombra
        )
        .opacity(animateElements ? 1.0 : 0.0)
        .offset(x: animateElements ? 0 : 50)
        .animation(.spring(response: 0.8, dampingFraction: 0.7).delay(delay), value: animateElements)
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

// MARK: - First Account Onboarding modificato (STEP 1 di 3)
struct FirstAccountOnboardingView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var accountName = ""
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
                                Text("Primo Passo! 🏦")
                                    .font(.largeTitle)
                                    .fontWeight(.bold)
                                    .multilineTextAlignment(.center)
                                    .foregroundStyle(LinearGradient(
                                        gradient: Gradient(colors: [.blue, .purple]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    ))
                                
                                Text("Iniziamo creando il tuo primo conto")
                                    .font(.title3)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                        }
                        
                        // Form semplificato - SOLO NOME CONTO
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
                                
                                // Info saldo automatico
                                VStack(alignment: .leading, spacing: 12) {
                                    HStack {
                                        Image(systemName: "info.circle.fill")
                                            .foregroundColor(.blue)
                                        Text("Saldo iniziale")
                                            .font(.headline)
                                            .fontWeight(.semibold)
                                    }
                                    
                                    HStack {
                                        Text("€0,00")
                                            .font(.title2)
                                            .fontWeight(.bold)
                                            .foregroundColor(.blue)
                                        
                                        Spacer()
                                        
                                        Text("(impostato automaticamente)")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    .padding()
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color.blue.opacity(0.1))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                                            )
                                    )
                                    
                                    Text("Il saldo verrà impostato dopo aver aggiunto i tuoi salvadanai e il saldo iniziale")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
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
                                                
                        // Progress indicator
                        VStack(spacing: 16) {
                            HStack {
                                Text("Passo 1 di 3")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Spacer()
                            }
                            
                            ProgressView(value: 1.0/3.0)
                                .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                                .scaleEffect(y: 2)
                        }
                        
                        // Bottone migliorato
                        VStack(spacing: 16) {
                            Button(action: {
                                createFirstAccount()
                            }) {
                                HStack {
                                    Text("Continua")
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
                            
                            Text("Successivamente: creerai i tuoi salvadanai")
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
        
        // MODIFICATO: Saldo sempre 0
        dataManager.addAccount(name: trimmedName, initialBalance: 0.0)
        
        // Animazione di successo
        withAnimation(.spring()) {
            // L'app si aggiornerà automaticamente mostrando il prossimo step
        }
    }
}

// MARK: - First Salvadanaio Onboarding (STEP 2 di 3) - MULTIPLI SALVADANAI
struct FirstSalvadanaiOnboardingView: View {
    @EnvironmentObject var dataManager: DataManager
    @AppStorage("hasCreatedFirstSalvadanaio") private var hasCreatedFirstSalvadanaio = false
    
    @State private var name = ""
    @State private var selectedType = "objective"
    @State private var targetAmount = 100.0
    @State private var targetDate = Date()
    @State private var monthlyRefill = 50.0
    @State private var selectedColor = "blue"
    @State private var isInfiniteObjective = false
    @State private var animateIcon = false
    
    // NUOVO: Array per gestire salvadanai creati durante l'onboarding
    @State private var createdSalvadanai: [OnboardingSalvadanaio] = []
    
    // NUOVO: Struct per salvadanai temporanei
    struct OnboardingSalvadanaio: Identifiable {
        let id = UUID()
        let name: String
        let type: String
        let targetAmount: Double
        let targetDate: Date?
        let monthlyRefill: Double
        let color: String
        let category: String // NUOVO: Categoria
        let isInfinite: Bool
    }
    
    let salvadanaiTypes = [
        ("objective", "Obiettivo", "target"),
        ("glass", "Glass", "cup.and.saucer.fill")
    ]
    
    var isFormValid: Bool {
        if name.isEmpty { return false }
        if selectedType == "objective" && !isInfiniteObjective && targetAmount <= 0 { return false }
        if selectedType == "glass" && monthlyRefill <= 0 { return false }
        return true
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [Color.green.opacity(0.1), Color.mint.opacity(0.1)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 40) {
                        Spacer(minLength: 60)
                        
                        // Header
                        VStack(spacing: 30) {
                            ZStack {
                                Circle()
                                    .fill(LinearGradient(
                                        gradient: Gradient(colors: [Color.green, Color.mint]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ))
                                    .frame(width: 120, height: 120)
                                    .shadow(color: .green.opacity(0.3), radius: 20, x: 0, y: 10)
                                
                                Image(systemName: "banknote.fill")
                                    .font(.system(size: 50))
                                    .foregroundColor(.white)
                                    .scaleEffect(animateIcon ? 1.1 : 1.0)
                                    .animation(.easeInOut(duration: 2).repeatForever(), value: animateIcon)
                            }
                            
                            VStack(spacing: 16) {
                                Text("Secondo Passo! 💰")
                                    .font(.largeTitle)
                                    .fontWeight(.bold)
                                    .multilineTextAlignment(.center)
                                    .foregroundStyle(LinearGradient(
                                        gradient: Gradient(colors: [.green, .mint]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    ))
                                
                                Text("Crea i tuoi salvadanai")
                                    .font(.title3)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                
                                if !createdSalvadanai.isEmpty {
                                    Text("\(createdSalvadanai.count) salvadanaio\(createdSalvadanai.count == 1 ? "" : "i") creato\(createdSalvadanai.count == 1 ? "" : "i")")
                                        .font(.subheadline)
                                        .foregroundColor(.green)
                                        .fontWeight(.medium)
                                }
                            }
                        }
                        
                        // Lista salvadanai creati
                        if !createdSalvadanai.isEmpty {
                            VStack(spacing: 16) {
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                    Text("Salvadanai creati")
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                    Spacer()
                                }
                                
                                VStack(spacing: 12) {
                                    ForEach(createdSalvadanai) { salvadanaio in
                                        CreatedSalvadanaiRow(salvadanaio: salvadanaio) {
                                            removeSalvadanaio(salvadanaio)
                                        }
                                    }
                                }
                            }
                            .padding(20)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.green.opacity(0.05))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(Color.green.opacity(0.3), lineWidth: 1)
                                    )
                            )
                        }
                        
                        // Form per nuovo salvadanaio
                        VStack(spacing: 24) {
                            VStack(spacing: 20) {
                                // Nome salvadanaio
                                VStack(alignment: .leading, spacing: 12) {
                                    HStack {
                                        Image(systemName: "tag.fill")
                                            .foregroundColor(.green)
                                        Text("Nome del salvadanaio")
                                            .font(.headline)
                                            .fontWeight(.semibold)
                                    }
                                    
                                    TextField("es. Vacanze Estate, Casa Nuova...", text: $name)
                                        .textFieldStyle(ModernTextFieldStyle())
                                        .textInputAutocapitalization(.words)
                                }
                                
                                // Tipo salvadanaio
                                VStack(alignment: .leading, spacing: 12) {
                                    HStack {
                                        Image(systemName: "list.bullet.circle.fill")
                                            .foregroundColor(.green)
                                        Text("Tipo di salvadanaio")
                                            .font(.headline)
                                            .fontWeight(.semibold)
                                    }
                                    
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
                                                    .foregroundColor(selectedType == type ? .green : .secondary)
                                                Text(displayName)
                                                Spacer()
                                                if selectedType == type {
                                                    Image(systemName: "checkmark.circle.fill")
                                                        .foregroundColor(.green)
                                                }
                                            }
                                            .padding(.vertical, 12)
                                            .padding(.horizontal, 16)
                                            .background(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .fill(selectedType == type ? Color.green.opacity(0.1) : Color.gray.opacity(0.05))
                                                    .overlay(
                                                        RoundedRectangle(cornerRadius: 12)
                                                            .stroke(selectedType == type ? Color.green : Color.clear, lineWidth: 2)
                                                    )
                                            )
                                            .contentShape(Rectangle())
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                        .foregroundColor(selectedType == type ? .green : .primary)
                                    }
                                }
                                
                                // Dettagli specifici per tipo
                                if selectedType == "objective" {
                                    VStack(alignment: .leading, spacing: 12) {
                                        HStack {
                                            Image(systemName: "target")
                                                .foregroundColor(.green)
                                            Text("Dettagli obiettivo")
                                                .font(.headline)
                                                .fontWeight(.semibold)
                                        }
                                        
                                        VStack(spacing: 16) {
                                            Toggle("Obiettivo infinito", isOn: $isInfiniteObjective)
                                                .toggleStyle(SwitchToggleStyle(tint: .green))
                                            
                                            if !isInfiniteObjective {
                                                VStack(spacing: 12) {
                                                    HStack {
                                                        Text("Obiettivo")
                                                        Spacer()
                                                        TextField("100", value: $targetAmount, format: .currency(code: "EUR"))
                                                            .multilineTextAlignment(.trailing)
                                                            .keyboardType(.decimalPad)
                                                            .textFieldStyle(RoundedBorderTextFieldStyle())
                                                            .frame(width: 100)
                                                    }
                                                    
                                                    DatePicker("Scadenza", selection: $targetDate, displayedComponents: .date)
                                                }
                                            }
                                        }
                                        .padding()
                                        .background(
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(Color.green.opacity(0.05))
                                        )
                                    }
                                } else {
                                    VStack(alignment: .leading, spacing: 12) {
                                        HStack {
                                            Image(systemName: "cup.and.saucer.fill")
                                                .foregroundColor(.green)
                                            Text("Dettagli Glass")
                                                .font(.headline)
                                                .fontWeight(.semibold)
                                        }
                                        
                                        HStack {
                                            Text("Ricarica mensile")
                                            Spacer()
                                            TextField("50", value: $monthlyRefill, format: .currency(code: "EUR"))
                                                .multilineTextAlignment(.trailing)
                                                .keyboardType(.decimalPad)
                                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                                .frame(width: 100)
                                        }
                                        .padding()
                                        .background(
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(Color.green.opacity(0.05))
                                        )
                                    }
                                }
                                
                                // Colore
                                VStack(alignment: .leading, spacing: 12) {
                                    HStack {
                                        Image(systemName: "paintbrush.fill")
                                            .foregroundColor(.green)
                                        Text("Colore")
                                            .font(.headline)
                                            .fontWeight(.semibold)
                                    }
                                    
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
                                }
                            }
                            .padding(28)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(.ultraThinMaterial)
                                    .shadow(color: .black.opacity(0.1), radius: 15, x: 0, y: 5)
                            )
                        }
                        
                        // Bottone per aggiungere salvadanaio
                        Button(action: {
                            addSalvadanaio()
                        }) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title2)
                                Text(createdSalvadanai.isEmpty ? "Crea primo salvadanaio" : "Aggiungi altro salvadanaio")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                Group {
                                    if !isFormValid {
                                        Color.gray
                                    } else {
                                        LinearGradient(
                                            gradient: Gradient(colors: [.green, .mint]),
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    }
                                }
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .shadow(color: isFormValid ? .green.opacity(0.3) : .clear, radius: 10, x: 0, y: 5)
                        }
                        .disabled(!isFormValid)
                        .animation(.spring(response: 0.5, dampingFraction: 0.6), value: isFormValid)
                        
                        // Progress indicator
                        VStack(spacing: 16) {
                            HStack {
                                Text("Passo 2 di 3")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Spacer()
                            }
                            
                            ProgressView(value: 2.0/3.0)
                                .progressViewStyle(LinearProgressViewStyle(tint: .green))
                                .scaleEffect(y: 2)
                        }
                        
                        // Bottone continua (solo se ha creato almeno un salvadanaio)
                        if !createdSalvadanai.isEmpty {
                            VStack(spacing: 16) {
                                Button(action: {
                                    saveAllSalvadanai()
                                }) {
                                    HStack {
                                        Text("Continua")
                                            .font(.headline)
                                            .fontWeight(.bold)
                                        
                                        Image(systemName: "arrow.right.circle.fill")
                                            .font(.title2)
                                    }
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(
                                        LinearGradient(
                                            gradient: Gradient(colors: [.blue, .purple]),
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                                    .shadow(color: .blue.opacity(0.3), radius: 10, x: 0, y: 5)
                                }
                                
                                Text("Successivamente: imposterai il saldo iniziale")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        } else {
                            VStack(spacing: 16) {
                                Text("⬆️ Crea almeno un salvadanaio per continuare")
                                    .font(.subheadline)
                                    .foregroundColor(.orange)
                                    .fontWeight(.medium)
                                    .multilineTextAlignment(.center)
                                
                                Text("I salvadanai ti aiutano a organizzare i tuoi risparmi per obiettivi specifici")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                            }
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
    
    private func addSalvadanaio() {
        let newSalvadanaio = OnboardingSalvadanaio(
            name: name,
            type: selectedType,
            targetAmount: isInfiniteObjective ? 0 : (selectedType == "objective" ? targetAmount : 0),
            targetDate: isInfiniteObjective ? nil : (selectedType == "objective" ? targetDate : nil),
            monthlyRefill: selectedType == "glass" ? monthlyRefill : 0,
            color: selectedColor,
            category: selectedType == "objective" ? "🎯 Obiettivi" : "🥤 Budget Mensili", // NUOVO: Categoria automatica
            isInfinite: selectedType == "objective" ? isInfiniteObjective : false
        )
        
        withAnimation(.spring()) {
            createdSalvadanai.append(newSalvadanaio)
        }
        
        // Reset form per il prossimo salvadanaio
        resetForm()
    }
    
    private func removeSalvadanaio(_ salvadanaio: OnboardingSalvadanaio) {
        withAnimation(.spring()) {
            createdSalvadanai.removeAll { $0.id == salvadanaio.id }
        }
    }
    
    private func resetForm() {
        name = ""
        selectedType = "objective"
        targetAmount = 100.0
        targetDate = Date()
        monthlyRefill = 50.0
        selectedColor = getNextAvailableColor()
        isInfiniteObjective = false
    }
    
    private func getNextAvailableColor() -> String {
        let usedColors = Set(createdSalvadanai.map(\.color))
        let availableColors = getSalvadanaiColors().map(\.name)
        
        for color in availableColors {
            if !usedColors.contains(color) {
                return color
            }
        }
        
        // Se tutti i colori sono usati, torna al primo
        return availableColors.first ?? "blue"
    }
    
    private func saveAllSalvadanai() {
        for salvadanaio in createdSalvadanai {
            dataManager.addSalvadanaio(
                name: salvadanaio.name,
                type: salvadanaio.type,
                targetAmount: salvadanaio.targetAmount,
                targetDate: salvadanaio.targetDate,
                monthlyRefill: salvadanaio.monthlyRefill,
                color: salvadanaio.color,
                category: salvadanaio.category, // NUOVO: Passa la categoria
                isInfinite: salvadanaio.isInfinite
            )
        }
        
        withAnimation(.spring()) {
            hasCreatedFirstSalvadanaio = true
        }
    }
}

// MARK: - Initial Balance Onboarding (STEP 3 di 3)
struct InitialBalanceOnboardingView: View {
    @EnvironmentObject var dataManager: DataManager
    @AppStorage("hasAddedInitialBalance") private var hasAddedInitialBalance = false
    
    @State private var amount = 0.0
    @State private var animateIcon = false
    @State private var showingDistribution = false
    
    var firstAccount: AccountModel? {
        dataManager.accounts.first
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [Color.orange.opacity(0.1), Color.yellow.opacity(0.1)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 40) {
                        Spacer(minLength: 60)
                        
                        // Header
                        VStack(spacing: 30) {
                            ZStack {
                                Circle()
                                    .fill(LinearGradient(
                                        gradient: Gradient(colors: [Color.orange, Color.yellow]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ))
                                    .frame(width: 120, height: 120)
                                    .shadow(color: .orange.opacity(0.3), radius: 20, x: 0, y: 10)
                                
                                Image(systemName: "eurosign.circle.fill")
                                    .font(.system(size: 50))
                                    .foregroundColor(.white)
                                    .scaleEffect(animateIcon ? 1.1 : 1.0)
                                    .animation(.easeInOut(duration: 2).repeatForever(), value: animateIcon)
                            }
                            
                            VStack(spacing: 16) {
                                Text("Ultimo Passo! 🎉")
                                    .font(.largeTitle)
                                    .fontWeight(.bold)
                                    .multilineTextAlignment(.center)
                                    .foregroundStyle(LinearGradient(
                                        gradient: Gradient(colors: [.orange, .yellow]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    ))
                                
                                Text("Imposta il tuo saldo iniziale")
                                    .font(.title3)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                        }
                        
                        // Form semplificato
                        VStack(spacing: 24) {
                            VStack(spacing: 20) {
                                // Info descrizione fissa
                                VStack(alignment: .leading, spacing: 12) {
                                    HStack {
                                        Image(systemName: "info.circle.fill")
                                            .foregroundColor(.orange)
                                        Text("Descrizione dell'entrata")
                                            .font(.headline)
                                            .fontWeight(.semibold)
                                    }
                                    
                                    HStack {
                                        Text("Saldo iniziale")
                                            .font(.title3)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.orange)
                                        
                                        Spacer()
                                        
                                        Text("(impostato automaticamente)")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    .padding()
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color.orange.opacity(0.1))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                                            )
                                    )
                                }
                                
                                // Campo importo
                                VStack(alignment: .leading, spacing: 12) {
                                    HStack {
                                        Image(systemName: "eurosign.circle.fill")
                                            .foregroundColor(.green)
                                        Text("Quanto hai attualmente?")
                                            .font(.headline)
                                            .fontWeight(.semibold)
                                    }
                                    
                                    VStack(spacing: 16) {
                                        HStack {
                                            Text("Importo")
                                                .font(.subheadline)
                                            Spacer()
                                            TextField("0", value: $amount, format: .currency(code: "EUR"))
                                                .multilineTextAlignment(.trailing)
                                                .keyboardType(.decimalPad)
                                                .font(.title2)
                                                .fontWeight(.bold)
                                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                                .frame(width: 120)
                                        }
                                        
                                        // Info conto destinazione
                                        if let account = firstAccount {
                                            HStack {
                                                Image(systemName: "building.columns.fill")
                                                    .foregroundColor(.blue)
                                                Text("Verrà aggiunto a: \(account.name)")
                                                    .font(.subheadline)
                                                    .foregroundColor(.blue)
                                                    .fontWeight(.medium)
                                                Spacer()
                                            }
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 8)
                                            .background(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .fill(Color.blue.opacity(0.1))
                                            )
                                        }
                                    }
                                }
                                
                                // Spiegazione
                                VStack(alignment: .leading, spacing: 12) {
                                    HStack {
                                        Image(systemName: "lightbulb.fill")
                                            .foregroundColor(.yellow)
                                        Text("Come funziona")
                                            .font(.headline)
                                            .fontWeight(.semibold)
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 8) {
                                        HStack(alignment: .top, spacing: 12) {
                                            Text("1.")
                                                .font(.caption)
                                                .fontWeight(.bold)
                                                .foregroundColor(.orange)
                                                .frame(width: 20, alignment: .leading)
                                            
                                            Text("L'importo verrà registrato come \"Saldo iniziale\" sul tuo conto")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                        
                                        HStack(alignment: .top, spacing: 12) {
                                            Text("2.")
                                                .font(.caption)
                                                .fontWeight(.bold)
                                                .foregroundColor(.orange)
                                                .frame(width: 20, alignment: .leading)
                                            
                                            Text("Potrai distribuire l'importo tra i tuoi salvadanai come preferisci")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                        
                                        HStack(alignment: .top, spacing: 12) {
                                            Text("3.")
                                                .font(.caption)
                                                .fontWeight(.bold)
                                                .foregroundColor(.orange)
                                                .frame(width: 20, alignment: .leading)
                                            
                                            Text("L'app sarà pronta per l'uso!")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                }
                            }
                            .padding(28)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(.ultraThinMaterial)
                                    .shadow(color: .black.opacity(0.1), radius: 15, x: 0, y: 5)
                            )
                        }
                        
                        // Progress indicator
                        VStack(spacing: 16) {
                            HStack {
                                Text("Passo 3 di 3")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Spacer()
                            }
                            
                            ProgressView(value: 3.0/3.0)
                                .progressViewStyle(LinearProgressViewStyle(tint: .orange))
                                .scaleEffect(y: 2)
                        }
                        
                        // Bottone finale
                        VStack(spacing: 16) {
                            Button(action: {
                                showInitialBalanceDistribution()
                            }) {
                                HStack {
                                    Text("Distribuisci Saldo!")
                                        .font(.headline)
                                        .fontWeight(.bold)
                                    
                                    Image(systemName: "arrow.branch")
                                        .font(.title2)
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(
                                    Group {
                                        if amount <= 0 {
                                            Color.gray
                                        } else {
                                            LinearGradient(
                                                gradient: Gradient(colors: [.orange, .yellow]),
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        }
                                    }
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .shadow(color: amount > 0 ? .orange.opacity(0.3) : .clear, radius: 10, x: 0, y: 5)
                            }
                            .disabled(amount <= 0)
                            .animation(.spring(response: 0.5, dampingFraction: 0.6), value: amount > 0)
                            
                            if amount <= 0 {
                                Button("Salta (inizia con €0)") {
                                    completeSetupWithoutBalance()
                                }
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            }
                            
                            Text("🎉 Dopo aver distribuito il saldo, l'app sarà pronta!")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
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
        .sheet(isPresented: $showingDistribution) {
            SalaryDistributionView(
                amount: amount,
                descr: "Saldo iniziale",
                transactionType: "income",
                selectedAccount: firstAccount?.name ?? "",
                onComplete: {
                    // Quando la distribuzione è completata, chiudi l'onboarding
                    withAnimation(.spring()) {
                        hasAddedInitialBalance = true
                    }
                }
            )
        }
    }
    
    private func showInitialBalanceDistribution() {
        showingDistribution = true
    }
    
    private func completeSetupWithoutBalance() {
        withAnimation(.spring()) {
            hasAddedInitialBalance = true
        }
    }
}

// MARK: - Created Salvadanaio Row (da aggiungere al file)
struct CreatedSalvadanaiRow: View {
    let salvadanaio: FirstSalvadanaiOnboardingView.OnboardingSalvadanaio
    let onRemove: () -> Void
    
    private func getColor(from colorString: String) -> Color {
        switch colorString.lowercased() {
        case "blue": return .blue
        case "green": return .green
        case "red": return .red
        case "orange": return .orange
        case "purple": return .purple
        case "pink": return .pink
        case "yellow": return .yellow
        case "indigo": return .indigo
        case "mint": return .mint
        case "teal": return .teal
        case "cyan": return .cyan
        case "brown": return .brown
        default: return .blue
        }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Pallino colorato
            Circle()
                .fill(getColor(from: salvadanaio.color))
                .frame(width: 16, height: 16)
            
            // Info salvadanaio
            VStack(alignment: .leading, spacing: 4) {
                Text(salvadanaio.name)
                    .font(.headline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                HStack(spacing: 8) {
                    // Tipo
                    HStack(spacing: 4) {
                        Image(systemName: salvadanaio.type == "objective" ? (salvadanaio.isInfinite ? "infinity" : "target") : "cup.and.saucer.fill")
                            .font(.caption)
                            .foregroundColor(getColor(from: salvadanaio.color))
                        
                        Text(salvadanaio.type == "objective" ? (salvadanaio.isInfinite ? "Infinito" : "Obiettivo") : "Glass")
                            .font(.caption)
                            .foregroundColor(getColor(from: salvadanaio.color))
                            .fontWeight(.medium)
                    }
                    
                    // NUOVO: Categoria
                    Text("• \(salvadanaio.category)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    // Dettagli specifici
                    if salvadanaio.type == "objective" && !salvadanaio.isInfinite {
                        Text("• €\(String(format: "%.0f", salvadanaio.targetAmount))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else if salvadanaio.type == "glass" {
                        Text("• €\(String(format: "%.0f", salvadanaio.monthlyRefill))/mese")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
            
            // Bottone rimuovi
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title3)
                    .foregroundColor(.red)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(getColor(from: salvadanaio.color).opacity(0.3), lineWidth: 1)
                )
        )
    }
}

// MARK: - Modern Text Field Style
struct ModernTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.regularMaterial) // Cambiato per dark mode
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(.tertiary, lineWidth: 1) // Cambiato per dark mode
                    )
            )
    }
}

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
                .background(color.opacity(0.15)) // Aumentata opacità per dark mode
                .clipShape(Circle())
            
            Text(name)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary) // Cambiato per adattarsi al tema
                .lineLimit(1)
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.regularMaterial) // Cambiato da Color.white per dark mode
                .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(.separator, lineWidth: 0.5) // Aggiunto bordo per definizione
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
                            totalBalance: totalBalance
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

// MARK: - Enhanced Home Salvadanaio Card - Accattivante e Animata
struct ImprovedSalvadanaiHomeCard: View {
    let salvadanaio: SalvadanaiModel
    @State private var animateProgress = false
    @State private var animateGlow = false
    @State private var animateIcon = false
    @State private var animateAmount = false
    @State private var isPressed = false
    
    private var progress: Double {
        // Per glass: currentAmount / monthlyRefill
        if salvadanaio.type == "glass" {
            let current = salvadanaio.currentAmount
            let monthly = salvadanaio.monthlyRefill
            
            if current > 0 && monthly > 0 {
                let result = current / monthly
                return min(result, 1.0)
            }
        }
        
        // Per obiettivi: currentAmount / targetAmount
        if salvadanaio.type == "objective" && !salvadanaio.isInfinite {
            let current = salvadanaio.currentAmount
            let target = salvadanaio.targetAmount
            
            if current > 0 && target > 0 {
                let result = current / target
                return min(result, 1.0)
            }
        }
        
        return 0
    }
    
    // Funzione per convertire string colore in Color
    private func getColor(from colorString: String) -> Color {
        switch colorString.lowercased() {
        case "blue": return .blue
        case "green": return .green
        case "red": return .red
        case "orange": return .orange
        case "purple": return .purple
        case "pink": return .pink
        case "yellow": return .yellow
        case "indigo": return .indigo
        case "mint": return .mint
        case "teal": return .teal
        case "cyan": return .cyan
        case "brown": return .brown
        default: return .blue
        }
    }
    
    private var cardGradient: LinearGradient {
        let baseColor = getColor(from: salvadanaio.color)
        
        if salvadanaio.currentAmount < 0 {
            // Gradiente rosso per saldi negativi
            return LinearGradient(
                gradient: Gradient(colors: [
                    Color.red.opacity(0.8),
                    Color.orange.opacity(0.7),
                    Color.pink.opacity(0.6)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else if progress >= 1.0 && !salvadanaio.isInfinite {
            // Gradiente dorato per obiettivi completati
            return LinearGradient(
                gradient: Gradient(colors: [
                    Color.yellow.opacity(0.8),
                    Color.orange.opacity(0.7),
                    baseColor.opacity(0.6)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            // Gradiente normale con il colore del salvadanaio
            return LinearGradient(
                gradient: Gradient(colors: [
                    baseColor.opacity(0.8),
                    baseColor.opacity(0.6),
                    baseColor.opacity(0.7)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
    
    private var statusInfo: (String, String, Color) {
        if salvadanaio.currentAmount < 0 {
            return ("⚠️", "In Rosso", .red)
        } else if progress >= 1.0 && !salvadanaio.isInfinite {
            return ("🎉", "Completato!", .yellow)
        } else if progress >= 0.8 && !salvadanaio.isInfinite {
            return ("🔥", "Quasi Fatto!", .orange)
        } else if salvadanaio.isInfinite {
            return ("♾️", "Infinito", getColor(from: salvadanaio.color))
        } else {
            return ("💪", "In Corso", getColor(from: salvadanaio.color))
        }
    }
    
    var body: some View {
        Button(action: {
            // Azione per aprire dettagli salvadanaio
        }) {
            ZStack {
                // Background card con gradiente animato
                RoundedRectangle(cornerRadius: 20)
                    .fill(cardGradient)
                    .frame(width: 200, height: 150)
                    .shadow(
                        color: getColor(from: salvadanaio.color).opacity(animateGlow ? 0.4 : 0.2),
                        radius: animateGlow ? 15 : 8,
                        x: 0,
                        y: animateGlow ? 8 : 4
                    )
                    .animation(.easeInOut(duration: 3.5).repeatForever(autoreverses: true), value: animateGlow)
                
                // Overlay decorativo
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        RadialGradient(
                            gradient: Gradient(colors: [
                                Color.white.opacity(0.3),
                                Color.clear,
                                Color.black.opacity(0.1)
                            ]),
                            center: .topTrailing,
                            startRadius: 10,
                            endRadius: 100
                        )
                    )
                    .frame(width: 200, height: 150)
                
                // Elementi decorativi fluttuanti
                GeometryReader { geometry in
                    ZStack {
                        // Cerchi decorativi
                        Circle()
                            .fill(Color.white.opacity(0.15))
                            .frame(width: 40, height: 40)
                            .position(x: geometry.size.width * 0.8, y: geometry.size.height * 0.25)
                            .scaleEffect(animateIcon ? 1.2 : 0.8)
                            .animation(.easeInOut(duration: 4).repeatForever(autoreverses: true), value: animateIcon)
                        
                        Circle()
                            .fill(Color.white.opacity(0.08))
                            .frame(width: 25, height: 25)
                            .position(x: geometry.size.width * 0.2, y: geometry.size.height * 0.8)
                            .scaleEffect(animateIcon ? 0.6 : 1.1)
                            .animation(.easeInOut(duration: 3.5).repeatForever(autoreverses: true), value: animateIcon)
                        
                        // Stelline decorative
                        if progress >= 0.8 || salvadanaio.currentAmount < 0 {
                            Image(systemName: "sparkles")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.6))
                                .position(x: geometry.size.width * 0.25, y: geometry.size.height * 0.3)
                                .scaleEffect(animateGlow ? 1.3 : 0.7)
                                .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: animateGlow)
                        }
                    }
                }
                .frame(width: 200, height: 150)
                
                // Contenuto principale
                VStack(spacing: 10) {
                    // Header con icona e status
                    HStack {
                        // Icona tipo salvadanaio animata
                        ZStack {
                            Circle()
                                .fill(Color.white.opacity(0.25))
                                .frame(width: 36, height: 36)
                                .blur(radius: animateGlow ? 1 : 0)
                            
                            Image(systemName: salvadanaio.type == "objective" ? (salvadanaio.isInfinite ? "infinity" : "target") : "cup.and.saucer.fill")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .scaleEffect(animateIcon ? 1.1 : 1.0)
                                .animation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true), value: animateIcon)
                        }
                        
                        Spacer()
                        
                        // Status badge animato
                        HStack(spacing: 4) {
                            Text(statusInfo.0)
                                .font(.caption)
                                .scaleEffect(statusInfo.0 == "🎉" ? (animateIcon ? 1.2 : 1.0) : 1.0)
                                .animation(.spring(response: 0.6, dampingFraction: 0.5).repeatForever(autoreverses: true), value: animateIcon)
                            
                            Text(statusInfo.1)
                                .font(.caption2)
                                .fontWeight(.semibold)
                                .foregroundColor(.white.opacity(0.9))
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(Color.white.opacity(0.2))
                        )
                    }
                    .padding(.top, 4)
                    
                    // Nome e importo
                    VStack(alignment: .leading, spacing: 6) {
                        // Nome salvadanaio
                        HStack {
                            Text(salvadanaio.name)
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .lineLimit(2)
                                .multilineTextAlignment(.leading)
                                .fixedSize(horizontal: false, vertical: true)
                            
                            Spacer()
                        }
                        
                        // Importo con animazione
                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text("€")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.8))
                            
                            Text(String(format: "%.0f", abs(salvadanaio.currentAmount)))
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .contentTransition(.numericText())
                                .scaleEffect(animateAmount ? 1.05 : 1.0)
                                .shadow(color: .white.opacity(0.5), radius: animateGlow ? 4 : 2)
                            
                            Spacer()
                        }
                    }
                    
                    // Progress o info obiettivo
                    if !salvadanaio.isInfinite && salvadanaio.currentAmount >= 0 {
                        VStack(spacing: 6) {
                            // Progress bar migliorata
                            GeometryReader { geometry in
                                ZStack(alignment: .leading) {
                                    // Background
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color.white.opacity(0.2))
                                        .frame(height: 6)
                                    
                                    // Progress fill
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(
                                            LinearGradient(
                                                gradient: Gradient(colors: [
                                                    Color.white.opacity(0.9),
                                                    Color.white.opacity(0.7),
                                                    Color.white.opacity(0.9)
                                                ]),
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .frame(width: max(0, geometry.size.width * (animateProgress ? progress : 0)), height: 6)
                                        .shadow(color: .white.opacity(0.5), radius: 2, x: 0, y: 1)
                                        .animation(.easeOut(duration: 1.5).delay(0.5), value: animateProgress)
                                    
                                    // Shimmer effect
                                    if progress > 0 {
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(
                                                LinearGradient(
                                                    gradient: Gradient(colors: [
                                                        Color.clear,
                                                        Color.white.opacity(0.8),
                                                        Color.clear
                                                    ]),
                                                    startPoint: .leading,
                                                    endPoint: .trailing
                                                )
                                            )
                                            .frame(width: max(0, geometry.size.width * progress), height: 6)
                                            .opacity(animateGlow ? 0.8 : 0.0)
                                            .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: animateGlow)
                                    }
                                }
                            }
                            .frame(height: 6)
                            
                            HStack {
                                Text("\(Int(progress * 100))%")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                
                                Spacer()
                                
                                if progress >= 1.0 {
                                    Text("🏆 Fatto!")
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .foregroundColor(.white)
                                } else {
                                    Text("di €\(String(format: "%.0f", salvadanaio.type == "objective" ? salvadanaio.targetAmount : salvadanaio.monthlyRefill))")
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.8))
                                }
                            }
                        }
                        .padding(.bottom, 4)
                    } else if salvadanaio.isInfinite {
                        // Info per infiniti
                        HStack {
                            Image(systemName: "infinity")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.8))
                            Text("Crescita continua")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.white.opacity(0.9))
                            Spacer()
                        }
                        .padding(.bottom, 4)
                    } else {
                        // Info per saldi negativi
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.caption)
                                .foregroundColor(.white)
                            Text("Recupera €\(String(format: "%.0f", abs(salvadanaio.currentAmount)))")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                            Spacer()
                        }
                        .padding(.bottom, 4)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 24)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }) {
            // Long press action
        }
        .onAppear {
            // Animazioni con delay per effetto staggered
            let delay = Double.random(in: 0.2...0.6)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                withAnimation(.easeInOut(duration: 0.8)) {
                    animateAmount = true
                }
                withAnimation(.easeInOut(duration: 1.2)) {
                    animateGlow = true
                }
                withAnimation(.easeInOut(duration: 1.5)) {
                    animateIcon = true
                }
                withAnimation(.easeOut(duration: 1.5).delay(0.3)) {
                    animateProgress = true
                }
            }
        }
    }
}

// MARK: - Versione ancora più minimal
struct MinimalSalvadanaiCard: View {
    let salvadanaio: SalvadanaiModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Nome con pallino colorato
            HStack(spacing: 8) {
                Circle()
                    .fill(Color(salvadanaio.color))
                    .frame(width: 12, height: 12)
                
                Text(salvadanaio.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)
                
                Spacer()
            }
            
            // Importo
            Text("€\(String(format: "%.0f", abs(salvadanaio.currentAmount)))")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(salvadanaio.currentAmount < 0 ? .red : .primary)
            
            // Info essenziale
            if salvadanaio.currentAmount < 0 {
                Text("In rosso")
                    .font(.caption2)
                    .foregroundColor(.red)
            } else if salvadanaio.type == "objective" && !salvadanaio.isInfinite {
                Text("di €\(String(format: "%.0f", salvadanaio.targetAmount))")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            } else if salvadanaio.type == "glass" {
                Text("Glass €\(String(format: "%.0f", salvadanaio.monthlyRefill))")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            } else {
                Text("Infinito")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(14)
        .frame(width: 160, height: 100)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(salvadanaio.color).opacity(0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(salvadanaio.color).opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Alternative: Versione più compatta ma stilosa
struct CompactStylishSalvadanaiCard: View {
    let salvadanaio: SalvadanaiModel
    @State private var animateAmount = false
    
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
        VStack(spacing: 16) {
            // Header con icona colorata
            HStack {
                // Icona tipo
                ZStack {
                    Circle()
                        .fill(Color(salvadanaio.color))
                        .frame(width: 36, height: 36)
                        .shadow(color: Color(salvadanaio.color).opacity(0.4), radius: 6, x: 0, y: 3)
                    
                    Image(systemName: salvadanaio.type == "objective" ? (salvadanaio.isInfinite ? "infinity" : "target") : "cup.and.saucer.fill")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                // Status emoji
                if salvadanaio.currentAmount < 0 {
                    Text("⚠️")
                        .font(.title3)
                } else if progress >= 1.0 {
                    Text("🎉")
                        .font(.title3)
                } else if progress >= 0.8 {
                    Text("🔥")
                        .font(.title3)
                }
            }
            
            // Nome e importo
            VStack(alignment: .leading, spacing: 8) {
                Text(salvadanaio.name)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                Text("€\(String(format: "%.0f", abs(salvadanaio.currentAmount)))")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(salvadanaio.currentAmount < 0 ? .red : Color(salvadanaio.color))
                    .scaleEffect(animateAmount ? 1.05 : 1.0)
                    .animation(.easeInOut(duration: 0.6), value: animateAmount)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // Progress minimalista
            if salvadanaio.currentAmount >= 0 && !salvadanaio.isInfinite && progress > 0 {
                VStack(spacing: 4) {
                    HStack {
                        Text("\(Int(progress * 100))%")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(Color(salvadanaio.color))
                        
                        Spacer()
                        
                        if salvadanaio.type == "objective" {
                            Text("€\(String(format: "%.0f", salvadanaio.targetAmount))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        } else {
                            Text("€\(String(format: "%.0f", salvadanaio.monthlyRefill))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    ProgressView(value: progress)
                        .progressViewStyle(LinearProgressViewStyle(tint: Color(salvadanaio.color)))
                        .scaleEffect(y: 1.5)
                }
            } else if salvadanaio.isInfinite {
                HStack {
                    Image(systemName: "infinity")
                        .font(.caption)
                        .foregroundColor(Color(salvadanaio.color))
                    Text("Infinito")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(Color(salvadanaio.color))
                    Spacer()
                }
            }
        }
        .padding(20)
        .frame(width: 180, height: 160)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 6)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(LinearGradient(
                    gradient: Gradient(colors: [
                        Color(salvadanaio.color).opacity(0.3),
                        Color(salvadanaio.color).opacity(0.1)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ), lineWidth: 1.5)
        )
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                animateAmount = true
            }
        }
    }
}

// MARK: - Enhanced Home Transaction Row - Compatta e Accattivante
struct ImprovedHomeTransactionRow: View {
    let transaction: TransactionModel
    @State private var animateAmount = false
    @State private var animateGlow = false
    @State private var animateIcon = false
    @State private var isPressed = false
    
    private var transactionColor: Color {
        switch transaction.type {
        case "expense": return .red
        case "salary": return .blue
        case "transfer": return .orange
        case "transfer_salvadanai": return .purple
        case "distribution": return .mint
        default: return .green
        }
    }
    
    private var categoryEmoji: String {
        if let firstChar = transaction.category.first, firstChar.isEmoji {
            return String(firstChar)
        }
        return ""
    }
    
    private var cleanCategoryName: String {
        if let firstChar = transaction.category.first, firstChar.isEmoji {
            return String(transaction.category.dropFirst()).trimmingCharacters(in: .whitespaces)
        }
        return transaction.category
    }
    
    private var iconName: String {
        switch transaction.type {
        case "expense": return "minus.circle.fill"
        case "salary": return "banknote.fill"
        case "transfer": return "arrow.left.arrow.right.circle.fill"
        case "transfer_salvadanai": return "arrow.triangle.swap"
        case "distribution": return "arrow.branch.circle.fill"
        default: return "plus.circle.fill"
        }
    }
    
    private var miniGradient: LinearGradient {
        switch transaction.type {
        case "expense":
            return LinearGradient(
                gradient: Gradient(colors: [
                    Color.red.opacity(0.9),
                    Color.orange.opacity(0.7)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case "salary":
            return LinearGradient(
                gradient: Gradient(colors: [
                    Color.blue.opacity(0.9),
                    Color.indigo.opacity(0.7)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case "transfer", "transfer_salvadanai":
            return LinearGradient(
                gradient: Gradient(colors: [
                    Color.orange.opacity(0.9),
                    Color.yellow.opacity(0.7)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case "distribution":
            return LinearGradient(
                gradient: Gradient(colors: [
                    Color.mint.opacity(0.9),
                    Color.teal.opacity(0.7)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        default:
            return LinearGradient(
                gradient: Gradient(colors: [
                    Color.green.opacity(0.9),
                    Color.cyan.opacity(0.7)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
    
    private var timeAgo: String {
        let now = Date()
        let interval = now.timeIntervalSince(transaction.date)
        
        if interval < 3600 { // Meno di 1 ora
            let minutes = Int(interval / 60)
            return minutes <= 1 ? "ora" : "\(minutes)m fa"
        } else if interval < 86400 { // Meno di 1 giorno
            let hours = Int(interval / 3600)
            return hours == 1 ? "1h fa" : "\(hours)h fa"
        } else { // Più di 1 giorno
            let days = Int(interval / 86400)
            return days == 1 ? "ieri" : "\(days)g fa"
        }
    }
    
    var body: some View {
        Button(action: {
            // Azione per andare ai dettagli transazione
        }) {
            ZStack {
                // Background con gradiente mini
                RoundedRectangle(cornerRadius: 14)
                    .fill(miniGradient)
                    .frame(height: 72)
                    .shadow(
                        color: transactionColor.opacity(animateGlow ? 0.3 : 0.15),
                        radius: animateGlow ? 8 : 4,
                        x: 0,
                        y: 2
                    )
                    .animation(.easeInOut(duration: 3.5).repeatForever(autoreverses: true), value: animateGlow)
                
                // Overlay decorativo sottile
                RoundedRectangle(cornerRadius: 14)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.white.opacity(0.2),
                                Color.clear,
                                Color.black.opacity(0.05)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(height: 72)
                
                // Elementi decorativi micro
                GeometryReader { geometry in
                    ZStack {
                        // Punto luminoso piccolo
                        Circle()
                            .fill(Color.white.opacity(0.15))
                            .frame(width: 20, height: 20)
                            .position(x: geometry.size.width * 0.85, y: geometry.size.height * 0.3)
                            .scaleEffect(animateIcon ? 1.3 : 0.7)
                            .animation(.easeInOut(duration: 4).repeatForever(autoreverses: true), value: animateIcon)
                        
                        // Micro sparkle per transazioni importanti
                        if transaction.amount >= 100 {
                            Image(systemName: "sparkle")
                                .font(.caption2)
                                .foregroundColor(.white.opacity(0.4))
                                .position(x: geometry.size.width * 0.15, y: geometry.size.height * 0.7)
                                .scaleEffect(animateGlow ? 1.4 : 0.6)
                                .animation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true), value: animateGlow)
                        }
                    }
                }
                .frame(height: 72)
                
                // Contenuto principale compatto
                HStack(spacing: 12) {
                    // Icona principale mini
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.25))
                            .frame(width: 40, height: 40)
                            .blur(radius: animateGlow ? 0.5 : 0)
                        
                        if !categoryEmoji.isEmpty {
                            Text(categoryEmoji)
                                .font(.system(size: 18))
                                .scaleEffect(animateIcon ? 1.1 : 1.0)
                                .animation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true), value: animateIcon)
                        } else {
                            Image(systemName: iconName)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .scaleEffect(animateIcon ? 1.1 : 1.0)
                                .animation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true), value: animateIcon)
                        }
                    }
                    
                    // Informazioni compatte
                    VStack(alignment: .leading, spacing: 3) {
                        // Descrizione principale
                        Text(transaction.descr)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .lineLimit(1)
                            .truncationMode(.tail)
                        
                        // Categoria e tempo
                        HStack(spacing: 6) {
                            Text(cleanCategoryName)
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.white.opacity(0.85))
                                .lineLimit(1)
                            
                            Circle()
                                .fill(Color.white.opacity(0.6))
                                .frame(width: 2, height: 2)
                            
                            Text(timeAgo)
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.75))
                        }
                        
                        // Conto se presente (solo per spese/entrate)
                        if !transaction.accountName.isEmpty && (transaction.type == "expense" || transaction.type == "income" || transaction.type == "salary") {
                            HStack(spacing: 4) {
                                Image(systemName: "building.columns")
                                    .font(.caption2)
                                    .foregroundColor(.white.opacity(0.7))
                                
                                Text(transaction.accountName)
                                    .font(.caption2)
                                    .foregroundColor(.white.opacity(0.8))
                                    .lineLimit(1)
                            }
                        }
                    }
                    
                    Spacer()
                    
                    // Importo e tipo compatti
                    VStack(alignment: .trailing, spacing: 4) {
                        // Importo
                        HStack(alignment: .firstTextBaseline, spacing: 1) {
                            Text(transaction.type == "expense" ? "-" : "+")
                                .font(.subheadline)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            Text("€\(String(format: "%.0f", transaction.amount))")
                                .font(.callout)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .scaleEffect(animateAmount ? 1.03 : 1.0)
                                .shadow(color: .white.opacity(0.3), radius: 1)
                        }
                        
                        // Badge tipo mini
                        Text(getShortTypeLabel())
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundColor(.white.opacity(0.8))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                Capsule()
                                    .fill(Color.white.opacity(0.2))
                            )
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.easeInOut(duration: 0.15), value: isPressed)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(.easeInOut(duration: 0.15)) {
                isPressed = pressing
            }
        }) {
            // Long press action
        }
        .onAppear {
            // Animazioni con delay casuali per effetto staggered
            let delay = Double.random(in: 0.1...0.4)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                withAnimation(.easeInOut(duration: 0.8)) {
                    animateAmount = true
                }
                withAnimation(.easeInOut(duration: 1.5)) {
                    animateGlow = true
                }
                withAnimation(.easeInOut(duration: 2.0)) {
                    animateIcon = true
                }
            }
        }
    }
    
    private func getShortTypeLabel() -> String {
        switch transaction.type {
        case "expense": return "SPESA"
        case "salary": return "STIP."
        case "transfer": return "TRASF."
        case "transfer_salvadanai": return "SALV."
        case "distribution": return "DISTR."
        default: return "ENTR."
        }
    }
}

// MARK: - Enhanced Wealth Card (MODIFICATA - solo conti)
struct EnhancedWealthCard: View {
    let totalBalance: Double
    @State private var animateBalance = false
    @State private var animateGlow = false
    
    private var totalWealth: Double {
        totalBalance // MODIFICATO: Solo dai conti, non dai salvadanai
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
            
            // Contenuto principale - CENTRATO VERTICALMENTE
            VStack(spacing: 0) {
                // Header con icona animata - rimane in alto
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
                    }
                    
                    Spacer()
                }
                
                // Spacer per centrare l'importo
                Spacer()
                
                // Importo principale con effetto wow - CENTRATO
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
                
                // Spacer per centrare l'importo
                Spacer()
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
