import SwiftUI
import Firebase
import FirebaseAuth

struct ProfileScreen: View {
    @EnvironmentObject var themeManager: ThemeManager
    @StateObject private var viewModel = ProfileViewModel() // Create an instance of the ViewModel
    
    @State private var selectedPeriod: String = "Week"
    let periods = ["Today", "Week", "Month", "Year"]
    let colors: [Color] = [.red, .green, .blue, .yellow, .orange, .purple, .pink]

    var body: some View {
        VStack {
            Text("Welcome, \(viewModel.userName)")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(themeManager.accentColor)
                .padding(.top)
            
            VStack(spacing: 20) {
                Text("Profile Stats")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(themeManager.accentColor)
                
                HStack {
                    VStack(alignment: .leading) {
                        Text("Miles Driven")
                            .font(.headline)
                            .foregroundColor(.gray)
                        Text("\(viewModel.milesDriven) miles") // Use data from the ViewModel
                            .font(.largeTitle)
                            .foregroundColor(themeManager.accentColor)
                    }
                    
                    VStack(alignment: .leading) {
                        Text("Minutes Driven")
                            .font(.headline)
                            .foregroundColor(.gray)
                        Text("\(viewModel.minutesDriven) mins") // Use data from the ViewModel
                            .font(.largeTitle)
                            .foregroundColor(themeManager.accentColor)
                    }
                    
                    VStack(alignment: .leading) {
                        Text("Fastest Speed")
                            .font(.headline)
                            .foregroundColor(.gray)
                        Text("\(viewModel.fastestSpeed) mph") // Use data from the ViewModel
                            .font(.largeTitle)
                            .foregroundColor(themeManager.accentColor)
                    }
                }
                .padding()
                .background(Color(uiColor: .systemBackground))

                Picker("Select Period", selection: $selectedPeriod) {
                    ForEach(periods, id: \.self) { period in
                        Text(period).tag(period)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                .onChange(of: selectedPeriod) { newValue in
                    viewModel.selectedPeriod = newValue // Update the ViewModel when the period changes
                    viewModel.fetchProfileStats() // Fetch new stats based on the selected period
                }
                
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 60))], spacing: 15) {
                    ForEach(colors, id: \.self) { color in
                        Button(action: {
                            themeManager.accentColor = color
                        }) {
                            Circle()
                                .fill(color)
                                .frame(width: 60, height: 60)
                                .overlay(
                                    Circle()
                                        .stroke(themeManager.accentColor == color ? Color.black : Color.clear, lineWidth: 3)
                                )
                        }
                    }
                }
                .padding()

                Button(action: saveColor) {
                    Text("Save Color")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .background(themeManager.accentColor)
                        .cornerRadius(8)
                        .shadow(radius: 4)
                }
                .padding(.bottom)
                
                Spacer()

                Button(action: signOut) {
                    Text("Sign Out")
                        .font(.headline)
                        .foregroundColor(.red)
                        .padding()
                        .background(Color.white)
                        .cornerRadius(8)
                        .shadow(radius: 4)
                }
                .padding(.bottom)
            }
            .padding()
            .background(Color(uiColor: .systemBackground))
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            viewModel.fetchUserName() // Fetch the username on view load
            viewModel.fetchProfileStats() // Fetch the stats initially
        }
    }

    private func saveColor() {
        // Optionally, save the theme color to persistent storage (UserDefaults, Firebase, etc.)
        print("Color \(themeManager.accentColor) saved.")
    }

    private func signOut() {
        do {
            try Auth.auth().signOut()
        } catch {
            print("Error signing out: \(error.localizedDescription)")
        }
    }
}
import Foundation
import Firebase
import FirebaseAuth

class ProfileViewModel: ObservableObject {
    @Published var milesDriven: Int = 0
    @Published var minutesDriven: Int = 0
    @Published var fastestSpeed: Int = 0
    @Published var userName: String = "User"
    
    let periods = ["Today", "Week", "Month", "Year"]
    
    var selectedPeriod: String = "Week" {
        didSet {
            fetchProfileStats()
        }
    }

    // Fetch user stats based on the selected period
    func fetchProfileStats() {
        guard let user = Auth.auth().currentUser else { return }
        
        let ref = Database.database().reference().child("users").child(user.uid)
        
        ref.observeSingleEvent(of: .value) { snapshot in
            if let data = snapshot.value as? [String: Any] {
                DispatchQueue.main.async { // Ensure updates happen on the main thread
                    switch self.selectedPeriod {
                    case "Today":
                        self.milesDriven = data["today_mileage"] as? Int ?? 0
                        self.minutesDriven = data["today_minutes"] as? Int ?? 0
                    case "Week":
                        self.milesDriven = data["weekly_mileage"] as? Int ?? 0
                        self.minutesDriven = data["weekly_minutes"] as? Int ?? 0
                    case "Month":
                        self.milesDriven = data["monthly_mileage"] as? Int ?? 0
                        self.minutesDriven = data["monthly_minutes"] as? Int ?? 0
                    case "Year":
                        self.milesDriven = data["yearly_mileage"] as? Int ?? 0
                        self.minutesDriven = data["yearly_minutes"] as? Int ?? 0
                    default:
                        break
                    }
                    self.fastestSpeed = data["fastest_all_time_speed"] as? Int ?? 0
                }
            }
        }
    }
    
    // Fetch the username for the profile
    func fetchUserName() {
        guard let user = Auth.auth().currentUser else { return }
        
        let ref = Database.database().reference().child("users").child(user.uid)
        
        ref.observeSingleEvent(of: .value) { snapshot in
            if let userData = snapshot.value as? [String: Any],
               let username = userData["username"] as? String {
                DispatchQueue.main.async {
                    self.userName = username
                }
            }
        }
    }
}
