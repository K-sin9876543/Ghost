
import SwiftUI
import MapKit
import Firebase
import FirebaseAuth
struct MapScreen: View {
    @State private var runs: [Run] = []
    @State private var selectedColor: Color = ThemeManager().accentColor
    @State private var selectedRun: Run?
    @State private var region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 0, longitude: 0), latitudinalMeters: 1000, longitudinalMeters: 1000)
    
    var body: some View {
        NavigationView {
            VStack {
                ScrollView {
                    LazyVStack(spacing: 0) { // Removed spacing to make cells contiguous
                        // Iterate over runs and display a map cell for each
                        ForEach(runs) { run in
                            NavigationLink(destination: RunDetailView(run: run)) {
                                RunCell(run: run)
                                    .frame(maxWidth: .infinity) // Make the cell take up the full width
                                    .padding(.vertical, 10)
                                    .background(Color.clear) // Optional, add a background to visually separate the cells
                                    .overlay(
                                        Rectangle() // Horizontal line to separate the cells
                                            .frame(height: 1)
                                            .foregroundColor(selectedColor)
                                            .padding(.horizontal)
                                            .padding(.top, 10) // Space between cell content and the line
                                        , alignment: .bottom
                                    )
                            }
                            .buttonStyle(PlainButtonStyle()) // To remove default button styles
                        }
                    }
                }
            }
            //.navigationBarTitle("My Runs")
            .onAppear(perform: loadRuns)
        }
        .navigationBarTitle("My Runs")
        .edgesIgnoringSafeArea(.bottom) // Ensure the view fills the entire space including navigation area
    }
    
    // Load previous runs from Firebase
    private func loadRuns() {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("User ID not available.")
            return
        }
        
        let ref = Database.database().reference().child("users").child(userId)
        
        ref.observeSingleEvent(of: .value) { snapshot in
            guard let userData = snapshot.value as? [String: Any],
                  let userName = userData["username"] as? String,
                  let drives = userData["drives"] as? [String: [String: Any]] else {
                print("Failed to fetch user data or drives.")
                return
            }
            
            var loadedRuns: [Run] = []
            for (_, runDict) in drives {
                if let run = Run(from: runDict, userName: userName) {
                    loadedRuns.append(run)
                }
            }
            runs = loadedRuns.sorted(by: { $0.date > $1.date }) // Sort by date (newest first)
        }
    }
}

// A vertical cell that shows a map and two key stats
struct RunCell: View {
    var run: Run
    
    @State private var region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 0, longitude: 0), latitudinalMeters: 1000, longitudinalMeters: 1000)
    
    var body: some View {
        VStack(alignment: .leading) {
            // Miniature map showing the route of the run
            RunMap(routeCoordinates: run.routeCoordinates, region: $region)
                .frame(height: 200)
                .cornerRadius(10)
            
            HStack {
                Text("Distance: \(String(format: "%.2f", run.distance)) miles")
                Spacer()
                Text("Top Speed: \(String(format: "%.2f", run.topSpeed)) mph")
            }
            .font(.headline)
            .padding(.horizontal)
        }
        .onAppear {
            if let firstCoordinate = run.routeCoordinates.first {
                region = MKCoordinateRegion(center: firstCoordinate, latitudinalMeters: 1000, longitudinalMeters: 1000)
            }
        }
    }
}

// Detail view showing full details for the run
struct RunDetailView: View {
    var run: Run
    
    @State private var region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 0, longitude: 0), latitudinalMeters: 1000, longitudinalMeters: 1000)
    @State private var animateProgress = false
    
    var body: some View {
        VStack(spacing: 0) {
            // User name and date at the top
            HStack {
                Text(run.userName)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .padding(.leading, 10)
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("Date")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text(formatDate(run.date))
                        .font(.headline)
                        .bold()
                }
                .padding(.trailing, 10)
            }
            .padding(.top, 10) // Padding from the top edge
            
            // Full map showing the route
            RunMap(routeCoordinates: run.routeCoordinates, region: $region)
                .frame(height: 400) // Increase height of the map
                .cornerRadius(10)
                .padding(.horizontal, -16) // Extend to screen edges
                .ignoresSafeArea(edges: .horizontal)
            
            // Stats for the run in a 1x3 layout
            HStack(spacing: 20) {
                CircularProgressBar(
                    value: .constant(animateProgress ? run.topSpeed : 0),
                    maxValue: 200,
                    label: "Top Speed",
                    unit: "mph"
                )
                .frame(width: 100, height: 100)
                
                CircularProgressBar(
                    value: .constant(animateProgress ? run.distance : 0),
                    maxValue: 50,
                    label: "Distance",
                    unit: "mi"
                )
                .frame(width: 100, height: 100)
                
                CircularProgressBar(
                    value: .constant(animateProgress ? run.duration / 60 : 0),
                    maxValue: 120,
                    label: "Duration",
                    unit: "min"
                )
                .frame(width: 100, height: 100)
            }
            .padding(.top, 10)
        }
        .padding(.horizontal)
        .navigationBarTitle("Run Details", displayMode: .inline)
        .onAppear {
            if let firstCoordinate = run.routeCoordinates.first {
                region = MKCoordinateRegion(center: firstCoordinate, latitudinalMeters: 1000, longitudinalMeters: 1000)
            }
            
            // Animate progress bars
            withAnimation(.easeOut(duration: 3.0)) {
                animateProgress = true
            }
        }
    }
    
    private func formatDate(_ timestamp: TimeInterval) -> String {
        let date = Date(timeIntervalSince1970: timestamp)
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}






struct Run: Identifiable {
    let id = UUID()
    let date: TimeInterval
    let routeCoordinates: [CLLocationCoordinate2D]
    let distance: Double
    let topSpeed: Double
    let duration: TimeInterval
    let userName: String // Add this property to store the user's name
    
    // Initialize run data from Firebase
    init?(from dict: [String: Any], userName: String) {
        guard let date = dict["date"] as? TimeInterval,
              let routeArray = dict["route"] as? [[String: Double]],
              let distance = dict["distance"] as? Double,
              let topSpeed = dict["topSpeed"] as? Double,
              let duration = dict["duration"] as? TimeInterval else {
            return nil
        }
        
        self.date = date
        self.distance = distance
        self.topSpeed = topSpeed
        self.duration = duration
        self.userName = userName // Assign the user name
        
        self.routeCoordinates = routeArray.compactMap { coord in
            if let lat = coord["lat"], let lng = coord["lng"] {
                return CLLocationCoordinate2D(latitude: lat, longitude: lng)
            }
            return nil
        }
    }
}

// A MapView to display the route of a selected run
struct RunMap: UIViewRepresentable {
    var routeCoordinates: [CLLocationCoordinate2D]
    @Binding var region: MKCoordinateRegion
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        return mapView
    }
    
    func updateUIView(_ mapView: MKMapView, context: Context) {
        mapView.removeOverlays(mapView.overlays)
        
        if routeCoordinates.count > 1 {
            let polyline = MKPolyline(coordinates: routeCoordinates, count: routeCoordinates.count)
            mapView.addOverlay(polyline)
        }
        
        mapView.setRegion(region, animated: true)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: RunMap
        
        init(_ parent: RunMap) {
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
