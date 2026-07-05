import SwiftUI

struct GameScreen: View {
    var body: some View {
        ZStack {
            // Background / 3D Model
            Color.themeCream.edgesIgnoringSafeArea(.all)
            
            Island3DView()
                .edgesIgnoringSafeArea(.all)
            
            // Map Pins Overlay (Mockup pins)
            ZStack {
                MapPin(iconName: "mappin.circle.fill")
                    .offset(x: -80, y: 150)
                
                MapPin(iconName: "mappin.circle.fill")
                    .offset(x: 10, y: -50)
                
                MapPin(iconName: "mappin.circle.fill")
                    .offset(x: 120, y: -20)
                
                MapPin(iconName: "mappin.circle.fill")
                    .offset(x: 80, y: 100)
            }
            
            // HUD Overlay
            HUD()
        }
    }
}

struct MapPin: View {
    let iconName: String
    
    var body: some View {
        Image(systemName: iconName)
            .resizable()
            .frame(width: 32, height: 32)
            .foregroundColor(Color.themeDarkTeal)
            .background(Circle().fill(Color.white).frame(width: 24, height: 24))
            .shadow(radius: 3, y: 3)
    }
}

#Preview {
    GameScreen()
}
