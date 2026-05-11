import Foundation
import os

private let logLevel = 0 // 0: VERBOSE, 1: DEBUG, 2: INFO, 3: WARNING, 4: ERROR

enum OZLogLevelType: Int {
    case v = 0, d, i, w, e

    var title: String {
        switch self {
        case .v: return "⚪️VERBOSE "
        case .d: return "🟢DEBUG "
        case .i: return "🔵INFO "
        case .w: return "🟡WARNING "
        case .e: return "⭕️ERROR "
        }
    }
}

final class Log {
    private static let logger = Logger(
        subsystem: "com.hyeonjunkim.Weather-closet",
        category: "WeatherCloset"
    )

    static func v(_ tag: String, _ message: String) { write(.v, tag, message) }
    static func d(_ tag: String, _ message: String) { write(.d, tag, message) }
    static func i(_ tag: String, _ message: String) { write(.i, tag, message) }
    static func w(_ tag: String, _ message: String) { write(.w, tag, message) }
    static func e(_ tag: String, _ message: String) { write(.e, tag, message) }

    private static func write(_ level: OZLogLevelType, _ tag: String, _ message: String) {
        guard level.rawValue >= logLevel else { return }
        let output = "\(level.title)\(tag)::\(message)"
        switch level {
        case .v: logger.log("\(output, privacy: .public)")
        case .d: logger.debug("\(output, privacy: .public)")
        case .i: logger.info("\(output, privacy: .public)")
        case .w: logger.warning("\(output, privacy: .public)")
        case .e: logger.error("\(output, privacy: .public)")
        }
    }
}
