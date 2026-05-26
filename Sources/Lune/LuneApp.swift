import SwiftUI

@main
struct LuneApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
        }
    }
}

struct RootView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        Group {
            switch appState.screen {
            case .connect:         ConnectScreen()
            case .signupSymptoms:      SignupSymptomsScreen()
            case .signupDiet:          SignupDietScreen()
            case .signupCookingStyle:  SignupCookingStyleScreen()
            case .signupNotes:         SignupNotesScreen()
            case .home:            HomeScreen()
            }
        }
        .background(Color.lCream.ignoresSafeArea())
    }
}
