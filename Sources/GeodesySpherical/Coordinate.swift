//
//  Coordinate.swift
//  swift-geodesy
//
//  Created by Florian Reinhart on 10/02/2017.
//
//

#if os(OSX) || os(iOS) || os(visionOS)
    import Darwin
#elseif os(Linux)
    import Glibc
#endif

public typealias Degrees = Double
public typealias Radians = Double
public typealias Distance = Double

internal extension Double {
    var sign: Double {
        if self < 0 {
            return -1
        } else if self == 0 {
            return 0
        } else {
             return 1
        }
    }
}

public extension Degrees {
    init(radians: Radians) {
        self = radians * 180 / Double.pi
    }
}

public extension Radians {
    init(degrees: Degrees) {
        self = degrees * Double.pi / 180
    }
}

/// A coordinate consisting of latitude and longitude
public struct Coordinate: Equatable, Hashable {
    /// Radius of the earth in meters: 6,371,000m
    public static let earthRadius = Distance(6371e3)
    
    public var latitude: Degrees
    public var longitude: Degrees
    
    public init(latitude: Degrees, longitude: Degrees) {
        self.latitude = latitude
        self.longitude = longitude
    }
    
    public init(_ latitude: Degrees, _ longitude: Degrees) {
        self.init(latitude: latitude, longitude: longitude)
    }
    
    #if swift(>=4.1)
    // Use default implementation of Equatable and Hashable
    #else
    public static func ==(lhs: Coordinate, rhs: Coordinate) -> Bool {
        return lhs.latitude == rhs.latitude && lhs.longitude == rhs.longitude
    }
    
    public var hashValue: Int {
        // DJB Hash Function
        var hash = 5381
        hash = ((hash << 5) &+ hash) &+ self.latitude.hashValue
        hash = ((hash << 5) &+ hash) &+ self.longitude.hashValue
        return hash
    }
    #endif
}

extension Coordinate: CustomStringConvertible {
    public var description: String {
        return "\(self.latitude),\(self.longitude)"
    }
}

extension Coordinate: LosslessStringConvertible {
    public init?(_ description: String) {
        let components = description.split(separator: ",")
        guard components.count == 2,
            let latitude = Degrees(components[0]),
            let longitude = Degrees(components[1]) else {
                return nil
        }
        
        self.init(latitude: latitude, longitude: longitude)
    }
}

public extension Coordinate {
    /**
     Calculates the distance to a destination coordinate in meters (using haversine formula).
     
     - Parameter coordinate: The destination coordinate
     - Parameter radius: (Mean) radius of earth (defaults to radius in meters).
     
     - Returns: The distance from this coordinate to the destination in meters
     */
    func distance(to coordinate: Coordinate, radius: Distance = Coordinate.earthRadius) -> Distance {
        // a = sin²(Δφ/2) + cos(φ1)⋅cos(φ2)⋅sin²(Δλ/2)
        // tanδ = √(a) / √(1−a)
        // see http://mathforum.org/library/drmath/view/51879.html for derivation
        
        let φ1 = Radians(degrees: self.latitude)
        let λ1 = Radians(degrees: self.longitude)
        let φ2 = Radians(degrees: coordinate.latitude)
        let λ2 = Radians(degrees: coordinate.longitude)
        let Δφ = φ2 - φ1
        let Δλ = λ2 - λ1
        
        let a = sin(Δφ / 2) * sin(Δφ / 2)
            + cos(φ1) * cos(φ2)
            * sin(Δλ / 2) * sin(Δλ / 2)
        let c = 2 * atan2(sqrt(a), sqrt(1 - a))
        let d = radius * c
        
        return d
    }

    /**
     Calculates the (initial) bearing to a destination.
     
     - Parameter coordinate: The destination coordinate.
     
     - Returns: The *initial* bearing to the destination in degrees from north.
     */
    func bearing(to coordinate: Coordinate) -> Degrees {
        // tanθ = sinΔλ⋅cosφ2 / cosφ1⋅sinφ2 − sinφ1⋅cosφ2⋅cosΔλ
        // see http://mathforum.org/library/drmath/view/55417.html for derivation
        
        let φ1 = Radians(degrees: self.latitude)
        let φ2 = Radians(degrees: coordinate.latitude)
        let Δλ = Radians(degrees: coordinate.longitude - self.longitude)
        
        let y = sin(Δλ) * cos(φ2)
        let x = cos(φ1)*sin(φ2)
            - sin(φ1) * cos(φ2) * cos(Δλ)
        let θ = atan2(y, x)
        
        return (Degrees(radians: θ) + 360).truncatingRemainder(dividingBy: 360)
    }


    /**
     Calculates the final bearing arriving at a destination.
     The final bearing will differ from the initial bearing by varying degrees according to distance and latitude.
     
     - Parameter coordinate: The destination coordinate.
     
     - Returns: The *final* bearing to the destination in degrees from north.
     */
    func finalBearing(to coordinate: Coordinate) -> Degrees {
        // get initial bearing from destination point to this point & reverse it by adding 180°
        return (coordinate.bearing(to: self) + 180).truncatingRemainder(dividingBy: 360)
    }
    
    /**
     Calculates the midpoint between *this* coordinate and the given coordinate.
     
     - Parameter coordinate: The destination coordinate.
     
     - Returns: The midpoint between this coordinate and the given coordinate.
     */
    func midpoint(to coordinate: Coordinate) -> Coordinate {
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
    func intermediatePoint(to coordinate: Coordinate, fraction: Double) -> Coordinate {
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
        let a = sin(Δφ / 2) * sin(Δφ / 2) + cos(φ1) * cos(φ2) * sin(Δλ / 2) * sin(Δλ / 2)
        let δ = 2 * atan2(sqrt(a), sqrt(1-a))
        
        let A = sin((1-fraction) * δ) / sin(δ)
        let B = sin(fraction * δ) / sin(δ)
        
        let x = A * cosφ1 * cosλ1 + B * cosφ2 * cosλ2
        let y = A * cosφ1 * sinλ1 + B * cosφ2 * sinλ2
        let z = A * sinφ1 + B * sinφ2
        
        let φ3 = atan2(z, sqrt(x * x + y * y))
        let λ3 = atan2(y, x)
        
        return Coordinate(latitude: Degrees(radians: φ3), longitude: (Degrees(radians: λ3) + 540).truncatingRemainder(dividingBy: 360) - 180) // normalise lon to −180..+180°
    }
    

    /**
     Calculates the destination coordinate from this coordinate having travelled the given distance on the given initial bearing (bearing normally varies around path followed).
     
     - Parameter distance Distance to travel in meters
     - Parameter bearing: The initial bearing in degrees from north
     - Parameter radius: (Mean) radius of earth (defaults to radius in meters).
     
     - Returns: The destination coordinate
     */
    func destination(with distance: Distance, bearing: Degrees, radius: Distance = Coordinate.earthRadius) -> Coordinate {
        // sinφ2 = sinφ1⋅cosδ + cosφ1⋅sinδ⋅cosθ
        // tanΔλ = sinθ⋅sinδ⋅cosφ1 / cosδ−sinφ1⋅sinφ2
        // see http://mathforum.org/library/drmath/view/52049.html for derivation
        
        let δ = distance / radius // angular distance in radians
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
    static func intersection(of path1: (coordinate: Coordinate, bearing: Degrees), with path2: (coordinate: Coordinate, bearing: Degrees)) -> Coordinate? {
        // see http://www.edwilliams.org/avform.htm#Intersection
        
        let φ1 = Radians(degrees: path1.coordinate.latitude)
        let λ1 = Radians(degrees: path1.coordinate.longitude)
        let φ2 = Radians(degrees: path2.coordinate.latitude)
        let λ2 = Radians(degrees: path2.coordinate.longitude)
        let θ13 = Radians(degrees: path1.bearing)
        let θ23 = Radians(degrees: path2.bearing)
        let Δφ = φ2 - φ1
        let Δλ = λ2 - λ1
        
        // angular distance p1-p2
        let δ12 = 2 * asin(sqrt(sin(Δφ / 2) * sin(Δφ / 2) + cos(φ1) * cos(φ2) * sin(Δλ / 2) * sin(Δλ / 2)))
        
        guard δ12 != 0 else {
            return nil
        }
        
        // initial/final bearings between points
        var θa = acos((sin(φ2) - sin(φ1) * cos(δ12)) / (sin(δ12) * cos(φ1)))
        if θa.isNaN {
            θa = 0 // protect against rounding
        }
        let θb = acos((sin(φ1) - sin(φ2) * cos(δ12)) / (sin(δ12) * cos(φ2)))
        
        let θ12 = sin(λ2 - λ1) > 0 ? θa : 2 * Double.pi - θa
        let θ21 = sin(λ2 - λ1) > 0 ? 2 * Double.pi - θb : θb
        
        let α1 = (θ13 - θ12 + Double.pi).truncatingRemainder(dividingBy: 2 * Double.pi) - Double.pi // angle 2-1-3
        let α2 = (θ21 - θ23 + Double.pi).truncatingRemainder(dividingBy: 2 * Double.pi) - Double.pi // angle 1-2-3
        
        // This is actually testing for: sin(α1) != 0 || sin(α2) != 0
        // However, due to the nature of floating point values sin(n * Double.pi) is not 0.
        // Since we know that sin(x) is 0 whenever x is a multitude of π, we can truncate the remainder by Double.pi and get an accurate result.
        guard α1.truncatingRemainder(dividingBy: Double.pi) != 0 || α2.truncatingRemainder(dividingBy: Double.pi) != 0 else {
            return nil // infinite intersections
        }
        guard sin(α1) * sin(α2) >= 0 else {
            return nil // ambiguous intersection
        }
        
        let α3 = acos(-cos(α1) * cos(α2) + sin(α1) * sin(α2) * cos(δ12))
        let δ13 = atan2(sin(δ12) * sin(α1) * sin(α2), cos(α2) + cos(α1) * cos(α3))
        let φ3 = asin(sin(φ1) * cos(δ13) + cos(φ1) * sin(δ13) * cos(θ13))
        let Δλ13 = atan2(sin(θ13) * sin(δ13) * cos(φ1), cos(δ13) - sin(φ1) * sin(φ3))
        let λ3 = λ1 + Δλ13
        
        return Coordinate(Degrees(radians: φ3), (Degrees(radians: λ3) + 540).truncatingRemainder(dividingBy: 360) - 180) // normalise to −180..+180°
    }
    
    /**
     Calculates the (signed) distance to a great circle defined by start and end coordinate.
     
     - Parameter pathStart: The start coordinate of the great circle path.
     - Parameter pathStart: The end coordinate of the great circle path.
     - Parameter radius: (Mean) radius of earth (defaults to radius in meters).
     
     - Returns: The distance to the great circle (-ve if to left, +ve if to right of path).
     */
    func crossTrackDistance(toPath path:(start: Coordinate, end: Coordinate), radius: Distance = Coordinate.earthRadius) -> Distance {
        let δ13 = path.start.distance(to: self) / radius
        let θ13 = Radians(degrees: path.start.bearing(to: self))
        let θ12 = Radians(degrees: path.start.bearing(to: path.end))
        
        let δ = asin( sin(δ13) * sin(θ13-θ12) )
        
        return δ * radius
    }
    
    /**
     Calculate how far ‘this’ point is along a path from from start-point, heading towards end-point.
     That is, if a perpendicular is drawn from ‘this’ point to the (great circle) path, the along-track
     distance is the distance from the start point to where the perpendicular crosses the path.
     
     - Parameter path: Great circle path defined by start and end coordinate.
     - Parameter radius: (Mean) radius of earth (defaults to radius in meters).
     
     - Returns: The distance along the path.
     */
    func alongTrackDistance(toPath path: (start: Coordinate, end: Coordinate), radius: Distance = Coordinate.earthRadius) -> Distance {
        let δ13 = path.start.distance(to: self) / radius
        let θ13 = Radians(degrees: path.start.bearing(to: self))
        let θ12 = Radians(degrees: path.start.bearing(to: path.end))
        
        let δxt = asin(sin(δ13) * sin(θ13 - θ12))
        
        let δat = acos(cos(δ13) / abs(cos(δxt)))
        
        return δat * cos(θ12 - θ13).sign * radius
    }
    
    /**
     Calculates the maximum latitude reached when travelling on a great circle on given bearing ('Clairaut's formula').
     Negate the result for the minimum latitude (in the Southern hemisphere).
     
     The maximum latitude is independent of longitude it will be the same for all points on a given latitude.
     
     - Parameter bearing: The initial bearing.
     
     - Returns: The maxium latitude reached.
     */
    func maxLatitude(with bearing: Degrees) -> Degrees {
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
    static func crossingParallels(coordinate1: Coordinate, coordinate2: Coordinate, latitude: Degrees) -> (longitude1: Degrees, longitude2: Degrees)? {
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



// MARK: - Rhumb

public extension Coordinate {
    
    /**
     Calculates the distance to a destination coordinate along a rhumb line.
     
     - Parameter coordinate: The destination coordinate
     - Parameter radius: (Mean) radius of earth (defaults to radius in meters).
     
     - Returns: The distance from this coordinate to the destination along a rhumb line
     */
    func rhumbDistance(to coordinate: Coordinate, radius: Distance = Coordinate.earthRadius) -> Distance {
        // see www.edwilliams.org/avform.htm#Rhumb
        
        let φ1 = Radians(degrees: self.latitude)
        let φ2 = Radians(degrees: coordinate.latitude)
        let Δφ = φ2 - φ1
        var Δλ = Radians(degrees: abs(coordinate.longitude - self.longitude))
        // if dLon over 180° take shorter rhumb line across the anti-meridian:
        if Δλ > Double.pi {
            Δλ -= 2 * Double.pi
        }
        
        // on Mercator projection, longitude distances shrink by latitude; q is the 'stretch factor'
        // q becomes ill-conditioned along E-W line (0/0); use empirical tolerance to avoid it
        let Δψ = log(tan(φ2 / 2 + Double.pi / 4) / tan(φ1 / 2 + Double.pi / 4))
        let q = abs(Δψ) > 10e-12 ? Δφ / Δψ : cos(φ1)
        
        // distance is pythagoras on 'stretched' Mercator projection
        let δ = sqrt((Δφ * Δφ) + (q * q * Δλ * Δλ)) // angular distance in radians
        let dist = δ * radius
        
        return dist
    }
    
    /**
     Calculates the bearing to a destination along a rhumb line.
     
     - Parameter coordinate: The destination coordinate.
     
     - Returns: The bearing to the destination along a rhumb line in degrees from north.
     */
    func rhumbBearing(to coordinate: Coordinate) -> Degrees {
        let φ1 = Radians(degrees: self.latitude)
        let φ2 = Radians(degrees: coordinate.latitude)
        var Δλ = Radians(degrees: coordinate.longitude - self.longitude)
        // if dLon over 180° take shorter rhumb line across the anti-meridian:
        if Δλ > Double.pi {
            Δλ -= 2 * Double.pi
        }
        if Δλ < -Double.pi {
            Δλ += 2 * Double.pi
        }
        
        let Δψ = log(tan(φ2 / 2 + Double.pi / 4) / tan(φ1 / 2 + Double.pi / 4))
        
        let θ = atan2(Δλ, Δψ)
        
        return (Degrees(radians: θ) + 360).truncatingRemainder(dividingBy: 360)
    }
    
    /**
     Calculates the destination coordinate from *this* coordinate having travelled along a rhumb line
     the given distance on the given bearing.
     
     - Parameter distance Distance to travel in meters
     - Parameter bearing: The bearing in degrees from north
     - Parameter radius: (Mean) radius of earth (defaults to radius in meters).
     
     - Returns: The destination coordinate
     */
    func rhumbDestination(with distance: Distance, bearing: Degrees, radius: Distance = Coordinate.earthRadius) -> Coordinate {
        let δ = distance / radius // angular distance in radians
        let φ1 = Radians(degrees: self.latitude)
        let λ1 = Radians(degrees: self.longitude)
        let θ = Radians(degrees: bearing)
        
        let Δφ = δ * cos(θ)
        var φ2 = φ1 + Δφ
        
        // check for some daft bugger going past the pole, normalise latitude if so
        if abs(φ2) > Double.pi / 2 {
            φ2 = φ2 > 0 ? Double.pi - φ2 : -Double.pi - φ2
        }
        
        let Δψ = log(tan(φ2 / 2 + Double.pi / 4) / tan(φ1 / 2 + Double.pi / 4))
        let q = abs(Δψ) > 10e-12 ? Δφ / Δψ : cos(φ1) // E-W course becomes ill-conditioned with 0/0
        
        let Δλ = δ * sin(θ) / q
        let λ2 = λ1 + Δλ
        
        return Coordinate(Degrees(radians: φ2), (Degrees(radians: λ2) + 540).truncatingRemainder(dividingBy: 360) - 180) // normalise to −180..+180°
    }
    
    /**
     Calculates the loxodromic midpoint (along a rhumb line) between *this* coordinate and the given coordinate.
     
     - Parameter coordinate: The destination coordinate.
     
     - Returns: The midpoint between this coordinate and the given coordinate.
     */
    func rhumbMidpoint(to coordinate: Coordinate) -> Coordinate {
        // see http://mathforum.org/kb/message.jspa?messageID=148837
        
        let φ1 = Radians(degrees: self.latitude)
        var λ1 = Radians(degrees: self.longitude)
        let φ2 = Radians(degrees: coordinate.latitude)
        let λ2 = Radians(degrees: coordinate.longitude)
        
        if abs(λ2 - λ1) > Double.pi {
            λ1 += 2 * Double.pi // crossing anti-meridian
        }
        
        let φ3 = (φ1 + φ2) / 2
        let f1 = tan(Double.pi / 4 + φ1 / 2)
        let f2 = tan(Double.pi / 4 + φ2 / 2)
        let f3 = tan(Double.pi / 4 + φ3 / 2)
        var λ3 = ((λ2 - λ1) * log(f3) + λ1 * log(f2) - λ2 * log(f1)) / log(f2 / f1)
        
        if !λ3.isFinite {
            λ3 = (λ1 + λ2) / 2 // parallel of latitude
        }
        
        let p = Coordinate(Degrees(radians: φ3), (Degrees(radians: λ3) + 540).truncatingRemainder(dividingBy: 360) - 180) // normalise to −180..+180°
        
        return p
    }
}

// MARK: - Area

public extension Coordinate {
    
    /**
     Calculates the area of a spherical polygon where the sides of the polygon are great circle
     arcs joining the vertices.
     
     - Parameter polygon: Array of coordinates defining vertices of the polygon.
     - Parameter radius: (Mean) radius of earth (defaults to radius in meters).
     
     - Returns: The area of the polygon.
     */
    static func area(of polygon: [Coordinate], radius: Distance = Coordinate.earthRadius) -> Double? {
        guard polygon.count >= 3 else {
            return nil
        }
        
        // uses method due to Karney: http://osgeo-org.1560.x6.nabble.com/Area-of-a-spherical-polygon-td3841625.html
        // for each edge of the polygon, tan(E/2) = tan(Δλ/2)·(tan(φ1/2) + tan(φ2/2)) / (1 + tan(φ1/2)·tan(φ2/2))
        // where E is the spherical excess of the trapezium obtained by extending the edge to the equator
        
        // close polygon so that last point equals first point
        var polygon = polygon
        if polygon.first! != polygon.last! {
            polygon.append(polygon.first!)
        }
        
        let nVertices = polygon.count - 1
        
        var S: Double = 0 // spherical excess in steradians
        for v in 0 ..< nVertices  {
            let φ1 = Radians(degrees: polygon[v].latitude)
            let φ2 = Radians(degrees: polygon[v + 1].latitude)
            let Δλ = Radians(degrees: polygon[v + 1].longitude - polygon[v].longitude)
            let E = 2 * atan2(tan(Δλ / 2) * (tan(φ1 / 2) + tan(φ2 / 2)), 1 + tan(φ1 / 2) * tan(φ2 / 2))
            S += E
        }
        
        // returns whether polygon encloses pole: sum of course deltas around pole is 0° rather than
        // normal ±360°: blog.element84.com/determining-if-a-spherical-polygon-contains-a-pole.html
        func isPoleEnclosed(by polygon: [Coordinate]) -> Bool {
            // TODO: any better test than this?
            var ΣΔ: Double = 0
            var prevBrng = polygon[0].bearing(to: polygon[1])
            for v in 0 ..< polygon.count - 1 {
                let initBrng = polygon[v].bearing(to: polygon[v+1])
                let finalBrng = polygon[v].finalBearing(to: polygon[v+1])
                ΣΔ += (initBrng - prevBrng + 540).truncatingRemainder(dividingBy: 360) - 180
                ΣΔ += (finalBrng - initBrng + 540).truncatingRemainder(dividingBy: 360) - 180
                prevBrng = finalBrng
            }
            let initBrng = polygon[0].bearing(to: polygon[1])
            ΣΔ += (initBrng - prevBrng + 540).truncatingRemainder(dividingBy: 360) - 180
            // TODO: fix (intermittant) edge crossing pole - eg (85,90), (85,0), (85,-90)
            let enclosed = abs(ΣΔ) < 90 // 0°-ish
            return enclosed
        }
        
        if isPoleEnclosed(by: polygon) {
            S = abs(S) - 2 * Double.pi
        }
        
        let A = abs(S * radius * radius) // area in units of R
        
        return A
    }
}
