//
//  LocationManager.swift
//  ChatApplication
//
//  Created by hamed on 8/30/22.
//

import MapKit

enum MapDetails {
    static let startingPoint = CLLocationCoordinate2D(latitude: 42.0422448, longitude: -102.0079053)
    static let defaultSpan = MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
}

final class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {

    private var locationManager: CLLocationManager?

    @Published var region = MKCoordinateRegion(
        center: MapDetails.startingPoint,
        span: MapDetails.defaultSpan
    )

    @Published
    var error: String? = nil

    @Published var userTappedSelectedCoordinate: CLLocationCoordinate2D? = nil

    func checkIfLocatioServiceIsEnabled() {
        if CLLocationManager.locationServicesEnabled() {
            locationManager = CLLocationManager()
            locationManager?.delegate = self
        } else {
            error = "The location service on this device is entirely disabled."
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else { return }
        DispatchQueue.main.async {
            self.region = MKCoordinateRegion(
                center: location.coordinate,
                span: MapDetails.defaultSpan
            )
        }
    }

    private func checkLocationAuthorizaiton() {
        guard let locationManager = locationManager else { return }

        switch locationManager.authorizationStatus {

        case .notDetermined:
            locationManager.requestAlwaysAuthorization()
        case .restricted:
            error = "Accessa is restricted may be via parental control."
        case .denied:
            error = "You have denied this app locaiton permission. Go into settings to enable it."
        case .authorizedAlways, .authorizedWhenInUse:
            locationManager.startUpdatingLocation()
            break
        @unknown default:
            break
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        checkLocationAuthorizaiton()
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        self.error = error.localizedDescription
    }
}
