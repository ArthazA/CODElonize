import SwiftUI

struct PreviewIsland: View {
    var body: some View {
        ZStack {
            // Background / 3D Model
            Color.themeCream.edgesIgnoringSafeArea(.all)
            
            Island3DView()
                .edgesIgnoringSafeArea(.all)
            
            // Bottom Ready Button
            VStack {
                Spacer()
                
                SecondaryButton(title: "Ready") {
                    // Ready action
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 40)
            }
        }
    }
}

#Preview {
    PreviewIsland()
}
