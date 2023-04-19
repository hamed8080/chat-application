//
//  Coordinate+.swift
//  ChatApplication
//
//  Created by hamed on 3/14/23.
//

import ChatDTO
import MapKit

public extension Coordinate {
    var location: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: lat, longitude: lng)
    }
}

extension Coordinate: Identifiable {
    public var id: String {
        "\(lat),\(lng)"
    }
}
