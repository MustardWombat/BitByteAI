import Foundation
import CoreLocation

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    static let shared = LocationManager()
    
    private let locationManager = CLLocationManager()
    @Published var currentLocationName: String = "unknown"
    
    private override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyReduced // Coarse accuracy for privacy
        locationManager.requestWhenInUseAuthorization()
    }
    
    func requestLocationPermission() {
        locationManager.requestWhenInUseAuthorization()
    }
    
    func startUpdatingLocation() {
        locationManager.startUpdatingLocation()
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        if manager.authorizationStatus == .authorizedWhenInUse || manager.authorizationStatus == .authorizedAlways {
            locationManager.startUpdatingLocation()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        // Reverse geocode to get a general location name
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(location) { [weak self] (placemarks, error) in
            guard error == nil, let placemark = placemarks?.first else {
                self?.currentLocationName = "unknown"
                return
            }
            
            // Use a general location category for privacy
            if placemark.thoroughfare != nil {
                self?.currentLocationName = "home" // Assume home if we have a street address
            } else if placemark.areasOfInterest?.first != nil {
                self?.currentLocationName = "public_place"
            } else if placemark.locality != nil {
                self?.currentLocationName = "city"
            } else {
                self?.currentLocationName = "unknown"
            }
        }
    }
}
