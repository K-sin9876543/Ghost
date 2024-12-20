import SwiftUI
import MapKit
import Firebase
import FirebaseAuth

struct StartNewRunScreen: View {
    @State private var isTracking = false
    @State private var routeCoordinates: [CLLocationCoordinate2D] = []
    @State private var currentSpeed: Double = 0.0
    @State private var topSpeed: Double = 0.0
    @State private var distanceTraveled: Double = 0.0
    @State private var startLocation: CLLocationCoordinate2D?
    @State private var endLocation: CLLocationCoordinate2D?
    @State private var locationManager = LocationManager()
   
    @State private var selectedColor: Color = ThemeManager().accentColor

    // Timer-related states
    @State private var elapsedTime: TimeInterval = 0.0
    @State private var timer: Timer? = nil
    @State private var startTime: Date? = nil
    
    // Track speeds over time for the graph
    @State private var speedHistory: [(time: TimeInterval, speed: Double)] = []

    var body: some View {
        VStack {
            // Map displaying the route and user's current location
            MapView(routeCoordinates: $routeCoordinates, startLocation: $startLocation, endLocation: $endLocation)
                .frame(height: 300)
                .cornerRadius(10)
            Spacer()
            
            VStack {
                // Start/Stop Button
                Button(action: {
                    isTracking.toggle()
                    if isTracking {
                        startRun()
                    } else {
                        stopRun()
                    }
                }) {
                    Text(isTracking ? "Stop Run" : "Start Run")
                        .font(.headline)
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(gradient: Gradient(colors: isTracking ? [Color.red, Color.orange] : [Color.green, Color.blue]),
                                           startPoint: .topLeading,
                                           endPoint: .bottomTrailing)
                        )
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .shadow(color: isTracking ? Color.red.opacity(0.6) : Color.green.opacity(0.6), radius: 6, x: 0, y: 4)
                        .scaleEffect(isTracking ? 1.05 : 1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.5, blendDuration: 0.5), value: isTracking)
                        .padding(.horizontal)
                }
                .buttonStyle(PressedButtonStyle())
                
                // Save Button
                if !isTracking && !routeCoordinates.isEmpty {
                    Button(action: saveRun) {
                        Text("Save Run")
                            .font(.headline)
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                LinearGradient(gradient: Gradient(colors: [selectedColor.opacity(0.8), selectedColor]),
                                               startPoint: .topLeading,
                                               endPoint: .bottomTrailing)
                            )
                            .foregroundColor(.white)
                            .cornerRadius(12)
                            .shadow(color: selectedColor.opacity(0.6), radius: 6, x: 0, y: 4)
                            .scaleEffect(1.0)
                           // .animation(.spring(response: 0.3, dampingFraction: 0.5, blendDuration: 0.5), value: routeCoordinates)
                            .padding(.horizontal)
                    }
                    .buttonStyle(PressedButtonStyle())
                }
            }
            .padding(.bottom, UIApplication.shared.windows.first?.safeAreaInsets.bottom ?? 0 + 16)
            // Live Stats with Visual Flair
            VStack(spacing: 20) {
                VStack(spacing: 40) {
                    // Speedometer for current speed
                    CircularProgressBar(value: $currentSpeed, maxValue: 150, label: "Speed", unit: "mph")
                        .frame(width: 100, height: 100)

                    // Arc for distance
                    DistanceArc(distance: $distanceTraveled, target: 100)
                        .frame(width: 100, height: 100)
                }

                // Graph for speed over time
                SpeedGraph(speedHistory: $speedHistory)
                    .frame(height: 150)
                    .padding(.horizontal)
            }
            .padding()
            
           
        }
        .onAppear {
            locationManager.checkPermissions()
        }
    }
    
    // Update stats during the run
    private func updateRunStats(with location: CLLocation) {
        routeCoordinates.append(location.coordinate)
        let speed = max(location.speed * 2.23694, 0) // Convert m/s to mph
        currentSpeed = speed
        topSpeed = max(topSpeed, speed)
        
        if let startTime = startTime {
            speedHistory.append((time: Date().timeIntervalSince(startTime), speed: speed))
        }
        
        if routeCoordinates.count > 1 {
            let lastLocation = CLLocation(latitude: routeCoordinates[routeCoordinates.count - 2].latitude, longitude: routeCoordinates[routeCoordinates.count - 2].longitude)
            distanceTraveled += location.distance(from: lastLocation) / 1609.34 // Convert meters to miles
        }
    }
    
    private func startRun() {
        locationManager.startTracking { location in
            updateRunStats(with: location)
        }
        startLocation = routeCoordinates.last
        startTime = Date()
        startTimer()
    }
    
    private func stopRun() {
        locationManager.stopTracking()
        endLocation = routeCoordinates.last
        stopTimer()
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if let startTime = startTime {
                elapsedTime = Date().timeIntervalSince(startTime)
            }
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    // Save run data to Firebase
    private func saveRun() {
        let userId = Auth.auth().currentUser?.uid ?? "unknown_user"
        let ref = Database.database().reference().child("users").child(userId)

        ref.observeSingleEvent(of: .value) { snapshot in
            if var userData = snapshot.value as? [String: Any] {
                // Fetch existing stats
                let todayMileage = userData["today_mileage"] as? Double ?? 0.0
                let todayMinutes = userData["today_minutes"] as? Double ?? 0.0
                let weeklyMileage = userData["weekly_mileage"] as? Double ?? 0.0
                let weeklyMinutes = userData["weekly_minutes"] as? Double ?? 0.0
                let monthlyMileage = userData["monthly_mileage"] as? Double ?? 0.0
                let monthlyMinutes = userData["monthly_minutes"] as? Double ?? 0.0
                let yearlyMileage = userData["yearly_mileage"] as? Double ?? 0.0
                let yearlyMinutes = userData["yearly_minutes"] as? Double ?? 0.0

                // Update stats with the new run data
                let updatedTodayMileage = todayMileage + distanceTraveled
                let updatedTodayMinutes = todayMinutes + (elapsedTime / 60) // Convert seconds to minutes
                let updatedWeeklyMileage = weeklyMileage + distanceTraveled
                let updatedWeeklyMinutes = weeklyMinutes + (elapsedTime / 60)
                let updatedMonthlyMileage = monthlyMileage + distanceTraveled
                let updatedMonthlyMinutes = monthlyMinutes + (elapsedTime / 60)
                let updatedYearlyMileage = yearlyMileage + distanceTraveled
                let updatedYearlyMinutes = yearlyMinutes + (elapsedTime / 60)

                // Prepare the data for saving
                let runData: [String: Any] = [
                    "route": routeCoordinates.map { ["lat": $0.latitude, "lng": $0.longitude] },
                    "topSpeed": topSpeed,
                    "distance": distanceTraveled,
                    "duration": elapsedTime,
                    "date": Date().timeIntervalSince1970,
                    "startLocation": ["lat": startLocation?.latitude ?? 0.0, "lng": startLocation?.longitude ?? 0.0],
                    "endLocation": ["lat": endLocation?.latitude ?? 0.0, "lng": endLocation?.longitude ?? 0.0],
                    "today_mileage": updatedTodayMileage,
                    "today_minutes": updatedTodayMinutes,
                    "weekly_mileage": updatedWeeklyMileage,
                    "weekly_minutes": updatedWeeklyMinutes,
                    "monthly_mileage": updatedMonthlyMileage,
                    "monthly_minutes": updatedMonthlyMinutes,
                    "yearly_mileage": updatedYearlyMileage,
                    "yearly_minutes": updatedYearlyMinutes
                ]
                
                // Save run data and updated stats
                let driveRef = ref.child("drives").childByAutoId()
                driveRef.setValue(runData) { error, _ in
                    if let error = error {
                        print("Error saving run: \(error.localizedDescription)")
                    } else {
                        // Save the updated stats back to the user node
                        let updatedStats: [String: Any] = [
                            "today_mileage": updatedTodayMileage,
                            "today_minutes": updatedTodayMinutes,
                            "weekly_mileage": updatedWeeklyMileage,
                            "weekly_minutes": updatedWeeklyMinutes,
                            "monthly_mileage": updatedMonthlyMileage,
                            "monthly_minutes": updatedMonthlyMinutes,
                            "yearly_mileage": updatedYearlyMileage,
                            "yearly_minutes": updatedYearlyMinutes
                        ]
                        
                        ref.updateChildValues(updatedStats) { error, _ in
                            if let error = error {
                                print("Error updating stats: \(error.localizedDescription)")
                            } else {
                                print("Run and stats saved successfully")
                                resetRun()
                            }
                        }
                    }
                }
            }
        }
    }
    
    // Reset data after saving
    private func resetRun() {
        routeCoordinates.removeAll()
        currentSpeed = 0.0
        topSpeed = 0.0
        distanceTraveled = 0.0
        elapsedTime = 0.0
        startLocation = nil
        endLocation = nil
    }
}



// Location Manager for tracking
class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    private var locationUpdateHandler: ((CLLocation) -> Void)?
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 5 // Smaller filter for faster updates
        locationManager.allowsBackgroundLocationUpdates = true // Enable background location updates
        locationManager.pausesLocationUpdatesAutomatically = false // Prevent location updates from stopping
    }
    
    func checkPermissions() {
        if CLLocationManager.locationServicesEnabled() {
            locationManager.requestAlwaysAuthorization() // Request permission to always access location
        }
    }
    
    func startTracking(updateHandler: @escaping (CLLocation) -> Void) {
        locationUpdateHandler = updateHandler
        locationManager.startUpdatingLocation()
    }
    
    func stopTracking() {
        locationManager.stopUpdatingLocation()
        locationUpdateHandler = nil
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last {
            locationUpdateHandler?(location)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("LocationManager failed with error: \(error.localizedDescription)")
    }
}

// MapView for displaying the route and user's location
struct MapView: UIViewRepresentable {
    @Binding var routeCoordinates: [CLLocationCoordinate2D]
    @Binding var startLocation: CLLocationCoordinate2D?
    @Binding var endLocation: CLLocationCoordinate2D?
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.showsUserLocation = true
        mapView.delegate = context.coordinator
        return mapView
    }
    
    func updateUIView(_ mapView: MKMapView, context: Context) {
        mapView.removeOverlays(mapView.overlays)
        mapView.removeAnnotations(mapView.annotations)
        
        if let startLocation = startLocation {
            let startAnnotation = MKPointAnnotation()
            startAnnotation.coordinate = startLocation
            startAnnotation.title = "Start"
            mapView.addAnnotation(startAnnotation)
        }
        
        if let endLocation = endLocation {
            let endAnnotation = MKPointAnnotation()
            endAnnotation.coordinate = endLocation
            endAnnotation.title = "End"
            mapView.addAnnotation(endAnnotation)
        }
        
        if routeCoordinates.count > 1 {
            let polyline = MKPolyline(coordinates: routeCoordinates, count: routeCoordinates.count)
            mapView.addOverlay(polyline)
        }
        
        if let lastLocation = routeCoordinates.last {
            let region = MKCoordinateRegion(center: lastLocation, latitudinalMeters: 1000, longitudinalMeters: 1000)
            mapView.setRegion(region, animated: true)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: MapView
        
        init(_ parent: MapView) {
            self.parent = parent
        }
        
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let polyline = overlay as? MKPolyline {
                let renderer = MKPolylineRenderer(overlay: polyline)
                renderer.strokeColor = .blue
                renderer.lineWidth = 4.0
                return renderer
            }
            return MKOverlayRenderer(overlay: overlay)
        }
    }
}

struct CircularProgressBar: View {
    @Binding var value: Double
    var maxValue: Double
    var label: String
    var unit: String
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.gray.opacity(0.3), lineWidth: 10)
            Circle()
                .trim(from: 0.0, to: CGFloat(min(value / maxValue, 1.0)))
                .stroke(Color.green, style: StrokeStyle(lineWidth: 10, lineCap: .round)) // Green progress bar
                .rotationEffect(.degrees(-90))
                .animation(.easeOut(duration: 3.0), value: value) // Slower animation

            VStack {
                Text(label)
                    .font(.caption)
                Text("\(String(format: "%.0f", value)) \(unit)")
                    .font(.headline)
            }
        }
    }
}

// Distance Arc Visualization
struct DistanceArc: View {
    @Binding var distance: Double
    var target: Double

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.gray.opacity(0.3), lineWidth: 10)
            Circle()
                .trim(from: 0.0, to: CGFloat(min(distance / target, 1.0)))
                .stroke(Color.green, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.linear, value: distance)

            VStack {
                Text("Distance")
                    .font(.caption)
                Text("\(String(format: "%.2f", distance)) mi")
                    .font(.headline)
            }
        }
    }
}

// Graph for Speed History
struct SpeedGraph: View {
    @Binding var speedHistory: [(time: TimeInterval, speed: Double)]

    var body: some View {
        GeometryReader { geometry in
            Path { path in
                guard speedHistory.count > 1 else { return }
                
                let maxSpeed = speedHistory.map { $0.speed }.max() ?? 0
                let timeSpan = speedHistory.last?.time ?? 1.0
                
                for (index, entry) in speedHistory.enumerated() {
                    let x = CGFloat(entry.time / timeSpan) * geometry.size.width
                    let y = geometry.size.height - (CGFloat(entry.speed / maxSpeed) * geometry.size.height)
                    
                    if index == 0 {
                        path.move(to: CGPoint(x: x, y: y))
                    } else {
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                }
            }
            .stroke(Color.red, lineWidth: 2)
        }
    }
}

struct PressedButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}
