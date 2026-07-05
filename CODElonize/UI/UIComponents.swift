import SwiftUI

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
    let name: String
    let isReady: Bool
    let isHost: Bool
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack(alignment: .bottomTrailing) {
                Circle()
                    .fill(Color.themeOrange)
                    .frame(width: 80, height: 80)
                    .overlay(
                        Circle()
                            .stroke(Color.themeTeal, lineWidth: 4)
                            .padding(-4)
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
            PlayerAvatar(name: "Adi", isReady: true, isHost: true)
            PlayerAvatar(name: "Arthaz", isReady: false, isHost: false)
        }
    }
    .padding()
    .background(Color.themeCream)
}
