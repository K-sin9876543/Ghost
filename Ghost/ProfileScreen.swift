import SwiftUI
import Firebase
import FirebaseAuth

struct ProfileScreen: View {
    @EnvironmentObject var themeManager: ThemeManager
    @State private var selectedPeriod: String = "Week"
    @State private var selectedColor: Color
    
    @State private var milesDriven: Int = 0
    @State private var minutesDriven: Int = 0
    @State private var fastestSpeed: Int = 0
    
    @State private var userName: String = "User"
    
    let periods = ["Today", "Week", "Month", "Year"]
    let colors: [Color] = [.red, .green, .blue, .yellow, .orange, .purple, .pink]

    init() {
        _selectedColor = State(initialValue: ThemeManager().accentColor)
    }

    var body: some View {
        VStack {
            Text("Welcome, \(userName)")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(selectedColor)
                .padding(.top)
            
            VStack(spacing: 20) {
                Text("Profile Stats")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(selectedColor)
                
                HStack {
                    VStack(alignment: .leading) {
                        Text("Miles Driven")
                            .font(.headline)
                            .foregroundColor(.gray)
                        Text("\(milesDriven) miles")
                            .font(.largeTitle)
                            .foregroundColor(selectedColor)
                    }
                    
                    VStack(alignment: .leading) {
                        Text("Minutes Driven")
                            .font(.headline)
                            .foregroundColor(.gray)
                        Text("\(minutesDriven) mins")
                            .font(.largeTitle)
                            .foregroundColor(selectedColor)
                    }
                    
                    VStack(alignment: .leading) {
                        Text("Fastest Speed")
                            .font(.headline)
                            .foregroundColor(.gray)
                        Text("\(fastestSpeed) mph")
                            .font(.largeTitle)
                            .foregroundColor(selectedColor)
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
                .onChange(of: selectedPeriod) { _ in
                    fetchProfileStats()
                }
                
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 60))], spacing: 15) {
                    ForEach(colors, id: \.self) { color in
                        Button(action: {
                            selectedColor = color
                        }) {
                            Circle()
                                .fill(color)
                                .frame(width: 60, height: 60)
                                .overlay(
                                    Circle()
                                        .stroke(selectedColor == color ? Color.black : Color.clear, lineWidth: 3)
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
                        .background(selectedColor)
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
            fetchUserName()
            fetchProfileStats()
        }
    }

    private func fetchProfileStats() {
        guard let user = Auth.auth().currentUser else { return }
        
        let ref = Database.database().reference().child("users").child(user.uid)
        
        ref.observeSingleEvent(of: .value) { snapshot in
            if let data = snapshot.value as? [String: Any] {
                switch selectedPeriod {
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
    
    private func fetchUserName() {
        guard let user = Auth.auth().currentUser else { return }
        
        let ref = Database.database().reference().child("users").child(user.uid)
        
        ref.observeSingleEvent(of: .value) { snapshot in
            if let userData = snapshot.value as? [String: Any],
               let username = userData["username"] as? String {
                self.userName = username
            }
        }
    }

    private func saveColor() {
        themeManager.accentColor = selectedColor
    }

    private func signOut() {
        do {
            try Auth.auth().signOut()
        } catch {
            print("Error signing out: \(error.localizedDescription)")
        }
    }
}

struct ProfileScreen_Previews: PreviewProvider {
    static var previews: some View {
        ProfileScreen()
            .environmentObject(ThemeManager())
    }
}
