import SwiftUI

// MARK: - StrengthX Design System
// Minimalistic, dark-first color palette optimized for gym use

extension Color {
    // MARK: - Primary Palette
    static let sxBackground = Color(red: 0.06, green: 0.06, blue: 0.08)
    static let sxSurface = Color(red: 0.11, green: 0.11, blue: 0.14)
    static let sxSurfaceElevated = Color(red: 0.16, green: 0.16, blue: 0.19)

    // MARK: - Accent Colors
    static let sxAccent = Color(red: 0.35, green: 0.68, blue: 1.0)       // Electric blue
    static let sxAccentSecondary = Color(red: 0.55, green: 0.36, blue: 1.0) // Purple
    static let sxSuccess = Color(red: 0.30, green: 0.85, blue: 0.55)     // Green
    static let sxWarning = Color(red: 1.0, green: 0.76, blue: 0.28)      // Amber
    static let sxDanger = Color(red: 1.0, green: 0.35, blue: 0.35)       // Red

    // MARK: - Text Colors
    static let sxTextPrimary = Color.white
    static let sxTextSecondary = Color(white: 0.6)
    static let sxTextTertiary = Color(white: 0.4)

    // MARK: - Muscle Group Colors
    static let sxChest = Color(red: 1.0, green: 0.42, blue: 0.42)
    static let sxBack = Color(red: 0.35, green: 0.68, blue: 1.0)
    static let sxLegs = Color(red: 0.55, green: 0.36, blue: 1.0)
    static let sxShoulders = Color(red: 1.0, green: 0.76, blue: 0.28)
    static let sxArms = Color(red: 0.30, green: 0.85, blue: 0.55)
    static let sxCore = Color(red: 1.0, green: 0.55, blue: 0.35)

    // MARK: - Gradient
    static var sxGradient: LinearGradient {
        LinearGradient(
            colors: [sxAccent, sxAccentSecondary],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// MARK: - Typography
struct SXFont {
    static func heavy(_ size: CGFloat) -> Font {
        .system(size: size, weight: .heavy, design: .rounded)
    }

    static func bold(_ size: CGFloat) -> Font {
        .system(size: size, weight: .bold, design: .rounded)
    }

    static func semibold(_ size: CGFloat) -> Font {
        .system(size: size, weight: .semibold, design: .rounded)
    }

    static func medium(_ size: CGFloat) -> Font {
        .system(size: size, weight: .medium, design: .rounded)
    }

    static func regular(_ size: CGFloat) -> Font {
        .system(size: size, weight: .regular, design: .rounded)
    }

    // Preset sizes
    static let title = heavy(28)
    static let heading = bold(22)
    static let subheading = semibold(18)
    static let body = medium(16)
    static let caption = regular(14)
    static let small = regular(12)
    static let metric = heavy(36)
}

// MARK: - View Modifiers
struct SXCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(16)
            .background(Color.sxSurface)
            .cornerRadius(16)
    }
}

struct SXPrimaryButtonStyle: ButtonStyle {
    var isEnabled: Bool = true

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(SXFont.semibold(16))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                isEnabled
                    ? Color.sxGradient
                    : LinearGradient(colors: [Color.sxTextTertiary], startPoint: .leading, endPoint: .trailing)
            )
            .cornerRadius(14)
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

struct SXSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(SXFont.semibold(16))
            .foregroundColor(.sxAccent)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.sxAccent.opacity(0.12))
            .cornerRadius(14)
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

extension View {
    func sxCard() -> some View {
        modifier(SXCardModifier())
    }
}

// MARK: - Haptics
struct SXHaptics {
    static func light() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    static func medium() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    static func heavy() {
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
    }

    static func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    static func selection() {
        UISelectionFeedbackGenerator().selectionChanged()
    }
}
