import SwiftUI

@main
struct DueffeApp: App {
    @State private var showSplash = true
    @State private var startTransition = false
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                // App principale
                ContentView()
                    .opacity(startTransition ? 1 : 0)
                    .scaleEffect(startTransition ? 1.0 : 0.9)
                    .blur(radius: startTransition ? 0 : 10)
                    .animation(.easeInOut(duration: 1.2), value: startTransition)
                
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
        }
    }
}
