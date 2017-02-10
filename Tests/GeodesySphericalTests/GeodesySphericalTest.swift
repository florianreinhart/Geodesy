//
//  SphericalTest.swift
//  swift-geodesy
//
//  Created by Florian Reinhart on 10/02/2017.
//
//

import XCTest
@testable import GeodesySpherical

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
        
        let cambridgeToParisFormatted = String(format: "%.f", cambridgeToParis)
        let parisToCambridgeFormatted = String(format: "%.f", parisToCambridge)
        
        XCTAssertEqual(cambridgeToParis, parisToCambridge)
        XCTAssertEqual(cambridgeToParisFormatted, "404279")
        XCTAssertEqual(parisToCambridgeFormatted, "404279")
    }
    
    func testInitialBearing() {
        let cambridgeToParis = cambridge.bearing(to: paris)
        let parisToCambridge = paris.bearing(to: cambridge)
        
        let cambridgeToParisFormatted = String(format: "%.1f", cambridgeToParis)
        let parisToCambridgeFormatted = String(format: "%.1f", parisToCambridge)
        
        XCTAssertEqual(cambridgeToParisFormatted, "156.2")
        XCTAssertEqual(parisToCambridgeFormatted, "337.9")
    }
    
    func testFinalBearing() {
        let cambridgeToParis = cambridge.finalBearing(to: paris)
        let parisToCambridge = paris.finalBearing(to: cambridge)
        
        let cambridgeToParisFormatted = String(format: "%.1f", cambridgeToParis)
        let parisToCambridgeFormatted = String(format: "%.1f", parisToCambridge)
        
        XCTAssertEqual(cambridgeToParisFormatted, "157.9")
        XCTAssertEqual(parisToCambridgeFormatted, "336.2")
    }
    
    func testMidpoint() {
        let cambridgeToParis = cambridge.midpoint(to: paris)
        let parisToCambridge = paris.midpoint(to: cambridge)
        
        let cambridgeToParisFormatted = String(format: "%.6f,%.6f", cambridgeToParis.latitude, cambridgeToParis.longitude)
        let parisToCambridgeFormatted = String(format: "%.6f,%.6f", parisToCambridge.latitude, parisToCambridge.longitude)
        
        XCTAssertEqual(cambridgeToParis, parisToCambridge)
        XCTAssertEqual(cambridgeToParisFormatted, "50.536327,1.274614")
        XCTAssertEqual(parisToCambridgeFormatted, "50.536327,1.274614")
    }
    
    func testIntermediatePoint() {
        let cambridgeToParis = cambridge.intermediatePoint(to: paris, fraction: 0.25)
        let parisToCambridge = paris.intermediatePoint(to: cambridge, fraction: 0.25)
        
        let cambridgeToParisFormatted = String(format: "%.6f,%.6f", cambridgeToParis.latitude, cambridgeToParis.longitude)
        let parisToCambridgeFormatted = String(format: "%.6f,%.6f", parisToCambridge.latitude, parisToCambridge.longitude)
        
        XCTAssertNotEqual(cambridgeToParis, parisToCambridge)
        XCTAssertEqual(cambridgeToParisFormatted, "51.372084,0.707337")
        XCTAssertEqual(parisToCambridgeFormatted, "49.697910,1.822107")
    }
    
    func testDestination() {
        let greenwich = Coordinate(51.4778, -0.0015)
        let distance = Distance(7794)
        let bearing = Degrees(300.7)
        
        let destination = greenwich.destination(with: distance, bearing: bearing)
        let destinationFormatted = String(format: "%.6f,%.6f", destination.latitude, destination.longitude)
        
        XCTAssertEqual(destinationFormatted, "51.513546,-0.098345")
    }
    
    func testIntersection() {
        let N = Degrees(0)
        let E = Degrees(90)
        let S = Degrees(180)
        let W = Degrees(270)
        
        // toward 1,1 N,E nearest
        let intersection1 = Coordinate.intersection(of: (Coordinate(0, 1), N), with: (Coordinate(1, 0), E))!
        let intersection1Formatted = String(format: "%.6f,%.6f", intersection1.latitude, intersection1.longitude)
        XCTAssertEqual(intersection1Formatted, "0.999848,1.000000")
        
        // toward 1,1 E,N nearest
        let intersection2 = Coordinate.intersection(of: (Coordinate(1, 0), E), with: (Coordinate(0, 1), N))!
        let intersection2Formatted = String(format: "%.6f,%.6f", intersection2.latitude, intersection2.longitude)
        XCTAssertEqual(intersection2Formatted, "0.999848,1.000000")
        
        // away 1,1 S,W antipodal
        let intersection3 = Coordinate.intersection(of: (Coordinate(0, 1), S), with: (Coordinate(1, 0), W))!
        let intersection3Formatted = String(format: "%.6f,%.6f", intersection3.latitude, intersection3.longitude)
        XCTAssertEqual(intersection3Formatted, "-0.999848,-179.000000")
        
        // away 1,1 W,S antipodal
        let intersection4 = Coordinate.intersection(of: (Coordinate(1, 0), W), with: (Coordinate(0, 1), S))!
        let intersection4Formatted = String(format: "%.6f,%.6f", intersection4.latitude, intersection4.longitude)
        XCTAssertEqual(intersection4Formatted, "-0.999848,-179.000000")
        
        // 1E/90E N,E nearest
        let intersection5 = Coordinate.intersection(of: (Coordinate(0, 1), N), with: (Coordinate(1, 92), E))!
        let intersection5Formatted = String(format: "%.6f,%.6f", intersection5.latitude, intersection5.longitude)
        XCTAssertEqual(intersection5Formatted, "0.017454,-179.000000")
        
        // stn-cdg-bxl
        let stn = Coordinate(51.8853, 0.2545)
        let cdg = Coordinate(49.0034, 2.5735)
        let intersection6 = Coordinate.intersection(of: (stn, 108.547), with: (cdg, 32.435))!
        let intersection6Formatted = String(format: "%.6f,%.6f", intersection6.latitude, intersection6.longitude)
        XCTAssertEqual(intersection6Formatted, "50.907809,4.508410")
    }
    
    func testCrossTrack() {
        let bradwell = Coordinate(53.3206, -1.7297)
        let distance1 = Coordinate(53.2611, -0.7972).crossTrackDistanceToPath(from: bradwell, to: Coordinate(53.1887, 0.1334))
        let distance2 = Coordinate(10, 1).crossTrackDistanceToPath(from: Coordinate(0, 0), to: Coordinate(0, 2))
        
        let distance1Formatted = String(format: "%.1f", distance1)
        let distance2Formatted = String(format: "%.1f", distance2)
        
        XCTAssertEqual(distance1Formatted, "-307.5")
        XCTAssertEqual(distance2Formatted, "-1111949.3")
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
        let parallels = Coordinate.crossingParallels(coordinate1: Coordinate(0, 0), coordinate2: Coordinate(60, 30), latitude: 30)!
        
        let longitude1Formatted = String(format: "%.6f", parallels.longitude1)
        let longitude2Formatted = String(format: "%.6f", parallels.longitude2)
        
        XCTAssertEqual(longitude1Formatted, "9.594068")
        XCTAssertEqual(longitude2Formatted, "170.405932")
    }
}
