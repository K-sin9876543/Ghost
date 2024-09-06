import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseDatabase
import FirebaseStorage

struct FriendsScreen: View {
    @State private var selectedColor: Color = ThemeManager().accentColor
    @State private var friends: [User] = []
    @State private var friendRequestsCount: Int = 0

    var body: some View {
        NavigationView {
            VStack {
                if friends.isEmpty {
                    Text("No Friends Found")
                        .foregroundColor(.gray)
                        .padding()
                } else {
                    List(friends) { friend in
                        NavigationLink(destination: FriendProfileScreen(friendId: friend.uid)) {
                            Text(friend.username)
                                .foregroundColor(selectedColor)
                        }
                    }
                }
            }
            .navigationBarTitle("Friends", displayMode: .inline)
            .navigationBarItems(
                leading: NavigationLink(destination: AddFriendScreen(selectedColor: selectedColor)) {
                    Image(systemName: "plus")
                        .foregroundColor(selectedColor)
                },
                trailing: NavigationLink(destination: NotificationScreen()) {
                    ZStack {
                        Image(systemName: "bell")
                            .foregroundColor(selectedColor)
                        if friendRequestsCount > 0 {
                            Text("\(friendRequestsCount)")
                                .font(.caption2)
                                .padding(5)
                                .background(Color.red)
                                .clipShape(Circle())
                                .offset(x: 10, y: -10)
                        }
                    }
                }
            )
            .onAppear {
                fetchFriends()
                fetchFriendRequestsCount()
            }
        }
    }

    private func fetchFriends() {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        let ref = Database.database().reference().child("users")

        ref.observeSingleEvent(of: .value) { snapshot in
            var fetchedFriends: [User] = []
            for child in snapshot.children {
                if let snapshot = child as? DataSnapshot,
                   let value = snapshot.value as? [String: Any],
                   let username = value["username"] as? String {
                    
                    let user = User(
                        uid: snapshot.key,
                        username: username,
                        email: value["email"] as? String ?? ""
                    )
                    fetchedFriends.append(user)
                }
            }
            self.friends = fetchedFriends
        }
    }

    private func fetchFriendRequestsCount() {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        let ref = Database.database().reference().child("friend_requests").child(currentUserId)
        
        ref.observeSingleEvent(of: .value) { snapshot in
            self.friendRequestsCount = Int(snapshot.childrenCount)
        }
    }
}


struct FriendProfileScreen_Previews: PreviewProvider {
    static var previews: some View {
        FriendProfileScreen(friendId: "exampleFriendId")
            .environmentObject(ThemeManager())
    }
}
