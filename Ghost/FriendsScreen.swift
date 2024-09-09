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
struct AddFriendScreen: View {
    @State private var searchText: String = ""
    @State private var searchResults: [User] = []
    @State private var selectedColor: Color
    @State private var showNoResultsMessage = false
    @State private var currentUserId: String = ""
    @State private var friendsList: [String] = []  // Stores friend IDs
    
    init(selectedColor: Color) {
        _selectedColor = State(initialValue: selectedColor)
    }

    var body: some View {
        VStack {
            TextField("Search by username", text: $searchText)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
                .onChange(of: searchText) { newValue in
                    if !newValue.isEmpty {
                        searchForUsers(with: newValue)
                    } else {
                        searchResults = []
                    }
                }

            if searchResults.isEmpty && showNoResultsMessage {
                Text("No users found")
                    .foregroundColor(.white)
                    .padding()
            } else {
                List(searchResults) { user in
                    VStack(alignment: .leading) {
                        Text(user.username)
                            .foregroundColor(selectedColor)
                        Button(action: { sendFriendRequest(to: user) }) {
                            Text("Send Friend Request")
                                .foregroundColor(.white)
                                .padding()
                                .background(selectedColor)
                                .cornerRadius(8)
                        }
                    }
                }
                .listStyle(PlainListStyle())
            }
        }
        .background(Color.black.ignoresSafeArea())
        .navigationBarTitle("Add Friend", displayMode: .inline)
        .onAppear {
            // Get current user ID and load the friends list when the view appears
            loadCurrentUserIdAndFriends()
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

    private func sendFriendRequest(to user: User) {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        let friendRequestRef = Database.database().reference().child("friend_requests").child(user.uid).child(currentUserId)
        friendRequestRef.setValue(["status": "pending"])
    }
}
struct FriendProfileScreen: View {
    var friendId: String
    @State private var selectedColor: Color = ThemeManager().accentColor

    @State private var weeklyMiles: Int = 0
    @State private var weeklyMinutes: Int = 0
    @State private var fastestWeeklySpeed: Int = 0
    @State private var monthlyMiles: Int = 0
    @State private var monthlyMinutes: Int = 0
    @State private var fastestMonthlySpeed: Int = 0
    @State private var allTimeMiles: Int = 0
    @State private var allTimeMinutes: Int = 0
    @State private var fastestAllTimeSpeed: Int = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Friend's Stats")
                .font(.largeTitle)
                .foregroundColor(selectedColor)
                .padding(.bottom, 20)

            statsView(title: "Weekly Stats", miles: weeklyMiles, minutes: weeklyMinutes, speed: fastestWeeklySpeed)
            statsView(title: "Monthly Stats", miles: monthlyMiles, minutes: monthlyMinutes, speed: fastestMonthlySpeed)
            statsView(title: "All Time Stats", miles: allTimeMiles, minutes: allTimeMinutes, speed: fastestAllTimeSpeed)

            Spacer()
        }
        .padding()
        .onAppear {
            fetchFriendStats()
        }
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func statsView(title: String, miles: Int, minutes: Int, speed: Int) -> some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(.headline)
            Text("Miles Driven: \(miles)")
            Text("Minutes Spent: \(minutes)")
            Text("Fastest Speed: \(speed) mph")
        }
        .padding()
    }

    private func fetchFriendStats() {
        let ref = Database.database().reference().child("users").child(friendId)

        ref.observeSingleEvent(of: .value) { snapshot in
            guard let value = snapshot.value as? [String: Any] else { return }

            self.weeklyMiles = value["weekly_mileage"] as? Int ?? 0
            self.weeklyMinutes = value["weekly_minutes"] as? Int ?? 0
            self.fastestWeeklySpeed = value["fastest_all_time_speed"] as? Int ?? 0

            self.monthlyMiles = value["monthly_mileage"] as? Int ?? 0
            self.monthlyMinutes = value["monthly_minutes"] as? Int ?? 0
            self.fastestMonthlySpeed = value["fastest_all_time_speed"] as? Int ?? 0

            self.allTimeMiles = value["yearly_mileage"] as? Int ?? 0
            self.allTimeMinutes = value["yearly_minutes"] as? Int ?? 0
            self.fastestAllTimeSpeed = value["fastest_all_time_speed"] as? Int ?? 0
        }
    }
}

struct FriendProfileScreen_Previews: PreviewProvider {
    static var previews: some View {
        FriendProfileScreen(friendId: "exampleFriendId")
            .environmentObject(ThemeManager())
    }
}
