//
//  MapPickerView.swift
//  Talk
//
//  Created by hamed on 3/14/23.
//

import Chat
import MapKit
import SwiftUI
import TalkModels
import TalkUI
import TalkViewModels

struct MapPickerView: View {
    @Environment(\.dismiss) var dismiss
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
                SubmitBottomButton(text: "General.add") {
                    if let location = locationManager.currentLocation {
                        viewModel.attachmentsViewModel.append(attachments: [.init(type: .map, request: location)])
                    }
                    viewModel.sheetType = nil
                    viewModel.animateObjectWillChange()
                }
                .environmentObject(viewModel)
            }
        }
        .overlay(alignment: .topTrailing) {
            Button {
                withAnimation {
                    viewModel.sheetType = nil
                    viewModel.animateObjectWillChange()
                    dismiss()
                }
            } label: {
                Image(systemName: "xmark")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 16, height: 16)
                    .padding()
                    .foregroundColor(Color.App.accent)
                    .aspectRatio(contentMode: .fit)
                    .contentShape(Rectangle())
            }
            .frame(width: 40, height: 40)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius:(20)))
            .padding(4)
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
                self?.currentLocation = .init(name: String(localized: .init("Map.mayLocation")), description: String(localized: .init("Map.hereIAm")), location: currentLocation.coordinate)
                self?.region.center = currentLocation.coordinate
            }
        }
    }

    func locationManager(_: CLLocationManager, didFailWithError error: Error) {
    }
}

struct MapView_Previews: PreviewProvider {
    static var previews: some View {
        MapPickerView()
    }
}
