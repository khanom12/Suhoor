import Foundation
import CoreLocation

struct City: Identifiable, Codable, Equatable {
    let id: String
    let name: String
    let latitude: Double
    let longitude: Double
    let timeZoneId: String

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    var timeZone: TimeZone {
        TimeZone(identifier: timeZoneId) ?? .current
    }

    static let all: [City] = [
        City(id: "toronto", name: "Toronto", latitude: 43.6532, longitude: -79.3832, timeZoneId: "America/Toronto"),
        City(id: "montreal", name: "Montreal", latitude: 45.5017, longitude: -73.5673, timeZoneId: "America/Toronto"),
        City(id: "vancouver", name: "Vancouver", latitude: 49.2827, longitude: -123.1207, timeZoneId: "America/Vancouver"),
        City(id: "calgary", name: "Calgary", latitude: 51.0447, longitude: -114.0719, timeZoneId: "America/Edmonton"),
        City(id: "edmonton", name: "Edmonton", latitude: 53.5461, longitude: -113.4938, timeZoneId: "America/Edmonton"),
        City(id: "ottawa", name: "Ottawa", latitude: 45.4215, longitude: -75.6972, timeZoneId: "America/Toronto"),
        City(id: "winnipeg", name: "Winnipeg", latitude: 49.8951, longitude: -97.1384, timeZoneId: "America/Winnipeg"),
        City(id: "halifax", name: "Halifax", latitude: 44.6488, longitude: -63.5752, timeZoneId: "America/Halifax"),
        City(id: "newyork", name: "New York", latitude: 40.7128, longitude: -74.0060, timeZoneId: "America/New_York"),
        City(id: "london", name: "London", latitude: 51.5072, longitude: -0.1276, timeZoneId: "Europe/London"),
        City(id: "dubai", name: "Dubai", latitude: 25.2048, longitude: 55.2708, timeZoneId: "Asia/Dubai"),
        City(id: "karachi", name: "Karachi", latitude: 24.8607, longitude: 67.0011, timeZoneId: "Asia/Karachi")
    ]

    static let defaultCity = City.all.first { $0.id == "toronto" } ?? City.all[0]
}
