import SwiftUI

struct UpgradePromptView: View {
    let upgradeInfo: UpgradeInfo
    let onUpgrade: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            // Icon
            Image(systemName: "crown.fill")
                .font(.system(size: 48))
                .foregroundColor(.yellow)
                .padding(.top, 20)

            // Title
            Text("Upgrade Required")
                .font(.title2)
                .fontWeight(.bold)

            // Message
            Text(upgradeInfo.message)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            // Usage info (if available)
            if let usage = upgradeInfo.currentUsage, let limit = upgradeInfo.limit {
                HStack {
                    Text("Current usage:")
                    Spacer()
                    Text("\(usage) / \(limit)")
                        .fontWeight(.semibold)
                }
                .padding(.horizontal, 32)
                .padding(.vertical, 8)
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(8)
                .padding(.horizontal)
            }

            // Upgrade benefit
            VStack(alignment: .leading, spacing: 8) {
                Label {
                    Text(upgradeInfo.upgradeBenefit)
                        .font(.subheadline)
                } icon: {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                }
            }
            .padding(.horizontal)

            Spacer()

            // Buttons
            VStack(spacing: 12) {
                SwiftUI.Button(action: onUpgrade) {
                    HStack {
                        Image(systemName: "arrow.up.circle.fill")
                        Text("Upgrade to \(upgradeInfo.recommendedPlan.capitalized)")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blPrimary)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }

                SwiftUI.Button(action: onDismiss) {
                    Text("Maybe Later")
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 20)
        }
        .background(Color(.systemBackground))
    }
}

struct UpgradePromptModifier: ViewModifier {
    @Binding var upgradeInfo: UpgradeInfo?
    let onUpgrade: () -> Void

    func body(content: Content) -> some View {
        content
            .sheet(item: $upgradeInfo) { info in
                UpgradePromptView(
                    upgradeInfo: info,
                    onUpgrade: {
                        upgradeInfo = nil
                        onUpgrade()
                    },
                    onDismiss: {
                        upgradeInfo = nil
                    }
                )
                .presentationDetents([.medium])
            }
    }
}

extension UpgradeInfo: Identifiable {
    var id: String { "\(reason)-\(recommendedPlan)" }
}

extension View {
    func upgradePrompt(upgradeInfo: Binding<UpgradeInfo?>, onUpgrade: @escaping () -> Void) -> some View {
        modifier(UpgradePromptModifier(upgradeInfo: upgradeInfo, onUpgrade: onUpgrade))
    }
}

#Preview {
    UpgradePromptView(
        upgradeInfo: UpgradeInfo(
            reason: "limit_reached",
            currentPlan: "Free",
            currentUsage: 5,
            limit: 5,
            recommendedPlan: "premium",
            upgradeBenefit: "Upgrade to Premium for up to 50 buttons, or Enterprise for unlimited buttons.",
            message: "You've reached the maximum of 5 buttons on the Free plan."
        ),
        onUpgrade: {},
        onDismiss: {}
    )
}
