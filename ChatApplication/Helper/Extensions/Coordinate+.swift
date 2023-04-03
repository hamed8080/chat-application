//
//  Coordinate+.swift
//  ChatApplication
//
//  Created by hamed on 3/14/23.
//

import Chat
import MapKit

extension Coordinate {
    var location: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: lat, longitude: lng)
    }
}

extension Coordinate: Identifiable {
    public var id: String {
        "\(lat),\(lng)"
    }
}
