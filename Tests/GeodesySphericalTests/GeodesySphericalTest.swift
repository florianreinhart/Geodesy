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

private extension Double {
    func rounded(to places: Int) -> Double {
        let factor = pow(10.0, Double(places))
        return (self * factor).rounded() / factor
    }
}

final class GeodesySphericalTest: XCTestCase {
    
    static let allTests = [
        ("testSign", testSign),
        ("testHashable", testHashable),
        ("testCustomStringConvertible", testCustomStringConvertible),
        ("testLosslessStringConvertible", testLosslessStringConvertible),
        ("testDistance", testDistance),
        ("testInitialBearing", testInitialBearing),
        ("testFinalBearing", testFinalBearing),
        ("testMidpoint", testMidpoint),
        ("testIntermediatePoint", testIntermediatePoint),
        ("testDestination", testDestination),
        ("testIntersection", testIntersection),
        ("testCrossTrack", testCrossTrack),
        ("testAlongTrackDistance", testAlongTrackDistance),
        ("testMaxLatitude", testMaxLatitude),
        ("testCrossingParallels", testCrossingParallels),
        ("testRhumbDistance", testRhumbDistance),
        ("testRhumbBearing", testRhumbBearing),
        ("testRhumbDestination", testRhumbDestination),
        ("testRhumbMidpoint", testRhumbMidpoint),
        ("testArea", testArea),
    ]
    
    private let cambridge = Coordinate(52.205, 0.119)
    private let paris = Coordinate(48.857, 2.351)
    private let greenwich = Coordinate(51.4778, -0.0015)
    private let bradwell = Coordinate(53.3206, -1.7297)
    private let dov = Coordinate(51.127, 1.338)
    private let cal = Coordinate(50.964, 1.853)
    
    func testSign() {
        XCTAssertEqual(-10.sign, -1)
        XCTAssertEqual(0.sign, 0)
        XCTAssertEqual(10.sign, 1)
    }
    
    func testHashable() {
        XCTAssertNotEqual(cambridge.hashValue, paris.hashValue)
        XCTAssertEqual(cambridge.hashValue, cambridge.hashValue)
    }
    
    func testCustomStringConvertible() {
        XCTAssertEqual("\(cambridge)", "52.205,0.119")
        XCTAssertEqual("\(paris)", "48.857,2.351")
    }
    
    func testLosslessStringConvertible() {
        XCTAssertEqual(Coordinate("\(cambridge)"), cambridge)
        XCTAssertEqual(Coordinate("\(paris)"), paris)
        XCTAssertEqual(Coordinate("52.205,0.119"), cambridge)
        XCTAssertEqual(Coordinate("48.857,2.351"), paris)
        XCTAssertNil(Coordinate("INVALID_STRING"))
        XCTAssertNil(Coordinate("42"))
        XCTAssertNil(Coordinate("42,"))
        XCTAssertNil(Coordinate(",42"))
        XCTAssertNil(Coordinate("1,2,3"))
    }
    
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
        // test('cross-track',      function() { new LatLon(53.2611, -0.7972).crossTrackDistanceTo(bradwell, new LatLon(53.1887,  0.1334)).toPrecision(4).should.equal('-307.5'); });
        let distance1 = Coordinate(53.2611, -0.7972).crossTrackDistance(toPath: (start: bradwell, end: Coordinate(53.1887, 0.1334)))
        XCTAssertEqual(distance1.rounded(to: 1), -307.5)
        
        let distance2 = Coordinate(10, 1).crossTrackDistance(toPath: (start: Coordinate(0, 0), end: Coordinate(0, 2)))
        XCTAssertEqual(distance2.rounded(to: 1), -1111949.3)
        
        // test('cross-track NE',   function() { LatLon( 1,  1).crossTrackDistanceTo(LatLon(0, 0), LatLon(0, 2)).toPrecision(4).should.equal('-1.112e+5'); });
        let distanceNE = Coordinate(1, 1).crossTrackDistance(toPath: (start: Coordinate(0, 0), end: Coordinate(0, 2)))
        XCTAssertEqual(distanceNE.rounded(to: 1), -111194.9)
        
        // test('cross-track SE',   function() { LatLon(-1,  1).crossTrackDistanceTo(LatLon(0, 0), LatLon(0, 2)).toPrecision(4).should.equal('1.112e+5'); });
        let distanceSE = Coordinate(-1, 1).crossTrackDistance(toPath: (start: Coordinate(0, 0), end: Coordinate(0, 2)))
        XCTAssertEqual(distanceSE.rounded(to: 1), 111194.9)
        
        // test('cross-track SW?',  function() { LatLon(-1, -1).crossTrackDistanceTo(LatLon(0, 0), LatLon(0, 2)).toPrecision(4).should.equal('1.112e+5'); });
        let distanceSW = Coordinate(-1, -1).crossTrackDistance(toPath: (start: Coordinate(0, 0), end: Coordinate(0, 2)))
        XCTAssertEqual(distanceSW.rounded(to: 1), 111194.9)
        
        // test('cross-track NW?',  function() { LatLon( 1, -1).crossTrackDistanceTo(LatLon(0, 0), LatLon(0, 2)).toPrecision(4).should.equal('-1.112e+5'); });
        let distanceNW = Coordinate(1, -1).crossTrackDistance(toPath: (start: Coordinate(0, 0), end: Coordinate(0, 2)))
        XCTAssertEqual(distanceNW.rounded(to: 1), -111194.9)
    }
    
    func testAlongTrackDistance() {
        // test('along-track',      function() { new LatLon(53.2611, -0.7972).alongTrackDistanceTo(bradwell, new LatLon(53.1887,  0.1334)).toPrecision(4).should.equal('6.233e+4'); });
        let distance1 = Coordinate(53.2611, -0.7972).alongTrackDistance(toPath: (start: bradwell, end: Coordinate(53.1887,  0.1334)))
        XCTAssertEqual(distance1.rounded(to: 0), 62331)

        // test('along-track NE',   function() { LatLon( 1,  1).alongTrackDistanceTo(LatLon(0, 0), LatLon(0, 2)).toPrecision(4).should.equal('1.112e+5'); });
        let distanceNE = Coordinate(1, 1).alongTrackDistance(toPath: (start: Coordinate(0, 0), end: Coordinate(0, 2)))
        XCTAssertEqual(distanceNE.rounded(to: 0), 111195)

        // test('along-track SE',   function() { LatLon(-1,  1).alongTrackDistanceTo(LatLon(0, 0), LatLon(0, 2)).toPrecision(4).should.equal('1.112e+5'); });
        let distanceSE = Coordinate(-1, 1).alongTrackDistance(toPath: (start: Coordinate(0, 0), end: Coordinate(0, 2)))
        XCTAssertEqual(distanceSE.rounded(to: 0), 111195)
        
        // test('along-track SW',   function() { LatLon(-1, -1).alongTrackDistanceTo(LatLon(0, 0), LatLon(0, 2)).toPrecision(4).should.equal('-1.112e+5'); });
        let distanceSW = Coordinate(-1, -1).alongTrackDistance(toPath: (start: Coordinate(0, 0), end: Coordinate(0, 2)))
        XCTAssertEqual(distanceSW.rounded(to: 0), -111195)
        
        // test('along-track NW',   function() { LatLon( 1, -1).alongTrackDistanceTo(LatLon(0, 0), LatLon(0, 2)).toPrecision(4).should.equal('-1.112e+5'); });
        let distanceNW = Coordinate(1, -1).alongTrackDistance(toPath: (start: Coordinate(0, 0), end: Coordinate(0, 2)))
        XCTAssertEqual(distanceNW.rounded(to: 0), -111195)
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
    
    func testRhumbDistance() {
        // test('distance',              function() { dov.rhumbDistanceTo(cal).toPrecision(4).should.equal('4.031e+4'); });
        do {
            let distance = dov.rhumbDistance(to: cal)
            XCTAssertEqual(distance.rounded(to: 0), 40308)
        }
        
        // test('distance dateline E-W', function() { new LatLon(1, -179).rhumbDistanceTo(new LatLon(1, 179)).toFixed(6).should.equal(new LatLon(1, 1).rhumbDistanceTo(new LatLon(1, -1)).toFixed(6)); });
        do {
            let distance1 = Coordinate(1, -179).rhumbDistance(to: Coordinate(1, 179))
            let distance2 = Coordinate(1, 1).rhumbDistance(to: Coordinate(1, -1))
            XCTAssertEqual(distance1.rounded(to: 6), distance2.rounded(to: 6))
        }
    }
    
    func testRhumbBearing() {
        // test('bearing',               function() { dov.rhumbBearingTo(cal).toFixed(1).should.equal('116.7'); });
        do {
            let bearing = dov.rhumbBearing(to: cal)
            XCTAssertEqual(bearing.rounded(to: 1), 116.7)
        }
        
        // test('bearing dateline',      function() { new LatLon(1, -179).rhumbBearingTo(new LatLon(1, 179)).should.equal(270); });
        do {
            let bearing = Coordinate(1, -179).rhumbBearing(to: Coordinate(1, 179))
            XCTAssertEqual(bearing, 270)
        }
        
        // test('bearing dateline',      function() { new LatLon(1, 179).rhumbBearingTo(new LatLon(1, -179)).should.equal(90); });
        do {
            let bearing = Coordinate(1, 179).rhumbBearing(to: Coordinate(1, -179))
            XCTAssertEqual(bearing, 90)
        }
    }
    
    func testRhumbDestination() {
        // test('dest’n',                function() { dov.rhumbDestinationPoint(40310, 116.7).toString('d').should.equal('50.9641°N, 001.8531°E'); });
        do {
            let destination = dov.rhumbDestination(with: 40310, bearing: 116.7)
            XCTAssertEqual(destination.latitude.rounded(to: 6), 50.964114)
            XCTAssertEqual(destination.longitude.rounded(to: 6), 1.853128)
        }
        
        // test('dest’n',                function() { new LatLon(1, 1).rhumbDestinationPoint(111178, 90).toString('d').should.equal('01.0000°N, 002.0000°E'); });
        do {
            let destination = Coordinate(1, 1).rhumbDestination(with: 111178, bearing: 90)
            XCTAssertEqual(destination.latitude.rounded(to: 6), 1)
            XCTAssertEqual(destination.longitude.rounded(to: 6), 2)
        }
        
        // test('dest’n dateline',       function() { new LatLon(1, 179).rhumbDestinationPoint(222356, 90).toString('d').should.equal('01.0000°N, 179.0000°W'); });
        do {
            let destination = Coordinate(1, 179).rhumbDestination(with: 222356, bearing: 90)
            XCTAssertEqual(destination.latitude.rounded(to: 6), 1)
            XCTAssertEqual(destination.longitude.rounded(to: 6), -179)
        }
        
        // test('dest’n dateline',       function() { new LatLon(1, -179).rhumbDestinationPoint(222356, 270).toString('d').should.equal('01.0000°N, 179.0000°E'); });
        do {
            let destination = Coordinate(1, -179).rhumbDestination(with: 222356, bearing: 270)
            XCTAssertEqual(destination.latitude.rounded(to: 6), 1)
            XCTAssertEqual(destination.longitude.rounded(to: 6), 179)
        }
        
        do {
            // Invalid coordinates check to get complete code coverage
            _ = Coordinate(180, 0).rhumbDestination(with: 222356, bearing: 270)
        }
    }
    
    func testRhumbMidpoint() {
        // test('midpoint',              function() { dov.rhumbMidpointTo(cal).toString('d').should.equal('51.0455°N, 001.5957°E'); });
        do {
            let midpoint = dov.rhumbMidpoint(to: cal)
            XCTAssertEqual(midpoint.latitude.rounded(to: 6), 51.0455)
            XCTAssertEqual(midpoint.longitude.rounded(to: 6), 1.595727)
        }
        
        // test('midpoint dateline',     function() { new LatLon(1, -179).rhumbMidpointTo(new LatLon(1, 178)).toString('d').should.equal('01.0000°N, 179.5000°E'); });
        do {
            let midpoint = Coordinate(1, -179).rhumbMidpoint(to: Coordinate(1, 178))
            XCTAssertEqual(midpoint.latitude.rounded(to: 6), 1)
            XCTAssertEqual(midpoint.longitude.rounded(to: 6), 179.5)
        }
    }
    
    func testArea() {
        let R = 6371e3
        let π = Double.pi
        let polyTriangle  = [Coordinate(1, 1), Coordinate(2, 1), Coordinate(1, 2)]
        let polySquareCw  = [Coordinate(1, 1), Coordinate(2, 1), Coordinate(2, 2), Coordinate(1, 2)]
        let polySquareCcw = [Coordinate(1, 1), Coordinate(1, 2), Coordinate(2, 2), Coordinate(2, 1)]
        let polyQuadrant  = [Coordinate(0, 0), Coordinate(0, 90), Coordinate(90, 0)]
        let polyHemi      = [Coordinate(0, 1), Coordinate(45, 0), Coordinate(89, 90), Coordinate(45, 180), Coordinate(0, 179), Coordinate(-45, 180), Coordinate(-89, 90), Coordinate(-45, 0)]
        let polyPole      = [Coordinate(89, 0), Coordinate(89, 120), Coordinate(89, -120)]
        let polyConcave   = [Coordinate(1, 1), Coordinate(5, 1), Coordinate(5, 3), Coordinate(1, 3), Coordinate(3, 2)]
        
        // test('triangle area',        function() { LatLon.areaOf(polyTriangle).toFixed(0).should.equal('6181527888'); });
        do {
            let area = Coordinate.area(of: polyTriangle)!
            XCTAssertEqual(area.rounded(to: 0), 6181527888)
        }

        // ('triangle area closed', function() { LatLon.areaOf(polyTriangle.concat(polyTriangle[0])).toFixed(0).should.equal('6181527888'); });
        do {
            let area = Coordinate.area(of: polyTriangle + [polyTriangle[0]])!
            XCTAssertEqual(area.rounded(to: 0), 6181527888)
        }

        // test('square cw area',       function() { LatLon.areaOf(polySquareCw).toFixed(0).should.equal('12360230987'); });
        do {
            let area = Coordinate.area(of: polySquareCw)!
            XCTAssertEqual(area.rounded(to: 0), 12360230987)
        }

        // test('square ccw area',      function() { LatLon.areaOf(polySquareCcw).toFixed(0).should.equal('12360230987'); });
        do {
            let area = Coordinate.area(of: polySquareCcw)!
            XCTAssertEqual(area.rounded(to: 0), 12360230987)
        }

        // test('quadrant area',        function() { LatLon.areaOf(polyQuadrant).toFixed(1).should.equal((π*R*R/2).toFixed(1)); });
        do {
            let area = Coordinate.area(of: polyQuadrant)!
            XCTAssertEqual(area.rounded(to: 1), (π * R * R / 2).rounded(to: 1))
        }

        // test('hemisphere area',      function() { LatLon.areaOf(polyHemi).toFixed(0).should.equal('252684679676459'); }); // TODO: vectors gives 252198975941606 (0.2% error) - which is right?
        do {
            let area = Coordinate.area(of: polyHemi)!
            XCTAssertEqual(area.rounded(to: 0), 252684679676459)
        }

        // test('pole area',            function() { LatLon.areaOf(polyPole).toFixed(0).should.equal('16063139192'); });
        do {
            let area = Coordinate.area(of: polyPole)!
            XCTAssertEqual(area.rounded(to: 0), 16063139192)
        }
        
        // test('concave area',         function() { LatLon.areaOf(polyConcave).toFixed(0).should.equal('74042699236'); });
        do {
            let area = Coordinate.area(of: polyConcave)!
            XCTAssertEqual(area.rounded(to: 0), 74042699236)
        }
        
        do {
            let distance = Coordinate.area(of: [])
            XCTAssertNil(distance)
        }
    }
}
