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
        
        // Fetch friends for the current user
        let friendsRef = Database.database().reference().child("friends").child(currentUserId)
        
        friendsRef.observeSingleEvent(of: .value) { snapshot in
            var fetchedFriends: [User] = []
            
            for child in snapshot.children {
                if let friendSnapshot = child as? DataSnapshot {
                    let friendId = friendSnapshot.key
                    
                    // Fetch friend's details from users node
                    let userRef = Database.database().reference().child("users").child(friendId)
                    userRef.observeSingleEvent(of: .value) { userSnapshot in
                        if let value = userSnapshot.value as? [String: Any],
                           let username = value["username"] as? String,
                           let email = value["email"] as? String {
                            
                            let friend = User(
                                uid: friendId,
                                username: username,
                                email: email
                            )
                            fetchedFriends.append(friend)
                            
                            // Update the friends list on the UI
                            self.friends = fetchedFriends
                        }
                    }
                }
            }
            
            // If no friends were found
            if fetchedFriends.isEmpty {
                self.friends = []
            }
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
import SwiftUI
import Firebase

import SwiftUI
import Firebase
import FirebaseAuth

struct AddFriendScreen: View {
    @State private var searchText: String = ""
    @State private var searchResults: [User] = []
    @State private var selectedColor: Color
    @State private var showNoResultsMessage = false
    @State private var currentUserId: String = ""
    @State private var friendsList: [String] = []  // Stores friend IDs
    @State private var friendRequestStatus: [String: Bool] = [:]  // Stores the friend request status for each user
    
    init(selectedColor: Color) {
        _selectedColor = State(initialValue: selectedColor)
    }
    
    var body: some View {
        VStack {
            // Custom Search Bar
            HStack {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    TextField("Search by username", text: $searchText)
                        .foregroundColor(.primary)
                        .onChange(of: searchText) { newValue in
                            if !newValue.isEmpty {
                                searchForUsers(with: newValue)
                            } else {
                                searchResults = []
                            }
                        }
                    
                    // Clear Button
                    if !searchText.isEmpty {
                        Button(action: {
                            searchText = ""
                            searchResults = []
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(.systemGray6))
                        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                )
            }
            .padding(.horizontal)
            .padding(.top)
            
            if searchResults.isEmpty && showNoResultsMessage {
                Spacer()
                Text("No users found")
                    .foregroundColor(selectedColor)
                    .font(.headline)
                Spacer()
            } else {
                // Search Results List
                ScrollView {
                    LazyVStack(spacing: 15) {
                        ForEach(searchResults) { user in
                            VStack(alignment: .leading, spacing: 8) {
                                Text(user.username)
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                // Check if the request is already sent
                                let isRequestSent = friendRequestStatus[user.uid] ?? false
                                
                                if isRequestSent {
                                    // Show "Request Sent" if the request was already sent
                                    Text("Request Sent")
                                        .font(.subheadline)
                                        .bold()
                                        .foregroundColor(.gray)
                                        .padding(.vertical, 10)
                                        .frame(maxWidth: .infinity)
                                        .background(Color.gray.opacity(0.3))
                                        .cornerRadius(10)
                                } else {
                                    Button(action: { sendFriendRequest(to: user) }) {
                                        Text("Send Friend Request")
                                            .font(.subheadline)
                                            .bold()
                                            .foregroundColor(.white)
                                            .padding(.vertical, 10)
                                            .frame(maxWidth: .infinity)
                                            .background(selectedColor)
                                            .cornerRadius(10)
                                    }
                                }
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 15)
                                    .fill(Color(.systemGray6))
                                    .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                            )
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
        .background(Color(.systemBackground).ignoresSafeArea())
        .navigationBarTitle("Add Friend", displayMode: .inline)
        .onAppear {
            // Get current user ID and load the friends list when the view appears
            loadCurrentUserIdAndFriends()
            loadFriendRequestsStatus() // Check the status of all friend requests
        }
    }
    
    // Fetches current user's ID and list of their friends
    private func loadCurrentUserIdAndFriends() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        self.currentUserId = userId
        
        // Fetch the current user's friends
        let friendsRef = Database.database().reference().child("friends").child(currentUserId)
        friendsRef.observeSingleEvent(of: .value) { snapshot in
            var fetchedFriends: [String] = []
            for child in snapshot.children {
                if let friendSnapshot = child as? DataSnapshot {
                    fetchedFriends.append(friendSnapshot.key)
                }
            }
            self.friendsList = fetchedFriends
        }
    }
    
    // Load friend requests status
    private func loadFriendRequestsStatus() {
        // Fetch all friend requests for the current user
        let friendRequestsRef = Database.database().reference().child("friend_requests").child(currentUserId)
        
        friendRequestsRef.observeSingleEvent(of: .value) { snapshot in
            var requestsStatus: [String: Bool] = [:]
            
            for child in snapshot.children {
                if let requestSnapshot = child as? DataSnapshot {
                    let senderId = requestSnapshot.key
                    let status = requestSnapshot.childSnapshot(forPath: "status").value as? String
                    if status == "pending" {
                        requestsStatus[senderId] = true
                    } else {
                        requestsStatus[senderId] = false
                    }
                }
            }
            
            self.friendRequestStatus = requestsStatus
        }
    }
    
    // Smart search with filtering to exclude self and current friends
    private func searchForUsers(with query: String) {
        let usersRef = Database.database().reference().child("users")
        usersRef.queryOrdered(byChild: "username")
            .queryStarting(atValue: query)
            .queryEnding(atValue: query + "\u{f8ff}")
            .observeSingleEvent(of: .value) { snapshot in
                var fetchedUsers: [User] = []
                for child in snapshot.children {
                    if let snapshot = child as? DataSnapshot,
                       let value = snapshot.value as? [String: AnyObject],
                       let username = value["username"] as? String,
                       let email = value["email"] as? String {
                        
                        let userId = snapshot.key
                        
                        // Filter out the current user and already friends
                        if userId != currentUserId && !friendsList.contains(userId) {
                            let user = User(uid: userId, username: username, email: email)
                            fetchedUsers.append(user)
                        }
                    }
                }
                
                // Update search results
                searchResults = fetchedUsers
                showNoResultsMessage = fetchedUsers.isEmpty
            }
    }
    
    // Send friend request to a user
    private func sendFriendRequest(to user: User) {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        // Ensure the correct path under friend_requests: /friend_requests/{recipientId}/{senderId}
        let friendRequestRef = Database.database().reference().child("friend_requests").child(user.uid).child(currentUserId)
        
        // Set the value for the friend request (status: "pending")
        friendRequestRef.setValue(["status": "pending"]) { error, _ in
            if let error = error {
                print("Error sending friend request: \(error.localizedDescription)")
            } else {
                print("Friend request sent successfully.")
                // Update the UI state to show "Request Sent"
                friendRequestStatus[user.uid] = true
            }
        }
    }
}
import Firebase

struct FriendProfileScreen_Previews: PreviewProvider {
    static var previews: some View {
        FriendProfileScreen(friendId: "exampleFriendId")
            .environmentObject(ThemeManager())
    }
}
