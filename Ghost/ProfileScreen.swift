import SwiftUI
import Firebase
import FirebaseAuth

import SwiftUI
import Firebase
import FirebaseAuth

import SwiftUI
import Firebase
import FirebaseAuth

struct ProfileScreen: View {
    @EnvironmentObject var themeManager: ThemeManager
    @StateObject private var viewModel = ProfileViewModel()
    @State private var isEditingProfile = false // Toggle for edit profile modal
    
    @State private var selectedStatIndex = 0 // To track which stat is selected (0 = miles, 1 = minutes, 2 = speed, etc.)
    
    // List of stats to cycle through
    let statsTitles = ["All-Time Miles", "All-Time Minutes", "Fastest Speed", "Minutes Today"]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Welcome Section
            Text("Welcome, \(viewModel.userName)")
                .font(.headline)
                .foregroundColor(themeManager.accentColor)
                .padding(.top)
                .padding(.leading)

            // Profile Stats Section
            VStack(spacing: 20) {
                // Semicircular Progress Animation
                VStack {
                    Text(statsTitles[selectedStatIndex])
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(themeManager.accentColor)
                    
                    // Semicircular progress
                    SemicircleProgressBar(value: getCurrentStatValue(), maxValue: getMaxStatValue())
                        .frame(width: 250, height: 250)
                        .padding(.top, 20)
                    
                    // Add swipe gesture to switch between stats
                    HStack {
                        Button(action: {
                            swipeLeft()
                        }) {
                            Image(systemName: "chevron.left.circle.fill")
                                .font(.title)
                                .foregroundColor(themeManager.accentColor)
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            swipeRight()
                        }) {
                            Image(systemName: "chevron.right.circle.fill")
                                .font(.title)
                                .foregroundColor(themeManager.accentColor)
                        }
                    }
                    .padding(.top, 20)
                }

                Divider() // Separate stats from the settings options
                
                // Settings Options Section
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        SettingsOptionRow(icon: "pencil", title: "Edit Profile") {
                            isEditingProfile = true
                        }
                        SettingsOptionRow(icon: "square.and.arrow.up", title: "Share Profile") {
                            print("Share Profile tapped")
                        }
                        SettingsOptionRow(icon: "bell", title: "Notifications") {
                            print("Notifications tapped")
                        }
                    }
                    .padding(.horizontal)
                }
                
                Spacer()

                // Sign Out Button
                Button(action: signOut) {
                    Text("Sign Out")
                        .font(.headline)
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(uiColor: .systemBackground))
                        .cornerRadius(8)
                        .shadow(radius: 4)
                }
                .padding(.horizontal)
            }
            .onAppear {
                viewModel.fetchUserData()
                viewModel.checkAndResetStats() // Check for resets
            }
            .sheet(isPresented: $isEditingProfile) {
                EditProfileView(viewModel: viewModel)
            }
            .background(Color(uiColor: .systemBackground))
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func getCurrentStatValue() -> Double {
        switch selectedStatIndex {
        case 0:
            return Double(viewModel.allTimeMileage) // All-Time Miles
        case 1:
            return Double(viewModel.allTimeMinutes) // All-Time Minutes
        case 2:
            return Double(viewModel.fastestSpeed) // Fastest Speed
        case 3:
            return Double(viewModel.todayMinutes) // Minutes Today
        default:
            return 0
        }
    }

    private func getMaxStatValue() -> Double {
        switch selectedStatIndex {
        case 0:
            return 200 // Max miles for the green gradient
        case 1:
            return 2000 // Max minutes for the gradient
        case 2:
            return 250 // Max speed for the gradient
        case 3:
            return 200 // Max minutes today for the gradient
        default:
            return 0
        }
    }

    private func swipeLeft() {
        // Move to the previous stat (with infinite looping)
        selectedStatIndex = (selectedStatIndex - 1 + statsTitles.count) % statsTitles.count
    }

    private func swipeRight() {
        // Move to the next stat (with infinite looping)
        selectedStatIndex = (selectedStatIndex + 1) % statsTitles.count
    }

    private func signOut() {
        do {
            try Auth.auth().signOut()
        } catch {
            print("Error signing out: \(error.localizedDescription)")
        }
    }
}

// Custom Semicircular Progress Bar
struct SemicircleProgressBar: View {
    var value: Double
    var maxValue: Double
    
    var body: some View {
        ZStack {
            // Full Circle (gray background)
            Circle()
                .stroke(Color.gray.opacity(0.3), lineWidth: 15)
            
            // Green Gradient for Progress
            Circle()
                .trim(from: 0, to: min(value / maxValue, 1)) // Dynamic trim based on value
                .stroke(LinearGradient(gradient: Gradient(colors: [.white, .green]), startPoint: .top, endPoint: .bottom), lineWidth: 15)
                .rotationEffect(.degrees(-90)) // Start at the top of the circle
                .animation(.easeInOut(duration: 2), value: value) // Smooth animation
            
            // Center Text
            Text("\(Int(value))")
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundColor(.white)
        }
    }
}

// Helper View for Settings Options
struct SettingsOptionRow: View {
    var icon: String
    var title: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.blue)
                Text(title)
                    .font(.body)
                    .foregroundColor(.primary)
                Spacer()
            }
            .padding()
            .background(Color(uiColor: .secondarySystemBackground))
            .cornerRadius(8)
        }
    }
}
// Custom Semicircular Progress Bar


// Helper View for Settings Options

// Edit Profile Modal
struct EditProfileView: View {
    @ObservedObject var viewModel: ProfileViewModel
    @Environment(\.presentationMode) var presentationMode
    @State private var newUsername: String = ""
    @State private var newEmail: String = ""

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Edit Profile")) {
                    TextField("New Username", text: $newUsername)
                    TextField("New Email", text: $newEmail)
                        .keyboardType(.emailAddress)
                }
                Button(action: saveChanges) {
                    Text("Save Changes")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(8)
                }
                .disabled(newUsername.isEmpty && newEmail.isEmpty)
            }
            .navigationTitle("Edit Profile")
            .navigationBarItems(trailing: Button("Cancel") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }

    private func saveChanges() {
        viewModel.updateProfile(username: newUsername, email: newEmail)
        presentationMode.wrappedValue.dismiss()
    }
}

// Profile ViewModel
class ProfileViewModel: ObservableObject {
    @Published var userName: String = "User"
   @Published var email: String = ""
    @Published var allTimeMileage: Int = 0
    @Published var allTimeMinutes: Int = 0
    @Published var fastestSpeed: Int = 0
    @Published var todayMinutes: Int = 0
    @Published var weeklyMileage: Int = 0
    @Published var monthlyMileage: Int = 0

    func fetchUserData() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        let ref = Database.database().reference().child("users").child(userId)

        ref.observeSingleEvent(of: .value) { snapshot in
            guard let data = snapshot.value as? [String: Any] else { return }

           self.userName = data["name"] as? String ?? "User"
           self.email = data["email"] as? String ?? ""
            self.allTimeMileage = Int(data["yearly_mileage"] as? Double ?? 0)
            self.allTimeMinutes = Int(data["yearly_minutes"] as? Double ?? 0)
            self.fastestSpeed = Int(data["fastest_all_time_speed"] as? Double ?? 0)
            self.todayMinutes = Int(data["today_minutes"] as? Double ?? 0)
            self.weeklyMileage = Int(data["weekly_mileage"] as? Double ?? 0)
            self.monthlyMileage = Int(data["monthly_mileage"] as? Double ?? 0)
        }
    }

    func updateProfile(username: String?, email: String?) {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        let ref = Database.database().reference().child("users").child(userId)
        
        var updates: [String: Any] = [:]
        if let username = username, !username.isEmpty {
            updates["username"] = username
        }
        if let email = email, !email.isEmpty {
            updates["email"] = email
        }
        
        ref.updateChildValues(updates) { error, _ in
            if let error = error {
                print("Error updating profile: \(error.localizedDescription)")
            } else {
                print("Profile updated successfully.")
                if let username = username, !username.isEmpty {
                    self.userName = username
                }
                if let email = email, !email.isEmpty {
                    self.email = email
                }
            }
        }
    }
    func checkAndResetStats() {
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.year, .month, .day], from: now)

        let isNewMonth = components.day == 1
        let isNewYear = components.month == 1 && components.day == 1

        guard let userId = Auth.auth().currentUser?.uid else { return }
        let ref = Database.database().reference().child("users").child(userId)

        if isNewMonth || isNewYear {
            ref.observeSingleEvent(of: .value) { snapshot in
                guard let data = snapshot.value as? [String: Any] else { return }

                var updates: [String: Any] = [:]

                if isNewMonth {
                    updates["monthly_mileage"] = 0
                    updates["monthly_minutes"] = 0
                }

                if isNewYear {
                    updates["yearly_mileage"] = 0
                    updates["yearly_minutes"] = 0
                }

                ref.updateChildValues(updates)
            }
        }
    }

}
// Helper View for Settings Options
