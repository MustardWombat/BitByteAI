import SwiftUI

struct FriendsView: View {
    var body: some View {
        VStack {
            Text("Friends")
                .font(.largeTitle)
                .bold()
                .padding()

            Text("This is where you can view and manage your friends.")
                .font(.body)
                .multilineTextAlignment(.center)
                .padding()

            Spacer()
        }
        .background(Color.black.ignoresSafeArea())
        .foregroundColor(.white)
    }
}

struct FriendsView_Previews: PreviewProvider {
    static var previews: some View {
        FriendsView()
    }
}
