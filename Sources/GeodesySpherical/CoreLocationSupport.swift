//
//  CoreLocationSupport.swift
//  swift-geodesy
//
//  Created by Florian Reinhart on 19/06/2024.
//

#if canImport(CoreLocation)

import CoreLocation

public extension Coordinate {
    init(_ coordinate: CLLocationCoordinate2D) {
        self.init(coordinate.latitude, coordinate.longitude)
    }
    
    init(_ location: CLLocation) {
        self.init(location.coordinate)
    }
    
    var clLocationCoordinate2D: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    var clLocation: CLLocation {
        CLLocation(latitude: latitude, longitude: longitude)
    }
}

#endif
