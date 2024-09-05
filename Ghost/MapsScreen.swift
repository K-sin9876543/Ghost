import SwiftUI
import MapKit

struct FriendMapRoute: Identifiable, Equatable {
    let id = UUID()
    let name: String
    let coordinate: CLLocationCoordinate2D
    let route: [CLLocationCoordinate2D]
    let duration: TimeInterval // Duration of the race

    // Conforming to Equatable
    static func == (lhs: FriendMapRoute, rhs: FriendMapRoute) -> Bool {
        return lhs.id == rhs.id
    }
}

struct MapsScreen: View {
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    
    @State private var selectedRoute: FriendMapRoute? = nil
    
    let friendsRoutes: [FriendMapRoute] = [
        FriendMapRoute(
            name: "Canyon Run",
            coordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
            route: [
                CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
                CLLocationCoordinate2D(latitude: 37.8044, longitude: -122.2712)
            ],
            duration: 3600 // 1 hour
        ),
        FriendMapRoute(
            name: "Mountain Drive",
            coordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4294),
            route: [
                CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4294),
                CLLocationCoordinate2D(latitude: 37.7844, longitude: -122.2712)
            ],
            duration: 5400 // 1.5 hours
        ),
        // Add more FriendMapRoute objects here
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            // MapView
            Map(coordinateRegion: $region, annotationItems: friendsRoutes) { route in
                MapAnnotation(coordinate: route.coordinate) {
                    Circle()
                        .strokeBorder(Color.red, lineWidth: 3)
                        .background(Circle().foregroundColor(Color.red.opacity(0.3)))
                        .frame(width: 30, height: 30)
                        .onTapGesture {
                            selectRoute(route)
                        }
                }
            }
            .edgesIgnoringSafeArea(.top)
            .frame(height: UIScreen.main.bounds.height * 0.5)
            .onChange(of: selectedRoute) { newValue in
                if let selectedRoute = newValue {
                    withAnimation {
                        region.center = selectedRoute.coordinate
                    }
                }
            }
            
            // Selected Route Details
//            if let selectedRoute = selectedRoute {
//                VStack(alignment: .leading, spacing: 8) {
//                    Text("Race: \(selectedRoute.name)")
//                        .font(.headline)
//                    Text("Time Taken: \(formatDuration(selectedRoute.duration))")
//                        .font(.subheadline)
//                    Text("Route Details:")
//                        .font(.subheadline)
//                    
//                    Map(coordinateRegion: $region, annotationItems: [selectedRoute]) { route in
//                        MapPolyline(coordinates: route.route)
//                            .stroke(Color.green, lineWidth: 4)
//                    }
//                    .frame(height: 200)
//                    .cornerRadius(10)
//                    .padding(.vertical, 8)
//                }
//                .padding()
//                .background(Color(uiColor: .systemBackground))
//                .cornerRadius(10)
//                .shadow(radius: 5)
//                .padding(.horizontal)
//            }
//            
            // Event List
            List(friendsRoutes) { route in
                Button(action: {
                    selectRoute(route)
                }) {
                    HStack {
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 40, height: 40)
                            .overlay(Text(route.name.prefix(1)).foregroundColor(.white))
                        Text(route.name)
                    }
                }
            }
            .frame(height: UIScreen.main.bounds.height * 0.3)
        }
        .navigationTitle("Maps")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func selectRoute(_ route: FriendMapRoute) {
        selectedRoute = route
        region.center = route.coordinate
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.unitsStyle = .abbreviated
        return formatter.string(from: duration) ?? ""
    }
}

struct MapsScreen_Previews: PreviewProvider {
    static var previews: some View {
        MapsScreen()
    }
}
