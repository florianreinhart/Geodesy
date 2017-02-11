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
    
    static var allTests : [(String, (GeodesySphericalTest) -> () throws -> Void)] {
        return [
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
    }
    
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
        let intersection1 = Coordinate.intersection(of: (Coordinate(0, 1), N), with: (Coordinate(1, 0), E))!
        XCTAssertEqual(intersection1.latitude.rounded(to: 6), 0.999848)
        XCTAssertEqual(intersection1.longitude.rounded(to: 6), 1.000000)
        
        // toward 1,1 E,N nearest
        let intersection2 = Coordinate.intersection(of: (Coordinate(1, 0), E), with: (Coordinate(0, 1), N))!
        XCTAssertEqual(intersection2.latitude.rounded(to: 6), 0.999848)
        XCTAssertEqual(intersection2.longitude.rounded(to: 6), 1.000000)
        
        // away 1,1 S,W antipodal
        let intersection3 = Coordinate.intersection(of: (Coordinate(0, 1), S), with: (Coordinate(1, 0), W))!
        XCTAssertEqual(intersection3.latitude.rounded(to: 6), -0.999848)
        XCTAssertEqual(intersection3.longitude.rounded(to: 6), -179.000000)
        
        // away 1,1 W,S antipodal
        let intersection4 = Coordinate.intersection(of: (Coordinate(1, 0), W), with: (Coordinate(0, 1), S))!
        XCTAssertEqual(intersection4.latitude.rounded(to: 6), -0.999848)
        XCTAssertEqual(intersection4.longitude.rounded(to: 6), -179.000000)
        
        // 1E/90E N,E nearest
        let intersection5 = Coordinate.intersection(of: (Coordinate(0, 1), N), with: (Coordinate(1, 92), E))!
        XCTAssertEqual(intersection5.latitude.rounded(to: 6), 0.017454)
        XCTAssertEqual(intersection5.longitude.rounded(to: 6), -179.000000)
        
        // stn-cdg-bxl
        let stn = Coordinate(51.8853, 0.2545)
        let cdg = Coordinate(49.0034, 2.5735)
        let intersection6 = Coordinate.intersection(of: (stn, 108.547), with: (cdg, 32.435))!
        XCTAssertEqual(intersection6.latitude.rounded(to: 6), 50.907809)
        XCTAssertEqual(intersection6.longitude.rounded(to: 6), 4.508410)
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
        let (longitude1, longitude2) = Coordinate.crossingParallels(coordinate1: Coordinate(0, 0), coordinate2: Coordinate(60, 30), latitude: 30)!

        XCTAssertEqual(longitude1.rounded(to: 6), 9.594068)
        XCTAssertEqual(longitude2.rounded(to: 6), 170.405932)
    }
}
