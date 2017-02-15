//
//  SphericalTest.swift
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
import XCTest
@testable import GeodesySpherical

extension Double {
    func rounded(to places: Int) -> Double {
        let factor = pow(10.0, Double(places))
        return (self * factor).rounded() / factor
    }
}

final class GeodesySphericalTest: XCTestCase {
    
    static let allTests = [
        ("testDistance", testDistance),
        ("testInitialBearing", testInitialBearing),
        ("testFinalBearing", testFinalBearing),
        ("testMidpoint", testMidpoint),
        ("testIntermediatePoint", testIntermediatePoint),
        ("testDestination", testDestination),
        ("testIntersection", testIntersection),
        ("testCrossTrack", testCrossTrack),
        ("testMaxLatitude", testMaxLatitude),
        ("testCrossingParallels", testCrossingParallels)
    ]
    
    private let cambridge = Coordinate(52.205, 0.119)
    private let paris = Coordinate(48.857, 2.351)
    
    func testDistance() {
        let cambridgeToParis = cambridge.distance(to: paris)
        let parisToCambridge = paris.distance(to: cambridge)
        
        XCTAssertEqual(cambridgeToParis, parisToCambridge)
        XCTAssertEqual(cambridgeToParis.rounded(to: 0), 404279)
        XCTAssertEqual(parisToCambridge.rounded(to: 0), 404279)
    }
    
    func testInitialBearing() {
        let cambridgeToParis = cambridge.bearing(to: paris)
        let parisToCambridge = paris.bearing(to: cambridge)
        
        XCTAssertEqual(cambridgeToParis.rounded(to: 1), 156.2)
        XCTAssertEqual(parisToCambridge.rounded(to: 1), 337.9)
    }
    
    func testFinalBearing() {
        let cambridgeToParis = cambridge.finalBearing(to: paris)
        let parisToCambridge = paris.finalBearing(to: cambridge)
        
        XCTAssertEqual(cambridgeToParis.rounded(to: 1), 157.9)
        XCTAssertEqual(parisToCambridge.rounded(to: 1), 336.2)
    }
    
    func testMidpoint() {
        let cambridgeToParis = cambridge.midpoint(to: paris)
        let parisToCambridge = paris.midpoint(to: cambridge)
        
        XCTAssertEqual(cambridgeToParis, parisToCambridge)
        XCTAssertEqual(cambridgeToParis.latitude.rounded(to: 6), 50.536327)
        XCTAssertEqual(cambridgeToParis.longitude.rounded(to: 6), 1.274614)
        XCTAssertEqual(parisToCambridge.latitude.rounded(to: 6), 50.536327)
        XCTAssertEqual(parisToCambridge.longitude.rounded(to: 6), 1.274614)
    }
    
    func testIntermediatePoint() {
        let cambridgeToParis = cambridge.intermediatePoint(to: paris, fraction: 0.25)
        let parisToCambridge = paris.intermediatePoint(to: cambridge, fraction: 0.25)

        XCTAssertNotEqual(cambridgeToParis, parisToCambridge)
        XCTAssertEqual(cambridgeToParis.latitude.rounded(to: 6), 51.372084)
        XCTAssertEqual(cambridgeToParis.longitude.rounded(to: 6), 0.707337)
        XCTAssertEqual(parisToCambridge.latitude.rounded(to: 6), 49.697910)
        XCTAssertEqual(parisToCambridge.longitude.rounded(to: 6), 1.822107)
    }
    
    func testDestination() {
        let greenwich = Coordinate(51.4778, -0.0015)
        let distance = Distance(7794)
        let bearing = Degrees(300.7)
        
        let destination = greenwich.destination(with: distance, bearing: bearing)
        
        XCTAssertEqual(destination.latitude.rounded(to: 6), 51.513546)
        XCTAssertEqual(destination.longitude.rounded(to: 6), -0.098345)
    }
    
    func testIntersection() {
        let N = Degrees(0)
        let E = Degrees(90)
        let S = Degrees(180)
        let W = Degrees(270)
        
        // toward 1,1 N,E nearest
        do {
            let intersection = Coordinate.intersection(of: (Coordinate(0, 1), N), with: (Coordinate(1, 0), E))!
            XCTAssertEqual(intersection.latitude.rounded(to: 6), 0.999848)
            XCTAssertEqual(intersection.longitude.rounded(to: 6), 1.000000)
        }
        
        // toward 1,1 E,N nearest
        do {
            let intersection = Coordinate.intersection(of: (Coordinate(1, 0), E), with: (Coordinate(0, 1), N))!
            XCTAssertEqual(intersection.latitude.rounded(to: 6), 0.999848)
            XCTAssertEqual(intersection.longitude.rounded(to: 6), 1.000000)
        }
        
        // away 1,1 S,W antipodal
        do {
            let intersection = Coordinate.intersection(of: (Coordinate(0, 1), S), with: (Coordinate(1, 0), W))!
            XCTAssertEqual(intersection.latitude.rounded(to: 6), -0.999848)
            XCTAssertEqual(intersection.longitude.rounded(to: 6), -179.000000)
        }
        // away 1,1 W,S antipodal
        do {
            let intersection = Coordinate.intersection(of: (Coordinate(1, 0), W), with: (Coordinate(0, 1), S))!
            XCTAssertEqual(intersection.latitude.rounded(to: 6), -0.999848)
            XCTAssertEqual(intersection.longitude.rounded(to: 6), -179.000000)
        }
        
        // 1E/90E N,E nearest
        do {
            let intersection = Coordinate.intersection(of: (Coordinate(0, 1), N), with: (Coordinate(1, 92), E))!
            XCTAssertEqual(intersection.latitude.rounded(to: 6), 0.017454)
            XCTAssertEqual(intersection.longitude.rounded(to: 6), -179.000000)
        }
        
        // stn-cdg-bxl
        do {
            let stn = Coordinate(51.8853, 0.2545)
            let cdg = Coordinate(49.0034, 2.5735)
            let intersection = Coordinate.intersection(of: (stn, 108.547), with: (cdg, 32.435))!
            XCTAssertEqual(intersection.latitude.rounded(to: 6), 50.907809)
            XCTAssertEqual(intersection.longitude.rounded(to: 6), 4.508410)
        }
        
        // Equal paths
        do {
            let coordinate = Coordinate(0, 0)
            let intersection = Coordinate.intersection(of: (coordinate, N), with: (coordinate, N))
            XCTAssertNil(intersection)
        }
        
        // Infinite intersections
        do {
            let coordinate1 = Coordinate(0, 0)
            let coordinate2 = Coordinate(0, 1)
            let intersection = Coordinate.intersection(of: (coordinate1, E), with: (coordinate2, E))
            XCTAssertNil(intersection)
        }
        
        // Ambiguous intersections
        do {
            let coordinate1 = Coordinate(0, 0)
            let coordinate2 = Coordinate(1, 0)
            let intersection = Coordinate.intersection(of: (coordinate1, N), with: (coordinate2, N))
            XCTAssertNil(intersection)
        }
        
        // NaN
        do {
            let coordinate = Coordinate(Double.nan, 0)
            let intersection = Coordinate.intersection(of: (coordinate, N), with: (coordinate, N))
            XCTAssertNil(intersection)
        }
    }
    
    func testCrossTrack() {
        let bradwell = Coordinate(53.3206, -1.7297)
        let distance1 = Coordinate(53.2611, -0.7972).crossTrackDistanceToPath(from: bradwell, to: Coordinate(53.1887, 0.1334))
        let distance2 = Coordinate(10, 1).crossTrackDistanceToPath(from: Coordinate(0, 0), to: Coordinate(0, 2))
        
        XCTAssertEqual(distance1.rounded(to: 1), -307.5)
        XCTAssertEqual(distance2.rounded(to: 1), -1111949.3)
    }
    
    func testMaxLatitude() {
        let clairaut0 = Coordinate(0,0).maxLatitude(with: 0)
        let clairaut1 = Coordinate(0,0).maxLatitude(with: 1)
        let clairaut90 = Coordinate(0,0).maxLatitude(with: 90)
        
        XCTAssertEqual(clairaut0, 90)
        XCTAssertEqual(clairaut1, 89)
        XCTAssertEqual(clairaut90, 0)
    }
    
    func testCrossingParallels() {
        do {
            let longitudes = Coordinate.crossingParallels(coordinate1: Coordinate(0, 0), coordinate2: Coordinate(60, 30), latitude: 30)
            XCTAssertNotNil(longitudes)
            XCTAssertEqual(longitudes?.longitude1.rounded(to: 6), 9.594068)
            XCTAssertEqual(longitudes?.longitude2.rounded(to: 6), 170.405932)
        }
        
        do {
            let longitudes = Coordinate.crossingParallels(coordinate1: Coordinate(0, 0), coordinate2: Coordinate(0, 1), latitude: 30)
            XCTAssertNil(longitudes)
        }
    }
    
    func testHashable() {
        XCTAssertNotEqual(cambridge.hashValue, paris.hashValue)
        XCTAssertEqual(cambridge.hashValue, cambridge.hashValue)
    }
    
    func testCustomStringConvertible() {
        XCTAssertEqual("\(cambridge)", "52.205,0.119")
        XCTAssertEqual("\(paris)", "48.857,2.351")
    }
}
