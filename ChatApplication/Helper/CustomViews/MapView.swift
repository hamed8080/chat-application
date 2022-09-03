//
//  MapView.swift
//  ChatApplication
//
//  Created by hamed on 8/29/22.
//

import SwiftUI
import FanapPodChatSDK
import MapKit
import Foundation

struct MapView: View {

    @StateObject
    var locationManager = LocationManager()
    var onCompletionLocation: ((CLLocationCoordinate2D)->())? = nil

    var body: some View {
        VStack {
            WrapMapview(locationManager: locationManager)
            Spacer()
            VStack {
                Button {
                    onCompletionLocation?(locationManager.region.center)
                } label: {
                    HStack {
                        Text("Current location".uppercased())
                            .font(.footnote.bold())
                        Image(systemName: "location.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 16, height: 16)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 24)
                    .padding(4)
                }

                Button {
                    if let coordinate = locationManager.userTappedSelectedCoordinate {
                        onCompletionLocation?(coordinate)
                    }
                } label: {
                    HStack {
                        Text("Selected Mark".uppercased())
                            .font(.footnote.bold())
                        Image(systemName: "pin.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 16, height: 16)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 24)
                    .padding(4)
                }
                .disabled(locationManager.userTappedSelectedCoordinate == nil)
            }
            .buttonStyle(.bordered)
            .padding()
        }
        .alert(Text("\(locationManager.error ?? "")"), isPresented: Binding(get: { return locationManager.error != nil }, set: {_ in}), actions: {
            Button("OK") {}
        })
        .onReceive(locationManager.$error, perform: { error in
            print("An error happened in Location Manager: \(error ?? "")")
        })
        .onAppear {
            locationManager.checkIfLocatioServiceIsEnabled()
        }
    }
}

struct WrapMapview: UIViewRepresentable{

    @StateObject
    var locationManager: LocationManager
    var mkMapView = MKMapView(frame: .zero)

    func makeUIView(context: Context) -> some UIView {
        mkMapView.showsUserLocation = true
        mkMapView.delegate = context.coordinator
        let gestureRecognizer = UITapGestureRecognizer(target: context.coordinator, action: #selector(MapCordinator.onLongPressOnMapView(_:)))
        mkMapView.addGestureRecognizer(gestureRecognizer)
        mkMapView.setRegion(locationManager.region, animated: true)
        return mkMapView
    }

    func updateUIView(_ uiView: UIViewType, context: Context) {
        mkMapView.setRegion(locationManager.region, animated: true)
    }

    func makeCoordinator() -> MapCordinator {
        return MapCordinator(mapView: mkMapView, locationManager: locationManager)
    }

    final class MapCordinator: NSObject, MKMapViewDelegate {

        var mapView: MKMapView
        var locationManager: LocationManager

        init(mapView: MKMapView, locationManager: LocationManager) {
            self.mapView = mapView
            self.locationManager = locationManager
        }

        func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
            let latDelta:CLLocationDegrees = 0.02
            let lonDelta:CLLocationDegrees = 0.02
            let span = MKCoordinateSpan(latitudeDelta: latDelta, longitudeDelta: lonDelta)
            let region = MKCoordinateRegion(center: userLocation.coordinate, span: span)
            mapView.setRegion(region, animated: true)
        }

        @objc func onLongPressOnMapView(_ gestureRecognizer : UILongPressGestureRecognizer) {

            if gestureRecognizer.state == .ended {
                mapView.removeAnnotations(mapView.annotations)
                let touchLocation = gestureRecognizer.location(in: mapView)
                let location = mapView.convert(touchLocation, toCoordinateFrom: mapView)
                locationManager.userTappedSelectedCoordinate = location
                let annotation = MKPointAnnotation()
                annotation.coordinate = location
                annotation.title = "Latitude: \(location.latitude), Longitude: \(location.longitude)"
                let coder = CLGeocoder()
                coder.reverseGeocodeLocation(CLLocation(latitude: location.latitude, longitude: location.longitude)) { addresses, error in
                    if let address = addresses?.first {
                        annotation.title = address.name
                    }
                }
                mapView.addAnnotation(annotation)
            }
        }
    }
}
struct MapView_Previews: PreviewProvider {
    static var previews: some View {
        MapView()
            .preferredColorScheme(.light)
    }
}
