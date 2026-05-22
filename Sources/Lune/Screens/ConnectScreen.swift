import SwiftUI

struct ConnectScreen: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color.lCream.ignoresSafeArea()

            // Decorative ambient moon — anchored top-right, partially clipped
            MoonView(
                phase: 0.62,
                size: 280,
                litColor: Color(hex: "faf5ec"),    // paper
                darkColor: Color(hex: "ece3d6"),   // cream2
                showCraters: false,
                showGlow: true
            )
            .opacity(0.7)
            .offset(x: 60, y: -20)
            .allowsHitTesting(false)

            VStack(alignment: .leading, spacing: 0) {
                Spacer()

                Eyebrow("Lune · Cycle Nutrition")

                Spacer().frame(height: 14)

                // Display headline with italic second line
                VStack(alignment: .leading, spacing: 0) {
                    Text("Eat with the")
                        .font(LFont.display(44))
                    Text("rhythm of your body.")
                        .font(LFont.display(44, italic: true))
                }
                .tracking(-0.4)
                .foregroundColor(.lInk)

                Spacer().frame(height: 18)

                BodyText(text: "Lune learns your cycle from Apple Health and gently shapes each day's food around it.",
                         size: 15.5)
                    .frame(maxWidth: 300, alignment: .leading)

                Spacer().frame(height: 28)

                // HealthKit card
                HStack(spacing: 14) {
                    // Apple Health heart icon
                    ZStack {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [Color(hex: "ff5e6e"), Color(hex: "ff2d55")],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 44, height: 44)
                        Image(systemName: "heart.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Apple Health")
                            .font(LFont.body(14.5, weight: .medium))
                            .foregroundColor(.lInk)
                        Text("Cycle tracking · symptoms · sleep")
                            .font(LFont.body(12.5))
                            .foregroundColor(.lInk3)
                    }

                    Spacer()

                    Text("READ ONLY")
                        .font(LFont.mono(10))
                        .tracking(1.2)
                        .foregroundColor(.lSageDeep)
                }
                .padding(18)
                .cardStyle()

                Spacer().frame(height: 16)

                if appState.healthKitLoading {
                    HStack(spacing: 10) {
                        SpinnerView()
                        Text("Connecting to Apple Health…")
                            .font(LFont.body(14))
                            .foregroundColor(.lInk2)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                } else {
                    PillButton(label: "Connect Apple Health") {
                        Task { await appState.connectHealthKit() }
                    }
                }

                if let err = appState.healthKitError {
                    Text(err)
                        .font(LFont.body(12.5))
                        .foregroundColor(.lRed)
                        .multilineTextAlignment(.center)
                        .padding(.top, 8)
                }

                Spacer().frame(height: 10)

                Button {
                    appState.advance()
                } label: {
                    Text("I'll set it up later")
                        .font(LFont.body(13.5))
                        .foregroundColor(.lInk3)
                        .frame(maxWidth: .infinity)
                        .padding(12)
                }
            }
            .padding(.horizontal, 28)
            .padding(.bottom, 40)
        }
    }
}
