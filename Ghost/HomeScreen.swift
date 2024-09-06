import SwiftUI

struct HomeScreen: View {
    @State private var showingMenu = false
    @State private var selectedTab: Tab = .home
    @ObservedObject var themeManager = ThemeManager()

    enum Tab {
        case home, profile, maps, friends , startrun
    }
    @State private var selectedColor: Color = ThemeManager().accentColor

    var body: some View {
        NavigationStack {
            ZStack {
                VStack(spacing: 0) {
                    if selectedTab == .home {
                        // Top Navigation Bar (only on Home screen)
                        HStack {
                            Spacer()
                            
                            Text("Ghost") // Replace with your app logo text or Image
                                .font(.headline)
                                .foregroundColor(selectedColor)
                                .frame(maxWidth: .infinity, alignment: .center) // Center the logo
                            
                            Spacer()
                            
                            NavigationLink(destination: SearchScreen()) { // Destination for the search icon
                                Image(systemName: "magnifyingglass")
                                    .font(.system(size: 24))
                                    .foregroundColor(selectedColor)
                                    .padding()
                            }
                            
                            NavigationLink(destination: NotificationsScreen()) { // Destination for the notification icon
                                Image(systemName: "bell")
                                    .font(.system(size: 24))
                                    .foregroundColor(selectedColor)
                                    .padding()
                            }
                        }
                        .frame(height: 80) // Height for the top bar
                        .background(Color(uiColor: .systemBackground)) // Background color for the top bar
                        .padding(.top, 5) // Position 5 points below the top of the screen
                    }

                    // Main content that can scroll
                    ScrollView {
                        VStack {
                            switch selectedTab {
                            case .home:
                                Text("Home Screen Content")
                                    .font(.largeTitle)
                                    .foregroundColor(selectedColor)
                            
                            case .profile:
                                ProfileScreen()
                            case .maps:
                                MapScreen()
                            case .friends:
                                FriendsScreen()
                            case .startrun:
                                 StartNewRunScreen()
                            }
                        }
                        .padding(.bottom, 20) // Add padding at the bottom to avoid overlap with the bottom nav bar
                    }
                }
                
                // Bottom Navigation Bar
                VStack {
                    Spacer() // Push the bottom nav bar to the bottom
                    HStack {
                       
                        
                        
                        Button(action: { selectedTab = .home }) {
                            Image(systemName: "house.fill")
                                .font(.system(size: 24))
                                .foregroundColor(selectedTab == .home ? themeManager.accentColor : themeManager.accentColor.opacity(0.5))
                                .padding()
                        }

                      
                        Spacer()

                        Button(action: { selectedTab = .friends }) {
                            Image(systemName: "person.3.fill")
                                .font(.system(size: 24))
                                .foregroundColor(selectedTab == .friends ? themeManager.accentColor : themeManager.accentColor.opacity(0.5))
                                .padding()
                        }
                        
                        Spacer()
                        
                        Button(action: { selectedTab = .startrun }) {
                            Image(systemName: "plus")
                                .font(.system(size: 24))
                                .foregroundColor(selectedTab == .home ? themeManager.accentColor : themeManager.accentColor.opacity(0.5))
                                .padding()
                        }

                        
                        Spacer()
                        Button(action: { selectedTab = .maps }) {
                            Image(systemName: "map.fill")
                                .font(.system(size: 24))
                                .foregroundColor(selectedTab == .maps ? themeManager.accentColor : themeManager.accentColor.opacity(0.5))
                                .padding()
                        }

                      
                        
                        Spacer()

                        Button(action: { selectedTab = .profile }) {
                            Image(systemName: "person.fill")
                                .font(.system(size: 24))
                                .foregroundColor(selectedTab == .profile ? themeManager.accentColor : themeManager.accentColor.opacity(0.5))
                                .padding()
                        }
                    }
                    .frame(height: 50) // Height of the bottom bar
                    .background(Color(uiColor: .systemBackground)) // Background color for the bottom bar
                }
            }
            .actionSheet(isPresented: $showingMenu) {
                ActionSheet(
                    title: Text("Select an Option"),
                    buttons: [
                        .default(Text("Start New Run")) {
                            // Navigate to Start New Run Screen
                            selectedTab = .home
                            NavigationLink(destination: StartNewRunScreen()) {
                                EmptyView()
                            }
                        },
                        .cancel()
                    ]
                )
            }
        }
    }
}

// Dummy screens for navigation

struct SearchScreen: View {
    var body: some View {
        Text("Search Screen")
            .font(.largeTitle)
            .navigationBarTitle("Search", displayMode: .inline)
            .background(Color(uiColor: .systemBackground)) // Background color
    }
}

struct NotificationsScreen: View {
    var body: some View {
        Text("Notifications Screen")
            .font(.largeTitle)
            .navigationBarTitle("Notifications", displayMode: .inline)
            .background(Color(uiColor: .systemBackground)) // Background color
    }
}
