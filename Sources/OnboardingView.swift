import SwiftUI

struct OnboardingView: View {
    @ObservedObject var viewModel: BypassViewModel
    @Binding var isComplete: Bool
    @State private var currentStep = 0
    @State private var animateContent = false
    @State private var selectedMode: String = "app"
    @State private var licenseKey = ""
    @State private var isActivating = false
    @State private var activationError: String?

    private let steps = [
        OnboardingStep(
            icon: "shield.checkered",
            title: "Welcome to SpoofTrap",
            subtitle: "The smart Roblox bypass launcher",
            description: "SpoofTrap routes your Roblox traffic through a local bypass to avoid network restrictions — no VPN required."
        ),
        OnboardingStep(
            icon: "network",
            title: "Choose Your Mode",
            subtitle: "How do you want to connect?",
            description: "We recommend \"App\" mode — it proxies only Roblox traffic without touching your system settings."
        ),
        OnboardingStep(
            icon: "bolt.shield",
            title: "FastFlags & Mods",
            subtitle: "Customize your experience",
            description: "Enable FastFlags for FPS boost, lower ping, and visual tweaks. Use Mods to replace sounds, cursors, and more."
        ),
        OnboardingStep(
            icon: "star.circle",
            title: "Free vs Pro",
            subtitle: "Unlock the full experience",
            description: "SpoofTrap works great for free. Pro unlocks advanced FastFlags editing, custom mod uploads, ping optimizer, and more."
        ),
        OnboardingStep(
            icon: "checkmark.circle",
            title: "You're All Set!",
            subtitle: "Ready to launch",
            description: "Hit Start to begin your session. SpoofTrap will handle the rest."
        )
    ]

    var body: some View {
        ZStack {
            Color(red: 0.04, green: 0.07, blue: 0.14)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                stepContent
                    .frame(maxWidth: 500)
                    .opacity(animateContent ? 1 : 0)
                    .offset(y: animateContent ? 0 : 20)

                Spacer()

                bottomControls
                    .padding(.bottom, 40)
            }
            .padding(.horizontal, 40)
        }
    }

    @ViewBuilder
    private var stepContent: some View {
        let step = steps[currentStep]

        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.cyan.opacity(0.2), Color.clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: 60
                        )
                    )
                    .frame(width: 120, height: 120)

                Image(systemName: step.icon)
                    .font(.system(size: 48, weight: .light))
                    .foregroundStyle(
                        LinearGradient(colors: [.cyan, .blue], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
            }

            VStack(spacing: 8) {
                Text(step.title)
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)

                Text(step.subtitle)
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundStyle(.cyan.opacity(0.8))
                    .multilineTextAlignment(.center)
            }

            Text(step.description)
                .font(.system(size: 14, weight: .regular, design: .rounded))
                .foregroundStyle(.white.opacity(0.6))
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)

            if currentStep == 1 {
                modeSelector
            }

            if currentStep == 3 {
                licenseEntry
            }
        }
    }

    private var modeSelector: some View {
        VStack(spacing: 10) {
            modeOption(
                id: "app",
                icon: "app.badge.checkmark",
                title: "App Mode",
                subtitle: "Recommended — proxies only Roblox",
                selected: selectedMode == "app"
            )
            modeOption(
                id: "system",
                icon: "network.badge.shield.half.filled",
                title: "System Proxy",
                subtitle: "Routes all traffic — use if App mode doesn't work",
                selected: selectedMode == "system"
            )
        }
        .padding(.top, 8)
    }

    private func modeOption(id: String, icon: String, title: String, subtitle: String, selected: Bool) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) { selectedMode = id }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundStyle(selected ? .cyan : .white.opacity(0.4))
                    .frame(width: 28)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                    Text(subtitle)
                        .font(.system(size: 11, weight: .regular, design: .rounded))
                        .foregroundStyle(.white.opacity(0.5))
                }

                Spacer()

                Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 18))
                    .foregroundStyle(selected ? .cyan : .white.opacity(0.2))
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(selected ? Color.cyan.opacity(0.08) : Color.white.opacity(0.04))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(selected ? Color.cyan.opacity(0.3) : Color.white.opacity(0.08), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }

    private var licenseEntry: some View {
        VStack(spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "key.fill")
                    .font(.system(size: 13))
                    .foregroundStyle(.white.opacity(0.4))

                TextField("License key (optional)", text: $licenseKey)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13, weight: .medium, design: .monospaced))
                    .foregroundStyle(.white)

                if isActivating {
                    ProgressView()
                        .scaleEffect(0.6)
                        .tint(.cyan)
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.white.opacity(0.06))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
            )

            if let error = activationError {
                Text(error)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(.red.opacity(0.8))
            }

            if !licenseKey.isEmpty {
                Button {
                    activateLicense()
                } label: {
                    Text("Activate Pro")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(
                                    LinearGradient(colors: [.yellow.opacity(0.6), .orange.opacity(0.6)], startPoint: .leading, endPoint: .trailing)
                                )
                        )
                }
                .buttonStyle(.plain)
                .disabled(isActivating)
            }

            Text("You can always activate later in Settings")
                .font(.system(size: 11, weight: .regular, design: .rounded))
                .foregroundStyle(.white.opacity(0.35))
        }
        .padding(.top, 4)
    }

    private var bottomControls: some View {
        VStack(spacing: 16) {
            HStack(spacing: 6) {
                ForEach(0..<steps.count, id: \.self) { i in
                    Capsule()
                        .fill(i == currentStep ? Color.cyan : Color.white.opacity(0.2))
                        .frame(width: i == currentStep ? 24 : 8, height: 4)
                        .animation(.easeInOut(duration: 0.3), value: currentStep)
                }
            }

            HStack(spacing: 16) {
                if currentStep > 0 {
                    Button {
                        goBack()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 11, weight: .bold))
                            Text("Back")
                                .font(.system(size: 13, weight: .medium, design: .rounded))
                        }
                        .foregroundStyle(.white.opacity(0.5))
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                    }
                    .buttonStyle(.plain)
                }

                Spacer()

                if currentStep == 0 {
                    Button {
                        finishOnboarding()
                    } label: {
                        Text("Skip")
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundStyle(.white.opacity(0.4))
                    }
                    .buttonStyle(.plain)
                }

                Button {
                    if currentStep == steps.count - 1 {
                        finishOnboarding()
                    } else {
                        goForward()
                    }
                } label: {
                    HStack(spacing: 6) {
                        Text(currentStep == steps.count - 1 ? "Get Started" : "Continue")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                        if currentStep < steps.count - 1 {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 11, weight: .bold))
                        }
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 28)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [Color.cyan.opacity(0.5), Color.blue.opacity(0.4)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func goForward() {
        if currentStep == 1 {
            viewModel.setProxyScope(selectedMode == "system" ? .system : .app)
        }

        withAnimation(.easeOut(duration: 0.15)) { animateContent = false }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            currentStep = min(currentStep + 1, steps.count - 1)
            withAnimation(.easeOut(duration: 0.3)) { animateContent = true }
        }
    }

    private func goBack() {
        withAnimation(.easeOut(duration: 0.15)) { animateContent = false }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            currentStep = max(currentStep - 1, 0)
            withAnimation(.easeOut(duration: 0.3)) { animateContent = true }
        }
    }

    private func finishOnboarding() {
        UserDefaults.standard.set(true, forKey: "SpoofTrap.onboardingComplete")
        withAnimation(.easeOut(duration: 0.4)) { isComplete = true }
    }

    private func activateLicense() {
        guard !licenseKey.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        isActivating = true
        activationError = nil

        Task {
            let result = await viewModel.proManager.activate(key: licenseKey.trimmingCharacters(in: .whitespaces))
            await MainActor.run {
                isActivating = false
                if result {
                    activationError = nil
                    licenseKey = ""
                } else {
                    activationError = "Invalid or expired license key"
                }
            }
        }
    }
}

private struct OnboardingStep {
    let icon: String
    let title: String
    let subtitle: String
    let description: String
}
