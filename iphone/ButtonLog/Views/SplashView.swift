import SwiftUI

struct SplashView: View {
    var body: some View {
        ZStack {
            Color.blBackground
                .ignoresSafeArea()

            VStack(spacing: BLSpacing.lg) {
                Image(systemName: "hand.tap.fill")
                    .font(.system(size: 64))
                    .foregroundColor(.blPrimary)

                Text("ButtonLog")
                    .font(BLTypography.displaySmall)
                    .foregroundColor(.blTextPrimary)

                ProgressView()
                    .tint(.blPrimary)
                    .padding(.top, BLSpacing.lg)
            }
        }
    }
}

#Preview {
    SplashView()
}
