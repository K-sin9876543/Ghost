import SwiftUI
import Firebase

struct FriendProfileScreen: View {
    var friendId: String
    
    // Stats
    @State private var allTimeMiles: Int = 0
    @State private var allTimeMinutes: Int = 0
    @State private var fastestAllTimeSpeed: Int = 0
    
    // Animation
    @State private var animatedMiles: Double = 0 // For gradient animation
    @State private var showStats = false

    var body: some View {
        ZStack {
            // Clean, simple background with color gradient
            LinearGradient(gradient: Gradient(colors: [Color.black.opacity(0.8), Color.gray.opacity(0.2)]), startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                // Title Section
                Text("Friend's Stats")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.top, 20)

                // Full Circle with Gradient Fill
                ZStack {
                    // Full Circle Track (Gray background)
                    Circle()
                        .stroke(Color.gray.opacity(0.3), lineWidth: 15)
                        .frame(width: 250, height: 250)

                    // Green Gradient Highlight (Filling based on mileage percentage)
                    Circle()
                        .trim(from: 0, to: min(animatedMiles / 15000, 1)) // Percent fill of the circle
                        .stroke(LinearGradient(gradient: Gradient(colors: [.white, .green]), startPoint: .top, endPoint: .bottom), lineWidth: 15)
                        .rotationEffect(.degrees(-90)) // Start at 0 (top of the circle)
                        .animation(.easeInOut(duration: 2), value: animatedMiles) // Smooth animation

                    // Center Circle (White center)
                    Circle()
                        .fill(Color.white)
                        .frame(width: 15, height: 15)

                    // Mileage Text
                    VStack {
                        Text("\(Int(animatedMiles))")
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        Text("All-Time Miles")
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundColor(.gray)
                    }
                }
                .padding(.vertical, 20)

                // Stats Cards
                ScrollView {
                    VStack(spacing: 15) {
                        statsCard(title: "Minutes Driven", value: "\(allTimeMinutes) mins")
                        statsCard(title: "Fastest Speed", value: "\(fastestAllTimeSpeed) mph")
                    }
                }
                .padding(.horizontal)

                Spacer()
            }
        }
        .onAppear {
            fetchFriendStats()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                showStats = true // Trigger animation
            }
        }
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func statsCard(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline)
                .foregroundColor(.white)

            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.white)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color.black.opacity(0.7))
                .shadow(color: .black.opacity(0.3), radius: 5, x: 0, y: 2)
        )
    }

    private func fetchFriendStats() {
        let ref = Database.database().reference().child("users").child(friendId)

        ref.observeSingleEvent(of: .value) { snapshot in
            guard let value = snapshot.value as? [String: Any] else { return }

            // Fetch stats from the database
            let miles = value["yearly_mileage"] as? Double ?? 0
            let minutes = value["yearly_minutes"] as? Double ?? 0
            let speed = value["fastest_all_time_speed"] as? Double ?? 0

            // Update stats and animate the gradient fill
            withAnimation {
                self.allTimeMiles = Int(miles)
                self.animatedMiles = miles // Update the mileage value for the gradient
                self.allTimeMinutes = Int(minutes)
                self.fastestAllTimeSpeed = Int(speed)
            }
        }
    }
}
