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
struct User: Identifiable {
    let id = UUID()
    let uid: String
    let username: String
    let email: String
}

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
