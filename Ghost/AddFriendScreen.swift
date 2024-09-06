import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseDatabase
import FirebaseStorage


struct AddFriendScreen: View {
    @State private var searchText: String = ""
    @State private var searchResult: User?
    @State private var selectedColor: Color

    init(selectedColor: Color) {
        _selectedColor = State(initialValue: selectedColor)
    }
    
    var body: some View {
        VStack {
            TextField("Search by username", text: $searchText)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            
            Button(action: searchForUser) {
                Text("Search")
                    .foregroundColor(.white)
                    .padding()
                    .background(selectedColor)
                    .cornerRadius(8)
            }
            
            if let user = searchResult {
                Text("User: \(user.username)")
                    .foregroundColor(.white)
                
                Button(action: { sendFriendRequest(to: user) }) {
                    Text("Send Friend Request")
                        .foregroundColor(.white)
                        .padding()
                        .background(selectedColor)
                        .cornerRadius(8)
                }
            } else {
                Text("No users found")
                    .foregroundColor(.white)
            }
        }
        .background(Color.black.ignoresSafeArea())
    }
    
    private func searchForUser() {
        let usersRef = Database.database().reference().child("users")
        usersRef.queryOrdered(byChild: "username").queryEqual(toValue: searchText).observeSingleEvent(of: .value) { snapshot in
            if snapshot.exists() {
                for child in snapshot.children {
                    if let snapshot = child as? DataSnapshot,
                       let value = snapshot.value as? [String: AnyObject],
                       let username = value["username"] as? String {
                        let user = User(uid: snapshot.key, username: username, email: value["email"] as? String ?? "")
                        searchResult = user
                        return
                    }
                }
            } else {
                searchResult = nil
            }
        }
    }
    
    private func sendFriendRequest(to user: User) {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        let friendRequestRef = Database.database().reference().child("friend_requests").child(user.uid).child(currentUserId)
        friendRequestRef.setValue(["status": "pending"])
    }
}
