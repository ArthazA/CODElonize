import SwiftUI

struct Home: View {
    @EnvironmentObject var appState: AppState
    @State private var roomCode = ["", "", "", ""] // Placeholder for the inputs
    
    var body: some View {
        ZStack {
            Color.themeTeal.edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 24) {
                // Title
                VStack(spacing: 8) {
                    HStack(spacing: 0) {
                        Text("CODE-")
                            .foregroundColor(.white)
                        Text("LONIZED")
                            .foregroundColor(Color.themeOrange)
                    }
                    .font(.system(size: 44, weight: .heavy, design: .rounded))
                    .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 4)
                    
                    Text("Answer fast & Conquer the Island!")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }
                .padding(.top, 40)
                
                // 3D Island
                Island3DView()
                    .frame(height: 280)
                
                Spacer()
                
                // Bottom Controls
                VStack(spacing: 20) {
                    PrimaryButton(title: "Host Game") {
                        appState.isHost = true
                        appState.navigate(to: .lobby)
                    }
                    
                    // Divider
                    HStack {
                        Rectangle()
                            .fill(Color.white.opacity(0.5))
                            .frame(height: 1)
                        Text("or enter room code")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                            .padding(.horizontal, 10)
                            .fixedSize()
                            .layoutPriority(1)
                        Rectangle()
                            .fill(Color.white.opacity(0.5))
                            .frame(height: 1)
                    }
                    
                    // Code Input Boxes
                    HStack(spacing: 12) {
                        ForEach(0..<4, id: \.self) { index in
                            RoomCodeBox(character: roomCode[index])
                        }
                    }
                    
                    // Loading State
                    HStack(spacing: 8) {
                        Text("will enter the lobby")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    }
                    
                    Button(action: {
                        // How to play action
                    }) {
                        Text("How to play?")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(Color.themeOrange)
                            .underline()
                    }
                    .padding(.top, 10)
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 20)
            }
        }
    }
}

#Preview {
    Home()
        .environmentObject(AppState())
}
