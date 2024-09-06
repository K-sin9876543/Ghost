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
            }
            .font(.headline)
            .padding()
            
            Spacer()
            
            // Start/Stop Button
            Button(action: {
                isTracking.toggle()
                if isTracking {
                    // Start run
                    locationManager.startTracking { location in
                        updateRunStats(with: location)
                    }
                    startLocation = routeCoordinates.last // Save start location
                } else {
                    // Stop run
                    locationManager.stopTracking()
                    endLocation = routeCoordinates.last // Save end location
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
    
    // Save run data to Firebase
    private func saveRun() {
        let userId = Auth.auth().currentUser?.uid ?? "unknown_user"
        let ref = Database.database().reference().child("users").child(userId).child("drives").childByAutoId()
        
        let runData: [String: Any] = [
            "route": routeCoordinates.map { ["lat": $0.latitude, "lng": $0.longitude] },
            "topSpeed": topSpeed,
            "distance": distanceTraveled,
            "date": Date().timeIntervalSince1970,
            "startLocation": ["lat": startLocation?.latitude ?? 0.0, "lng": startLocation?.longitude ?? 0.0],
            "endLocation": ["lat": endLocation?.latitude ?? 0.0, "lng": endLocation?.longitude ?? 0.0]
        ]
        
        ref.setValue(runData) { error, _ in
            if let error = error {
                print("Error saving run: \(error.localizedDescription)")
            } else {
                print("Run saved successfully")
                resetRun()
            }
        }
    }
    
    // Reset data after saving
    private func resetRun() {
        routeCoordinates.removeAll()
        currentSpeed = 0.0
        topSpeed = 0.0
        distanceTraveled = 0.0
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
    }
    
    func checkPermissions() {
        if CLLocationManager.locationServicesEnabled() {
            locationManager.requestWhenInUseAuthorization()
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
            return MKOverlayRenderer()
        }
    }
}
