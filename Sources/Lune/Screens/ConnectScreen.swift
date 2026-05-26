import SwiftUI

struct ConnectScreen: View {
    @EnvironmentObject var appState: AppState
    @State private var mode: ConnectMode = .choose
    @State private var manualLength: Int = 28
    @State private var manualRefDate: Date = Calendar.current.date(byAdding: .day, value: -14, to: Date()) ?? Date()

    enum ConnectMode { case choose, manual }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color.lCream.ignoresSafeArea()

            MoonView(
                phase: 0.62,
                size: 280,
                litColor: Color(hex: "faf5ec"),
                darkColor: Color(hex: "ece3d6"),
                showCraters: false,
                showGlow: true
            )
            .opacity(0.7)
            .offset(x: 60, y: -20)
            .allowsHitTesting(false)

            VStack(alignment: .leading, spacing: 0) {
                Spacer()

                Eyebrow("Ona · Cycle Nutrition")
                Spacer().frame(height: 14)

                VStack(alignment: .leading, spacing: 0) {
                    Text("Eat with the")
                        .font(LFont.display(44))
                    Text("rhythm of your body.")
                        .font(LFont.display(44, italic: true))
                }
                .tracking(-0.4)
                .foregroundColor(.lInk)

                Spacer().frame(height: 18)

                BodyText(text: "Ona learns your cycle and gently shapes each day's food around it.",
                         size: 15.5)
                    .frame(maxWidth: 300, alignment: .leading)

                Spacer().frame(height: 28)

                if mode == .choose {
                    chooseView
                } else {
                    manualEntryView
                }
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 40)
        }
    }

    // MARK: - Choose path
    var chooseView: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(LinearGradient(
                            colors: [Color(hex: "ff5e6e"), Color(hex: "ff2d55")],
                            startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 44, height: 44)
                    Image(systemName: "heart.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Apple Health")
                        .font(LFont.body(14.5, weight: .medium))
                        .foregroundColor(.lInk)
                    Text("Cycle tracking · read only")
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
                    .padding(.top, 4)
            }

            Spacer().frame(height: 4)

            Button {
                withAnimation(.easeInOut(duration: 0.2)) { mode = .manual }
            } label: {
                Text("Enter my cycle manually")
                    .font(LFont.body(13.5))
                    .foregroundColor(.lPlum)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(Color.lPaper)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.lRule, lineWidth: 1))
            }
        }
    }

    // MARK: - Manual entry
    var manualEntryView: some View {
        VStack(alignment: .leading, spacing: 0) {
            Eyebrow("Your cycle")
            Spacer().frame(height: 16)

            VStack(alignment: .leading, spacing: 8) {
                Text("Average cycle length")
                    .font(LFont.body(13.5))
                    .foregroundColor(.lInk)

                HStack {
                    Button {
                        if manualLength > 21 { manualLength -= 1 }
                    } label: {
                        Image(systemName: "minus")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.lInk)
                            .frame(width: 36, height: 36)
                            .background(Color.lCream)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.lRule, lineWidth: 1))
                    }

                    Text("\(manualLength) days")
                        .font(LFont.display(20))
                        .foregroundColor(.lInk)
                        .frame(minWidth: 90, alignment: .center)

                    Button {
                        if manualLength < 40 { manualLength += 1 }
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.lInk)
                            .frame(width: 36, height: 36)
                            .background(Color.lCream)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.lRule, lineWidth: 1))
                    }

                    Spacer()
                }
            }
            .padding(18)
            .background(Color.lPaper)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(Color.lRule, lineWidth: 1))

            Spacer().frame(height: 12)

            VStack(alignment: .leading, spacing: 8) {
                Text("First day of your most recent period")
                    .font(LFont.body(13.5))
                    .foregroundColor(.lInk)

                DatePicker("", selection: $manualRefDate, in: ...Date(), displayedComponents: .date)
                    .datePickerStyle(.compact)
                    .labelsHidden()
                    .tint(Color.lPlum)
            }
            .padding(18)
            .background(Color.lPaper)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(Color.lRule, lineWidth: 1))

            Spacer().frame(height: 8)
            Text("Ona will use this to estimate where you are in your cycle. You can update it any time in Settings.")
                .font(LFont.body(11.5))
                .foregroundColor(.lInk3)
                .lineSpacing(2)

            Spacer().frame(height: 20)

            PillButton(label: "Continue") {
                appState.setManualCycle(referenceDate: manualRefDate, length: manualLength)
            }

            Spacer().frame(height: 10)

            Button {
                withAnimation(.easeInOut(duration: 0.2)) { mode = .choose }
            } label: {
                Text("← back")
                    .font(LFont.body(13))
                    .foregroundColor(.lInk3)
                    .frame(maxWidth: .infinity)
                    .padding(10)
            }
        }
        .transition(.opacity.combined(with: .move(edge: .trailing)))
    }
}
