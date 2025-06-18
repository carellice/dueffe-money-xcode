import SwiftUI

@main
struct DueffeApp: App {
    @StateObject private var biometricAuthManager = BiometricAuthManager()
    @State private var showSplash = true
    @State private var startTransition = false
    @State private var needsAuthentication = false
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                // App principale
                if needsAuthentication {
                    BiometricAuthView {
                        needsAuthentication = false
                        biometricAuthManager.isAuthenticated = true
                    }
                } else {
                    ContentView()
                        .opacity(startTransition ? 1 : 0)
                        .scaleEffect(startTransition ? 1.0 : 0.9)
                        .blur(radius: startTransition ? 0 : 10)
                        .animation(.easeInOut(duration: 1.2), value: startTransition)
                        .environmentObject(biometricAuthManager)
                }
                
                // Splash screen con effetti multipli
                if showSplash {
                    AnimatedSplashScreen()
                        .opacity(startTransition ? 0 : 1)
                        .scaleEffect(startTransition ? 1.2 : 1.0)
                        .blur(radius: startTransition ? 20 : 0)
                        .animation(.easeInOut(duration: 1.2), value: startTransition)
                }
            }
            .onAppear {
                // Controlla se è necessaria l'autenticazione
                if biometricAuthManager.biometricAuthEnabled {
                    needsAuthentication = true
                }
                
                // Inizia transizione dopo 3 secondi
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                    withAnimation(.easeInOut(duration: 1.2)) {
                        startTransition = true
                    }
                    
                    // Rimuovi splash dopo transizione
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                        showSplash = false
                    }
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                // Richiedi autenticazione quando l'app torna in foreground
                if biometricAuthManager.biometricAuthEnabled {
                    biometricAuthManager.resetAuthentication()
                    needsAuthentication = true
                }
            }
        }
    }
}
