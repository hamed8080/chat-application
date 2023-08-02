//
//  MapPickerView.swift
//  ChatApplication
//
//  Created by hamed on 3/14/23.
//

import Chat
import ChatAppModels
import ChatAppUI
import ChatAppViewModels
import MapKit
import SwiftUI

struct MapPickerView: View {
    @StateObject var locationManager: LocationManager = .init()
    @EnvironmentObject var viewModel: ThreadViewModel

    var body: some View {
        ZStack {
            Map(coordinateRegion: $locationManager.region,
                interactionModes: .all,
                showsUserLocation: true,
                annotationItems: [locationManager.currentLocation].compactMap { $0 }) { item in
                    MapMarker(coordinate: item.location)
                }
            VStack {
                Spacer()
                SendTextViewWithButtons {
                    if let location = locationManager.currentLocation {
                        viewModel.sendLoaction(location)
                    }
                    viewModel.sheetType = nil
                    viewModel.animateObjectWillChange()
                } onCancel: {
                    viewModel.sheetType = nil
                    viewModel.animateObjectWillChange()
                }
                .environmentObject(viewModel)
            }
        }
    }
}

final class LocationManager: NSObject, CLLocationManagerDelegate, ObservableObject {
    @Published var currentLocation: LocationItem?
    let manager = CLLocationManager()
    @Published var region: MKCoordinateRegion = .init(center: CLLocationCoordinate2D(latitude: 51.507222,
                                                                                     longitude: -0.1275),
                                                      span: MKCoordinateSpan(latitudeDelta: 0.005,
                                                                             longitudeDelta: 0.005))

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        manager.requestAlwaysAuthorization()
        manager.startUpdatingLocation()
    }

    func locationManager(_: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        DispatchQueue.main.async { [weak self] in
            if let currentLocation = locations.first, MKMapPoint(currentLocation.coordinate).distance(to: MKMapPoint(self?.currentLocation?.location ?? CLLocationCoordinate2D())) > 100 {
                self?.currentLocation = .init(name: "My location", description: "I'm here!", location: currentLocation.coordinate)
                self?.region.center = currentLocation.coordinate
            }
        }
    }

    func locationManager(_: CLLocationManager, didFailWithError error: Error) {
        print(error)
    }
}

struct MapView_Previews: PreviewProvider {
    static var previews: some View {
        MapPickerView()
    }
}
