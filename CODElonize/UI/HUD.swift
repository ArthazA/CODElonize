import SwiftUI

struct HUD: View {
    let players = [
        ("Adi", 3),
        ("Arthaz", 1),
        ("Dila", 1),
        ("Kinah", 1),
        ("Barra", 1)
    ]
    
    var body: some View {
        VStack {
            HStack(alignment: .top) {
                // Top Left: Leaderboard
                VStack(alignment: .leading, spacing: 8) {
                    Text("Area Conquer")
                        .font(.system(size: 16, weight: .heavy, design: .rounded))
                        .foregroundColor(Color.themeOrange)
                        .padding(.bottom, 4)
                    
                    ForEach(0..<players.count, id: \.self) { index in
                        let player = players[index]
                        HStack {
                            Text(player.0)
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                                .foregroundColor(.white)
                            Spacer()
                            Text("\(player.1) area")
                                .font(.system(size: 14, weight: .heavy, design: .rounded))
                                .foregroundColor(.white)
                        }
                        if index < players.count - 1 {
                            Divider().background(Color.white.opacity(0.5))
                        }
                    }
                }
                .padding(16)
                .frame(width: 150)
                .background(Color.themeDarkTeal.opacity(0.9))
                .cornerRadius(12, corners: [.bottomRight])
                .edgesIgnoringSafeArea(.top)
                
                Spacer()
                
                // Top Right: Timer
                Text("05:00")
                    .font(.system(size: 36, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.top, 50)
                    .padding(.trailing, 20)
                    // Simple outline effect using shadows
                    .shadow(color: Color.themeOrange, radius: 1, x: 2, y: 2)
                    .shadow(color: Color.themeOrange, radius: 1, x: -2, y: -2)
                    .shadow(color: Color.themeOrange, radius: 1, x: 2, y: -2)
                    .shadow(color: Color.themeOrange, radius: 1, x: -2, y: 2)
            }
            
            Spacer()
            
            // Bottom Action Bar
            HStack(spacing: 20) {
                ActionButton(iconName: "drop.fill", color: .blue)
                ActionButton(iconName: "house.fill", color: .red)
                ActionButton(iconName: "tree.fill", color: .green)
            }
            .padding(.horizontal, 30)
            .padding(.vertical, 16)
            .background(Color.themeDarkTeal.opacity(0.9))
            .cornerRadius(24)
            .padding(.bottom, 30)
        }
    }
}

// Helper view for the circular action buttons
struct ActionButton: View {
    let iconName: String
    let color: Color
    
    var body: some View {
        Circle()
            .fill(Color.themeOrange)
            .frame(width: 70, height: 70)
            .overlay(
                ZStack {
                    Circle()
                        .stroke(Color.white, lineWidth: 4)
                    
                    Image(systemName: iconName)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 30, height: 30)
                        .foregroundColor(color)
                }
            )
            .shadow(radius: 4)
    }
}


#Preview {
    ZStack {
        Color.black
        HUD()
    }
}
