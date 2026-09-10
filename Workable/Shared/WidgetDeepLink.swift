import Foundation

/// URLs the `TodayGlanceWidget` uses for its `widgetURL` tap targets, and the
/// in-app routing they map to. Scheme must be registered in the app's
/// Info.plist (`CFBundleURLTypes`) for `onOpenURL` to receive it.
enum WidgetDeepLink {
    static let scheme = "workable"

    enum Destination: Equatable {
        case home
        case timeOff
        case recruiting
    }

    /// `workable://home`, `workable://timeoff`, `workable://recruiting`.
    static func destination(for url: URL) -> Destination? {
        guard url.scheme == scheme else { return nil }
        switch url.host {
        case "timeoff":
            return .timeOff
        case "recruiting":
            return .recruiting
        case "home", .none:
            return .home
        default:
            return nil
        }
    }

    static func url(for destination: Destination) -> URL {
        switch destination {
        case .home:
            return URL(string: "\(scheme)://home")!
        case .timeOff:
            return URL(string: "\(scheme)://timeoff")!
        case .recruiting:
            return URL(string: "\(scheme)://recruiting")!
        }
    }
}
