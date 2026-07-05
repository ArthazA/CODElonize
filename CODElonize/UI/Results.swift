import SwiftUI

struct Results: View {
    let winner = "ADI"
    
    let leaderboard = [
        ("Adi", 3),
        ("Arthaz", 1),
        ("Dila", 1),
        ("Kinah", 1),
        ("Barra", 1)
    ]
    
    var body: some View {
        ZStack {
            Color.themeTeal.edgesIgnoringSafeArea(.all)
            
            VStack {
                Text("\(winner) WINS!")
                    .font(.system(size: 44, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 3)
                    .padding(.top, 60)
                    .padding(.bottom, 40)
                
                // Leaderboard list
                VStack(spacing: 0) {
                    ForEach(0..<leaderboard.count, id: \.self) { index in
                        let player = leaderboard[index]
                        
                        HStack {
                            Text(player.0)
                                .font(.system(size: 24, weight: .regular, design: .rounded))
                                .foregroundColor(.white)
                            Spacer()
                            Text("\(player.1) area")
                                .font(.system(size: 24, weight: .heavy, design: .rounded))
                                .foregroundColor(.white)
                        }
                        .padding(.vertical, 16)
                        
                        if index < leaderboard.count - 1 {
                            Divider()
                                .background(Color.white.opacity(0.5))
                        }
                    }
                }
                .padding(.horizontal, 60)
                
                Spacer()
                
                // Bottom Buttons
                VStack(spacing: 24) {
                    PrimaryButton(title: "Play again") {
                        // Play again action
                    }
                    
                    Button(action: {
                        // Back to home action
                    }) {
                        Text("Back to home")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    }
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 50)
            }
        }
    }
}

#Preview {
    Results()
}
