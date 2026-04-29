import Foundation

enum CalculationMethod: String, Codable, CaseIterable, Identifiable, Sendable {
    case muslimWorldLeague
    case egyptian
    case karachi
    case northAmerica
    case makkah

    var id: String { profile.id }

    var profile: PrayerCalculationMethod { PrayerCalculationMethod.profile(for: self) }

    var canonicalID: String { profile.id }

    var fajrAngle: Double { profile.fajrAngleDegrees }

    var displayName: String { profile.displayName }

    var authorityName: String? { profile.authorityName }

    static func defaultForTimeZone(_ timeZone: TimeZone) -> CalculationMethod {
        let id = timeZone.identifier
        if id.hasPrefix("America/") {
            return .northAmerica
        }
        if id.hasPrefix("Europe/") || id.hasPrefix("Africa/") {
            return .muslimWorldLeague
        }
        if id.hasPrefix("Asia/") {
            return .karachi
        }
        return .muslimWorldLeague
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawID = try container.decode(String.self)
        self = Self.method(forStoredID: rawID)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(canonicalID)
    }

    private static func method(forStoredID id: String) -> CalculationMethod {
        switch id {
        case "muslimWorldLeague":
            return .muslimWorldLeague
        case "isna", "northAmerica":
            return .northAmerica
        case "egyptianGeneralAuthority", "egyptian":
            return .egyptian
        case "karachi":
            return .karachi
        case "ummAlQura", "makkah":
            return .makkah
        default:
            return .muslimWorldLeague
        }
    }
}

struct PrayerCalculationMethod: Codable, Equatable, Hashable, Sendable {
    let id: String
    let legacyIDs: [String]
    let displayName: String
    let shortDisplayName: String?
    let authorityName: String?
    let countryOrRegionHints: [String]
    let fajrAngleDegrees: Double
    let defaultHighLatitudeRule: PrayerHighLatitudeRule
    let sourceNotes: String?
    let isBuiltIn: Bool
    let isDeprecated: Bool

    static func profile(for method: CalculationMethod) -> PrayerCalculationMethod {
        switch method {
        case .muslimWorldLeague:
            return PrayerCalculationMethod(
                id: "muslimWorldLeague",
                legacyIDs: [],
                displayName: "Muslim World League",
                shortDisplayName: "MWL",
                authorityName: "Muslim World League",
                countryOrRegionHints: ["Global fallback", "Europe", "Africa"],
                fajrAngleDegrees: 18.0,
                defaultHighLatitudeRule: .automatic,
                sourceNotes: "Common global calculation profile.",
                isBuiltIn: true,
                isDeprecated: false
            )
        case .egyptian:
            return PrayerCalculationMethod(
                id: "egyptianGeneralAuthority",
                legacyIDs: ["egyptian"],
                displayName: "Egyptian General Authority of Survey",
                shortDisplayName: "Egyptian",
                authorityName: "Egyptian General Authority of Survey",
                countryOrRegionHints: ["Egypt"],
                fajrAngleDegrees: 19.5,
                defaultHighLatitudeRule: .automatic,
                sourceNotes: "Existing Egyptian method value retained.",
                isBuiltIn: true,
                isDeprecated: false
            )
        case .karachi:
            return PrayerCalculationMethod(
                id: "karachi",
                legacyIDs: [],
                displayName: "University of Islamic Sciences, Karachi",
                shortDisplayName: "Karachi",
                authorityName: "University of Islamic Sciences, Karachi",
                countryOrRegionHints: ["Pakistan", "India", "Bangladesh", "Afghanistan"],
                fajrAngleDegrees: 18.0,
                defaultHighLatitudeRule: .automatic,
                sourceNotes: "Existing Karachi method value retained.",
                isBuiltIn: true,
                isDeprecated: false
            )
        case .northAmerica:
            return PrayerCalculationMethod(
                id: "isna",
                legacyIDs: ["northAmerica"],
                displayName: "Islamic Society of North America",
                shortDisplayName: "ISNA",
                authorityName: "Islamic Society of North America",
                countryOrRegionHints: ["United States", "Canada"],
                fajrAngleDegrees: 15.0,
                defaultHighLatitudeRule: .automatic,
                sourceNotes: "Existing North America method value retained under the ISNA profile.",
                isBuiltIn: true,
                isDeprecated: false
            )
        case .makkah:
            return PrayerCalculationMethod(
                id: "ummAlQura",
                legacyIDs: ["makkah"],
                displayName: "Umm al-Qura, Makkah",
                shortDisplayName: "Umm al-Qura",
                authorityName: "Umm al-Qura University, Makkah",
                countryOrRegionHints: ["Saudi Arabia"],
                fajrAngleDegrees: 18.5,
                defaultHighLatitudeRule: .automatic,
                sourceNotes: "Existing Makkah method value retained under the Umm al-Qura profile.",
                isBuiltIn: true,
                isDeprecated: false
            )
        }
    }
}

enum PrayerHighLatitudeRule: String, Codable, Equatable, Hashable, Sendable {
    case none
    case middleOfNight
    case oneSeventhOfNight
    case angleBased
    case automatic
}

enum PrayerRoundingPolicy: String, Codable, Equatable, Hashable, Sendable {
    case nearestMinute
    case floorMinute
    case ceilMinute
}

enum PrayerCalculationSource: String, Codable, Equatable, Hashable, Sendable {
    case localCalculated
    case providerAPI
    case cachedProviderAPI
    case mosqueTimetable
    case userOverride
    case fallbackLocalCalculated
    case unavailable
}

enum FajrBeginSource: String, Codable, Equatable, Hashable, Sendable {
    case localSolarAngle
    case providerAPI
    case mosqueTimetable
    case userOverride
    case unavailable
}

enum FajrEndSource: String, Codable, Equatable, Hashable, Sendable {
    case solarSunrise
    case providerSunrise
    case providerFajrEnd
    case mosqueTimetable
    case userOverride
    case unavailable

    var providerNote: String {
        switch self {
        case .solarSunrise:
            return "source:solar_sunrise_fajr_end"
        case .providerSunrise:
            return "source:provider_sunrise_fajr_end"
        case .providerFajrEnd:
            return "source:provider_fajr_end"
        case .mosqueTimetable:
            return "source:mosque_timetable_fajr_end"
        case .userOverride:
            return "source:user_override_fajr_end"
        case .unavailable:
            return "fallback:missing_fajr_end"
        }
    }
}

enum MaghribSource: String, Codable, Equatable, Hashable, Sendable {
    case localSolarSunset
    case providerAPI
    case mosqueTimetable
    case userOverride
    case unavailable
}

struct PrayerBoundaryAdjustments: Codable, Equatable, Hashable, Sendable {
    let fajrBeginMinutes: Int
    let fajrEndMinutes: Int
    let maghribMinutes: Int

    static let none = PrayerBoundaryAdjustments(
        fajrBeginMinutes: 0,
        fajrEndMinutes: 0,
        maghribMinutes: 0
    )
}

struct PrayerCalculationDiagnostics: Codable, Equatable, Hashable, Sendable {
    let engineVersion: Int
    let methodVersion: Int
    let inputLatitude: Double?
    let inputLongitude: Double?
    let inputTimeZoneIdentifier: String?
    let dayOfYearUsed: Int?
    let solarAlgorithmName: String
    let rawFajrHour: Double?
    let rawSunriseHour: Double?
    let rawSunsetHour: Double?
    let highLatitudeFailureReason: String?
    let validationWarnings: [String]
    let fallbackChain: [String]

    static let unavailable = PrayerCalculationDiagnostics(
        engineVersion: 1,
        methodVersion: 1,
        inputLatitude: nil,
        inputLongitude: nil,
        inputTimeZoneIdentifier: nil,
        dayOfYearUsed: nil,
        solarAlgorithmName: "NOAA sunrise equation",
        rawFajrHour: nil,
        rawSunriseHour: nil,
        rawSunsetHour: nil,
        highLatitudeFailureReason: nil,
        validationWarnings: [],
        fallbackChain: []
    )
}
