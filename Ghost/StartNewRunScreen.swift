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

    var body: some View {
        VStack {
            // Map displaying the route and user's current location
            MapView(routeCoordinates: $routeCoordinates, startLocation: $startLocation, endLocation: $endLocation)
                .frame(height: 300)
                .cornerRadius(10)
            
            // Live Stats
            VStack(spacing: 20) {
                Text("Current Speed: \(String(format: "%.2f", currentSpeed)) mph")
                Text("Top Speed: \(String(format: "%.2f", topSpeed)) mph")
                Text("Distance: \(String(format: "%.2f", distanceTraveled)) miles")
                Text("Time: \(formatElapsedTime(elapsedTime))") // Display the elapsed time
            }
            .font(.headline)
            .padding()
            
            Spacer()
            
            // Start/Stop Button
            Button(action: {
                isTracking.toggle()
                if isTracking {
                    // Start run
                    startRun()
                } else {
                    // Stop run
                    stopRun()
                }
            }) {
                Text(isTracking ? "Stop Run" : "Start Run")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isTracking ? Color.red : Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .padding(.horizontal)
            }
            
            // Save Button (Only appears after run stops)
            if !isTracking && !routeCoordinates.isEmpty {
                Button(action: saveRun) {
                    Text("Save Run")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(selectedColor)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .padding(.horizontal)
                }
            }
            
            Spacer()
        }
        .onAppear {
            locationManager.checkPermissions()
        }
    }
    
    // Update stats during the run
    private func updateRunStats(with location: CLLocation) {
        routeCoordinates.append(location.coordinate)
        currentSpeed = max(location.speed * 2.23694, 0) // Convert m/s to mph, ensure no negative speed
        topSpeed = max(topSpeed, currentSpeed)
        
        if routeCoordinates.count > 1 {
            let lastLocation = CLLocation(latitude: routeCoordinates[routeCoordinates.count - 2].latitude, longitude: routeCoordinates[routeCoordinates.count - 2].longitude)
            distanceTraveled += location.distance(from: lastLocation) / 1609.34 // Convert meters to miles
        }
    }
    
    // Start the run and the timer
    private func startRun() {
        locationManager.startTracking { location in
            updateRunStats(with: location)
        }
        startLocation = routeCoordinates.last // Save start location
        startTime = Date()
        startTimer()
    }
    
    // Stop the run and the timer
    private func stopRun() {
        locationManager.stopTracking()
        endLocation = routeCoordinates.last // Save end location
        stopTimer()
    }
    
    // Start the timer
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if let startTime = startTime {
                elapsedTime = Date().timeIntervalSince(startTime)
            }
        }
    }
    
    // Stop the timer
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    // Format elapsed time as hh:mm:ss
    private func formatElapsedTime(_ time: TimeInterval) -> String {
        let hours = Int(time) / 3600
        let minutes = (Int(time) % 3600) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
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
