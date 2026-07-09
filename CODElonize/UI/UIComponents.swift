import SwiftUI

extension Color {
    static let themePaper = Color(hex: "F3EACE")
    
    // Quick hex initializer
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

struct PrimaryButton: View {
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 20, weight: .heavy, design: .rounded))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.themeOrange)
                .cornerRadius(12)
        }
    }
}

struct SecondaryButton: View {
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 20, weight: .heavy, design: .rounded))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.themeDarkTeal)
                .cornerRadius(12)
        }
    }
}

struct RoomCodeBox: View {
    let character: String
    
    var body: some View {
        Text(character)
            .font(.system(size: 32, weight: .heavy, design: .rounded))
            .foregroundColor(Color.themeDarkTeal)
            .frame(width: 60, height: 70)
            .background(Color.white)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.themeDarkTeal, lineWidth: 3)
            )
            .cornerRadius(12)
    }
}

struct PlayerAvatar: View {
    let imageName: String
    let name: String
    let isReady: Bool
    let isHost: Bool
    let isSelf: Bool
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack(alignment: .bottomTrailing) {
                Image(imageName)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 80, height: 80)
                    .clipShape(Circle())
                    .overlay(
                        Circle().stroke(
                            isSelf ? Color.green : Color.themeDarkTeal,
                            lineWidth: isSelf ? 4 : 3
                        )
                    )
                    .overlay(
                        isReady ?
                            Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.white)
                            .background(Circle().fill(Color.green))
                            .offset(x: 25, y: 25)
                        : nil
                    )
                if isReady {
                    Image(systemName: "checkmark.circle.fill")
                        .resizable()
                        .frame(width: 24, height: 24)
                        .foregroundColor(.white)
                        .background(Circle().fill(Color.themeTeal))
                        .offset(x: 4, y: 4)
                }
            }
            
            Text(isHost ? "\(name) (Host)" : name)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(Color.themeDarkTeal)
            
            Text(isReady ? "Ready" : "Waiting")
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(Color.themeTeal)
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        PrimaryButton(title: "Primary Button") {}
        SecondaryButton(title: "Secondary Button") {}
        HStack {
            RoomCodeBox(character: "5")
            RoomCodeBox(character: "A")
        }
        HStack(spacing: 30) {
            PlayerAvatar(
                imageName: "player_1",
                name: "Adi",
                isReady: true,
                isHost: true,
                isSelf: true
            )

            PlayerAvatar(
                imageName: "player_2",
                name: "Arthaz",
                isReady: false,
                isHost: false,
                isSelf: false
            )
        }
    }
    .padding()
    .background(Color.themeCream)
}
