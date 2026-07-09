import SwiftUI

struct PreviewIsland: View {
    var body: some View {
        ZStack {

            Color.themeCream.edgesIgnoringSafeArea(.all)

            Island3DView()
                .edgesIgnoringSafeArea(.all)

            VStack {
                Spacer()

                SecondaryButton(title: "Ready") {

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
