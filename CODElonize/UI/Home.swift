import SwiftUI

struct Home: View {
    @EnvironmentObject var appState: AppState
    @State private var roomCode = ""
    @FocusState private var isRoomCodeFocused: Bool
    @State private var isJoining = false
    
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
                    .frame(height: isRoomCodeFocused ? 100 : 280)
                    .animation(.easeInOut(duration: 0.3), value: isRoomCodeFocused)
                
                Spacer()
                ScrollView(showsIndicators: false) {
                    // Bottom Controls
                    VStack(spacing: 20) {
                        PrimaryButton(title: "Host Game") {
                            appState.isHost = true
                            appState.lobbyManager.createLobby(
                                hostID: appState.playerID,
                                hostName: appState.playerName
                            )
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
                        VStack {
                            
                            HStack(spacing: 12) {
                                
                                ForEach(0..<4, id: \.self) { index in
                                    
                                    ZStack {
                                        
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(.white)
                                            .frame(width: 55, height: 60)
                                        
                                        Text(character(at: index))
                                            .font(.system(size: 28, weight: .bold))
                                            .foregroundColor(.black)
                                        
                                    }
                                    
                                }
                                
                            }
                            
                            // Hidden TextField
                            TextField("", text: $roomCode)
                                .keyboardType(.numberPad)
                                .textContentType(.oneTimeCode)
                                .focused($isRoomCodeFocused)
                                .opacity(0.01)
                                .frame(width: 1, height: 1)
                                .onChange(of: roomCode) { _, newValue in
                                    
                                    roomCode = newValue.filter(\.isNumber)
                                    
                                    if roomCode.count > 4 {
                                        roomCode = String(roomCode.prefix(4))
                                    }
                                    
                                    if roomCode.count == 4 {
                                        
                                        isRoomCodeFocused = false
                                        isJoining = true
                                        
                                        joinLobby(roomCode)
                                        
                                    }
                                }
                            
                        }
                        .onTapGesture {
                            isRoomCodeFocused = true
                        }
                        
                        //Loading State
                        if isJoining {
                            HStack(spacing: 8) {
                                Text("Joining lobby...")
                                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                                    .foregroundColor(.white)
                                
                                ProgressView()
                                    .progressViewStyle(.circular)
                                    .tint(.white)
                            }
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
        .contentShape(Rectangle())
        .onTapGesture {
            isRoomCodeFocused = false
        }
        .onAppear {
            if appState.playerName.isEmpty {
                appState.playerName = Self.randomFruitName()
            }
            appState.lobbyManager.clientManager.browseHosts()
        }
        .onChange(of: appState.lobbyManager.lobby?.roomCode) { _, newCode in
            if !appState.isHost, newCode != nil {
                isJoining = false
                appState.navigate(to: .lobby)
            }
        }
    }
    private func joinLobby(_ code: String) {
        print("Joining room \(code)")
        appState.lobbyManager.joinLobby(
            roomCode: code,
            playerID: appState.playerID,
            playerName: appState.playerName
        )
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            if isJoining {
                isJoining = false
            }
        }
    }

    private static func randomFruitName() -> String {
        let fruits = ["Mango", "Apple", "Orange", "Pineapple","Rambutan","Duren","Grape","Melon","Watermelon","Kiwi"]
        return fruits.randomElement()! + "\(Int.random(in: 1...99))"
    }
    private func character(at index: Int) -> String {
        guard index < roomCode.count else {
            return ""
        }
        let i = roomCode.index(roomCode.startIndex, offsetBy: index)
        return String(roomCode[i])
    }
}

#Preview {
    Home()
        .environmentObject(AppState(preview: true))
}
