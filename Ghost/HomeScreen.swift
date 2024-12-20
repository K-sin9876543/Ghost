import SwiftUI
import FirebaseAuth
import Firebase

struct HomeScreen: View {
    @State private var runs: [Run] = [] // Store only friends' runs
    @ObservedObject var themeManager = ThemeManager()
    @State private var selectedTab: Tab = .home
    @Namespace private var animationNamespace // For smooth animations

    enum Tab {
        case home, profile, maps, friends, startrun
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                VStack(spacing: 0) {
                    // Main content that can scroll
                    ScrollView {
                        VStack(spacing: 16) {
                            if selectedTab == .home {
                                if runs.isEmpty {
                                    Text("No runs available from friends.")
                                        .font(.headline)
                                        //.foregroundColor(.gray)
                                        .padding()
                                } else {
                                    LazyVStack(spacing: 16) {
                                        ForEach(runs.indices, id: \.self) { index in
                                            NavigationLink(destination: RunDetailView(run: runs[index])) {
                                                RunCell(run: runs[index])
                                                  //  .background(RoundedRectangle(cornerRadius: 12).fill(index % 2 == 0 ? Color(.systemGray6) : Color(.systemGray5)))
                                                    //.shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                                                   // .padding(.horizontal)
                                                    .frame(maxWidth: .infinity) // Make the cell take up the full width
                                                    .padding(.vertical, 10)
                                                    .background(Color.clear) // Optional, add a background to visually separate the cells
                                                    .overlay(
                                                        Rectangle() // Horizontal line to separate the cells
                                                            .frame(height: 1)
                                                            .foregroundColor(Color.green)
                                                            .padding(.horizontal)
                                                            .padding(.top, 10) // Space between cell content and the line
                                                        , alignment: .bottom
                                                    )
                                            }
                                            .buttonStyle(PlainButtonStyle())
                                        }
                                    }
                                }
                            } else {
                                switch selectedTab {
                                case .profile: ProfileScreen()
                                case .maps: MapScreen()
                                case .friends: FriendsScreen()
                                case .startrun: StartNewRunScreen()
                                default: EmptyView()
                                }
                            }
                        }
                        .padding(.bottom, 20) // Avoid overlap with bottom nav bar
                    }
                }
                
                // Bottom Navigation Bar
                VStack {
                    Spacer()
                    ZStack {
                        // Highlight Circle Animation
                        HStack {
                            Spacer()
                                .frame(width: tabWidth(for: .home))
                            Circle()
                                .fill(themeManager.accentColor.opacity(0.2))
                                .frame(width: 50, height: 50)
                                .matchedGeometryEffect(id: "highlightCircle", in: animationNamespace)
                        }
                        .frame(height: 50)
                        .animation(.easeInOut, value: selectedTab)
                        
                        // Bottom Navigation Buttons
                        HStack {
                            BottomNavButton(
                                icon: "house.fill",
                                isSelected: selectedTab == .home,
                                themeManager: themeManager
                            ) { selectedTab = .home }
                            Spacer()
                            BottomNavButton(
                                icon: "person.3.fill",
                                isSelected: selectedTab == .friends,
                                themeManager: themeManager
                            ) { selectedTab = .friends }
                            Spacer()
                            BottomNavButton(
                                icon: "plus",
                                isSelected: selectedTab == .startrun,
                                themeManager: themeManager
                            ) { selectedTab = .startrun }
                            Spacer()
                            BottomNavButton(
                                icon: "map.fill",
                                isSelected: selectedTab == .maps,
                                themeManager: themeManager
                            ) { selectedTab = .maps }
                            Spacer()
                            BottomNavButton(
                                icon: "person.fill",
                                isSelected: selectedTab == .profile,
                                themeManager: themeManager
                            ) { selectedTab = .profile }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(RoundedRectangle(cornerRadius: 60).fill(Color(.systemGray6)))
                        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: -2)
                    }
                    .frame(height: 60)
                }
            }
        }
        .onAppear(perform: loadFriendsRuns)
    }
    private func tabWidth(for tab: Tab) -> CGFloat {
          switch tab {
          case .home: return 0
          case .friends: return UIScreen.main.bounds.width / 5 * 1
          case .startrun: return UIScreen.main.bounds.width / 5 * 2
          case .maps: return UIScreen.main.bounds.width / 5 * 3
          case .profile: return UIScreen.main.bounds.width / 5 * 4
          }
      }
    // Load runs for the current user's friends only
    private func loadFriendsRuns() {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("User ID not available.")
            return
        }
        
        let friendsRef = Database.database().reference().child("friends").child(userId)
        
        friendsRef.observeSingleEvent(of: .value) { snapshot in
            var friendsList: [String] = []
            
            for child in snapshot.children {
                if let friendSnapshot = child as? DataSnapshot {
                    friendsList.append(friendSnapshot.key) // Friend's user IDs
                }
            }
            
            fetchDrivesForFriends(friendIds: friendsList)
        }
    }
    
    // Fetch drives for friends
    private func fetchDrivesForFriends(friendIds: [String]) {
        var allRuns: [Run] = []
        let dispatchGroup = DispatchGroup()

        for friendId in friendIds {
            dispatchGroup.enter()

            let userRef = Database.database().reference().child("users").child(friendId)
            
            userRef.observeSingleEvent(of: .value) { snapshot in
                guard let userData = snapshot.value as? [String: Any],
                      let userName = userData["username"] as? String,
                      let drives = userData["drives"] as? [String: [String: Any]] else {
                    print("Failed to fetch user data or drives for friend \(friendId).")
                    dispatchGroup.leave()
                    return
                }
                
                for (_, runDict) in drives {
                    if let run = Run(from: runDict, userName: userName) {
                        allRuns.append(run)
                    }
                }
                dispatchGroup.leave()
            }
        }

        dispatchGroup.notify(queue: .main) {
            self.runs = allRuns.sorted(by: { $0.date > $1.date }) // Sort by date (newest first)
        }
    }
}


struct BottomNavButton: View {
    let icon: String
    let isSelected: Bool
    let themeManager: ThemeManager
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(isSelected ? themeManager.accentColor : themeManager.accentColor.opacity(0.5))
                .padding()
        }
    }
}
