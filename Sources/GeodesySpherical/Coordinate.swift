//
//  Coordinate.swift
//  swift-geodesy
//
//  Created by Florian Reinhart on 10/02/2017.
//
//

#if os(OSX) || os(iOS)
    import Darwin
#elseif os(Linux)
    import Glibc
#endif

public typealias Degrees = Double
public typealias Radians = Double
public typealias Distance = Double


public extension Degrees {
    public init(radians: Radians) {
        self = radians * 180 / Double.pi
    }
}

public extension Radians {
    public init(degrees: Degrees) {
        self = degrees * Double.pi / 180
    }
}

/// A coordinate consisting of latitude and longitude
public struct Coordinate {
    fileprivate static let earthRadius = Distance(6371e3)
    
    public var latitude: Degrees
    public var longitude: Degrees
    
    public init(latitude: Degrees, longitude: Degrees) {
        self.latitude = latitude
        self.longitude = longitude
    }
    
    public init(_ latitude: Degrees, _ longitude: Degrees) {
        self = Coordinate(latitude: latitude, longitude: longitude)
    }
}

extension Coordinate: Equatable {
    public static func ==(lhs: Coordinate, rhs: Coordinate) -> Bool {
        return lhs.latitude == rhs.latitude && lhs.longitude == rhs.longitude
    }
}

extension Coordinate: Hashable {
    public var hashValue: Int {
        // DJB Hash Function
        var hash = 5381
        hash = ((hash << 5) &+ hash) &+ self.latitude.hashValue
        hash = ((hash << 5) &+ hash) &+ self.longitude.hashValue
        return hash
    }
}

extension Coordinate: CustomStringConvertible {
    public var description: String {
        return "\(self.latitude),\(self.longitude)"
    }
}

public extension Coordinate {
    /**
     Calculates the distance to a destination coordinate in meters (using haversine formula).
     
     - Parameter coordinate: The destination coordinate
     
     - Returns: The distance from this coordinate to the destination in meters
     */
    public func distance(to coordinate: Coordinate) -> Double {
        let φ1 = Radians(degrees: self.latitude)
        let λ1 = Radians(degrees: self.longitude)
        let φ2 = Radians(degrees: coordinate.latitude)
        let λ2 = Radians(degrees: coordinate.longitude)
        let Δφ = φ2 - φ1
        let Δλ = λ2 - λ1
        
        let a = sin(Δφ/2) * sin(Δφ/2) + cos(φ1) * cos(φ2) * sin(Δλ/2) * sin(Δλ/2)
        let c = 2 * atan2(sqrt(a), sqrt(1-a))
        let d = Coordinate.earthRadius * c
        
        return d
    }

    /**
     Calculates the (initial) bearing to a destination.
     
     - Parameter to: The destination coordinate.
     
     - Returns: The *initial* bearing to the destination in degrees from north.
     */
    public func bearing(to coordinate: Coordinate) -> Double {
        let φ1 = Radians(degrees: self.latitude)
        let φ2 = Radians(degrees: coordinate.latitude)
        let Δλ = Radians(degrees: coordinate.longitude - self.longitude)
        
        // see http://mathforum.org/library/drmath/view/55417.html
        let y = sin(Δλ) * cos(φ2)
        let x = cos(φ1)*sin(φ2) - sin(φ1)*cos(φ2)*cos(Δλ)
        let θ = atan2(y, x)
        
        return (Degrees(radians: θ)+360).truncatingRemainder(dividingBy: 360)
    }


    /**
     Calculates the final bearing arriving at a destination.
     The final bearing will differ from the initial bearing by varying degrees according to distance and latitude.
     
     - Parameter to: The destination coordinate.
     
     - Returns: The *final* bearing to the destination in degrees from north.
     */
    public func finalBearing(to coordinate: Coordinate) -> Double {
        // get initial bearing from destination point to this point & reverse it by adding 180°
        return (coordinate.bearing(to: self) + 180).truncatingRemainder(dividingBy: 360)
    }
    
    /**
     Calculates the midpoint between *this* coordinate and the given coordinate.
     
     - Parameter to: The destination coordinate.
     
     - Returns: The midpoint between this coordinate and the given coordinate.
     */
    public func midpoint(to coordinate: Coordinate) -> Coordinate {
        // φm = atan2( sinφ1 + sinφ2, √( (cosφ1 + cosφ2⋅cosΔλ) ⋅ (cosφ1 + cosφ2⋅cosΔλ) ) + cos²φ2⋅sin²Δλ )
        // λm = λ1 + atan2(cosφ2⋅sinΔλ, cosφ1 + cosφ2⋅cosΔλ)
        // see http://mathforum.org/library/drmath/view/51822.html for derivation
        
        let φ1 = Radians(degrees: self.latitude)
        let λ1 = Radians(degrees: self.longitude)
        let φ2 = Radians(degrees: coordinate.latitude)
        let Δλ = Radians(degrees: coordinate.longitude - self.longitude)
        
        let Bx = cos(φ2) * cos(Δλ)
        let By = cos(φ2) * sin(Δλ)
        
        let x = sqrt((cos(φ1) + Bx) * (cos(φ1) + Bx) + By * By)
        let y = sin(φ1) + sin(φ2)
        let φ3 = atan2(y, x)
        
        let λ3 = λ1 + atan2(By, cos(φ1) + Bx)
        
        return Coordinate(latitude: Degrees(radians: φ3), longitude: (Degrees(radians: λ3) + 540).truncatingRemainder(dividingBy: 360) - 180) // normalise to −180..+180°
    }
    
    /**
     Calculates an intermediate point at a given fraction on the path between this coordinate and a given destination coordinate.
     
     - Parameter to: The destination coordinate.
     - Parameter fraction: The fraction between the two coordinate (0 = this coordinate, 1 = destination coordinate).
     
     - Returns: The intermediate coordinate between this coordinate and the destination.
     */
    public func intermediatePoint(to coordinate: Coordinate, fraction: Double) -> Coordinate {
        let φ1 = Radians(degrees: self.latitude)
        let λ1 = Radians(degrees: self.longitude)
        let φ2 = Radians(degrees: coordinate.latitude)
        let λ2 = Radians(degrees: coordinate.longitude)
        let sinφ1 = sin(φ1)
        let cosφ1 = cos(φ1)
        let sinλ1 = sin(λ1)
        let cosλ1 = cos(λ1)
        let sinφ2 = sin(φ2)
        let cosφ2 = cos(φ2)
        let sinλ2 = sin(λ2)
        let cosλ2 = cos(λ2)
        
        // distance between points
        let Δφ = φ2 - φ1
        let Δλ = λ2 - λ1
        let a = sin(Δφ/2) * sin(Δφ/2) + cos(φ1) * cos(φ2) * sin(Δλ/2) * sin(Δλ/2)
        let δ = 2 * atan2(sqrt(a), sqrt(1-a))
        
        let A = sin((1-fraction)*δ) / sin(δ)
        let B = sin(fraction*δ) / sin(δ)
        
        let x = A * cosφ1 * cosλ1 + B * cosφ2 * cosλ2
        let y = A * cosφ1 * sinλ1 + B * cosφ2 * sinλ2
        let z = A * sinφ1 + B * sinφ2
        
        let φ3 = atan2(z, sqrt(x*x + y*y))
        let λ3 = atan2(y, x)
        
        return Coordinate(latitude: Degrees(radians: φ3), longitude: (Degrees(radians: λ3) + 540).truncatingRemainder(dividingBy: 360) - 180) // normalise lon to −180..+180°
    }
    

    /**
     Calculates the destination coordinate from this coordinate having travelled the given distance on the given initial bearing (bearing normally varies around path followed).
     
     - Parameter distance Distance to travel in meters
     - Parameter bearing: The initial bearing in degrees from north
     
     - Returns: The destination coordinate
     */
    public func destination(with distance: Distance, bearing: Degrees) -> Coordinate {
        // sinφ2 = sinφ1⋅cosδ + cosφ1⋅sinδ⋅cosθ
        // tanΔλ = sinθ⋅sinδ⋅cosφ1 / cosδ−sinφ1⋅sinφ2
        // see http://williams.best.vwh.net/avform.htm#LL
        
        let δ = distance / Coordinate.earthRadius // angular distance in radians
        let θ = Radians(degrees: bearing)
        
        let φ1 = Radians(degrees: self.latitude)
        let λ1 = Radians(degrees: self.longitude)
        
        let sinφ1 = sin(φ1)
        let cosφ1 = cos(φ1)
        let sinδ = sin(δ)
        let cosδ = cos(δ)
        let sinθ = sin(θ)
        let cosθ = cos(θ)
        
        let sinφ2 = sinφ1 * cosδ + cosφ1 * sinδ * cosθ
        let φ2 = asin(sinφ2)
        let y = sinθ * sinδ * cosφ1
        let x = cosδ - sinφ1 * sinφ2
        let λ2 = λ1 + atan2(y, x)
        
        return Coordinate(latitude: Degrees(radians: φ2), longitude: (Degrees(radians: λ2) + 540).truncatingRemainder(dividingBy: 360) - 180) // normalise to −180..+180°
    }

    /**
     Calculates the point of intersection of two paths defined by coordinate and bearing.
     
     - Parameter path1: The first path, defined by coordinate and bearing
     - Parameter path1: The second path, defined by coordinate and bearing
     
     - Returns: The intersection coordinate or `nil` if there is no unique intersection
     */
    public static func intersection(of path1: (coordinate: Coordinate, bearing: Degrees), with path2: (coordinate: Coordinate, bearing: Degrees)) -> Coordinate? {
        // see http://williams.best.vwh.net/avform.htm#Intersection
        
        let φ1 = Radians(degrees: path1.coordinate.latitude)
        let λ1 = Radians(degrees: path1.coordinate.longitude)
        let φ2 = Radians(degrees: path2.coordinate.latitude)
        let λ2 = Radians(degrees: path2.coordinate.longitude)
        let θ13 = Radians(degrees: path1.bearing)
        let θ23 = Radians(degrees: path2.bearing)
        let Δφ = φ2-φ1
        let Δλ = λ2-λ1
        
        let δ12 = 2*asin( sqrt( sin(Δφ/2)*sin(Δφ/2) + cos(φ1)*cos(φ2)*sin(Δλ/2)*sin(Δλ/2) ) )
        
        guard δ12 != 0 else {
            return nil
        }
        
        // initial/final bearings between points
        var θa = acos( ( sin(φ2) - sin(φ1)*cos(δ12) ) / ( sin(δ12)*cos(φ1) ) )
        if θa.isNaN {
            θa = 0 // protect against rounding
        }
        let θb = acos( ( sin(φ1) - sin(φ2)*cos(δ12) ) / ( sin(δ12)*cos(φ2) ) )
        
        let θ12 = sin(λ2-λ1)>0 ? θa : 2*Double.pi-θa
        let θ21 = sin(λ2-λ1)>0 ? 2*Double.pi-θb : θb
        
        let α1 = (θ13 - θ12 + Double.pi).truncatingRemainder(dividingBy: 2*Double.pi) - Double.pi // angle 2-1-3
        let α2 = (θ21 - θ23 + Double.pi).truncatingRemainder(dividingBy: 2*Double.pi) - Double.pi // angle 1-2-3
        
        // This is actually testing for: sin(α1) != 0 || sin(α2) != 0
        // However, due to the nature of floating point values sin(n * Double.pi) is not 0.
        // Since we know that sin(x) is 0 whenever x is a multitude of π, we can truncate the remainder by Double.pi and get an accurate result.
        guard α1.truncatingRemainder(dividingBy: Double.pi) != 0 || α2.truncatingRemainder(dividingBy: Double.pi) != 0 else {
            return nil // infinite intersections
        }
        guard sin(α1) * sin(α2) >= 0 else {
            return nil // ambiguous intersection
        }
        
        //α1 = abs(α1)
        //α2 = abs(α2)
        // ... Ed Williams takes abs of α1/α2, but seems to break calculation?
        
        let α3 = acos( -cos(α1)*cos(α2) + sin(α1)*sin(α2)*cos(δ12) )
        let δ13 = atan2( sin(δ12)*sin(α1)*sin(α2), cos(α2)+cos(α1)*cos(α3) )
        let φ3 = asin( sin(φ1)*cos(δ13) + cos(φ1)*sin(δ13)*cos(θ13) )
        let Δλ13 = atan2( sin(θ13)*sin(δ13)*cos(φ1), cos(δ13)-sin(φ1)*sin(φ3) )
        let λ3 = λ1 + Δλ13
        
        return Coordinate(latitude: Degrees(radians: φ3), longitude: (Degrees(radians: λ3) + 540).truncatingRemainder(dividingBy: 360) - 180) // normalise to −180..+180°
    }
    
    /**
     Calculates the (signed) distance to a great circle defined by start and end coordinate.
     
     - Parameter pathStart: The start coordinate of the great circle path.
     - Parameter pathStart: The end coordinate of the great circle path.
     
     - Returns: The distance to the great circle (-ve if to left, +ve if to right of path).
     */
    public func crossTrackDistanceToPath(from pathStart: Coordinate, to pathEnd: Coordinate) -> Distance {
        let δ13 = pathStart.distance(to: self) / Coordinate.earthRadius
        let θ13 = Radians(degrees: pathStart.bearing(to: self))
        let θ12 = Radians(degrees: pathStart.bearing(to: pathEnd))
        
        let δ = asin( sin(δ13) * sin(θ13-θ12) )
        
        return δ * Coordinate.earthRadius
    }
    
    /**
     Calculates the maximum latitude reached when travelling on a great circle on given bearing ('Clairaut's formula').
     Negate the result for the minimum latitude (in the Southern hemisphere).
     
     The maximum latitude is independent of longitude it will be the same for all points on a given latitude.
     
     - Parameter bearing: The initial bearing.
     
     - Returns: The maxium latitude reached.
     */
    public func maxLatitude(with bearing: Degrees) -> Degrees {
        let θ = Radians(degrees: bearing)
        
        let φ = Radians(degrees: self.latitude)
        
        let φMax = acos(abs(sin(θ)*cos(φ)))
        
        return Degrees(radians: φMax)
    }
    
    /**
     Calculates the pair of meridians at which a great circle defined by two coordinates crosses the given latitude.
     If the great circle doesn't reach the given latitude, `nil` is returned.
     
     - Parameter coordinate1: The first coordinate defining the great circle path.
     - Parameter coordinate2: The second coordinate defining the great circle path.
     - Parameter latitude: The latitude crossings are to be determined for.
     
     - Returns: A tupel containing to longitude values or `nil` if the given latitude is not reached.
     */
    public static func crossingParallels(coordinate1: Coordinate, coordinate2: Coordinate, latitude: Degrees) -> (longitude1: Degrees, longitude2: Degrees)? {
        let φ = Radians(degrees: latitude)
    
        let φ1 = Radians(degrees: coordinate1.latitude)
        let λ1 = Radians(degrees: coordinate1.longitude)
        let φ2 = Radians(degrees: coordinate2.latitude)
        let λ2 = Radians(degrees: coordinate2.longitude)
        
        let Δλ = λ2 - λ1
        
        let x = sin(φ1) * cos(φ2) * cos(φ) * sin(Δλ)
        let y = sin(φ1) * cos(φ2) * cos(φ) * cos(Δλ) - cos(φ1) * sin(φ2) * cos(φ)
        let z = cos(φ1) * cos(φ2) * sin(φ) * sin(Δλ)
        
        guard z*z <= x*x + y*y else {
            return nil // great circle doesn't reach latitude
        }
        
        let λm = atan2(-y, x) // longitude at max latitude
        let Δλi = acos(z / sqrt(x*x+y*y)) // Δλ from λm to intersection points
        
        let λi1 = λ1 + λm - Δλi
        let λi2 = λ1 + λm + Δλi
        
        return (longitude1: (Degrees(radians: λi1) + 540).truncatingRemainder(dividingBy: 360) - 180, // normalise to −180..+180°
                longitude2: (Degrees(radians:λi2) + 540).truncatingRemainder(dividingBy: 360) - 180) // normalise to −180..+180°
    }
}
