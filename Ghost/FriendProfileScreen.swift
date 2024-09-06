import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseDatabase
import FirebaseStorage

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
